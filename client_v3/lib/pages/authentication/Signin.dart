import 'package:flutter/material.dart';
import 'package:flutter_keychain/flutter_keychain.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:client_v3/constants/ui.dart';
import 'package:client_v3/pages/home/Home.dart';
import 'package:client_v3/providers/ClientProvider.dart';
import 'package:client_v3/repositories/ClientRepository.dart';
import 'package:client_v3/setupSingletons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:rxdart/rxdart.dart';

class AuthenticationSignInForm extends StatelessWidget {
  final clientProvider = getIt.get<ClientProvider>();
  final clientRepository = getIt.get<ClientRepository>();

  final BehaviorSubject _loading$ = BehaviorSubject.seeded(false);
  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  final RegExp _emailRegex = new RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

  final _passwordFocusNode = FocusNode();

  final _emailController = TextEditingController(text: "");
  final _passwordController = TextEditingController(text: "");

  @override
  Widget build(BuildContext context) {
    _loading$.pairwise().listen((val) async {
      final latestValues = val.toList();
      if (!latestValues[0] && latestValues[1]) {
        try {
          final email = _emailController.value.text;
          final password = _passwordController.value.text;

          final result =
              await clientRepository.signIn(email: email, password: password);
          _loading$.add(false);

          if (result == null) {
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text(
                "Email/senha incorretos",
                textAlign: TextAlign.center,
              ),
            ));
          } else {
            FlutterKeychain.put(key: "token", value: result);
            await clientProvider.loadClient();

            Navigator.pushReplacement(
                context,
                PageTransition(
                    duration: const Duration(milliseconds: 500),
                    type: PageTransitionType.fade,
                    child: HomePage()));
          }
        } catch (e) {
          debugPrint(e.toString());
          _loading$.add(false);
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text(
              "Erro. Por favor, tente novamente",
              textAlign: TextAlign.center,
            ),
          ));
        }
      }
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: <Widget>[
          Container(
            height: 300,
            child: Stack(
              children: [
                Container(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors["background2"],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 50, right: 50, bottom: 50),
                      child: _buildForm(context),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, 30),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildButton(),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _buildButton() {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5), color: colors["primary"]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _submitForm();
          },
          child: Container(
            width: 200,
            height: 60,
            child: StreamBuilder(
                stream: _loading$.stream,
                builder: (context, snapshot) {
                  return Center(
                      child: !snapshot.hasData || !snapshot.data
                          ? Text(
                              "Entrar",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : SpinKitWave(
                              color: Colors.white,
                              size: 20,
                            ));
                }),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _buildEmailInput(context),
          _buildPasswordInput(context)
        ],
      ),
    );
  }

  Widget _buildEmailInput(BuildContext context) {
    return TextFormField(
        validator: (value) {
          if (value.isEmpty || !_emailRegex.hasMatch(value)) {
            return "Email inválido";
          }
        },
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) {
          FocusScope.of(context).requestFocus(_passwordFocusNode);
        },
        controller: _emailController,
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 20.0),
            hintText: "Email",
            hintStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Icon(
                Icons.email,
                color: colors["primary"],
              ),
            ),
            border: UnderlineInputBorder(
                borderSide: BorderSide(color: colors["primary"])),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors["primary"])),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors["primary"]))));
  }

  Widget _buildPasswordInput(BuildContext context) {
    return TextFormField(
        validator: (value) {
          if (value.isEmpty) {
            return "Digite a senha";
          }
        },
        textInputAction: TextInputAction.done,
        focusNode: _passwordFocusNode,
        controller: _passwordController,
        obscureText: true,
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 20.0),
            hintText: "Senha",
            hintStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Icon(
                Icons.lock,
                color: colors["primary"],
              ),
            ),
            border: UnderlineInputBorder(
                borderSide: BorderSide(color: colors["primary"])),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors["primary"])),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors["primary"]))));
  }

  void _submitForm() {
    if (_form.currentState.validate()) {
      _loading$.add(true);
    }
  }
}

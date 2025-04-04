import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String error = '';
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? "Login" : "Register")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                onChanged: (val) => setState(() => email = val),
                decoration: InputDecoration(labelText: "Email"),
                validator: (val) => val!.isEmpty ? "Enter an email" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                onChanged: (val) => setState(() => password = val),
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
                validator:
                    (val) =>
                        val!.length < 6 ? "Password must be 6+ chars" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    dynamic result;
                    if (isLogin) {
                      result = await _auth.signInWithEmailAndPassword(
                        email,
                        password,
                      );
                    } else {
                      result = await _auth.registerWithEmailAndPassword(
                        email,
                        password,
                      );
                    }
                    if (result == null) {
                      setState(() => error = "Invalid credentials");
                    }
                  }
                },
                child: Text(isLogin ? "Login" : "Register"),
              ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? "Create an account" : "Login instead"),
              ),
              Text(error, style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }
}

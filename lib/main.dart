import 'package:flutter/material.dart';
import 'package:olivia_journal/auth.dart';
import 'package:olivia_journal/views/survey_selection.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Center(
        child: InkWell(
          hoverColor: Colors.redAccent.shade400,
          child: Container(color: Colors.lightBlueAccent.shade400, child: Center(child: Text("Start", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w500)))),
          onTap: (){
            signInWithGoogle().whenComplete(() => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => SurveySelector()
            )));
          },
        )
      )
    );
  }
}



void main() => runApp(new MaterialApp(
  home: LoginPage(),
  debugShowCheckedModeBanner: false
));

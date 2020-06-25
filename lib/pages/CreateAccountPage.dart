import 'dart:async';
import 'package:Askforum/widgets/HeaderWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateAccountPage extends StatefulWidget {
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  String username;

  submitUsername(){
    final form = _formKey.currentState;
    if(form.validate()){
      form.save();

      SnackBar snackBar = SnackBar(content: Text("Welcome  " + username));
      _scaffoldKey.currentState.showSnackBar(snackBar);
      Timer(Duration(seconds: 4), (){
        Navigator.pop(context, username);
      });
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context, strTitle: "Settings", disappearedBackButton: true),
      body: ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(padding: EdgeInsets.only(top: 26.0),
                child: Center(
                  child: Text("Set up a username", style: TextStyle(fontSize: 26.0),),
                ),
                ),
                Padding(padding: EdgeInsets.all(17.0),
                child: Container(
                 child: Form(
                   key: _formKey,
                     autovalidate: true,
                     child: TextFormField(
                       style: TextStyle(color: Colors.white),
                       validator: (val){
                         if(val.trim().length<5 || val.isEmpty){
                           return "user name is very short.";
                         }
                         else if(val.trim().length>15 || val.isEmpty){
                           return "user name is very long.";
                         }
                         else{
                           return null;
                         }
                       },
                       onSaved: (val) => username = val,
                       decoration: InputDecoration(
                         enabledBorder: UnderlineInputBorder(
                           borderSide: BorderSide(
                             color: Colors.grey),
                           ),
                           focusedBorder: UnderlineInputBorder(
                           borderSide: BorderSide(
                             color: Colors.white,
                           )
                         ),
                         border: OutlineInputBorder(),
                         labelText: "Username",
                         labelStyle: TextStyle(
                           fontSize: 16.0
                         ),
                         hintText: "must be atleast 5 character",
                         hintStyle: TextStyle(
                           color: Colors.grey,
                         ),
                       ),
                     ),
                 ),
                ),
                ),
                GestureDetector(
                  onTap: submitUsername,
                  child: Container(
                    height: 55.0,
                    width: 360.0,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text("Proceed",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

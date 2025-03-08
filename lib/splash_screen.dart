// ignore_for_file: use_key_in_widget_constructors, camel_case_types

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sphere/main.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _splashScreenState();
}

class _splashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AuthCheck(),
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.pink[300],
        child: Center(
          child: Text(
            "String",
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: use_key_in_widget_constructors, camel_case_types

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vetra/main.dart';

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
        color: Color(0xFF00A676),
        child: Center(
          child: Text(
            "VETRA",
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

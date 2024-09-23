import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chatbot/HomePage.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Lottie.network(
            "https://lottie.host/08917e40-ce1c-472c-aab1-8cb643f45caf/w8htzgNZoc.json",
            fit: BoxFit.contain,
            width: 300,
            height: 300,
          ),
        ],
      ),
      nextScreen: HomePage(),
      duration: 4000,
      splashIconSize: 400,
      backgroundColor: Colors.grey.shade800  ,
      centered: true,
    );
  }
}

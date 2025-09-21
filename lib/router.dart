import 'package:cnn/features/Auth/abc.dart';
import 'package:cnn/features/Auth/screens/login_page.dart';
import 'package:cnn/features/Auth/screens/sign_up_updated.dart';
import 'package:flutter/material.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case LoginPage.routeName:
      return MaterialPageRoute(builder: (context) => const LoginPage());
    case SignUp.routeName:
      return MaterialPageRoute(builder: (context) => const SignUp());
    case Home.routeName:
      return MaterialPageRoute(builder: (context) => const Home());
    default:
      return MaterialPageRoute(
        builder: (context) =>
            const Scaffold(body: Center(child: Text('No route defined'))),
      );
  }
}

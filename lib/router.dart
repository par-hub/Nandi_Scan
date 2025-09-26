import 'package:cnn/features/Specifation/screens/specification_with_controller.dart';
import 'package:cnn/home.dart';
import 'package:cnn/features/Auth/screens/login_page.dart';
import 'package:cnn/features/Auth/screens/sign_up_updated.dart';
import 'package:cnn/features/Auth/screens/splash_screen.dart';
import 'package:cnn/features/health/screen/health.dart';
import 'package:cnn/api_test_screen.dart';
import 'package:cnn/features/registration/screen/reg_screen.dart';
import 'package:cnn/features/cattle/screens/cattle_owned_screen.dart';
import 'package:cnn/features/prediction/screens/breed_prediction_screen.dart';
import 'package:cnn/features/profile/screens/profile_screen.dart';
import 'package:cnn/features/settings/screens/settings_screen.dart';
import 'package:cnn/features/activity/screen/activity_screen.dart';
import 'package:cnn/features/activity/screen/create_activity.dart';
import 'package:flutter/material.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case SplashScreen.routeName:
      return MaterialPageRoute(builder: (context) => const SplashScreen());
    case LoginPage.routeName:
      return MaterialPageRoute(builder: (context) => const LoginPage());
    case SignUp.routeName:
      return MaterialPageRoute(builder: (context) => const SignUp());
    case Home.routeName:
      return MaterialPageRoute(builder: (context) => const Home());
    case SpecificationScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const SpecificationScreen(),
      );
    case AnimalRegistrationScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const AnimalRegistrationScreen(),
      );
    case HealthScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const HealthScreen(),
      );
    case CattleOwnedScreen.routeName:
      return MaterialPageRoute(builder: (context) => const CattleOwnedScreen());
    case BreedPredictionScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const BreedPredictionScreen(),
      );
    case ProfileScreen.routeName:
      return MaterialPageRoute(builder: (context) => const ProfileScreen());
    case SettingsScreen.routeName:
      return MaterialPageRoute(builder: (context) => const SettingsScreen());
    case ActivityScreen.routeName:
      return MaterialPageRoute(builder: (context) => const ActivityScreen());
    case CreateActivityScreen.routeName:
      return MaterialPageRoute(builder: (context) => const CreateActivityScreen());
    case '/api-test':
      return MaterialPageRoute(builder: (context) => const ApiTestScreen());
    default:
      return MaterialPageRoute(
        builder: (context) =>
            const Scaffold(body: Center(child: Text('No route defined'))),
      );
  }
}

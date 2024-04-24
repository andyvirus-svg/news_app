import 'package:flutter/material.dart';
import 'package:news_app/login_screen.dart'; // Import the Login Screen
import 'package:news_app/news_screen.dart'; // Import the News Screen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Set the initial route to '/'
      routes: {
        '/': (context) => LoginScreen(), // Navigate to LoginScreen on '/'
        '/news': (context) => NewsScreen(), // Navigate to NewsScreen on '/news'
      },
    );
  }
}
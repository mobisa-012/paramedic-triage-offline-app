import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paramedic Triage Offline App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF102A43)
        ),
      ),
      fontFamily: "Roboto"
      home: const MyHomePage(title: 'Paramedic Triage Offline App'),
    );
  }
}

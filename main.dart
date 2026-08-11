import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class ApiEndpoints {
  
static const String baseUrl = 'http://localhost:3000/api/v1';  
  static const String auth          = '$baseUrl/auth';
  static const String routes        = '$baseUrl/routes';
  static const String smartbin      = '$baseUrl/smartbin';
  static const String aiVision      = '$baseUrl/ai-vision';
  static const String notifications = '$baseUrl/notifications';
}

void main() => runApp(const TrashTimeApp());

class TrashTimeApp extends StatelessWidget {
  const TrashTimeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TrashTime Microservicios',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFF2ECC71), useMaterial3: true),
        home: const LoginScreen(),
      );
}

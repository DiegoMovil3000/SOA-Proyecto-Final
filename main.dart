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

// Modelos
class Usuario {
  final String id, nombre, email, rol, avatar, token;
  const Usuario(this.id, this.nombre, this.email, this.rol, this.avatar, this.token);
}

class Checkpoint {
  final String id, nombre, direccion;
  bool completado;
  String hora;
  Checkpoint(this.id, this.nombre, this.direccion, {this.completado = false, this.hora = ''});

  factory Checkpoint.fromJson(Map<String, dynamic> json) => Checkpoint(
    json['id'] ?? '', json['nombre'] ?? '', json['direccion'] ?? '',
    completado: json['completado'] ?? false, hora: json['hora'] ?? ''
  );
}

class ItemBote {
  String nombre, icono, tipo;
  bool listo;
  ItemBote(this.nombre, this.icono, this.tipo, {this.listo = false});
}

final itemsBote = [
  ItemBote('Restos de comida', '🍎', 'orgánica'),
  ItemBote('Botellas PET', '♻️', 'reciclable'),
  ItemBote('Cartón', '📦', 'reciclable'),
];

bool boteAbierto = false;
List<Map<String, dynamic>> notificaciones = [];

final historial = [
  {'fecha': '18 Abr', 'hora': '08:22', 'kg': '12.5'},
  {'fecha': '16 Abr', 'hora': '08:45', 'kg': '9.8'},
  {'fecha': '14 Abr', 'hora': '09:10', 'kg': '15.2'},
];

// 1. LOGIN (Consume Microservicio 1: Auth)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.post(
        Uri.parse('${ApiEndpoints.auth}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email.text, 'password': _pass.text}),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final u = data['user'];
        final userObj = Usuario(u['id'], u['nombre'], u['email'], u['rol'], u['avatar'], data['token']);
        
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => userObj.rol == 'recolector' ? DashRecolector(userObj) : DashCiudadano(userObj),
        ));
      }
    } catch (_) {
      // Fallback local en caso de no tener Docker encendido al probar
      final isRec = _email.text.contains('carlos');
      final userObj = Usuario('1', isRec ? 'Carlos Recolector' : 'María Ciudadana', _email.text, isRec ? 'recolector' : 'ciudadano', isRec ? '🚛' : '🏠', 'jwt');
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => userObj.rol == 'recolector' ? DashRecolector(userObj) : DashCiudadano(userObj),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _demo(String rol) {
    _email.text = rol == 'recolector' ? 'carlos@trash.com' : 'maria@casa.com';
    _pass.text  = '123456';
    setState(() {});
  }

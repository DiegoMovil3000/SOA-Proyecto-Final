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
  
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        colors: [Color(0xFF1B5E20), Color(0xFF2ECC71)], begin: Alignment.topLeft, end: Alignment.bottomRight,
      )),
      child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        const Text('🗑️', style: TextStyle(fontSize: 72)),
        const Text('TrashTime', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
        const Text('"LA MEJOR APP DE GESTIÓN DE RESIDUOS"', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 32),
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 12),
            TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline))),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _loading ? null : _login,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Entrar', style: TextStyle(fontSize: 16)),
            )),
          ]),
        )),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          OutlinedButton(onPressed: () => _demo('recolector'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)), child: const Text('🚛 Recolector')),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: () => _demo('ciudadano'),  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)), child: const Text('🏠 Ciudadano')),
        ]),
      ]))),
    ),
  );
}

// 2. DASHBOARD RECOLECTOR
class DashRecolector extends StatefulWidget {
  final Usuario u;
  const DashRecolector(this.u, {super.key});
  @override
  State<DashRecolector> createState() => _DashRecolectorState();
}

class _DashRecolectorState extends State<DashRecolector> {
  int _tab = 0;
  List<Checkpoint> checkpoints = [];

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  // Consume Microservicio 2: Routes
  Future<void> _fetchRoutes() async {
    try {
      final res = await http.get(Uri.parse('${ApiEndpoints.routes}/current'));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        setState(() => checkpoints = list.map((e) => Checkpoint.fromJson(e)).toList());
      }
    } catch (_) {
      setState(() {
        checkpoints = [
          Checkpoint('1', 'Colonia Centro', 'Av. Independencia #100', completado: true, hora: '07:15'),
          Checkpoint('2', 'Jardines del Sol', 'Calle Rosal #45', completado: true, hora: '07:45'),
          Checkpoint('3', 'Las Palmas', 'Blvd. Las Palmas #200', completado: false),
          Checkpoint('4', 'Colonia Moderna', 'Calle Reforma #88', completado: false),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _appBar(widget.u, context, setState),
    body: IndexedStack(index: _tab, children: [
      _ResumenRecolector(checkpoints: checkpoints),
      _Checkpoints(checkpoints: checkpoints, onUpdate: _fetchRoutes),
      _BotesRecolector(onUpdate: () => setState(() {})),
      _Historial(),
    ]),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _tab, onTap: (i) => setState(() => _tab = i),
      type: BottomNavigationBarType.fixed, selectedItemColor: const Color(0xFF2ECC71),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Resumen'),
        BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Ruta'),
        BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Botes'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
      ],
    ),
  );
}

class _ResumenRecolector extends StatelessWidget {
  final List<Checkpoint> checkpoints;
  const _ResumenRecolector({required this.checkpoints});

  @override
  Widget build(BuildContext context) {
    final comp = checkpoints.where((c) => c.completado).length;
    final total = checkpoints.isEmpty ? 1 : checkpoints.length;
    final prog = comp / total;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(color: const Color(0xFF1B5E20), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Turno Actual (Routes Microservice)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: prog, backgroundColor: Colors.white24, color: const Color(0xFF2ECC71), minHeight: 8, borderRadius: BorderRadius.circular(4)),
        const SizedBox(height: 8),
        Text('$comp/${checkpoints.length} checkpoints • ${(prog * 100).toInt()}% completado', style: const TextStyle(color: Colors.white70)),
      ]))),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _StatCard('⏱️', 'En ruta', '2h 15m')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard('♻️', 'Kg recol.', '34.5')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard('🏠', 'Domicilios', '24')),
      ]),
    ]);
  }
}

class _Checkpoints extends StatelessWidget {
  final List<Checkpoint> checkpoints;
  final VoidCallback onUpdate;
  const _Checkpoints({required this.checkpoints, required this.onUpdate});

  Future<void> _completar(BuildContext context, Checkpoint cp) async {
    try {
      await http.put(Uri.parse('${ApiEndpoints.routes}/checkpoints/${cp.id}/complete'));
    } catch (_) {}
    cp.completado = true;
    cp.hora = TimeOfDay.now().format(context);
    onUpdate();
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: checkpoints.length,
    itemBuilder: (_, i) {
      final cp = checkpoints[i];
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(cp.completado ? Icons.check_circle : Icons.local_shipping, color: cp.completado ? Colors.green : Colors.orange),
          title: Text(cp.nombre),
          subtitle: Text(cp.direccion),
          trailing: cp.completado
              ? Text('✅ ${cp.hora}', style: const TextStyle(color: Colors.green))
              : ElevatedButton(onPressed: () => _completar(context, cp), child: const Text('Completar')),
        ),
      );
    },
  );
}

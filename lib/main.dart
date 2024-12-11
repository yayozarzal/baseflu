import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Raíz de la aplicación
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión Académica',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade100),
        useMaterial3: true,
      ),
      home: const DefaultTabController(
        length: 4,
        child: MyHomePage(title: 'Gestión de Usuarios'),
      ),

    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // No necesitamos variables de estado aquí

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Usuario'),
            Tab(text: 'Tramite'),
            Tab(text: 'Mapa'),
            Tab(text: 'Acelerómetro'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          UsuarioTab(),
          TramiteTab(),
          MapaTab(),
          AcelerometroTab(),
        ],
      ),
    );
  }
}

class AcelerometroTab extends StatefulWidget {
  const AcelerometroTab({Key? key}) : super(key: key);

  @override
  State<AcelerometroTab> createState() => _AcelerometroTabState();
}

class _AcelerometroTabState extends State<AcelerometroTab> {
  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;
  late final StreamSubscription<AccelerometerEvent> _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    // Suscribirse a las actualizaciones del acelerómetro
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _x = event.x;
        _y = event.y;
        _z = event.z;
      });
    });
  }

  @override
  void dispose() {
    // Cancelar la suscripción para evitar fugas de memoria
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Acelerómetro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text('X: ${_x.toStringAsFixed(2)}'),
          Text('Y: ${_y.toStringAsFixed(2)}'),
          Text('Z: ${_z.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}


class UsuarioTab extends StatefulWidget {
  const UsuarioTab({Key? key}) : super(key: key);

  @override
  _UsuarioTabState createState() => _UsuarioTabState();
}

class _UsuarioTabState extends State<UsuarioTab> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _nombreUsuarioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  List<Map<String, dynamic>> usuarios = [];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  void _cargarUsuarios() {
    DatabaseReference ref = FirebaseDatabase.instance.ref("usuarios");
    ref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        usuarios = [];
        data.forEach((key, value) {
          usuarios.add({
            "id": key,
            "login": value["login"],
            "contrasena": value["contrasena"],
            "nombre_usuario": value["nombre_usuario"],
            "email": value["email"],
          });
        });
        setState(() {});
      }
    });
  }

  void _agregarUsuario() {
    String login = _loginController.text;
    String contrasena = _contrasenaController.text;
    String nombreUsuario = _nombreUsuarioController.text;
    String email = _emailController.text;

    if (login.isNotEmpty && contrasena.isNotEmpty && nombreUsuario.isNotEmpty && email.isNotEmpty) {
      DatabaseReference ref = FirebaseDatabase.instance.ref("usuarios");

      ref.push().set({
        "login": login,
        "contrasena": contrasena,
        "nombre_usuario": nombreUsuario,
        "email": email,
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario agregado')),
        );
        _loginController.clear();
        _contrasenaController.clear();
        _nombreUsuarioController.clear();
        _emailController.clear();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar usuario: $error')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos')),
      );
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _contrasenaController.dispose();
    _nombreUsuarioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Formulario para agregar usuario
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _loginController,
                decoration: InputDecoration(
                  labelText: 'Login',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _contrasenaController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nombreUsuarioController,
                decoration: InputDecoration(
                  labelText: 'Nombre de Usuario',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _agregarUsuario,
                child: Text('Agregar Usuario'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              return ListTile(
                title: Text('${usuario["nombre_usuario"]} (${usuario["login"]})'),
                subtitle: Text('Email: ${usuario["email"]}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TramiteTab extends StatefulWidget {
  const TramiteTab({Key? key}) : super(key: key);

  @override
  _TramiteTabState createState() => _TramiteTabState();
}

class _TramiteTabState extends State<TramiteTab> {
  final TextEditingController _tipoTramiteController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _tiempoEsperaController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();

  List<Map<String, dynamic>> tramites = [];

  @override
  void initState() {
    super.initState();
    _cargarTramites();
  }

  void _cargarTramites() {
    DatabaseReference ref = FirebaseDatabase.instance.ref("tramites");
    ref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        tramites = [];
        data.forEach((key, value) {
          tramites.add({
            "id": key,
            "tipo_tramite": value["tipo_tramite"],
            "estado": value["estado"],
            "fecha_inicio": value["fecha_inicio"],
            "tiempo_espera": value["tiempo_espera"],
            "observaciones": value["observaciones"],
          });
        });
        setState(() {});
      }
    });
  }

  void _agregarTramite() {
    String tipoTramite = _tipoTramiteController.text;
    String estado = _estadoController.text;
    String fechaInicio = _fechaInicioController.text;
    String tiempoEspera = _tiempoEsperaController.text;
    String observaciones = _observacionesController.text;

    if (tipoTramite.isNotEmpty && estado.isNotEmpty && fechaInicio.isNotEmpty && tiempoEspera.isNotEmpty && observaciones.isNotEmpty) {
      DatabaseReference ref = FirebaseDatabase.instance.ref("tramites");

      ref.push().set({
        "tipo_tramite": tipoTramite,
        "estado": estado,
        "fecha_inicio": fechaInicio,
        "tiempo_espera": tiempoEspera,
        "observaciones": observaciones,
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trámite agregado')),
        );
        _tipoTramiteController.clear();
        _estadoController.clear();
        _fechaInicioController.clear();
        _tiempoEsperaController.clear();
        _observacionesController.clear();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar trámite: $error')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos')),
      );
    }
  }

  @override
  void dispose() {
    _tipoTramiteController.dispose();
    _estadoController.dispose();
    _fechaInicioController.dispose();
    _tiempoEsperaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Formulario para agregar trámite
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _tipoTramiteController,
                decoration: InputDecoration(
                  labelText: 'Tipo de Trámite',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _estadoController,
                decoration: InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _fechaInicioController,
                decoration: InputDecoration(
                  labelText: 'Fecha de Inicio (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _tiempoEsperaController,
                decoration: InputDecoration(
                  labelText: 'Tiempo de Espera',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _observacionesController,
                decoration: InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _agregarTramite,
                child: Text('Agregar Trámite'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: tramites.length,
            itemBuilder: (context, index) {
              final tramite = tramites[index];
              return ListTile(
                title: Text('${tramite["tipo_tramite"]} - ${tramite["estado"]}'),
                subtitle: Text('Inició el: ${tramite["fecha_inicio"]}, Espera: ${tramite["tiempo_espera"]}\nObservaciones: ${tramite["observaciones"]}'),
              );
            },
          ),
        ),
      ],
    );
  }
}


class MapaTab extends StatefulWidget {
  const MapaTab({Key? key}) : super(key: key);

  @override
  _MapaTabState createState() => _MapaTabState();
}

class _MapaTabState extends State<MapaTab> {
  final TextEditingController _idDireccionController = TextEditingController();
  final TextEditingController _latitudController = TextEditingController();
  final TextEditingController _longitudController = TextEditingController();

  List<Map<String, dynamic>> direcciones = [];

  @override
  void initState() {
    super.initState();
    _cargarDirecciones();
  }

  void _cargarDirecciones() {
    DatabaseReference ref = FirebaseDatabase.instance.ref("mapa");
    ref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        direcciones = [];
        data.forEach((key, value) {
          direcciones.add({
            "id": key,
            "id_direccion": value["id_direccion"],
            "latitud": value["latitud"],
            "longitud": value["longitud"],
          });
        });
        setState(() {});
      }
    });
  }

  void _agregarDireccion() {
    String idDir = _idDireccionController.text;
    String latStr = _latitudController.text;
    String lonStr = _longitudController.text;

    if (idDir.isNotEmpty && latStr.isNotEmpty && lonStr.isNotEmpty) {
      double? lat = double.tryParse(latStr);
      double? lon = double.tryParse(lonStr);

      if (lat != null && lon != null) {
        DatabaseReference ref = FirebaseDatabase.instance.ref("mapa");

        ref.push().set({
          "id_direccion": idDir,
          "latitud": lat,
          "longitud": lon,
        }).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dirección agregada')),
          );
          _idDireccionController.clear();
          _latitudController.clear();
          _longitudController.clear();
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al agregar dirección: $error')),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, ingresa latitud y longitud válidas')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos')),
      );
    }
  }

  @override
  void dispose() {
    _idDireccionController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Formulario para agregar dirección
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _idDireccionController,
                decoration: InputDecoration(
                  labelText: 'ID de Dirección',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _latitudController,
                decoration: InputDecoration(
                  labelText: 'Latitud',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _longitudController,
                decoration: InputDecoration(
                  labelText: 'Longitud',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _agregarDireccion,
                child: Text('Agregar Dirección'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: direcciones.length,
            itemBuilder: (context, index) {
              final dir = direcciones[index];
              return ListTile(
                title: Text('ID: ${dir["id_direccion"]}'),
                subtitle: Text('Lat: ${dir["latitud"]}, Lon: ${dir["longitud"]}'),
              );
            },
          ),
        ),
      ],
    );
  }
}





import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = FlutterSecureStorage();

  String? _token;
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _carregarToken();
  }

  Future<void> _carregarToken() async {
    final token = await _storage.read(key: 'token');
    final expString = await _storage.read(key: 'token_exp');

    if (token != null && expString != null) {
      final expTimestamp = int.parse(expString);
      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = ((expTimestamp - now) / 1000).ceil();

      if (remaining > 0) {
        setState(() {
          _token = token;
          _secondsLeft = remaining;
        });
        _startTimer();
      } else {
        // Token expirou
        await _storage.delete(key: 'token');
        await _storage.delete(key: 'token_exp');
      }
    }
  }

  Future<void> _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isNotEmpty && password.isNotEmpty) {
      final token = 'token_${DateTime.now().millisecondsSinceEpoch}';
      final expTime = DateTime.now().add(Duration(minutes: 2)).millisecondsSinceEpoch;

      await _storage.write(key: 'token', value: token);
      await _storage.write(key: 'token_exp', value: expTime.toString());

      setState(() {
        _token = token;
        _secondsLeft = 2 * 60;
      });

      _startTimer();

      print('Token armazenado: $token');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        await _storage.delete(key: 'token');
        await _storage.delete(key: 'token_exp');
        setState(() {
          _token = null;
          _timer?.cancel();
        });
        print('Token expirou');
      }
    });
  }

  Future<void> _verificarToken() async {
    final token = await _storage.read(key: 'token');
    setState(() => _token = token);
    print('Token atual: $token');
  }

  String _formatTempo(int segundos) {
    final min = (segundos ~/ 60).toString().padLeft(2, '0');
    final sec = (segundos % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Token Persistente')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Senha')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text('Login')),
            ElevatedButton(onPressed: _verificarToken, child: Text('Verificar Token')),
            SizedBox(height: 20),
            Text(_token != null ? 'Token: $_token' : 'Nenhum token armazenado'),
            if (_token != null) Text('Expira em: ${_formatTempo(_secondsLeft)}'),
          ],
        ),
      ),
    );
  }
}

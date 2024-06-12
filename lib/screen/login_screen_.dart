// ignore_for_file: prefer_const_constructors, sort_child_properties_last, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:aplikasi_absen/screen/dashboard_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; // Import TextInputFormatter

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() {
    return _LoginForm();
  }
}

class _LoginForm extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _usernameError = false;
  bool _passwordError = false;
  bool _loginError = false; // Variabel untuk melacak status kesalahan login
  String _errorMessage = ''; // Variabel untuk menyimpan pesan kesalahan
  bool _obscureText = true;
  bool _isLoading = false;

  Future<void> _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      Future.microtask(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter your username and password')),
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loginError = false; // Reset status kesalahan login
    });

    const url =
        'https://presensi.spilme.id/login'; // Replace with your server address
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final token = responseBody['token'];
      final name = responseBody['nama'];
      final dept = responseBody['departemen'];
      final imgUrl = responseBody['imgUrl'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt', token);
      await prefs.setString('name', name);
      await prefs.setString('dept', dept);
      await prefs.setString('imgProfil', imgUrl);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => Dashboard()),
        (route) => false,
      );
    } else {
      setState(() {
        _loginError = true;
        _errorMessage = 'Invalid username or password'; // Pesan kesalahan login
      });

      // Menunggu hingga setState selesai dan context memiliki Scaffold
      Future.microtask(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid username or password')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image(
                  image: AssetImage('assets/images/logoPolbeng.png'),
                  height: 100.0,
                ),
                Text(
                  'Selamat Datang di ',
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'PresensiApp',
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      errorText: _usernameError ? 'Username salah' : null,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(
                          r'[a-zA-Z0-9]')), // Only allow alphanumeric characters
                      LowerCaseTextFormatter(), // Convert input to lowercase
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                      errorText: _passwordError ? 'Password salah' : null,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(
                          r'[a-zA-Z0-9]')), // Only allow alphanumeric characters
                      LowerCaseTextFormatter(), // Convert input to lowercase
                    ],
                  ),
                ),
                SizedBox(height: 10),
                // Menampilkan pesan kesalahan di bawah kolom password
                Visibility(
                  visible: _loginError,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        // Tambahkan logika saat tombol "Lupa Password" ditekan
                      },
                      child: Text(
                        'Lupa Password',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _usernameError = _usernameController.text.isEmpty;
                        _passwordError = _passwordController.text.isEmpty;
                      });

                      if (!_usernameError && !_passwordError) {
                        _login();
                      }
                    },
                    child: _isLoading
                        ? CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text(
                            'Masuk',
                            style: TextStyle(color: Colors.white),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Column(
                  children: <Widget>[
                    Text('Masuk Dengan Sidik Jari ?',
                        style: TextStyle(fontSize: 16.0)),
                    SizedBox(height: 20),
                    Image(
                      image: AssetImage('assets/images/fingerprint.png'),
                      height: 41.92,
                      width: 39.9,
                    ),
                    SizedBox(height: 20),
                    Text('Belum punya akun ?'),
                    Text(
                      'Daftar',
                      style: TextStyle(color: Colors.purple),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toLowerCase(),
    );
  }
}

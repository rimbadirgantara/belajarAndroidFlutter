// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

void main() {
  runApp(Testing());
}

class Testing extends StatelessWidget {
  const Testing({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi Keren',
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              children: <Widget>[
                SizedBox(height: 50),
                Image(
                  image: AssetImage('assets/images/logoPolbeng.png'),
                  height: 200,
                ),
                Text(
                  'Testing',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: <Widget>[
                    SizedBox(height: 50),
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(color: Colors.blue),
                      child: Text('ini dia',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

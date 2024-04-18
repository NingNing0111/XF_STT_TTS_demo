import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iflytek_tts_stt_demo/page/stt.dart';
import 'package:iflytek_tts_stt_demo/page/tts.dart';
import 'package:iflytek_tts_stt_demo/service/iflytek_service.dart';
import 'package:logger/logger.dart';

var logger = Logger();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final navigationBarItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.abc), label: "tts"),
    const BottomNavigationBarItem(icon: Icon(Icons.adb_rounded), label: "stt")
  ];

  int _currIndex = 0;

  final List<Widget> bodyList = [
    const XFTTSPage(),
    const XFSTTPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("科大讯飞 STT 和 TTS"),
        centerTitle: true,
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: bodyList[_currIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: navigationBarItems,
        onTap: (value) {
          setState(() {
            _currIndex = value;
          });
        },
        currentIndex: _currIndex,
      ),
    );
  }
}

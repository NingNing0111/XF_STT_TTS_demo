import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:iflytek_tts_stt_demo/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../service/iflytek_service.dart';

class XFSTTPage extends StatefulWidget {
  const XFSTTPage({super.key});

  @override
  State<StatefulWidget> createState() => _XFSTTPageState();
}

class _XFSTTPageState extends State<XFSTTPage> {
  late XfService _service;
  late bool _isSpeech;
  List<int> _currByte = [];
  late AudioRecorder audioRecorder;
  Stream<Uint8List>? _recorderStream;

  @override
  void initState() {
    super.initState();
    _service = XfService(
        appId: "xxx",
        apiSecret: "xxx",
        apiKey: "xxx");
    _isSpeech = false;
    audioRecorder = AudioRecorder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: toSTT,
        child: _isSpeech ? const Icon(Icons.mic_off) : const Icon(Icons.mic),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> toSTT() async {
    bool recorderStates = await audioRecorder.hasPermission();
    var fileStates = await Permission.storage.status;
    var audioStates = await Permission.audio.status;
    if(!fileStates.isDenied){
      logger.e("存储无权限");
      return;
    }
    if(!audioStates.isDenied){
      logger.e("音频无权限");
    }
    if (!recorderStates) {
      logger.e("麦克风未授权");
      return;
    }
    if (!_isSpeech) {
      setState(() {
        _isSpeech = true;
      });
      await startRecorder();
    } else {
      setState(() {
        _isSpeech = false;
      });
      await stopRecorder();
      logger.f("录音完成");
      logger.f(base64Encode(_currByte));
      final AudioPlayer audioPlayer = AudioPlayer();
      await audioPlayer.play(BytesSource(Uint8List.fromList(_currByte)));
    }
  }

  Future<void> startRecorder() async {

    _recorderStream = await audioRecorder
        .startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits));

  }

  Future<void> stopRecorder() async {
    await audioRecorder.cancel();
  }

  void onEvent(event) {
    logger.f(event);
  }
}

import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iflytek_tts_stt_demo/main.dart';
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
  late AudioRecorder audioRecorder;
  int _sendStatus = 0;
  List<Uint8List> _currUint8List = [];

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
    bool recorderStatues = await audioRecorder.hasPermission();
    if(!recorderStatues){
      logger.e("无权限");
      return;
    }
    if (!_isSpeech) {
      setState(() {
        _isSpeech = true;
      });
      // _service.setupSTTListener((event)=>onEvent(event));
      startRecording();
    } else {
      setState(() {
        _isSpeech = false;
      });
      stopRecording();
      logger.f("录音完成");
    }
  }

  void onEvent(event) {
    logger.f(event);
  }

  Future<void> startRecording() async {
    Stream<Uint8List> stream = await audioRecorder
        .startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits));

  }

  Future<Uint8List> _collectStreamData(Stream<Uint8List> stream) async {
    // 列表用于累积所有的音频数据块
    List<Uint8List> audioDataList = [];

    // 订阅流并将每个数据块添加到列表中
    await for (Uint8List audioChunk in stream) {
      audioDataList.add(audioChunk);
    }

    // 将所有的音频数据块合并成一个完整的 Uint8List
    int totalLength = audioDataList.fold(0, (prev, chunk) => prev + chunk.length);
    Uint8List fullAudioData = Uint8List(totalLength);
    int offset = 0;
    for (Uint8List audioChunk in audioDataList) {
      fullAudioData.setRange(offset, offset + audioChunk.length, audioChunk);
      offset += audioChunk.length;
    }

    return fullAudioData;
  }

  Future<void> stopRecording() async {
    await audioRecorder.cancel();
  }
}

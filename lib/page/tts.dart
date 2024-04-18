import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../service/iflytek_service.dart';

class XFTTSPage extends StatefulWidget {
  const XFTTSPage({super.key});

  @override
  State<StatefulWidget> createState() => _XFTTSPageState();
}

class _XFTTSPageState extends State<XFTTSPage> {
  late XfService _service;
  final AudioPlayer audioPlayer = AudioPlayer();
  List<int> _currByte = [];
  final String testText =
      """埃隆·马斯克（Elon Musk）是一位著名的企业家、工程师和投资者。他在科技和商业领域拥有众多成就，并创办或领导了一些全球知名的公司。以下是他的一些主要成就和角色：
              1. **特斯拉（Tesla）：** 马斯克是电动汽车公司特斯拉的联合创始人和现任首席执行官（CEO）。在他的领导下，特斯拉成为电动汽车领域的领军企业，并在全球范围内推动了电动汽车的发展。""";

  @override
  void initState() {
    super.initState();
    _service = XfService(
        appId: "xxx",
        apiSecret: "xxx",
        apiKey: "xxx");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(testText)),
      floatingActionButton: FloatingActionButton(
        onPressed: toTTS,
        child: const Icon(Icons.ad_units_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> toTTS() async {
    await audioPlayer.stop();
    initTTS();
    Map<String, dynamic> param = _service.createTTSRequestParam(text: testText);
    _service.ttsSendText(param);
  }

  // 建立TTS通道连接，并设置监听函数
  void initTTS() {
    _service.initConnect(tts: true);
    _service.setupTTSListener((event) => onEvent(event));
  }

  // 合成后的base64合并并播放
  void onEvent(event) {
    logger.f(event);
    int status = event['status'];
    String base64 = event['audio'];
    Uint8List base64Byte = base64Decode(base64);
    _currByte = [..._currByte, ...base64Byte];
    if (status == 2) {
      audioPlayer.play(BytesSource(Uint8List.fromList(_currByte)));
      _currByte.clear();
      _currByte = [];
    }
  }
}

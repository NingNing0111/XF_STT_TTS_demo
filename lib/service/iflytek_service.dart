import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/io.dart';

class _XfAPI {
  static const String ttsUrl = "wss://tts-api.xfyun.cn/v2/tts";
  static const String sttUrl = "wss://iat-api.xfyun.cn/v2/iat";
}

class XfService {
  late String _appId;
  late String _apiSecret;
  late String _apiKey;
  IOWebSocketChannel? _ttsChannel;
  IOWebSocketChannel? _sttChannel;
  var logger = Logger();

  XfService({required appId, required apiSecret, required apiKey}) {
    _apiKey = apiKey;
    _apiSecret = apiSecret;
    _appId = appId;
  }

  void initConnect({tts = false, stt = false}) {
    if (tts) {
      _ttsChannel = _createWebSocketChannel(_XfAPI.ttsUrl);
    }
    if (stt) {
      _sttChannel = _createWebSocketChannel(_XfAPI.sttUrl);
    }
  }

  IOWebSocketChannel _createWebSocketChannel(String url) {
    return IOWebSocketChannel.connect(assembleAuthUrl(url, _apiKey, _apiSecret),
        connectTimeout: const Duration(seconds: 5),
        pingInterval: const Duration(seconds: 5));
  }

  void close() {
    _ttsChannel?.sink.close();
    _sttChannel?.sink.close();
  }

  void setupTTSListener(Function(dynamic) onEvent,
      {Function? onError, Function? onDone}) {
    // 监听 TTS 通道的数据流
    _ttsChannel?.stream.listen(
      (event) {
        Map<String, dynamic> resp = jsonDecode(event);
        if (resp['code'] == 0) {
          var data = resp['data'];
          if (data != null) {
            onEvent(data);
          }
        } else {
          onError!.call(resp);
        }
      }, // 接收到数据时调用的函数
      onError: (error) {
        // 如果提供了 onError 参数，则使用它处理错误，否则记录日志
        logger.e('WebSocket error: $error');
        onError?.call();
      },
      onDone: () {
        logger.i('WebSocket connection closed');
        onDone?.call();
      },
    );
  }

  void ttsSendText(Map<String, dynamic> param) {
    // 检查 TTS 通道是否可用
    if (_ttsChannel == null || _ttsChannel!.closeCode != null) {
      _ttsChannel = _createWebSocketChannel(_XfAPI.ttsUrl);
    }
    try {
      String json = jsonEncode(param);
      logger.f("发送的消息:$json");
      _ttsChannel?.sink.add(json);
    } catch (e) {
      logger.e('Failed to send TTS text: $e');
    }
  }

  void setupSTTListener(Function(dynamic) onEvent,
      {Function? onError, Function? onDone}) {
    _sttChannel?.stream.listen((event) {
      logger.f(event.toString());
    }, onError: (error) {
      logger.e(error);
    }, onDone: () {
      logger.f("完成");
    });
  }

  void sendAudio(Map<String, dynamic> param) {
    if (_sttChannel == null || _sttChannel!.closeCode != null) {
      _sttChannel = _createWebSocketChannel(_XfAPI.sttUrl);
    }
    try {
      String json = jsonEncode(param);
      logger.f("音频发送的参数:$json");
      _sttChannel?.sink.add(param);
    } catch (e) {
      logger.e(e);
    }
  }

  Map<String, dynamic> createSTTRequestParam({
    String language = "zh_cn",
    String domain = "iat",
    String accent = "mandarin",
    int vad_eos = 2000,
    String? dwa,
    String? pd,
    int ptt = 1,
    String? rlang,
    int vinfo = 0,
    int nunum = 1,
    int? speex_size,
    int? nbest,
    int? wbest,
    required int status,
    String format = "audio/L16;rate=16000",
    String encoding = "raw",
    required Uint8List audio,
  }) {
    return {
      "common": {"app_id": _appId},
      "business": {
        "language": language,
        "domain": domain,
        "accent": accent,
        "vad_eos": vad_eos,
        "dwa": dwa,
        "pd": pd,
        "ptt": ptt,
        "rlang": rlang,
        "vinfo": vinfo,
        "nunum": nunum,
        "speex_size": speex_size,
        "nbest": nbest,
        "wbest": wbest,
        "encoding": encoding,
      },
      "data": {"status": status, "format": format, "audio": base64Encode(audio)}
    };
  }

  Map<String, dynamic> createTTSRequestParam(
      {String aue = "lame",
      String vcn = "x4_lingxiaolu_en",
      int speed = 50,
      int volume = 50,
      int pitch = 50,
      int sfl = 1,
      String auf = "audio/L16;rate=16000",
      int bgs = 0,
      String tte = "UTF8",
      String reg = "2",
      String rdn = "0",
      required String text}) {
    return {
      "common": {"app_id": _appId},
      "business": {
        "aue": aue,
        "vcn": vcn,
        "speed": speed,
        "volume": volume,
        "pitch": pitch,
        "sfl": sfl,
        "auf": auf,
        "bgs": bgs,
        "tte": tte,
        "reg": reg,
        "rdn": rdn
      },
      "data": {"text": base64.encode(utf8.encode(text)), "status": 2}
    };
  }

  // 鉴权API
  static String assembleAuthUrl(
      String hostUrl, String apiKey, String apiSecret) {
    // 解析 URL
    var ul = Uri.parse(hostUrl);
    // 签名时间
    var date =
        DateFormat('EEE, dd MMM yyyy HH:mm:ss').format(DateTime.now().toUtc());
    // 参与签名的字段 host, date, request-line
    List<String> signString = [
      'host: ${ul.host}',
      'date: $date',
      'GET ${ul.path} HTTP/1.1',
    ];

    // 拼接签名字符串
    var sgin = signString.join('\n');
    // 生成 HMAC-SHA256 签名
    var hmacSha256 = Hmac(sha256, utf8.encode(apiSecret));
    var digest = hmacSha256.convert(utf8.encode(sgin));
    var sha = base64.encode(digest.bytes);
    // 构建请求参数
    var authUrl =
        'api_key="$apiKey", algorithm="hmac-sha256", headers="host date request-line", signature="$sha"';

    // 对请求参数进行 Base64 编码
    var authorization = base64.encode(utf8.encode(authUrl));

    // 构建 URL 参数
    var params = {
      'host': ul.host,
      'date': date,
      'authorization': authorization,
    };

    // 将参数进行 URL 编码并拼接到 URL 后面
    var callUrl =
        Uri.parse(hostUrl).replace(queryParameters: params).toString();

    return callUrl;
  }
}

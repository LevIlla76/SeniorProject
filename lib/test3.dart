import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  stt.SpeechToText _speech = stt.SpeechToText();
  FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _text = "กดปุ่มเพื่อเริ่มพูด...";
  bool _speechAvailable = false;
  bool _isLoading = false;
  String? _warningMessage;
  String _userSpeech = "";
  ScrollController _scrollController = ScrollController();
  bool _isAtBottom = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

    @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize();
    setState(() {
      _speechAvailable = available;
      // ไม่ต้อง setState _text ที่นี่ ถ้าใช้ Text แยกหัวข้อ
    });
  }

  Future<void> _startListening() async {
    if (_speechAvailable) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _userSpeech = result.recognizedWords;
            _text = result.recognizedWords; // ยังแสดงบนหน้าจอได้เหมือนเดิม
          });
        },
      );
    } else {
      setState(() => _text = "ไม่สามารถเริ่มการฟังได้");
    }
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    await _speech.stop();
    await _processText(_userSpeech); // 🔄 ใช้เฉพาะที่ผู้ใช้พูด
  }

  Future<void> _processText(String userInput) async {
    // ❌ ถ้าไม่พูดอะไรเลย หรือยังเป็นข้อความเริ่มต้น
    if (userInput.trim().isEmpty || userInput == "กดปุ่มเพื่อเริ่มพูด...") {
      setState(() {
        _warningMessage = "⚠️ โปรดพูดข้อความก่อน";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _text = "🤖 กำลังประมวลผล...";
      _warningMessage = null;
    });

    String responseText = await _sendTextToNLP(userInput);

    await _speak(responseText);

    setState(() {
      _text = responseText;
      _isLoading = false;
    });

     // ✅ ถ้าได้รับการยืนยันปลายทาง
  if (responseText.contains("Confirmed. Going to D1")) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DestinationPage(destination: "D1")),
    );
  } else if (responseText.contains("Confirmed. Going to E1")) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DestinationPage(destination: "E1")),
    );
  }
  }

  Future<String> _sendTextToNLP(String text) async {
    try {
      var response = await http.post(
        Uri.parse(
            'http://192.168.1.114:8000/analyze/'), // เปลี่ยนเป็น IP ของคุณ
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}),
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['response'];
      } else {
        return "❌ เซิร์ฟเวอร์ไม่ตอบกลับ หรือเกิดข้อผิดพลาด";
      }
    } catch (e) {
      return "❌ ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้";
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts
        .setLanguage("en-US"); // เปลี่ยนเป็น "th-TH" ถ้าอยากให้พูดไทย
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Chatbot")),
      body: Stack(
        children: [
          // ส่วนข้อความเลื่อนดูได้ อยู่ด้านบน
            Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "🎙️ สถานะไมโครโฟน",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent) {
                if (!_isAtBottom) {
                  setState(() {
                    _isAtBottom = true;
                  });
                }
              } else {
                if (_isAtBottom) {
                  setState(() {
                    _isAtBottom = false;
                  });
                }
              }
              return true;
            },
            child: Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.2,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _isAtBottom
                          ? [Colors.black, Colors.black]
                          : [Colors.black, Colors.black, Colors.transparent],
                      stops: _isAtBottom ? [0.0, 1.0] : [0.0, 0.8, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading)
                            Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 20),
                                Text(
                                  "🤖 กำลังประมวลผล...",
                                  style: TextStyle(fontSize: 18),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          else ...[
                            if (_warningMessage != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  _warningMessage!,
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.orange),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            Text(
                              _text,
                              style: TextStyle(
                                fontSize: 18,
                                color: _speechAvailable
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),

          // ปุ่มอยู่กลางหน้าจอเสมอ
          Align(
            alignment: Alignment.center,
            child: _isLoading
                ? SizedBox.shrink()
                : SizedBox(
                    width: 200,
                    height: 200,
                    child: FloatingActionButton(
                      onPressed:
                          _isListening ? _stopListening : _startListening,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        _isListening ? Icons.mic_off : Icons.mic,
                        size: 120,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class DestinationPage extends StatelessWidget {
  final String destination;

  const DestinationPage({Key? key, required this.destination}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Destination: $destination")),
      body: Center(
        child: Text(
          "You're now heading to $destination!",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  bool _isSpeaking = false;
  String _text = "กดปุ่มเพื่อเริ่มพูด...";
  bool _speechAvailable = false;

  // ตัวแปรเพื่อเก็บภาษาที่เลือก
  String _selectedLanguage = 'th_TH'; // ค่าเริ่มต้นเป็นภาษาไทย

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  // เริ่มต้นการตรวจสอบไมโครโฟน
  Future<void> _initSpeech() async {
    bool available = await _speech.initialize();
    setState(() {
      _speechAvailable = available;
      _text = available ? "พร้อมใช้งาน Speech-to-Text" : "ไมโครโฟนไม่สามารถใช้งานได้ หรือไม่รองรับฟังก์ชัน Speech-to-Text";
    });
  }

  // เริ่มการฟังจากไมโครโฟน
  Future<void> _startListening() async {
    if (_speechAvailable) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _text = result.recognizedWords;  // แสดงข้อความที่พูดออกมาในขณะนั้น
          });
        },
        listenFor: Duration(seconds: 30), // ฟังต่อเนื่อง 30 วินาที
        pauseFor: Duration(seconds: 3),   // ถ้าไม่มีเสียง 3 วินาทีจะหยุดการฟัง
        partialResults: true,             // ต้องการผลลัพธ์ที่ยังไม่สมบูรณ์ (เรียลไทม์)
        localeId: _selectedLanguage,      // ใช้ภาษาที่เลือก
      );
    } else {
      setState(() => _text = "ไมโครโฟนไม่สามารถเริ่มการฟังได้");
    }
  }

  // หยุดการฟัง
  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    await _speech.stop();
  }

  // ฟังก์ชันให้พูดข้อความที่ได้จากการแปลงเสียง
  Future<void> _speak() async {
    if (_text.isNotEmpty) {
      setState(() => _isSpeaking = true);
      await _flutterTts.setLanguage(_selectedLanguage == 'th_TH' ? 'th-TH' : 'en-US'); // เลือกภาษา TTS ตามที่เลือก
      await _flutterTts.speak(_text);
      setState(() => _isSpeaking = false);
    }
  }

  // ฟังก์ชันเลือกภาษา
  void _onLanguageChanged(String? newLanguage) {
    setState(() {
      _selectedLanguage = newLanguage!;
      _text = "เลือกภาษา: ${_selectedLanguage == 'th_TH' ? 'ภาษาไทย' : 'ภาษาอังกฤษ'}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Speech-to-Text & Text-to-Speech")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ตัวเลือกเลือกภาษา
            DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: _onLanguageChanged,
              items: [
                DropdownMenuItem(
                  value: 'th_TH',
                  child: Text('ภาษาไทย'),
                ),
                DropdownMenuItem(
                  value: 'en_US',
                  child: Text('English'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              _text,
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center, // เพื่อให้อยู่กลางจอ
            ),
            SizedBox(height: 20),
            // ปุ่มสำหรับเริ่ม/หยุดการฟัง
            FloatingActionButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Icon(_isListening ? Icons.mic_off : Icons.mic),
            ),
            SizedBox(height: 20),
            // ปุ่มสำหรับให้ TTS อ่านข้อความ
            FloatingActionButton(
              onPressed: _isSpeaking ? null : _speak, // ป้องกันไม่ให้กดขณะพูด
              child: Icon(Icons.volume_up),
            ),
          ],
        ),
      ),
    );
  }
}

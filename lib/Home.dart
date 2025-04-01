import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart'; // นำเข้า audioplayers

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); 
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<String> locations = ["M square", "D1", "C1", "C2", "C3"];
  final AudioPlayer _audioPlayer = AudioPlayer(); // สร้างอินสแตนซ์ของ AudioPlayer

  // ฟังก์ชันที่เล่นเสียงตามตำแหน่ง
  Future<void> _playSound(String location) async {
    String soundFile = '';
    switch (location) {
      case 'M square':
        soundFile = 'm_square_click.mp3';
        break;
      case 'D1':
        soundFile = '/d1_click.mp3';
        break;
      case 'C1':
        soundFile = '/c1_click.mp3';
        break;
      case 'C2':
        soundFile = '/c2_click.mp3';
        break;
      case 'C3':
        soundFile = '/c3_click.mp3';
        break;
      default:
        soundFile = '/button_click.mp3'; // เสียงปกติ
    }
    await _audioPlayer.play(AssetSource(soundFile)); // เล่นเสียงที่เลือก
  }

  // ฟังก์ชันแสดง Dialog ยืนยันการไปยังสถานที่
  Future<void> _showConfirmationDialog(BuildContext context, String location) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // ปิดไม่ให้ปิดด้วยการคลิกภายนอก
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการไปที่ $location'),
          content: Text('คุณแน่ใจจะไป $location หรือไม่?'),
          actions: <Widget>[
            TextButton(
              child: Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop(); // ปิด Dialog
              },
            ),
            TextButton(
              child: Text('ตกลง'),
              onPressed: () {
                Navigator.of(context).pop(); // ปิด Dialog
                _showConfirmationMessage(context, location); // แสดงข้อความยืนยัน
              },
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันแสดงข้อความยืนยันการไปยังสถานที่
  void _showConfirmationMessage(BuildContext context, String location) {
    final message = 'คุณยืนยันจะไปที่ $location';
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar); // แสดง SnackBar ที่ด้านล่างของหน้าจอ
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            // Title
            Text(
              "MFU SmartPath AI Vision",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            // List of locations as buttons
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        _playSound(locations[index]); // เล่นเสียงทันทีเมื่อกดปุ่ม
                        _showConfirmationDialog(context, locations[index]); // แสดง Dialog ยืนยัน
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.store, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            locations[index],
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

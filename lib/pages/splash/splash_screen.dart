import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:video_call_flutter/pages/room/room_page.dart';
import 'package:video_call_flutter/pages/socket.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  TextEditingController inputController = TextEditingController(text: '');
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            children: [
              TextFormField(
                controller: inputController,
              ),
              TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MySocketPage(
                              userId: int.parse(inputController.text)))),
                  child: const Text('Go'))
            ],
          ),
        ),
      ),
    );
  }
}

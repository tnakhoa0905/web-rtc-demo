import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';
import 'package:video_call_flutter/service/signaling_service.dart';

class MySocketPage extends StatefulWidget {
  const MySocketPage({super.key, required this.userId});

  @override
  _MySocketPageState createState() => _MySocketPageState();
  final int userId;
}

class _MySocketPageState extends State<MySocketPage> {
  late IO.Socket socket;
  final SignalingService _signalingService = SignalingService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  StreamController<String> _messageStreamController =
      StreamController<String>();

  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    init();
    openMedia();
    print('abc');

    socket.on('connection', (_) {
      print('Connected to server');
      print(socket.id);
    });
    socket.on('socket_result', (data) {
      var result = data.toString();
      eventHandle(data['key']);
      _messageStreamController.add(result);
    });

    socket.on('message', (data) {
      // print('Received message: $data');
      // _messageStreamController.add(data);
    });
  }

  openMedia() async {
    await _signalingService.openUserMedia(
        _localRenderer, _remoteRenderer, widget.userId);
  }

  eventHandle(String key) {
    switch (key) {
      case "ready_call_video":
        print('123');
        break;
      case "accept":
        print(456);
        break;
      case "test_caller":
        print(456);
        break;
      default:
        print('sai me roi');
    }
  }

  init() async {
    socket = IO.io(
        // 'http://localhost:3000/',
        'http://192.168.1.19:3011/',
        IO.OptionBuilder().setTransports(['websocket']).setExtraHeaders(
          {
            'userId': widget.userId == 1
                ? "65a9eeec07eb5e12fc89b022"
                : "65ade51d52ec9524543d1393",
          },
        )
            // .disableAutoConnect()
            .build());
    socket.onConnect((data) => {print('connecttion')});
    socket.onConnectError((data) => {print("wrong in $data")});
    socket.connect();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    print('logout');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(socket.id);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Socket.IO Chat'),
          leading: TextButton(
              onPressed: () async {
                // Navigator.pop(context);
              },
              child: const Text(
                'aaa',
                style: TextStyle(color: Colors.white),
              )),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Type your message here...',
                ),
                onChanged: (text) {
                  socket.emit('chat message', text);
                  socket.emit('login', 'user1');
                },
              ),
              Expanded(
                child: StreamBuilder(
                  stream: _messageStreamController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Text(snapshot.data.toString()),
                          ],
                        ),
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.userId == 1)
                        Expanded(
                            child: RTCVideoView(_localRenderer, mirror: true)),
                      if (widget.userId == 0)
                        Expanded(child: RTCVideoView(_remoteRenderer)),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                  onPressed: () {
                    openMedia();
                    socket.emit('ready_call_video', {
                      "userId": widget.userId == 1
                          ? "65a9eeec07eb5e12fc89b022"
                          : "65ade51d52ec9524543d1393",
                      "roomId": "65ae21676e6bf82890133864"
                    });
                  },
                  child: const Text('hehe')),
              ElevatedButton(
                  onPressed: () async {
                    List result = await _signalingService.createRoom(
                        _remoteRenderer, socket);
                    print("8" * 100);
                    print(result[1]);
                    // socket.emit('call_video', {
                    //   "roomId": "65ae21676e6bf82890133864",
                    //   "userId": "65ade51d52ec9524543d1393",
                    //   'spd': result[0].sdp,
                    //   'type': result[0].type,
                    //   "caller": result[1]
                    // });
                  },
                  child: const Text('call_video')),
              ElevatedButton(
                  onPressed: () {
                    socket.emit(
                        'call_video', {"roomId": "65ae21676e6bf82890133864"});
                  },
                  child: const Text('join room')),
            ],
          ),
        ),
      ),
    );
  }
}

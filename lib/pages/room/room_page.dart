import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:video_call_flutter/pages/socket.dart';
import 'package:video_call_flutter/signaling.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key, required this.isAdmin});
  final int isAdmin;

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  Signaling signaling = Signaling();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  TextEditingController textEditingController = TextEditingController(text: '');
  TextEditingController userController = TextEditingController(text: '');

  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });
    init();
    super.initState();
  }

  init() async {
    await signaling.openUserMedia(
        _localRenderer, _remoteRenderer, widget.isAdmin);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to Flutter Explained - WebRTC"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    signaling.openUserMedia(
                        _localRenderer, _remoteRenderer, widget.isAdmin);
                  },
                  child: const Text("Open camera & microphone"),
                ),
                const SizedBox(
                  width: 8,
                ),
                ElevatedButton(
                  onPressed: () async {
                    roomId = await signaling.createRoom(_remoteRenderer);
                    textEditingController.text = roomId!;
                    setState(() {});
                  },
                  child: const Text("Create room"),
                ),
                const SizedBox(
                  width: 8,
                ),
                // ElevatedButton(
                //   onPressed: () {
                //     // Add roomId
                //     signaling.joinRoom(
                //       textEditingController.text.trim(),
                //       _remoteRenderer,
                //     );
                //   },
                //   child: Text("Join room"),
                // ),
                ElevatedButton(
                  onPressed: () async {
                    signaling.joinStream(
                      textEditingController.text.trim(),
                      _remoteRenderer,
                    );
                  },
                  child: const Text("Join Stream"),
                ),
                const SizedBox(
                  width: 8,
                ),
                const SizedBox(
                  width: 8,
                ),
                ElevatedButton(
                  onPressed: () {
                    signaling.hangUp(_localRenderer);
                  },
                  child: const Text("Hangup"),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isAdmin == 1)
                    Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
                  if (widget.isAdmin == 0)
                    Expanded(child: RTCVideoView(_remoteRenderer)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Join the following Room: "),
                Flexible(
                  child: TextFormField(
                    controller: textEditingController,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("User: "),
                Flexible(
                  child: TextFormField(
                    controller: userController,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8)
        ],
      ),
    );
  }
}

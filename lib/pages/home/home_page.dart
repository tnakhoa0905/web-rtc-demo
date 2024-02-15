import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:video_call_flutter/cubit/home/home_cubit.dart';
import 'package:video_call_flutter/cubit/home/home_state.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _localVideoRenderer = RTCVideoRenderer();
  final _remoteVideoRenderer = RTCVideoRenderer();
  final sdpController = TextEditingController();

  bool _offer = false;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  initRenderer() async {
    await _localVideoRenderer.initialize();
    await _remoteVideoRenderer.initialize();
  }

  _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      }
    };

    MediaStream stream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);

    _localVideoRenderer.srcObject = stream;
    return stream;
  }

  _createPeerConnecion() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    _localStream = await _getUserMedia();

    RTCPeerConnection pc =
        await createPeerConnection(configuration, offerSdpConstraints);

    pc.addStream(_localStream!);

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        print(json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMLineIndex,
        }));
      }
    };

    pc.onIceConnectionState = (e) {
      print(e);
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      _remoteVideoRenderer.srcObject = stream;
    };

    return pc;
  }

  void _createOffer() async {
    RTCSessionDescription description =
        await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp.toString());
    print(json.encode(session));
    _offer = true;

    _peerConnection!.setLocalDescription(description);
  }

  void _createAnswer() async {
    RTCSessionDescription description =
        await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});

    var session = parse(description.sdp.toString());
    print(json.encode(session));

    _peerConnection!.setLocalDescription(description);
  }

  void _setRemoteDescription() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString);

    String sdp = write(session, null);

    RTCSessionDescription description =
        RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
    print(description.toMap());

    await _peerConnection!.setRemoteDescription(description);
  }

  void _addCandidate() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString);
    print(session['candidate']);
    dynamic candidate = RTCIceCandidate(
        session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
    await _peerConnection!.addCandidate(candidate);
  }

  @override
  void initState() {
    initRenderer();
    _createPeerConnecion().then((pc) {
      _peerConnection = pc;
    });
    // _getUserMedia();
    super.initState();
  }

  @override
  void dispose() async {
    await _localVideoRenderer.dispose();
    sdpController.dispose();
    super.dispose();
  }

  SizedBox videoRenderers() => SizedBox(
        height: 210,
        child: Row(children: [
          Flexible(
            child: Container(
              key: const Key('local'),
              margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(_localVideoRenderer),
            ),
          ),
          Flexible(
            child: Container(
              key: const Key('remote'),
              margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(_remoteVideoRenderer),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('asd'),
        ),
        body: Column(
          children: [
            videoRenderers(),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: TextField(
                      controller: sdpController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 4,
                      maxLength: TextField.noMaxLength,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _createOffer,
                      child: const Text("Offer"),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ElevatedButton(
                      onPressed: _createAnswer,
                      child: const Text("Answer"),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ElevatedButton(
                      onPressed: _setRemoteDescription,
                      child: const Text("Set Remote Description"),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ElevatedButton(
                      onPressed: _addCandidate,
                      child: const Text("Set Candidate"),
                    ),
                  ],
                )
              ],
            ),
          ],
        ));
  }
  // bool _offer = false;
  // RTCPeerConnection? _peerConnection;
  // MediaStream? _localStream;
  // RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  // RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // final sdpController = TextEditingController();
  // late IO.Socket socket;
  // @override
  // dispose() {
  //   _localRenderer.dispose();
  //   _remoteRenderer.dispose();
  //   sdpController.dispose();
  //   super.dispose();
  // }

  // @override
  // void initState() {
  //   initRenderer();
  //   _createPeerConnecion().then((pc) {
  //     _peerConnection = pc;
  //   });
  //   // _getUserMedia();
  //   super.initState();
  //   // Kết nối tới server Socket.IO
  // }

  // initRenderer() async {
  //   await _localRenderer.initialize();
  //   await _remoteRenderer.initialize();
  // }

  // _createPeerConnecion() async {
  //   Map<String, dynamic> configuration = {
  //     "iceServers": [
  //       {"url": "stun:stun.l.google.com:19302"},
  //     ]
  //   };

  //   final Map<String, dynamic> offerSdpConstraints = {
  //     "mandatory": {
  //       "OfferToReceiveAudio": true,
  //       "OfferToReceiveVideo": true,
  //     },
  //     "optional": [],
  //   };

  //   _localStream = await _getUserMedia();

  //   RTCPeerConnection pc =
  //       await createPeerConnection(configuration, offerSdpConstraints);

  //   pc.addStream(_localStream!);

  //   pc.onIceCandidate = (e) {
  //     if (e.candidate != null) {
  //       // print(json.encode({
  //       //   'candidate': e.candidate.toString(),
  //       //   'sdpMid': e.sdpMid.toString(),
  //       //   'sdpMlineIndex': e.sdpMLineIndex,
  //       // }));
  //     }
  //   };

  //   pc.onIceConnectionState = (e) {
  //     // print(e);
  //   };

  //   pc.onAddStream = (stream) {
  //     // print('addStream: ' + stream.id);
  //     _remoteRenderer.srcObject = stream;
  //   };

  //   return pc;
  // }

  // _getUserMedia() async {
  //   final Map<String, dynamic> constraints = {
  //     'audio': false,
  //     'video': {
  //       'facingMode': 'user',
  //     },
  //   };

  //   MediaStream stream = await navigator.mediaDevices.getUserMedia(constraints);

  //   _localRenderer.srcObject = stream;
  //   // _localRenderer.mirror = true;

  //   return stream;
  // }

  // void _createOffer() async {
  //   RTCSessionDescription description =
  //       await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
  //   var session = parse(description.sdp.toString());
  //   // print(json.encode(session));
  //   _offer = true;

  //   _peerConnection!.setLocalDescription(description);
  // }

  // void _createAnswer() async {
  //   RTCSessionDescription description =
  //       await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});

  //   var session = parse(description.sdp.toString());
  //   // print(json.encode(session));
  //   // print(json.encode({
  //   //       'sdp': description.sdp.toString(),
  //   //       'type': description.type.toString(),
  //   //     }));

  //   _peerConnection!.setLocalDescription(description);
  // }

  // void _setRemoteDescription() async {
  //   String jsonString = sdpController.text;
  //   dynamic session = await jsonDecode(jsonString);

  //   String sdp = write(session, null);

  //   // RTCSessionDescription description =
  //   //      RTCSessionDescription(session['sdp'], session['type']);
  //   RTCSessionDescription description =
  //       RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
  //   // print(description.toMap());

  //   await _peerConnection!.setRemoteDescription(description);
  // }

  // void _addCandidate() async {
  //   String jsonString = sdpController.text;
  //   dynamic session = await jsonDecode(jsonString);
  //   // print(session['candidate']);
  //   dynamic candidate = RTCIceCandidate(
  //       session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
  //   await _peerConnection!.addCandidate(candidate);
  // }

  // SizedBox videoRenderers() => SizedBox(
  //     height: 210,
  //     child: Row(children: [
  //       Flexible(
  //         child: Container(
  //             key: const Key("local"),
  //             margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
  //             decoration: const BoxDecoration(color: Colors.black),
  //             child: RTCVideoView(_localRenderer)),
  //       ),
  //       Flexible(
  //         child: Container(
  //             key: const Key("remote"),
  //             margin: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
  //             decoration: const BoxDecoration(color: Colors.black),
  //             child: RTCVideoView(_remoteRenderer)),
  //       )
  //     ]));

  // Row offerAndAnswerButtons() =>
  //     Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
  //       ElevatedButton(
  //         // onPressed: () {
  //         //   return showDialog(
  //         //       context: context,
  //         //       builder: (context) {
  //         //         return AlertDialog(
  //         //           content: Text(sdpController.text),
  //         //         );
  //         //       });
  //         // },
  //         onPressed: _createOffer,
  //         child: const Text('Offer'),
  //         // color: Colors.amber,
  //       ),
  //       ElevatedButton(
  //         onPressed: _createAnswer,
  //         style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
  //         child: const Text('Answer'),
  //       ),
  //     ]);

  // Row sdpCandidateButtons() =>
  //     Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
  //       ElevatedButton(
  //         onPressed: _setRemoteDescription,
  //         child: const Text('Set Remote Desc'),
  //         // color: Colors.amber,
  //       ),
  //       ElevatedButton(
  //         onPressed: _addCandidate,
  //         child: const Text('Add Candidate'),
  //         // color: Colors.amber,
  //       )
  //     ]);

  // Padding sdpCandidatesTF() => Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: TextField(
  //         controller: sdpController,
  //         keyboardType: TextInputType.multiline,
  //         maxLines: 4,
  //         maxLength: TextField.noMaxLength,
  //       ),
  //     );
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //       appBar: AppBar(
  //         title: const Text('video call'),
  //       ),
  //       body: Column(
  //         children: [
  //           videoRenderers(),
  //           offerAndAnswerButtons(),
  //           sdpCandidatesTF(),
  //           sdpCandidateButtons(),
  //         ],
  //       ));
}

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       backgroundColor: Theme.of(context).colorScheme.inversePrimary,
  //       title: const Text('video call'),
  //     ),
  //     body: BlocBuilder<HomeCubit, HomeState>(builder: (context, state) {
  //       if (state is HomeInitial) {
  //         return const Center(
  //           child: SizedBox(
  //               width: 40, height: 40, child: CircularProgressIndicator()),
  //         );
  //       }
  //       if (state is HomeLoaded) {
  //         return Stack(
  //           children: [
  //             Positioned(
  //                 top: 0,
  //                 bottom: 0,
  //                 left: 0,
  //                 right: 0,
  //                 child: Container(
  //                   child: RTCVideoView(_localRenderer),
  //                 )),
  //             Center(
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: <Widget>[
  //                   const Text(
  //                     'You have pushed the button this many times:',
  //                   ),
  //                   Text(
  //                     '',
  //                     style: Theme.of(context).textTheme.headlineMedium,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         );
  //       }
  //       return Container(
  //         child: Text('Wrong pass data'),
  //       );
  //     }),
  //   );
  // }
// }

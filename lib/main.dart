// import 'dart:async';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_callkit_incoming/entities/entities.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import 'package:video_call_flutter/route/app_route.dart';
// import 'package:video_call_flutter/service/navigation_service.dart';
// import 'package:uuid/uuid.dart';

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print("Handling a background message: ${message.messageId}");
//   print(message.data);
//   await Firebase
//       .initializeApp(); //make sure firebase is initialized before using it (showCallkitIncoming)
//   showCallkitIncoming(const Uuid().v4());
// }

// Future<void> showCallkitIncoming(String uuid) async {
//   final params = CallKitParams(
//     id: uuid,
//     nameCaller: 'Hien Nguyen',
//     appName: 'Callkit',
//     avatar: 'https://i.pravatar.cc/100',
//     handle: '0123456789',
//     type: 0,
//     duration: 30000,
//     textAccept: 'Accept',
//     textDecline: 'Decline',
//     missedCallNotification: const NotificationParams(
//       showNotification: true,
//       isShowCallback: true,
//       subtitle: 'Missed call',
//       callbackText: 'Call back',
//     ),
//     extra: <String, dynamic>{'userId': '1a2b3c4d'},
//     headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
//     android: const AndroidParams(
//       isCustomNotification: true,
//       isShowLogo: false,
//       ringtonePath: 'system_ringtone_default',
//       backgroundColor: '#0955fa',
//       backgroundUrl: 'assets/test.png',
//       actionColor: '#4CAF50',
//       textColor: '#ffffff',
//     ),
//     ios: const IOSParams(
//       iconName: 'CallKitLogo',
//       handleType: '',
//       supportsVideo: true,
//       maximumCallGroups: 2,
//       maximumCallsPerCallGroup: 1,
//       audioSessionMode: 'default',
//       audioSessionActive: true,
//       audioSessionPreferredSampleRate: 44100.0,
//       audioSessionPreferredIOBufferDuration: 0.005,
//       supportsDTMF: true,
//       supportsHolding: true,
//       supportsGrouping: false,
//       supportsUngrouping: false,
//       ringtonePath: 'system_ringtone_default',
//     ),
//   );
//   await FlutterCallkitIncoming.showCallkitIncoming(params);
// }

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const MyApp());
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   MyAppState createState() => MyAppState();
// }

// class MyAppState extends State<MyApp> with WidgetsBindingObserver {
//   late final Uuid _uuid;
//   String? _currentUuid;

//   late final FirebaseMessaging _firebaseMessaging;

//   @override
//   void initState() {
//     super.initState();
//     _uuid = const Uuid();
//     initFirebase();
//     WidgetsBinding.instance.addObserver(this);
//     //Check call when open app from terminated
//     checkAndNavigationCallingPage();
//   }

//   Future<dynamic> getCurrentCall() async {
//     //check current call from pushkit if possible
//     var calls = await FlutterCallkitIncoming.activeCalls();
//     if (calls is List) {
//       if (calls.isNotEmpty) {
//         print('DATA: $calls');
//         _currentUuid = calls[0]['id'];
//         return calls[0];
//       } else {
//         _currentUuid = "";
//         return null;
//       }
//     }
//   }

//   Future<void> checkAndNavigationCallingPage() async {
//     var currentCall = await getCurrentCall();
//     if (currentCall != null) {
//       NavigationService.instance
//           .pushNamedIfNotCurrent(AppRoute.callingPage, args: currentCall);
//     }
//   }

//   @override
//   Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
//     print(state);
//     if (state == AppLifecycleState.resumed) {
//       //Check call when open app from background
//       checkAndNavigationCallingPage();
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   Future<void> initFirebase() async {
//     await Firebase.initializeApp();
//     _firebaseMessaging = FirebaseMessaging.instance;
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
//       print(
//           'Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');
//       _currentUuid = _uuid.v4();
//       showCallkitIncoming(_currentUuid!);
//     });
//     _firebaseMessaging.getToken().then((token) {
//       print('Device Token FCM: $token');
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData.light(),
//       onGenerateRoute: AppRoute.generateRoute,
//       initialRoute: AppRoute.homePage,
//       navigatorKey: NavigationService.instance.navigationKey,
//       navigatorObservers: <NavigatorObserver>[
//         NavigationService.instance.routeObserver
//       ],
//     );
//   }

//   Future<void> getDevicePushTokenVoIP() async {
//     var devicePushTokenVoIP =
//         await FlutterCallkitIncoming.getDevicePushTokenVoIP();
//     print(devicePushTokenVoIP);
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_call_flutter/cubit/home/home_cubit.dart';
import 'package:video_call_flutter/firebase_options.dart';
import 'package:video_call_flutter/pages/home/home_page.dart';
import 'package:video_call_flutter/pages/room/room_page.dart';
import 'package:video_call_flutter/pages/socket.dart';
import 'package:video_call_flutter/pages/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: BlocProvider(
            create: (context) => HomeCubit(), child: SplashPage()));
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:video_call_flutter/cubit/home/home_cubit.dart';
// import 'package:video_call_flutter/pages/home/home_page.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         title: 'Flutter Demo',
//         theme: ThemeData(
//           colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//           useMaterial3: true,
//         ),
//         home: BlocProvider(
//             create: (context) => HomeCubit(), child: const HomePage()));
//   }
// }
// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:video_call_flutter/pages/join_screen.dart';
// import 'package:video_call_flutter/service/socket.dart';

// void main() {
//   // start videoCall app
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   MyApp({super.key});

//   // signalling server url
//   final String websocketUrl = "WEB_SOCKET_SERVER_URL";

//   // generate callerID of local user
//   final String selfCallerID =
//       Random().nextInt(999999).toString().padLeft(6, '0');

//   @override
//   Widget build(BuildContext context) {
//     // init signalling service
//     SignallingService.instance.init(
//       websocketUrl: websocketUrl,
//       selfCallerID: selfCallerID,
//     );

//     // return material app
//     return MaterialApp(
//       darkTheme: ThemeData.dark().copyWith(
//         useMaterial3: true,
//         colorScheme: const ColorScheme.dark(),
//       ),
//       themeMode: ThemeMode.dark,
//       home: JoinScreen(selfCallerId: selfCallerID),
//     );
//   }
// }

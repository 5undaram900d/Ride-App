import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ride_app_admin_web_panel/dashboard/side_navigation_drawer.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAUSBWg8QCJLp5j44Dvl5-C640AMQC8MqA",
      authDomain: "ride-app-66de8.firebaseapp.com",
      databaseURL: "https://ride-app-66de8-default-rtdb.firebaseio.com",
      projectId: "ride-app-66de8",
      storageBucket: "ride-app-66de8.appspot.com",
      messagingSenderId: "462679725333",
      appId: "1:462679725333:web:fa879256b5f097ea6d051c",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: SideNavigationDrawer(),
    );
  }
}


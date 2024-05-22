
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:ride_app/appInfo/app_info.dart';
import 'package:ride_app/authentication/login_screen.dart';
import 'package:ride_app/pages/home_page.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Permission.locationWhenInUse.isDenied.then((valueOfPermission){
    if(valueOfPermission){
      Permission.locationWhenInUse.request();
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context)=> AppInfo(),
      child: MaterialApp(
        title: 'Ride App User',
        debugShowCheckedModeBanner: false,
        // theme: ThemeData(
        //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        //   useMaterial3: true,
        // ),
        theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
        home: FirebaseAuth.instance.currentUser==null ? LoginScreen() : HomePage(),
      ),
    );
  }
}


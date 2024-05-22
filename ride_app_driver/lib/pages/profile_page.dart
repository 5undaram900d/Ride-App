
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ride_app_driver/authentication/login_screen.dart';
import 'package:ride_app_driver/global/global_var.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController carTextEditingController = TextEditingController();

  setDriverInfo(){
    setState(() {
      nameTextEditingController.text = driverName;
      phoneTextEditingController.text = driverPhone;
      emailTextEditingController.text = FirebaseAuth.instance.currentUser!.email.toString();
      carTextEditingController.text = "$carNumber - $carColor - $carModel";
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setDriverInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /** image **/
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                  image: DecorationImage(
                    fit: BoxFit.fitHeight,
                    image: NetworkImage(driverPhoto),
                  ),
                ),
              ),

              SizedBox(height: 16,),

              /** driver name **/
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25).copyWith(top: 4),
                child: TextField(
                  controller: nameTextEditingController,
                  textAlign: TextAlign.center,
                  enabled: true,
                  style: TextStyle(fontSize: 16, color: Colors.white,),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2,),
                    ),
                    prefixIcon: Icon(Icons.person, color: Colors.white,),
                  ),
                ),
              ),

              /** driver phone **/
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25).copyWith(top: 4),
                child: TextField(
                  controller: phoneTextEditingController,
                  textAlign: TextAlign.center,
                  enabled: true,
                  style: TextStyle(fontSize: 16, color: Colors.white,),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2,),
                    ),
                    prefixIcon: Icon(Icons.phone_android_outlined, color: Colors.white,),
                  ),
                ),
              ),

              /** driver email **/
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25).copyWith(top: 4),
                child: TextField(
                  controller: emailTextEditingController,
                  textAlign: TextAlign.center,
                  enabled: true,
                  style: TextStyle(fontSize: 16, color: Colors.white,),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2,),
                    ),
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.white,),
                  ),
                ),
              ),

              /** driver car info **/
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25,).copyWith(top: 4,),
                child: TextField(
                  controller: carTextEditingController,
                  textAlign: TextAlign.center,
                  enabled: true,
                  style: TextStyle(fontSize: 16, color: Colors.white,),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2,),
                    ),
                    prefixIcon: Icon(Icons.drive_eta, color: Colors.white,),
                  ),
                ),
              ),

              SizedBox(height: 12,),

              /** logout btn **/
              ElevatedButton(
                onPressed: (){
                  FirebaseAuth.instance.signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> LoginScreen(),),);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 18,),
                  backgroundColor: Colors.tealAccent,
                ),
                child: const Text('Logout'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

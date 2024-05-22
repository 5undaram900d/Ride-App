
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ride_app/authentication/signup_screen.dart';
import 'package:ride_app/global/global_var.dart';
import 'package:ride_app/methods/common_methods.dart';
import 'package:ride_app/pages/home_page.dart';
import 'package:ride_app/widgets/loading_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  CommonMethods commonMethods = CommonMethods();

  checkIfNetworkIsAvailable(){
    commonMethods.checkConnectivity(context);
    signInFormValidation();
  }

  signInFormValidation(){
    if(!emailTextEditingController.text.contains("@")){
      commonMethods.displaySnackBar(context, "Please provide valid email");
    }
    else if(passwordTextEditingController.text.trim().length < 5){
      commonMethods.displaySnackBar(context, "password must have at least 6 character");
    }
    else{
      /* register user */
      signInUser();
    }
  }

  signInUser() async{
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Login your account.....",),
    );

    final User? userFirebase = (
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          password: passwordTextEditingController.text.trim(),
        ).catchError((error){
          Navigator.pop(context);
          commonMethods.displaySnackBar(context, error.toString());
        })
    ).user;

    if(!context.mounted) return;
    Navigator.pop(context);

    if(userFirebase != null){
      DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(userFirebase.uid);
      await userRef.once().then((snap) {
        if(snap.snapshot.value != null){
          if((snap.snapshot.value as Map)['blockStatus']=='no'){
            userName = (snap.snapshot.value as Map)['name'];
            userPhone = (snap.snapshot.value as Map)['phone'];
            Navigator.push(context, MaterialPageRoute(builder: (context)=> const HomePage(),),);
          }
          else{
            FirebaseAuth.instance.signOut();
            commonMethods.displaySnackBar(context, "you are blocked, contact to admin");
          }
        }
        else{
          FirebaseAuth.instance.signOut();
          commonMethods.displaySnackBar(context, "you record do not exist as a user");
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              /* logo */
              Image.asset("assets/images/logo.png"),
              /* heading */
              const Text("Login as User", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,),),
              /* text-field + button */
              Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  children: [
                    /* email text field */
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "User Id",
                        labelStyle: TextStyle(fontSize: 14,),
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 15,),
                    ),
                    const SizedBox(height: 22,),
                    /* password text field */
                    TextField(
                      controller: passwordTextEditingController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(fontSize: 14,),
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 15,),
                    ),
                    const SizedBox(height: 32,),
                    /* button */
                    ElevatedButton(
                      onPressed: (){
                        checkIfNetworkIsAvailable();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                        backgroundColor: Colors.purple,
                      ),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12,),
              /* text button */
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (context)=> const SignUpScreen(),),),
                    child: const Text("Register Here", style: TextStyle(color: Colors.grey,),),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

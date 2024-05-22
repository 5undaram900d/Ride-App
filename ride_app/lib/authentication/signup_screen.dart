
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ride_app/authentication/login_screen.dart';
import 'package:ride_app/methods/common_methods.dart';
import 'package:ride_app/pages/home_page.dart';
import 'package:ride_app/widgets/loading_dialog.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {

  TextEditingController usernameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController userPhoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  CommonMethods commonMethods = CommonMethods();

  checkIfNetworkIsAvailable(){
    commonMethods.checkConnectivity(context);
    signUpFormValidation();
  }

  signUpFormValidation(){
    if(usernameTextEditingController.text.trim().length < 3){
      commonMethods.displaySnackBar(context, "your name must be at least 3 character");
    }
    else if(!emailTextEditingController.text.contains("@")){
      commonMethods.displaySnackBar(context, "Please provide valid email");
    }
    else if(userPhoneTextEditingController.text.trim().length != 10){
      commonMethods.displaySnackBar(context, "Phone number should be 10 digit");
    }
    else if(passwordTextEditingController.text.trim().length < 5){
      commonMethods.displaySnackBar(context, "password must have at least 6 character");
    }
    else{
      /* register user */
      registerNewUser();
    }
  }

  registerNewUser() async{
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Registering your account.....",),
    );
    final User? userFirebase = (
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextEditingController.text.trim(), 
        password: passwordTextEditingController.text.trim(),
      ).catchError((error){
        Navigator.pop(context);
        commonMethods.displaySnackBar(context, error.toString());
      })
    ).user;

    if(!context.mounted) return;
    Navigator.pop(context);

    DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(userFirebase!.uid);
    Map userDataMap = {
      "name": usernameTextEditingController.text.trim(),
      "email": emailTextEditingController.text.trim(),
      "phone": userPhoneTextEditingController.text.trim(),
      "id": userFirebase.uid,
      "blockStatus": "no",
    };
    userRef.set(userDataMap);

    Navigator.push(context, MaterialPageRoute(builder: (context)=> const HomePage(),),);
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
              const Text("Create a user's account", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,),),
              /* text-field + button */
              Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  children: [
                    /* username text field */
                    TextField(
                      controller: usernameTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "User Name",
                        labelStyle: TextStyle(fontSize: 14,),
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 15,),
                    ),
                    const SizedBox(height: 22,),
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
                    /* user phone text field */
                    TextField(
                      controller: userPhoneTextEditingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "User Phone Number",
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
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12,),
              /* text button */
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  TextButton(
                    onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (context)=> const LoginScreen(),),),
                    child: const Text("Login Here", style: TextStyle(color: Colors.grey,),),
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

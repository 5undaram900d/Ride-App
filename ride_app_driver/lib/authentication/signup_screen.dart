
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_app_driver/authentication/login_screen.dart';
import 'package:ride_app_driver/methods/common_methods.dart';
import 'package:ride_app_driver/pages/dashboard.dart';
import 'package:ride_app_driver/widgets/loading_dialog.dart';

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
  TextEditingController vehicleModelTextEditingController = TextEditingController();
  TextEditingController vehicleColorTextEditingController = TextEditingController();
  TextEditingController vehicleNumberTextEditingController = TextEditingController();

  CommonMethods commonMethods = CommonMethods();

  XFile? imageFile;
  String urlOfUploadedImage = '';

  checkIfNetworkIsAvailable(){
    commonMethods.checkConnectivity(context);
    if(imageFile != null){
      signUpFormValidation();
    }
    else{
      commonMethods.displaySnackBar(context, "Please choose image first");
    }
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
    else if(vehicleModelTextEditingController.text.trim().isEmpty){
      commonMethods.displaySnackBar(context, "please provide your car model");
    }
    else if(vehicleColorTextEditingController.text.trim().isEmpty){
      commonMethods.displaySnackBar(context, "please provide your car color");
    }
    else if(vehicleNumberTextEditingController.text.trim().isEmpty){
      commonMethods.displaySnackBar(context, "please provide your car number");
    }
    else{
      uploadImageToStorage();
    }
  }

  uploadImageToStorage()async{
    String imageIdName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceImage = FirebaseStorage.instance.ref().child("images").child(imageIdName);
    UploadTask uploadTask = referenceImage.putFile(File(imageFile!.path));
    TaskSnapshot snapshot = await uploadTask;
    urlOfUploadedImage = await snapshot.ref.getDownloadURL();
    setState(() {
      urlOfUploadedImage;
    });
    registerNewDriver();
  }

  registerNewDriver() async{
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

    DatabaseReference userRef = FirebaseDatabase.instance.ref().child("drivers").child(userFirebase!.uid);

    Map driverCarInfo = {
      "carModel": vehicleModelTextEditingController.text.trim(),
      "carColor": vehicleColorTextEditingController.text.trim(),
      "carNumber": vehicleNumberTextEditingController.text.trim()
    };

    Map driverDataMap = {
      "photo": urlOfUploadedImage,
      "car_details": driverCarInfo,
      "name": usernameTextEditingController.text.trim(),
      "email": emailTextEditingController.text.trim(),
      "phone": userPhoneTextEditingController.text.trim(),
      "id": userFirebase.uid,
      "blockStatus": "no",
    };
    userRef.set(driverDataMap);

    Navigator.push(context, MaterialPageRoute(builder: (context)=> const Dashboard(),),);
  }

  chooseImageFromGallery() async{
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery,);
    if(pickedFile != null){
      imageFile = pickedFile;
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
              const SizedBox(height: 50,),
              /* logo */
              imageFile == null
              ? const CircleAvatar(
                radius: 85,
                  backgroundImage: AssetImage("assets/images/avatarman.png"),
              )
              : Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                  image: DecorationImage(
                    fit: BoxFit.fitHeight,
                    image: FileImage(File(imageFile!.path),),
                  ),
                ),
              ),
              const SizedBox(height: 10,),
              /* image select */
              GestureDetector(
                onTap: (){
                  chooseImageFromGallery();
                  setState(() {

                  });
                },
                child: const Text("Choose Image", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,),),
              ),
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
                        labelText: "Your Name",
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
                        labelText: "Your Id",
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
                        labelText: "Your Phone Number",
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
                    const SizedBox(height: 22,),
                    /* car model text field */
                    TextField(
                      controller: vehicleModelTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "Your Car Model",
                        labelStyle: TextStyle(fontSize: 14,),
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 15,),
                    ),
                    const SizedBox(height: 22,),
                    /* car color text field */
                    TextField(
                      controller: vehicleColorTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "Your Car Color",
                        labelStyle: TextStyle(fontSize: 14,),
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 15,),
                    ),
                    const SizedBox(height: 22,),
                    /* car number text field */
                    TextField(
                      controller: vehicleNumberTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "Your Car Number",
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

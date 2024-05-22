
import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Developed by", style: TextStyle(color: Colors.grey,),),
        centerTitle: true,
        leading: IconButton(
          onPressed: (){
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.grey,),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset("assets/images/logo.png"),

            SizedBox(height: 20,),

            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text("This app is developed by King Vishwakarma", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 22,),),
            ),

            SizedBox(height: 10,),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("In case of any bug please contact at <email> ", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16,),),
            ),
          ],
        ),
      ),
    );
  }
}

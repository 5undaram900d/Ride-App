
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ride_app_driver/pages/trips_history_page.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {

  String currentDriverTotalTripsCompleted = "";

  getCurrentDriverTotalNumberOfTripsCompleted() async{
    DatabaseReference tripRequestsRef = FirebaseDatabase.instance.ref().child("tripRequests");
    await tripRequestsRef.once().then((snap) {
      if(snap.snapshot.value != null){
        Map<dynamic, dynamic> allTripsMap = snap.snapshot.value as Map;
        int allTripsLength = allTripsMap.length;

        List<String> tripsCompletedByCurrentDriver = [];

        allTripsMap.forEach((key, value) {
          if(value["status"] != null){
            if(value["status"] == "ended"){
              if(value["driverID"] == FirebaseAuth.instance.currentUser!.uid){
                tripsCompletedByCurrentDriver.add(key);
              }
            }
          }
        });

        setState(() {
           currentDriverTotalTripsCompleted = tripsCompletedByCurrentDriver.length.toString();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /** total trips **/
          Center(
            child: Container(
              color: Colors.indigoAccent,
              width: 300,
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  children: [
                    Image.asset("assets/images/totaltrips.png", width: 120,),

                    SizedBox(height: 10,),

                    Text("Total Trips: ", style: TextStyle(color: Colors.white,),),
                    Text(currentDriverTotalTripsCompleted, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,),),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 20,),

          /** check trip history **/
          GestureDetector(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=> TripsHistoryPage(),),);
            },
            child: Center(
              child: Container(
                color: Colors.indigoAccent,
                width: 300,
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Image.asset("assets/images/tripscompleted.png", width: 150,),
            
                      SizedBox(height: 10,),
            
                      Text("Total Trips History", style: TextStyle(color: Colors.white,),),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

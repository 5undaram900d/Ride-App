
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TripsHistoryPage extends StatefulWidget {
  const TripsHistoryPage({super.key});

  @override
  State<TripsHistoryPage> createState() => _TripsHistoryPageState();
}

class _TripsHistoryPageState extends State<TripsHistoryPage> {
  final completedTripRequestsOfCurrentDriver = FirebaseDatabase.instance.ref().child("tripRequests");

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text("My Trips History", style: TextStyle(color: Colors.white,),),
        leading: IconButton(
          onPressed: (){
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.white,),
        ),
      ),

      body: StreamBuilder(
        stream: completedTripRequestsOfCurrentDriver.onValue,
        builder: (BuildContext context, snapshotData){
          if(snapshotData.hasError){
            return Center(child: Text("Error Occurred.", style: TextStyle(color: Colors.white,),),);
          }
          if(!(snapshotData.hasData)){
            return Center(child: Text("No record found.", style: TextStyle(color: Colors.white,),),);
          }

          Map dataTrips = snapshotData.data!.snapshot.value as Map;
          List tripsList = [];

          dataTrips.forEach((key, value)=> tripsList.add({"key": key, ...value}));

          return ListView.builder(
            shrinkWrap: true,
            itemCount: tripsList.length,
            itemBuilder: (context, index){
              if(tripsList[index]["status"] != null && tripsList[index]["status"] == "ended" && tripsList[index]["userID"] == FirebaseAuth.instance.currentUser!.uid){
                return Card(
                  color: Colors.white12,
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /** pickUp - fare amount **/
                        Row(
                          children: [
                            Image.asset("assets/images/initial.png", height: 16, width: 16,),
                            Expanded(
                              child: Text(tripsList[index]["pickUpAddress"].toString(), style: TextStyle(fontSize: 18, color: Colors.white38,),),
                            ),
                            SizedBox(width: 5,),
                            Text("\$${tripsList[index]["fareAmount"]}", style: TextStyle(fontSize: 15, color: Colors.white38),),
                          ],
                        ),

                        SizedBox(height: 8,),

                        /** dropOff **/
                        Row(
                          children: [
                            Image.asset("assets/images/final.png", height: 16, width: 16,),
                            Expanded(
                              child: Text(tripsList[index]["dropOffAddress"].toString(), style: TextStyle(fontSize: 18, color: Colors.white38,),),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                );
              }
              else{
                return Container(

                );
              }
            },
          );
        },
      ),
    );
  }
}


import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ride_app_admin_web_panel/methods/common_methods.dart';
import 'package:url_launcher/url_launcher.dart';

class TripsDataList extends StatefulWidget {
  const TripsDataList({super.key});

  @override
  State<TripsDataList> createState() => _TripsDataListState();
}

class _TripsDataListState extends State<TripsDataList> {

  final completedTripsRecordsFromDatabase = FirebaseDatabase.instance.ref().child("tripRequests");
  CommonMethods commonMethods = CommonMethods();

  launchGoogleMapFromSourceToDestination(pickUpLat, pickUpLng, dropOffLat, dropOffLng) async{
    String directionApiUrl = "https://www.google.com/maps/dir/?api=1&origin=$pickUpLat,$pickUpLng&destination=$dropOffLat,$dropOffLng&dir_action=navigate";

    if(await canLaunchUrl(Uri.parse(directionApiUrl))){
      await launchUrl(Uri.parse(directionApiUrl),);
    }
    else{
      throw "Could not launch google map";
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: completedTripsRecordsFromDatabase.onValue,
      builder: (BuildContext context, snapshotData){
        if(snapshotData.hasError){
          return Center(
            child: Text("Error Occurred, Try later", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple,),),
          );
        }
        if(snapshotData.connectionState == ConnectionState.waiting){
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        Map dataMap = snapshotData.data!.snapshot.value as Map;
        List itemsList = [];
        dataMap.forEach((key, value) {
          itemsList.add({"key": key, ...value});
        });

        return ListView.builder(
          shrinkWrap: true,
          itemCount: itemsList.length,
          itemBuilder: ((context, index){
            if(itemsList[index]["status"] == null && itemsList[index]["status"] == "ended"){
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  commonMethods.data(2, Text(itemsList[index]["tripID"].toString(),),),
                  commonMethods.data(1, Text(itemsList[index]["userName"].toString(),),),
                  commonMethods.data(1, Text(itemsList[index]["driverName"].toString(),),),
                  commonMethods.data(1, Text(itemsList[index]["carDetails"].toString(),),),
                  commonMethods.data(1, Text(itemsList[index]["publishedDateTime"].toString(),),),
                  commonMethods.data(1, Text("\$ ${itemsList[index]["fareAmount"]}",),),
                  commonMethods.data(
                    1,
                    ElevatedButton(
                      onPressed: (){
                        String pickUpLat = itemsList[index]["pickUpLatLng"]["latitude"];
                        String pickUpLng = itemsList[index]["pickUpLatLng"]["longitude"];

                        String dropOffLat = itemsList[index]["dropOffLatLng"]["latitude"];
                        String dropOffLng = itemsList[index]["dropOffLatLng"]["longitude"];

                        launchGoogleMapFromSourceToDestination(pickUpLat, pickUpLng, dropOffLat, dropOffLng);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pink,),
                      child: Text("View More", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),),
                    ),
                  ),
                ],
              );
            }
            else{
              return Container();
            }
          }),
        );
      },
    );
  }
}

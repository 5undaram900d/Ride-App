
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ride_app_driver/global/global_var.dart';
import 'package:ride_app_driver/methods/common_methods.dart';
import 'package:ride_app_driver/models/trip_details.dart';
import 'package:ride_app_driver/pages/new_trip_page.dart';
import 'package:ride_app_driver/widgets/loading_dialog.dart';

class NotificationDialog extends StatefulWidget {
  TripDetails? tripDetailsInfo;

  NotificationDialog({super.key, this.tripDetailsInfo});

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {

  String tripRequestStatus = "";
  CommonMethods commonMethods = CommonMethods();

  cancelNotificationDialogAfter20Sec(){
    const oneTickPerSecond = Duration(seconds: 1,);
    var timerCountDown = Timer.periodic(oneTickPerSecond, (timer) {
      driverTripRequestTimeout = driverTripRequestTimeout - 1;
      if(tripRequestStatus=="accepted"){
        timer.cancel();
        driverTripRequestTimeout = 20;
      }
      if(driverTripRequestTimeout == 0){
        Navigator.pop(context);
        timer.cancel();
        driverTripRequestTimeout = 20;
        audioPlayer.stop();
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    cancelNotificationDialogAfter20Sec();
  }

  checkAvailabilityOfTripRequest(BuildContext context) async{
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context)=> LoadingDialog(messageText: "Please wait..."),
    );

    DatabaseReference driverTripStatusRef = FirebaseDatabase.instance.ref().child("drivers").child(FirebaseAuth.instance.currentUser!.uid).child("newTripStatus");
    await driverTripStatusRef.once().then((snap){
      Navigator.pop(context);
      Navigator.pop(context);

      String newTripStatusValue = "";
      if(snap.snapshot.value != null){
        newTripStatusValue = snap.snapshot.value.toString();
      }
      else{
        commonMethods.displaySnackBar(context, "Trip Request Not Found.");
      }

      if(newTripStatusValue == widget.tripDetailsInfo!.tripID){
        driverTripStatusRef.set("accepted");
        /** disable homePage location updates **/
        commonMethods.turnOffLocationUpdateForHomePage();
        Navigator.push(context, MaterialPageRoute(builder: (context)=> NewTripPage(newTripDetailsInfo: widget.tripDetailsInfo,),),);
      }
      else if(newTripStatusValue == "cancelled"){
        commonMethods.displaySnackBar(context, "Trip Request has been cancelled by user.");
      }
      else if(newTripStatusValue == "timeout"){
        commonMethods.displaySnackBar(context, "Trip Request Timed out.");
      }
      else{
        commonMethods.displaySnackBar(context, "Trip Request Removed. Not found..");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.black54,
      child: Container(
        margin: EdgeInsets.all(5),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            SizedBox(height: 30,),
            Image.asset("assets/images/uberexec.png", width: 140,),
            SizedBox(height: 36,),
            /** title **/
            Text("NEW TRIP REQUEST", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey,),),
            SizedBox(height: 20,),

            Divider(height: 1, color: Colors.white, thickness: 1,),
            SizedBox(height: 10,),

            /** pickUp & dropOff **/
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  /** pickUp **/
                  Row(
                    children: [
                      Image.asset("assets/images/initial.png", height: 16, width: 16,),
                      SizedBox(width: 18,),
                      Expanded(
                        child: Text(
                          widget.tripDetailsInfo!.pickUpAddress.toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(color: Colors.grey, fontSize: 18,),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 15,),

                  /** dropOff **/
                  Row(
                    children: [
                      Image.asset("assets/images/final.png", height: 16, width: 16,),
                      SizedBox(width: 18,),
                      Expanded(
                        child: Text(
                          widget.tripDetailsInfo!.dropOffAddress.toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(color: Colors.grey, fontSize: 18,),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20,),
            Divider(height: 1, color: Colors.white, thickness: 1,),

            SizedBox(height: 8,),

            /** decline & accept button **/
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (){
                          Navigator.pop(context);
                          audioPlayer.stop();
                        },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple,),
                      child: Text("DECLINE", style: TextStyle(color: Colors.white,),),
                    ),
                  ),

                  SizedBox(width: 10,),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: (){
                        audioPlayer.stop();
                        setState(() {
                          tripRequestStatus = "accepted";
                        });
                        checkAvailabilityOfTripRequest(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green,),
                      child: Text("ACCEPT", style: TextStyle(color: Colors.white,),),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10,),
          ],
        ),
      ),
    );
  }
}

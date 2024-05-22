
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app_driver/global/global_var.dart';
import 'package:ride_app_driver/models/trip_details.dart';
import 'package:ride_app_driver/widgets/loading_dialog.dart';
import 'package:ride_app_driver/widgets/notification_dialog.dart';

class PushNotificationSystem{
  FirebaseMessaging firebaseCloudMessaging = FirebaseMessaging.instance;

  Future<String?> generateDeviceRegistrationToken() async{
    String? deviceRecognitionToken = await firebaseCloudMessaging.getToken();

    DatabaseReference referenceOnlineDriver = FirebaseDatabase.instance.ref().child("drivers").child(FirebaseAuth.instance.currentUser!.uid).child("deviceToken");
    
    referenceOnlineDriver.set(deviceRecognitionToken);
    
    firebaseCloudMessaging.subscribeToTopic("drivers");
    firebaseCloudMessaging.subscribeToTopic("users");
  }

  startListeningForNewNotification(BuildContext context) async{
    /** 1.Terminated: when the app is completely closed **/
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? messageRemote){
      if(messageRemote != null){
        String tripID = messageRemote.data["tripID"];
        retrieveTripRequestInfo(tripID, context);
      }
    });

    /** 2.Foreground: When the app is open and it receives a push notification **/
    FirebaseMessaging.onMessage.listen((RemoteMessage? messageRemote) {
      if(messageRemote != null){
        String tripID = messageRemote.data["tripID"];
        retrieveTripRequestInfo(tripID, context);
      }
    });

    /** 3.Background: when the app is in the background **/
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? messageRemote) {
      if(messageRemote != null){
        String tripID = messageRemote.data["tripID"];
      }
    });
  }

  retrieveTripRequestInfo(String tripID, BuildContext context){
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context)=> LoadingDialog(messageText: "getting details...",),
    );

    DatabaseReference tripRequestRef = FirebaseDatabase.instance.ref().child("tripRequests").child(tripID);
    
    tripRequestRef.once().then((dataSnapshot) {
      Navigator.pop(context);

      /** play notification sound **/
      audioPlayer.open(Audio("assets/audio/alert_sound.mp3",),);
      audioPlayer.play();

      TripDetails tripDetailsInfo = TripDetails();

      double pickUpLat = double.parse((dataSnapshot.snapshot.value! as Map)["pickUpLatLng"]["latitude"]);
      double pickUpLng = double.parse((dataSnapshot.snapshot.value! as Map)["pickUpLatLng"]["latitude"]);
      tripDetailsInfo.pickUpLatLng = LatLng(pickUpLat, pickUpLng);

      tripDetailsInfo.pickUpAddress = (dataSnapshot.snapshot.value! as Map)["pickUpLatLng"];

      double dropOffLat = double.parse((dataSnapshot.snapshot.value! as Map)["dropOffLatLng"]["latitude"]);
      double dropOffLng = double.parse((dataSnapshot.snapshot.value! as Map)["dropOffLatLng"]["latitude"]);
      tripDetailsInfo.dropOffLatLng = LatLng(dropOffLat, dropOffLng);

      tripDetailsInfo.dropOffAddress = (dataSnapshot.snapshot.value! as Map)["dropOffLatLng"];

      tripDetailsInfo.userName = (dataSnapshot.snapshot.value! as Map)["userName"];
      tripDetailsInfo.userPhone = (dataSnapshot.snapshot.value! as Map)["userPhone"];

      tripDetailsInfo.tripID = tripID;
      
      showDialog(
        context: context,
        builder: (BuildContext context)=> NotificationDialog(tripDetailsInfo: tripDetailsInfo,),
      );

    });
  }
}

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app_driver/global/global_var.dart';
import 'package:http/http.dart' as http;
import 'package:ride_app_driver/models/direction_details.dart';

class CommonMethods{
  checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity().checkConnectivity();
    if(!connectionResult.contains(ConnectivityResult.mobile) && !connectionResult.contains(ConnectivityResult.wifi)){
      if(!context.mounted) return;
      displaySnackBar(context, "No Internet Connection");
    }
  }

  displaySnackBar(BuildContext context, String messageText){
    var snackBar = SnackBar(content: Text(messageText),);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  turnOffLocationUpdateForHomePage(){
    positionStreamHomePage!.pause();
    Geofire.removeLocation(FirebaseAuth.instance.currentUser!.uid);
  }

  turnOnLocationUpdateForHomePage(){
    positionStreamHomePage!.resume();
    Geofire.setLocation(FirebaseAuth.instance.currentUser!.uid, driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);
  }

  static sendRequestToAPI(String apiUrl) async{
    http.Response responseFromAPI = await http.get(Uri.parse(apiUrl),);
    try{
      if(responseFromAPI.statusCode == 200){
        String dataFormAPI = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFormAPI);
        return dataDecoded;
      }
      else{
        return "error";
      }
    } catch (error){
      return "error";
    }
  }

  ///** Direction API **/
  static Future<DirectionDetails?> getDirectionDetailsFromAPI(LatLng source, LatLng destination) async{
    String urlDirectionsAPI = "https://maps.googleapis.com/maps/api/directions/json?destination=${destination.latitude},${destination.longitude}&origin=${source.latitude},${source.longitude}&mode=driving&key=$googleMapKey";
    var responseFromDirectionAPI = await sendRequestToAPI(urlDirectionsAPI);

    if(responseFromDirectionAPI == "error"){
      return null;
    }

    DirectionDetails detailsModel = DirectionDetails();

    detailsModel.distanceTextString = responseFromDirectionAPI["routes"][0]["legs"][0]["distance"]["text"];
    detailsModel.distanceValueDigits = responseFromDirectionAPI["routes"][0]["legs"][0]["distance"]["value"];

    detailsModel.durationTextString = responseFromDirectionAPI["routes"][0]["legs"][0]["duration"]["text"];
    detailsModel.durationValueDigits = responseFromDirectionAPI["routes"][0]["legs"][0]["duration"]["value"];

    detailsModel.encodedPoints = responseFromDirectionAPI["routes"][0]["overview_polyline"]["points"];

    return detailsModel;
  }

  calculateFareAmount(DirectionDetails directionDetails){
    double distancePerKmAmount = 0.4;
    double durationPerMinuteAmount = 0.3;
    double baseFareAmount = 2.0;

    double totalDistanceTravelFareAmount = (directionDetails.distanceValueDigits!/1000) * distancePerKmAmount;
    double totalDurationSpendFareAmount = (directionDetails.durationValueDigits!/60) * durationPerMinuteAmount;

    double overAllTotalFareAmount = baseFareAmount + totalDistanceTravelFareAmount + totalDurationSpendFareAmount;

    return overAllTotalFareAmount.toStringAsFixed(1);
  }

}
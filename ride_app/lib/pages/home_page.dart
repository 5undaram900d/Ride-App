
import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:ride_app/appInfo/app_info.dart';
import 'package:ride_app/authentication/login_screen.dart';
import 'package:ride_app/global/global_var.dart';
import 'package:ride_app/global/trip_var.dart';
import 'package:ride_app/methods/common_methods.dart';
import 'package:ride_app/methods/manage_drivers_methods.dart';
import 'package:ride_app/methods/push_notification_service.dart';
import 'package:ride_app/models/direction_details.dart';
import 'package:ride_app/models/online_nearby_drivers.dart';
import 'package:ride_app/pages/about_page.dart';
import 'package:ride_app/pages/search_destination_page.dart';
import 'package:ride_app/pages/trips_history_page.dart';
import 'package:ride_app/widgets/info_dialog.dart';
import 'package:ride_app/widgets/loading_dialog.dart';
import 'package:ride_app/widgets/payment_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;

  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();

  CommonMethods commonMethods = CommonMethods();

  double searchContainerHeight = 275;
  double bottomMapPadding = 0;
  double rideDetailsContainerHeight = 0;
  double requestContainerHeight = 0;
  double tripContainerHeight = 0;

  DirectionDetails? tripDirectionDetailsInfo;
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};

  bool isDrawerOpened = true;
  String stateOfApp = "normal";
  bool nearbyOnlineDriversKeysLoaded = false;
  BitmapDescriptor? carIconNearbyDriver;
  DatabaseReference? tripRequestRef;
  List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
  StreamSubscription<DatabaseEvent>? tripStreamSubscription;
  bool requestingDirectionDetailsInfo = false;




  makeDriverNearbyCarIcon(){
    if(carIconNearbyDriver==null){
      ImageConfiguration configuration = createLocalImageConfiguration(context, size: Size(0.5, 0.5));
      BitmapDescriptor.fromAssetImage(configuration, "assets/images/tracking.png").then((iconImage){
        carIconNearbyDriver = iconImage;
      });
    }
  }

  void updateMapTheme(GoogleMapController controller){
    getJsonFileFromMapThemes("assets/mapThemes/dark_theme.json").then((value)=> setGoogleMapStyle(value, controller));
  }

  Future<String> getJsonFileFromMapThemes(String mapStylePath) async{
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
    controller.setMapStyle(googleMapStyle);
  }

  getCurrentLiveLocationOfUser() async{
    Position positionOfUser = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;

    LatLng positionOfUserInLatLng = LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

    CameraPosition cameraPosition = CameraPosition(target: positionOfUserInLatLng, zoom: 14,);
    controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    await CommonMethods.convertGeographicCoordinateIntoHumanReadableAddress(currentPositionOfUser!, context);

    await getUserInfoAndCheckBlockStatus();

    await initializeGeoFireListener();
  }

  getUserInfoAndCheckBlockStatus() async{
    DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(FirebaseAuth.instance.currentUser!.uid);
    await userRef.once().then((snap) {
      if(snap.snapshot.value != null){
        if((snap.snapshot.value as Map)["blockStatus"]=="no"){
          setState(() {
            userName = (snap.snapshot.value as Map)["name"];
            userPhone = (snap.snapshot.value as Map)["phone"];
          });
        }
        else{
          FirebaseAuth.instance.signOut();
          Navigator.push(context, MaterialPageRoute(builder: (context)=> const LoginScreen(),),);
          commonMethods.displaySnackBar(context, "you are blocked, contact to admin");
        }
      }
      else{
        FirebaseAuth.instance.signOut();
        Navigator.push(context, MaterialPageRoute(builder: (context)=> const LoginScreen(),),);
      }
    });
  }

  displayUserRideDetailsContainer() async{
    /* Directions API */
    await retrieveDirectionDetails();

    setState(() {
      searchContainerHeight = 0;
      bottomMapPadding = 240;
      rideDetailsContainerHeight = 242;
      isDrawerOpened = false;
    });
  }

  retrieveDirectionDetails() async{
    var pickUpLocation = Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation = Provider.of<AppInfo>(context, listen: false).dropOffLocation;
    var pickUpGeoGraphicCoordinates = LatLng(pickUpLocation!.latitudePosition!, pickUpLocation.longitudePosition!);
    var dropOffDestinationGeoGraphicCoordinates = LatLng(dropOffDestinationLocation!.latitudePosition!, dropOffDestinationLocation.longitudePosition!);

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context)=> LoadingDialog(messageText: "Getting direction..."),
    );

    /** Direction API **/
    var detailsFromDirectionAPI = await CommonMethods.getDirectionDetailsFromAPI(pickUpGeoGraphicCoordinates, dropOffDestinationGeoGraphicCoordinates);
    setState(() {
      tripDirectionDetailsInfo = detailsFromDirectionAPI;
    });

    Navigator.pop(context);

    /** draw route from pickUp to dropOffDestination **/
    PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latLngPointsFromPickUpToDestination = pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodedPoints!);

    polylineCoordinates.clear();
    if(latLngPointsFromPickUpToDestination.isNotEmpty){
      latLngPointsFromPickUpToDestination.forEach((PointLatLng latLngPoint) {
        polylineCoordinates.add(LatLng(latLngPoint.latitude, latLngPoint.longitude),);
      });
    }

    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        polylineId: PolylineId("polylineId"),
        color: Colors.purple,
        points: polylineCoordinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polylineSet.add(polyline);
    });

    /** fit polyline into the map **/
    LatLngBounds boundsLatLng;
    if(pickUpGeoGraphicCoordinates.latitude > dropOffDestinationGeoGraphicCoordinates.latitude && pickUpGeoGraphicCoordinates.longitude > dropOffDestinationGeoGraphicCoordinates.longitude){
      boundsLatLng = LatLngBounds(southwest: dropOffDestinationGeoGraphicCoordinates, northeast: pickUpGeoGraphicCoordinates);
    }
    else if(pickUpGeoGraphicCoordinates.longitude > dropOffDestinationGeoGraphicCoordinates.longitude){
      boundsLatLng = LatLngBounds(southwest: LatLng(pickUpGeoGraphicCoordinates.latitude, dropOffDestinationGeoGraphicCoordinates.longitude), northeast: LatLng(dropOffDestinationGeoGraphicCoordinates.latitude, pickUpGeoGraphicCoordinates.longitude),);
    }
    else if(pickUpGeoGraphicCoordinates.latitude > dropOffDestinationGeoGraphicCoordinates.latitude){
      boundsLatLng = LatLngBounds(southwest: LatLng(dropOffDestinationGeoGraphicCoordinates.latitude, pickUpGeoGraphicCoordinates.longitude), northeast: LatLng(pickUpGeoGraphicCoordinates.latitude, dropOffDestinationGeoGraphicCoordinates.longitude),);
    }
    else{
      boundsLatLng = LatLngBounds(southwest: pickUpGeoGraphicCoordinates, northeast: dropOffDestinationGeoGraphicCoordinates);
    }
    
    controllerGoogleMap!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72),);

    /** add markers to pickUp & destination Points **/
    Marker pickUpPointMarker = Marker(
      markerId: MarkerId("pickUpPointMarkerID"),
      position: pickUpGeoGraphicCoordinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen,),
      infoWindow: InfoWindow(title: pickUpLocation.placeName, snippet: "Location",),
    );

    Marker dropOffDestinationPointMarker = Marker(
      markerId: MarkerId("dropOffDestinationPointMarkerID"),
      position: dropOffDestinationGeoGraphicCoordinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed,),
      infoWindow: InfoWindow(title: dropOffDestinationLocation.placeName, snippet: "Destination Location",),
    );

    setState(() {
      markerSet.add(pickUpPointMarker);
      markerSet.add(dropOffDestinationPointMarker);
    });

    /** add circles to pickUp & destination Points **/
    Circle pickUpPointCircle = Circle(
      circleId: CircleId("pickUpCircleID"),
      strokeColor: Colors.blue,
      strokeWidth: 6,
      radius: 16,
      center: pickUpGeoGraphicCoordinates,
      fillColor: Colors.red.withOpacity(0.4),
    );

    Circle dropOffDestinationPointCircle = Circle(
      circleId: CircleId("dropOffDestinationPointCircleID"),
      strokeColor: Colors.blue,
      strokeWidth: 6,
      radius: 16,
      center: dropOffDestinationGeoGraphicCoordinates,
      fillColor: Colors.green.withOpacity(0.4),
    );

    setState(() {
      circleSet.add(pickUpPointCircle);
      circleSet.add(dropOffDestinationPointCircle);
    });

  }

  resetAppNow(){
    setState(() {
      polylineCoordinates.clear();
      polylineSet.clear();
      markerSet.clear();
      circleSet.clear();
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 0;
      tripContainerHeight = 0;
      searchContainerHeight = 276;
      bottomMapPadding = 300;
      isDrawerOpened = true;

      status = "";
      nameDriver = "";
      photoDriver = "";
      phoneNumberDriver = "";
      carDetailsDriver = "";
      tripStatusDisplay = "Driver is Arriving";
    });

    Restart.restartApp();
  }

  cancelRideRequest(){
    /** remove ride request from database **/
    tripRequestRef!.remove();

    setState(() {
      stateOfApp = "normal";
    });
  }

  displayRequestContainer(){
    setState(() {
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 220;
      bottomMapPadding = 200;
      isDrawerOpened = true;
    });

    /** send ride request **/
    makeTripRequest();
  }

  updateAvailableNearbyOnlineDriversOnMap(){
    setState(() {
      markerSet.clear();
    });

    Set<Marker> markersTempSet = Set<Marker>();

    for(OnlineNearbyDrivers eachOnlineNearbyDriver in ManageDriversMethods.nearbyOnlineDriversList){
      LatLng driverCurrentPosition = LatLng(eachOnlineNearbyDriver.latDriver!, eachOnlineNearbyDriver.lngDriver!);

      Marker driverMarker = Marker(
        markerId: MarkerId("driver ID = ${eachOnlineNearbyDriver.uidDriver}"),
        position: driverCurrentPosition,
        icon: carIconNearbyDriver!,
      );

      markersTempSet.add(driverMarker);

      setState(() {
        markerSet = markersTempSet;
      });

    }
  }

  initializeGeoFireListener(){
    Geofire.initialize("onlineDrivers");
    Geofire.queryAtLocation(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude, 22)!.listen((driverEvent) {
      if(driverEvent != null){
        var onlineDriverChild = driverEvent["callBack"];
        switch(onlineDriverChild){
          case Geofire.onKeyEntered:
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent["key"];
            onlineNearbyDrivers.latDriver = driverEvent["latitude"];
            onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
            ManageDriversMethods.nearbyOnlineDriversList.add(onlineNearbyDrivers);
            if(nearbyOnlineDriversKeysLoaded==true){
              /** update drivers on google map **/
              updateAvailableNearbyOnlineDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            ManageDriversMethods.removeDriverFromList(driverEvent["key"]);
            /** update drivers on google map **/
            updateAvailableNearbyOnlineDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent["key"];
            onlineNearbyDrivers.latDriver = driverEvent["latitude"];
            onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
            ManageDriversMethods.updateOnlineNearbyDriversLocation(onlineNearbyDrivers);
            /** update drivers on google map **/
            updateAvailableNearbyOnlineDriversOnMap();
            break;

          case Geofire.onGeoQueryReady:
            nearbyOnlineDriversKeysLoaded = true;
            /** update drivers on google map **/
            updateAvailableNearbyOnlineDriversOnMap();
            break;
        }
      }
    });
  }

  makeTripRequest(){
    tripRequestRef = FirebaseDatabase.instance.ref().child("tripRequests").push();

    var pickUpLocation = Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation = Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    Map pickUpCoordinatesMap = {
      "latitude": pickUpLocation!.latitudePosition.toString(),
      "longitude": pickUpLocation.longitudePosition.toString(),
    };

    Map dropOffDestinationCoordinatesMap = {
      "latitude": dropOffDestinationLocation!.latitudePosition.toString(),
      "longitude": dropOffDestinationLocation.longitudePosition.toString(),
    };

    Map driverCoordinates = {
      "latitude": "",
      "longitude": "",
    };

    Map dataMap = {
      "tripID": tripRequestRef!.key,
      "publishedDateTime": DateTime.now().toString(),

      "userName": userName,
      "userPhone": userPhone,
      "userID": userID,
      "pickUpLatLng": pickUpCoordinatesMap,
      "dropOffLatLng": dropOffDestinationCoordinatesMap,
      "pickUpAddress": pickUpLocation.placeName,
      "dropOffAddress": dropOffDestinationLocation.placeName,

      "driverID": "waiting",
      "carDetails": "",
      "driverLocation": driverCoordinates,
      "driverName": "",
      "driverPhone": "",
      "driverPhoto": "",
      "fareAmount": "",
      "status": "new",
    };
    
    tripRequestRef!.set(dataMap);

    tripStreamSubscription = tripRequestRef!.onValue.listen((eventSnapshot) async{
      if(eventSnapshot.snapshot.value == null){
        return;
      }
      if((eventSnapshot.snapshot.value as Map)["driverName"] != null){
        nameDriver = (eventSnapshot.snapshot.value as Map)["driverName"];
      }
      if((eventSnapshot.snapshot.value as Map)["driverPhone"] != null){
        phoneNumberDriver = (eventSnapshot.snapshot.value as Map)["driverPhone"];
      }
      if((eventSnapshot.snapshot.value as Map)["driverPhoto"] != null){
        photoDriver = (eventSnapshot.snapshot.value as Map)["driverPhoto"];
      }
      if((eventSnapshot.snapshot.value as Map)["carDetails"] != null){
        carDetailsDriver = (eventSnapshot.snapshot.value as Map)["carDetails"];
      }
      if((eventSnapshot.snapshot.value as Map)["status"] != null){
        status = (eventSnapshot.snapshot.value as Map)["status"];
      }
      if((eventSnapshot.snapshot.value as Map)["driverLocation"] != null){
        double driverLatitude = double.parse((eventSnapshot.snapshot.value as Map)["driverLocation"]["latitude"].toString(),);
        double driverLongitude = double.parse((eventSnapshot.snapshot.value as Map)["driverLocation"]["longitude"].toString(),);
        LatLng driverCurrentLocationLatLng = LatLng(driverLatitude, driverLongitude);

        if(status=="accepted"){
          /** update info for pickUp to user on UI **/
          /** info from driver current location to user pickUp location **/
          updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng);
        }
        else if(status=="arrived"){
          /** update info for arrived - when driver reach at the pickUp point of user **/
          setState(() {
            tripStatusDisplay = "Driver has Arrived";
          });
        }
        else if(status=="onTrip"){
          /** update info for dropOff to user on UI **/
          /** info from driver current location to user dropOff location **/
          updateFromDriverCurrentLocationToDropOffDestination(driverCurrentLocationLatLng);
        }

      }

      if(status == "accepted"){
        displayTripDetailsContainer();
        Geofire.stopListener();
        /** remove drivers markers **/
        setState(() {
          markerSet.removeWhere((element) => element.markerId.value.contains("driver"),);
        });
      }

      if(status == "ended"){
        if((eventSnapshot.snapshot.value as Map)["fareAmount"] != null){
          double fareAmount = double.parse((eventSnapshot.snapshot.value as Map)["fareAmount"].toString());

          var responseFromPaymentDialog = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context)=> PaymentDialog(fareAmount: fareAmount.toString(),),
          );

          if(responseFromPaymentDialog == "paid"){
            tripRequestRef!.onDisconnect();
            tripRequestRef = null;

            tripStreamSubscription!.cancel();
            tripStreamSubscription = null;

            resetAppNow();
          }
        }
      }

    });
  }

  displayTripDetailsContainer(){
    setState(() {
      requestContainerHeight = 0;
      tripContainerHeight = 290;
      bottomMapPadding = 280;
    });
  }

  updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng) async{
    if(!requestingDirectionDetailsInfo){
      requestingDirectionDetailsInfo = true;
      var userPickUpLocationLatLng = LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
      
      var directionDetailsPickUp = await CommonMethods.getDirectionDetailsFromAPI(driverCurrentLocationLatLng, userPickUpLocationLatLng);

      if(directionDetailsPickUp==null){
        return;
      }

      setState(() {
        tripStatusDisplay = "Driver is Coming - ${directionDetailsPickUp.durationTextString}";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  updateFromDriverCurrentLocationToDropOffDestination(driverCurrentLocationLatLng) async{
    if(!requestingDirectionDetailsInfo){
      requestingDirectionDetailsInfo = true;
      var dropOffLocation = Provider.of<AppInfo>(context, listen: false).dropOffLocation;
      var userDropOffLocationLatLng = LatLng(dropOffLocation!.latitudePosition!, dropOffLocation.longitudePosition!);

      var directionDetailsPickUp = await CommonMethods.getDirectionDetailsFromAPI(driverCurrentLocationLatLng, userDropOffLocationLatLng);

      if(directionDetailsPickUp==null){
        return;
      }

      setState(() {
        tripStatusDisplay = "Driving to dropOff Location - ${directionDetailsPickUp.durationTextString}";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  noDriverAvailable(){
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context)=> InfoDialog(title: "No Driver Available", description: "No Driver found to the nearby location, Please try again shortly",),
    );
  }

  searchDriver(){
    if(availableNearbyOnlineDriversList!.isEmpty){
      cancelRideRequest();
      resetAppNow();
      noDriverAvailable();
      return;
    }

    var currentDriver = availableNearbyOnlineDriversList![0];

    /** send notification to this currentDriver - selected driver **/
    sendNotificationToDriver(currentDriver);

    availableNearbyOnlineDriversList!.removeAt(0);
  }

  sendNotificationToDriver(OnlineNearbyDrivers currentDriver){
    /** update driver's newTripStatus - assign tripID to current driver **/
    DatabaseReference currentDriverRef = FirebaseDatabase.instance.ref().child("drivers").child(currentDriver.uidDriver.toString()).child("newTripStatus");
    currentDriverRef.set(tripRequestRef!.key);

    /** get current driver device recognition token **/
    DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance.ref().child("drivers").child(currentDriver.uidDriver.toString()).child("deviceToken");

    tokenOfCurrentDriverRef.once().then((dataSnapshot){
      if(dataSnapshot.snapshot.value != null){
        String deviceToken = dataSnapshot.snapshot.value.toString();
        /** send notification **/
        PushNotificationService.sendNotificationToSelectedDriver(deviceToken, context, tripRequestRef!.key.toString());
      }
      else{
        return;
      }

      const oneTickPerSec = Duration(seconds: 1);
      var timerCountDown = Timer.periodic(oneTickPerSec, (timer) {
        requestTimeoutDriver = requestTimeoutDriver-1;
        /** when trip request is not requesting means trip request cancelled - stop timer **/
        if(stateOfApp != "requesting"){
          timer.cancel();
          currentDriverRef.set("cancelled");
          currentDriverRef.onDisconnect();
          requestTimeoutDriver = 20;
        }
        /** when trip request is accepted by online nearest available driver **/
        currentDriverRef.onValue.listen((dataSnapshot) {
          if(dataSnapshot.snapshot.value.toString()=="accepted"){
            timer.cancel();
            currentDriverRef.onDisconnect();
            requestTimeoutDriver = 20;
          }
        });
        /** if 20 sec passed - send notification to next online available driver **/
        if(requestTimeoutDriver==0){
          currentDriverRef.set("timeout");
          timer.cancel();
          currentDriverRef.onDisconnect();
          requestTimeoutDriver = 20;
          /** send notification to next online available driver **/
          searchDriver();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    makeDriverNearbyCarIcon();

    return Scaffold(
      key: sKey,
      drawer: Container(
        width: 255,
        color: Colors.black87,
        child: Drawer(
          backgroundColor: Colors.white10,
          child: ListView(
            children: [
              Divider(height: 1, color: Colors.white, thickness: 1,),

              /* header */
              Container(
                color: Colors.black,
                height: 160,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.black,),
                  child: Row(
                    children: [
                      Image.asset("assets/images/avatarman.png", width: 60, height: 60,),
                      Icon(Icons.person, size: 60,),
                      SizedBox(width: 16,),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(userName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,),),
                          SizedBox(height: 5,),
                          Text("Profile", style: TextStyle(color: Colors.white30,),),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Divider(height: 1, color: Colors.white, thickness: 1,),
              SizedBox(height: 10,),

              /* body */
              GestureDetector(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> TripsHistoryPage(),),);
                },
                child: ListTile(
                  leading: IconButton(
                    onPressed: (){},
                    icon: Icon(Icons.history, color: Colors.grey,),
                  ),
                  title: Text("History", style: TextStyle(color: Colors.grey,),),
                ),
              ),

              GestureDetector(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> AboutPage(),),);
                },
                child: ListTile(
                  leading: IconButton(
                    onPressed: (){},
                    icon: Icon(Icons.info, color: Colors.grey,),
                  ),
                  title: Text("About", style: TextStyle(color: Colors.grey,),),
                ),
              ),

              GestureDetector(
                onTap: (){
                  FirebaseAuth.instance.signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> LoginScreen(),),);
                },
                child: ListTile(
                  leading: IconButton(onPressed: (){}, icon: Icon(Icons.logout, color: Colors.grey,),),
                  title: Text("Logout", style: TextStyle(color: Colors.grey,),),
                ),
              ),

            ],
          ),
        ),
      ),

      body: Stack(
        children: [
          /** google map **/
          GoogleMap(
            padding: EdgeInsets.only(top: 25, bottom: bottomMapPadding,),
            initialCameraPosition: googlePlexInitialPosition,
            mapType: MapType.normal,
            myLocationEnabled: true,
            polylines: polylineSet,
            markers: markerSet,
            circles: circleSet,
            onMapCreated: (GoogleMapController googleMapController){
              controllerGoogleMap = googleMapController;
              updateMapTheme(controllerGoogleMap!);

              googleMapCompleterController.complete(controllerGoogleMap);
              setState(() {
                bottomMapPadding = 150;
              });
              getCurrentLiveLocationOfUser();
            },
          ),

          /** drawer button **/
          Positioned(
            top: 35,
            left: 20,
            child: GestureDetector(
              onTap: (){
                if(isDrawerOpened==true){
                  sKey.currentState!.openDrawer();
                }
                else{
                  resetAppNow();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 20,
                  child: Icon(isDrawerOpened==true ? Icons.menu : Icons.close, color: Colors.black87,),
                ),
              ),
            ),
          ),

          /** search location icon button **/
          Positioned(
            left: 0,
            right: 0,
            bottom: -80,
            child: Container(
              height: searchContainerHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () async{
                      var responseFromSearchPage = await Navigator.push(context, MaterialPageRoute(builder: (context)=> SearchDestinationPage(),),);
                      if(responseFromSearchPage == "placeSelected"){
                        // String dropOffLocation = Provider.of<AppInfo>(context, listen: false).dropOffLocation!.placeName ?? "";
                        // print("dropOffLocation: $dropOffLocation");
                        displayUserRideDetailsContainer();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(24),
                      backgroundColor: Colors.grey,
                    ),
                    child: Icon(Icons.search, color: Colors.white, size: 20,),
                  ),
                  ElevatedButton(
                    onPressed: (){},
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(24),
                      backgroundColor: Colors.grey,
                    ),
                    child: Icon(Icons.home, color: Colors.white, size: 20,),
                  ),
                  ElevatedButton(
                    onPressed: (){},
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(24),
                      backgroundColor: Colors.grey,
                    ),
                    child: Icon(Icons.work, color: Colors.white, size: 20,),
                  ),
                ],
              ),
            ),
          ),

          /** ride details container **/
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: rideDetailsContainerHeight,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15),),
                boxShadow: [
                  BoxShadow(color: Colors.white12, blurRadius: 15, spreadRadius: 0.5, offset: Offset(0.7, 0.7),),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 18,),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16,),
                      child: SizedBox(
                        height: 200,
                        child: Card(
                          elevation: 10,
                          child: Container(
                            width: MediaQuery.of(context).size.width * .7,
                            color: Colors.black45,
                            child: Padding(
                              padding: EdgeInsets.only(top: 8, bottom: 8,),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0,),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text((tripDirectionDetailsInfo != null) ? tripDirectionDetailsInfo!.distanceTextString! : "", style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold,),),
                                        Text((tripDirectionDetailsInfo != null) ? tripDirectionDetailsInfo!.durationTextString! : "", style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold,),),
                                      ],
                                    ),
                                  ),

                                  GestureDetector(
                                    onTap: (){
                                      setState(() {
                                        stateOfApp = "requesting";
                                      });

                                      displayRequestContainer();

                                      /** get nearest available online drivers **/
                                      availableNearbyOnlineDriversList = ManageDriversMethods.nearbyOnlineDriversList;

                                      /** search driver **/
                                      searchDriver();
                                    },
                                    child: Image.asset("assets/images/uberexec.png", height: 122, width: 122,),
                                  ),

                                  Text(tripDirectionDetailsInfo != null ? "\$ ${commonMethods.calculateFareAmount(tripDirectionDetailsInfo!)}" : "", style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold,),),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /** request container **/
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: requestContainerHeight,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16),),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 0.5, offset: Offset(0.7, 0.7),),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  children: [
                    SizedBox(height: 12,),
                    SizedBox(
                      width: 200,
                      child: LoadingAnimationWidget.flickr(leftDotColor: Colors.greenAccent, rightDotColor: Colors.purpleAccent, size: 50,),
                    ),
                    SizedBox(height: 20,),
                    GestureDetector(
                      onTap: (){
                        resetAppNow();
                        cancelRideRequest();
                      },
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(width: 1.5, color: Colors.green,),
                        ),
                        child: Icon(Icons.close, color: Colors.black, size: 25,),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /** trip details container **/
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: tripContainerHeight,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16),),
                boxShadow: [
                  BoxShadow(color: Colors.white24, blurRadius: 15, spreadRadius: 0.5, offset: Offset(0.7, 0.7),),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5,),

                    /** trip status display text **/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(tripStatusDisplay, style: TextStyle(fontSize: 19, color: Colors.grey,),),
                      ],
                    ),

                    SizedBox(height: 19,),

                    Divider(height: 1, color: Colors.white70, thickness: 1,),

                    SizedBox(height: 19,),

                    /** image - driver name & driver car details **/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.network(photoDriver=="" ? "https://cdn3d.iconscout.com/3d/premium/thumb/driver-10961405-8772481.png" : photoDriver, width: 60, height: 60, fit: BoxFit.cover,),
                        ),

                        SizedBox(width: 8,),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nameDriver, style: TextStyle(fontSize: 20, color: Colors.grey,),),
                            Text(carDetailsDriver, style: TextStyle(fontSize: 20, color: Colors.grey,),),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 19,),

                    Divider(height: 1, color: Colors.white70, thickness: 1,),

                    SizedBox(height: 19,),

                    /** call driver button **/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: (){
                            launchUrl(Uri.parse("tel://$phoneNumberDriver"),);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(25),),
                                  border: Border.all(width: 1, color: Colors.white,),
                                ),
                                child: Icon(Icons.phone, color: Colors.white,),
                              ),

                              SizedBox(height: 10,),

                              Text("Call", style: TextStyle(color: Colors.grey,),)
                            ],
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

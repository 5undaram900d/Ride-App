
import 'package:flutter/material.dart';
import 'package:ride_app_admin_web_panel/methods/common_methods.dart';
import 'package:ride_app_admin_web_panel/widgets/trips_data_list.dart';

class TripsPage extends StatefulWidget {
  static const String id = "\\webPageTrips";

  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {

  CommonMethods commonMethods = CommonMethods();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.topLeft,
                child: Text("Manage Trips", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,),),
              ),
              SizedBox(height: 18,),
              Row(
                children: [
                  commonMethods.header(2, "TRIP ID"),
                  commonMethods.header(1, "USER NAME"),
                  commonMethods.header(1, "RIDER NAME"),
                  commonMethods.header(1, "CAR DETAILS"),
                  commonMethods.header(1, "TIMING"),
                  commonMethods.header(1, "FARE"),
                  commonMethods.header(1, "VIEW DETAILS"),
                ],
              ),

              /** display data **/
              TripsDataList(),
            ],
          ),
        ),
      ),
    );
  }
}

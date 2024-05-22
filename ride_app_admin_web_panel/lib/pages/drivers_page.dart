

import 'package:flutter/material.dart';
import 'package:ride_app_admin_web_panel/methods/common_methods.dart';
import 'package:ride_app_admin_web_panel/widgets/drivers_data_list.dart';

class DriversPage extends StatefulWidget {
  static const String id = "\\webPageDrivers";

  const DriversPage({super.key});

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {

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
                child: Text("Manage Drivers", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,),),
              ),
              SizedBox(height: 18,),
              Row(
                children: [
                  commonMethods.header(2, "DRIVER ID"),
                  commonMethods.header(1, "PICTURE"),
                  commonMethods.header(1, "NAME"),
                  commonMethods.header(1, "CAR DETAILS"),
                  commonMethods.header(1, "PHONE"),
                  commonMethods.header(1, "TOTAL EARNINGS"),
                  commonMethods.header(1, "ACTION"),
                ],
              ),

              /* display data */
              DriversDataList(),
            ],
          ),
        ),
      ),
    );
  }
}

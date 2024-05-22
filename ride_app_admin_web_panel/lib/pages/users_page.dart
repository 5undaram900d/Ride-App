

import 'package:flutter/material.dart';
import 'package:ride_app_admin_web_panel/methods/common_methods.dart';
import 'package:ride_app_admin_web_panel/widgets/users_data_list.dart';

class UsersPage extends StatefulWidget {
  static const String id = "\\webPageUsers";

  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {

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
                child: Text("Manage Users", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,),),
              ),
              SizedBox(height: 18,),
              Row(
                children: [
                  commonMethods.header(2, "USER ID"),
                  commonMethods.header(1, "USER NAME"),
                  commonMethods.header(1, "USER EMAIL"),
                  commonMethods.header(1, "PHONE"),
                  commonMethods.header(1, "ACTION"),
                ],
              ),
              /* display data */
              const UsersDataList(),
            ],
          ),
        ),
      ),
    );
  }
}

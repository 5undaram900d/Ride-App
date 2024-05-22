
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ride_app_admin_web_panel/methods/common_methods.dart';

class UsersDataList extends StatefulWidget {
  const UsersDataList({super.key});

  @override
  State<UsersDataList> createState() => _UsersDataListState();
}

class _UsersDataListState extends State<UsersDataList> {

  final usersRecordsFromDatabase = FirebaseDatabase.instance.ref().child("users");
  CommonMethods commonMethods = CommonMethods();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: usersRecordsFromDatabase.onValue,
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
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                commonMethods.data(2, Text(itemsList[index]["id"].toString(),),),
                commonMethods.data(1, Text(itemsList[index]["name"].toString(),),),
                commonMethods.data(1, Text(itemsList[index]["email"].toString(),),),
                commonMethods.data(1, Text(itemsList[index]["phone"].toString(),),),
                commonMethods.data(
                  1,
                  itemsList[index]["blockStatus"] == "no"
                      ? ElevatedButton(
                    onPressed: () async{
                      await FirebaseDatabase.instance.ref().child("users").child(itemsList[index]["id"]).update({"blockStatus": "yes",});
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pink,),
                    child: Text("Block", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),),
                  )
                      : ElevatedButton(
                    onPressed: () async{
                      await FirebaseDatabase.instance.ref().child("users").child(itemsList[index]["id"]).update({"blockStatus": "no",});
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pink,),
                    child: Text("Approve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}


import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ride_app_admin_web_panel/methods/common_methods.dart';

class DriversDataList extends StatefulWidget {
  const DriversDataList({super.key});

  @override
  State<DriversDataList> createState() => _DriversDataListState();
}

class _DriversDataListState extends State<DriversDataList> {

  final driversRecordsFromDatabase = FirebaseDatabase.instance.ref().child("drivers");
  CommonMethods commonMethods = CommonMethods();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: driversRecordsFromDatabase.onValue,
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
                commonMethods.data(1, Image.network(itemsList[index]["photo"].toString(), width: 50, height: 50,),),
                commonMethods.data(1, Text(itemsList[index]["name"].toString(),),),
                commonMethods.data(1, Text("${itemsList[index]["car_details"]["carModel"]} ${itemsList[index]["car_details"]["carNumber"]}",),),
                commonMethods.data(1, Text(itemsList[index]["phone"].toString(),),),
                commonMethods.data(
                  1,
                  itemsList[index]["earnings"] != null
                  ? Text("\$ ${itemsList[index]["earnings"]}",)
                  : Text("\$ 0"),
                ),
                commonMethods.data(
                  1,
                  itemsList[index]["blockStatus"] == "no"
                  ? ElevatedButton(
                    onPressed: () async{
                      await FirebaseDatabase.instance.ref().child("drivers").child(itemsList[index]["id"]).update({"blockStatus": "yes",});
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pink,),
                    child: Text("Block", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),),
                  )
                  : ElevatedButton(
                    onPressed: ()async{
                      await FirebaseDatabase.instance.ref().child("drivers").child(itemsList[index]["id"]).update({"blockStatus": "no",});
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

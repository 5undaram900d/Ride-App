
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_app/appInfo/app_info.dart';
import 'package:ride_app/global/global_var.dart';
import 'package:ride_app/methods/common_methods.dart';
import 'package:ride_app/models/prediction_model.dart';
import 'package:ride_app/widgets/prediction_place_ui.dart';

class SearchDestinationPage extends StatefulWidget {
  const SearchDestinationPage({super.key});

  @override
  State<SearchDestinationPage> createState() => _SearchDestinationPageState();
}

class _SearchDestinationPageState extends State<SearchDestinationPage> {

  TextEditingController pickupTextEditingController = TextEditingController();
  TextEditingController destinationTextEditingController = TextEditingController();

  List<PredictionModel> dropOffPredictionsPlaceList = [];

  /* Google Places API - Place AutoComplete */
  searchLocation(String locationName) async{
    if(locationName.length > 1){
      String apiPlaceUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$locationName&key=$googleMapKey&components=country:in";
      var responseFromPlaceAPI = await CommonMethods.sendRequestToAPI(apiPlaceUrl);
      if(responseFromPlaceAPI=="error"){
        return;
      }
      if(responseFromPlaceAPI["status"]=="OK"){
        var predictionResultInJson = responseFromPlaceAPI["predictions"];
        var predictionsList = (predictionResultInJson as List).map((eachPlacePrediction) => PredictionModel.fromJson(eachPlacePrediction),).toList();
        setState(() {
          dropOffPredictionsPlaceList = predictionsList;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String userAddress = Provider.of<AppInfo>(context, listen: false).pickUpLocation!.humanReadableAddress ?? "";
    pickupTextEditingController.text = userAddress;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 10,
              child: Container(
                height: 230,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 5.0, spreadRadius: 0.5, offset: Offset(0.7, 0.7),),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 24, top: 40, right: 24, bottom: 20,),
                  child: Column(
                    children: [
                      SizedBox(height: 6,),
                      /* icon-button title */
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: (){
                              Navigator.pop(context);
                            },
                            child: Icon(Icons.arrow_back, color: Colors.white,),
                          ),
                          Center(child: Text("Set dropOff Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,),),),
                        ],
                      ),
                      SizedBox(height: 18,),
                      /* pickup text field */
                      Row(
                        children: [
                          Image.asset("assets/images/initial.png", width: 20,),
                          SizedBox(height: 18,),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(3),
                                child: TextField(
                                  controller: pickupTextEditingController,
                                  decoration: InputDecoration(
                                    hintText: "Pickup Address",
                                    fillColor: Colors.white12,
                                    filled: true,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(left: 11, top: 9, bottom: 9,),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12,),
                      /* destination text field */
                      Row(
                        children: [
                          Image.asset("assets/images/final.png", width: 20,),
                          SizedBox(height: 18,),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(3),
                                child: TextField(
                                  controller: destinationTextEditingController,
                                  onChanged: (inputText){
                                    searchLocation(inputText);
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Destination Address",
                                    fillColor: Colors.white12,
                                    filled: true,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(left: 11, top: 9, bottom: 9,),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /* display prediction results for destination Place */
            (dropOffPredictionsPlaceList.length>0)
            ? Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListView.separated(
                padding: EdgeInsets.all(0),
                itemBuilder: (context, index){
                  return Card(
                    elevation: 3,
                    child: PredictionPlaceUI(predictionPlaceData: dropOffPredictionsPlaceList[index],),
                  );
                },
                separatorBuilder: (BuildContext context, int index)=> SizedBox(height: 2,),
                itemCount: dropOffPredictionsPlaceList.length,
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
              ),
            )
            : Container(),
          ],
        ),
      ),
    );
  }
}

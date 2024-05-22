
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_app/appInfo/app_info.dart';
import 'package:ride_app/global/global_var.dart';
import 'package:ride_app/methods/common_methods.dart';
import 'package:ride_app/models/address_model.dart';
import 'package:ride_app/models/prediction_model.dart';
import 'package:ride_app/widgets/loading_dialog.dart';

class PredictionPlaceUI extends StatefulWidget {

  PredictionModel? predictionPlaceData;

  PredictionPlaceUI({super.key, this.predictionPlaceData});

  @override
  State<PredictionPlaceUI> createState() => _PredictionPlaceUIState();
}

class _PredictionPlaceUIState extends State<PredictionPlaceUI> {

  /* Place Details - Places API */
  fetchClickedPlaceDetails(String placeID) async{
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context)=> LoadingDialog(messageText: "Getting details..."),
    );

    String urlPlaceDetailsAPI = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeID&key=$googleMapKey";
    var responseFromPlaceDetailsAPI = await CommonMethods.sendRequestToAPI(urlPlaceDetailsAPI,);

    Navigator.pop(context);

    if(responseFromPlaceDetailsAPI=="error"){
      return;
    }
    if(responseFromPlaceDetailsAPI["status"]=="OK"){
      AddressModel dropOffLocation = AddressModel();

      dropOffLocation.placeName = responseFromPlaceDetailsAPI["result"]["name"];
      dropOffLocation.latitudePosition = responseFromPlaceDetailsAPI["result"]["geometry"]["location"]["lat"];
      dropOffLocation.longitudePosition = responseFromPlaceDetailsAPI["result"]["geometry"]["location"]["lng"];
      dropOffLocation.placeID = placeID;

      Provider.of<AppInfo>(context, listen: false).updateDropOffLocation(dropOffLocation);

      Navigator.pop(context, "placeSelected");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: (){
        fetchClickedPlaceDetails(widget.predictionPlaceData!.place_id.toString());
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white,),
      child: Container(
        child: Column(
          children: [
            SizedBox(height: 10,),
            Row(
              children: [
                Icon(Icons.share_location, color: Colors.grey,),
                SizedBox(width: 13,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.predictionPlaceData!.main_text.toString(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, color: Colors.black87,),
                      ),
                      SizedBox(height: 3,),
                      Text(
                        widget.predictionPlaceData!.secondary_text.toString(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.black54,),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10,),
          ],
        ),
      ),
    );
  }
}

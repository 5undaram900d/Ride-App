
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:ride_app/methods/common_methods.dart';

class PaymentDialog extends StatefulWidget {
  String fareAmount;

  PaymentDialog({super.key, required this.fareAmount});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  CommonMethods commonMethods = CommonMethods();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),),
      backgroundColor: Colors.black54,
      child: Container(
        margin: EdgeInsets.all(5),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20,),

            Text("PAY CASH", style: TextStyle(height: 1.5, color: Colors.grey,),),

            SizedBox(height: 20,),
            Divider(height: 1.5, color: Colors.white70, thickness: 1.2,),
            SizedBox(height: 15,),

            Text("\$" + widget.fareAmount!, style: TextStyle(color: Colors.grey, fontSize: 36, fontWeight: FontWeight.bold,),),
            
            SizedBox(height: 16,),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20,),
              child: Text("This is fare amount (\$ ${widget.fareAmount}) you have pay to the driver.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey,),),
            ),

            SizedBox(height: 30,),
            
            ElevatedButton(
              onPressed: (){
                Navigator.pop(context, "paid");
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green,),
              child: Text("PAY CASH",),
            ),

            SizedBox(height: 40,),

          ],
        ),
      ),
    );
  }
}

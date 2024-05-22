
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';

class InfoDialog extends StatefulWidget {
  String? title, description;

  InfoDialog({super.key, this.title, this.description});

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.grey,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 12,),
                Text(widget.title.toString(), style: TextStyle(fontSize: 22, color: Colors.white60, fontWeight: FontWeight.bold,),),

                SizedBox(height: 27,),
                Text(widget.description.toString(), textAlign: TextAlign.center, style: TextStyle(color: Colors.white54,),),

                SizedBox(height: 32,),

                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: (){
                      Navigator.pop(context);
                      Restart.restartApp();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent,),
                    child: Text("OK"),
                  ),
                ),

                SizedBox(height: 12,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

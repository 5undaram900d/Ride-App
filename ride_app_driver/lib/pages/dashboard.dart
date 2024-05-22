
import 'package:flutter/material.dart';
import 'package:ride_app_driver/pages/earnings_page.dart';
import 'package:ride_app_driver/pages/home_page.dart';
import 'package:ride_app_driver/pages/profile_page.dart';
import 'package:ride_app_driver/pages/trips_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin{
  TabController? controller;
  int indexSelected = 0;

  onBarItemClicked(int i){
    setState(() {
      indexSelected = i;
      controller!.index = indexSelected;
    });
  }
  
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller!.dispose();
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        physics: NeverScrollableScrollPhysics(),
        controller: controller,
        children: [
          HomePage(),
          EarningsPage(),
          TripsPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home,), label: "Home",),
          BottomNavigationBarItem(icon: Icon(Icons.monetization_on,), label: "Earning",),
          BottomNavigationBarItem(icon: Icon(Icons.car_crash,), label: "Trip",),
          BottomNavigationBarItem(icon: Icon(Icons.person,), label: "Profile",),
        ],
        currentIndex: indexSelected,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.white,
        showSelectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 12,),
        type: BottomNavigationBarType.fixed,
        onTap: onBarItemClicked,
      ),
    );
  }
}

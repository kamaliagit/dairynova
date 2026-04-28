import 'package:flutter/material.dart';
import './rider_jobs_screen.dart';
import './my_deliveries_screen.dart';

class RiderMainScreen extends StatefulWidget {
  const RiderMainScreen({super.key});

  @override
  State<RiderMainScreen> createState() => _RiderMainScreenState();
}

class _RiderMainScreenState extends State<RiderMainScreen> {
  int _selectedIndex = 0;

  // The two screens we created for the Rider
  final List<Widget> _screens = [
    const RiderJobsScreen(),
    const MyDeliveriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Available Jobs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bike),
            label: "My Tasks",
          ),
        ],
      ),
    );
  }
}

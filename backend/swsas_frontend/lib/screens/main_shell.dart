import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'sos_dashboard.dart';
import 'profile_screen.dart'; // We'll create this next

class MainShell extends StatefulWidget {
  final int initialIndex;
  
  const MainShell({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _MainShellState createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const SosDashboard(isStandalone: false),
    const Center(child: Text("Calls")), // Placeholder
    const MapScreen(isStandalone: false),
    const Center(child: Text("Directory")), // Placeholder
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          
          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFC8BA2), // Soft pink matching theme
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navItem(0, Icons.warning_amber_rounded),
                  _navItem(1, Icons.call),
                  _navItem(2, Icons.map_outlined),
                  _navItem(3, Icons.menu_book_rounded),
                  _navItem(4, Icons.person_outline),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFFFA648C) : Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

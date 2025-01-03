import 'package:flutter/material.dart';
import 'package:ticketing_event/core/assets/assets.gen.dart';
import 'package:ticketing_event/core/constants/colors.dart';
import 'package:ticketing_event/core/extensions/build_context_ext.dart';
import 'package:ticketing_event/pages/checkin/checkin_scanner_auto_rotate.dart';

class MainNavDesktop extends StatefulWidget {
  const MainNavDesktop({super.key});

  @override
  State<MainNavDesktop> createState() => _MainNavDesktopState();
}

class _MainNavDesktopState extends State<MainNavDesktop> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('This is page 1')),
    const TabletQRScannerPage(),
    const Center(child: Text('Home')),
    const Center(child: Text('This is page 3')),
    const Center(child: Text('This is page 4')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: SizedBox(
        height: 100, // Increased height to accommodate floating button
        child: Stack(
          clipBehavior: Clip.none, // Prevents clipping of floating button
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 0), // Add bottom margin
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.event, 'Events'),
                  _buildNavItem(1, Icons.qr_code_scanner, 'Scan'),
                  const SizedBox(width: 80), // Space for center button
                  _buildNavItem(3, Icons.history, 'History'),
                  _buildNavItem(4, Icons.person, 'Profile'),
                ],
              ),
            ),
            Positioned(
              top: -15, // Adjusted position
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = 2),
                child: Container(
                  height: 90, // Slightly smaller button
                  width: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.home,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : Colors.grey,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
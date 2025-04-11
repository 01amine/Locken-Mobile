import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_lock/home/screens/alert_screen.dart';
import 'package:smart_lock/home/screens/logs_screen.dart';
import 'package:smart_lock/presentation/pages/beacon_scanner_page.dart';

import '../cubit/bottom_navigation_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = [
      SecurityDashboard(),
      SecurityLogsScreen(),
      BeaconScannerPage(),
    ];

    return Scaffold(
      body: BlocBuilder<BottomNavigationCubit, int>(
        builder: (context, state) {
          return pages[state];
        },
      ),
      bottomNavigationBar: BlocBuilder<BottomNavigationCubit, int>(
        builder: (context, state) {
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: state,
            onTap: (index) {
              context.read<BottomNavigationCubit>().changeTab(index);
            },
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home,
                    color: state == 0 ? Colors.white : Colors.grey),
                label: 'Alerts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined,
                    color: state == 1 ? Colors.white : Colors.grey),
                label: 'Logs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.lock_outlined,
                    color: state == 2 ? Colors.white : Colors.grey),
                label: 'Access',
              ),
            ],
          );
        },
      ),
    );
  }
}

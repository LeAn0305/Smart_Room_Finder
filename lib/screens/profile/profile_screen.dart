import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Cá nhân', style: TextStyle(color: AppColors.textPrimary)),
      ),
    );
  }
}

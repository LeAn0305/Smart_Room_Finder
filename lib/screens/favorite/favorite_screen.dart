import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Yêu thích', style: TextStyle(color: AppColors.textPrimary)),
      ),
    );
  }
}

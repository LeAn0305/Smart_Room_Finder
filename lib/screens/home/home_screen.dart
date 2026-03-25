import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/models/user_model.dart';
import 'package:smart_room_finder/widgets/custom_text_field.dart';
import 'package:smart_room_finder/widgets/room_card.dart';
import 'package:smart_room_finder/widgets/section_title.dart';
import 'package:smart_room_finder/screens/search/search_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<RoomModel> rooms;
  String selectedCategory = 'Tất cả';
  final List<String> categories = ['Tất cả', 'Chung cư', 'Phòng trọ', 'Nhà riêng', 'Biệt thự'];

  @override
  void initState() {
    super.initState();
    rooms = List.from(RoomModel.sampleRooms);
  }

  List<RoomModel> get filteredRooms {
    if (selectedCategory == 'Tất cả') return rooms;
    final typeMap = {
      'Chung cư': RoomType.apartment,
      'Phòng trọ': RoomType.studio,
      'Nhà riêng': RoomType.house,
      'Biệt thự': RoomType.villa,
    };
    final type = typeMap[selectedCategory];
    return rooms.where((r) => r.type == type).toList();
  }

  void _toggleFavorite(RoomModel room) {
    setState(() {
      final idx = rooms.indexWhere((r) => r.id == room.id);
      if (idx != -1) rooms[idx] = room.copyWith(isFavorite: !room.isFavorite);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = UserModel.currentUser;

    return Scaffold(
      backgroundColor: AppColors.mintLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chào buổi sáng,',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          user.name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.teal, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(user.profileImageUrl),
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: CustomTextField(
                  hintText: 'Tìm kiếm phòng trọ, khu vực...',
                  prefixIcon: Icons.search_rounded,
                  suffixIcon: Icons.tune_rounded,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.teal, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      user.location,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 18),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = selectedCategory == categories[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = categories[index];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.teal : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (!isSelected)
                              BoxShadow(
                                color: AppColors.blue.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            color: isSelected ? AppColors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SectionTitle(
                title: 'Gợi ý cho bạn',
                actionText: 'Xem tất cả',
                onActionTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchResultScreen(),
                    ),
                  );
                },
              ),
              SizedBox(
                height: 360,
                child: filteredRooms.isEmpty
                    ? const Center(child: Text('Không có phòng nào', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredRooms.length,
                        itemBuilder: (context, index) {
                          return RoomCard(
                            room: filteredRooms[index],
                            isHorizontal: true,
                            onFavoriteTap: () => _toggleFavorite(filteredRooms[index]),
                          );
                        },
                      ),
              ),

              SectionTitle(
                title: 'Phòng gần đây',
                actionText: 'Xem bản đồ',
                onActionTap: () {},
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredRooms.length < 2 ? filteredRooms.length : 2,
                itemBuilder: (context, index) {
                  final room = filteredRooms[filteredRooms.length - 1 - index];
                  return RoomCard(
                    room: room,
                    onFavoriteTap: () => _toggleFavorite(room),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
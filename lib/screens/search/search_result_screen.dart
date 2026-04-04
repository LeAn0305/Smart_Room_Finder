import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/providers/room_provider.dart';
import 'package:smart_room_finder/widgets/room_card.dart';
import 'package:smart_room_finder/screens/room_detail/room_detail_screen.dart';

class SearchResultScreen extends StatefulWidget {
  final String? initialSearch;
  
  const SearchResultScreen({super.key, this.initialSearch});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  late TextEditingController _searchController;
  List<RoomModel> _filteredRooms = [];
  String _selectedType = 'Tất cả';
  final List<String> _types = ['Tất cả', 'Chung cư', 'Phòng trọ', 'Nhà riêng', 'Biệt thự'];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch);
    _applyFilters();
  }

  void _applyFilters() {
    final allRooms = context.read<RoomProvider>().activePublicRooms;
    setState(() {
      _filteredRooms = allRooms.where((room) {
        final matchesSearch = room.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            room.address.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesType = _selectedType == 'Tất cả' || room.typeString == _selectedType;
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tìm kiếm phòng',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, địa chỉ...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.teal),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _types.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedType == _types[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = _types[index];
                      _applyFilters();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.teal : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.teal : AppColors.mintSoft,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _types[index],
                      style: TextStyle(
                        color: isSelected ? AppColors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _filteredRooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 80, color: AppColors.teal.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        const Text(
                          'Không tìm thấy phòng nào',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredRooms.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return RoomCard(
                        room: _filteredRooms[index],
                        isHorizontal: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomDetailScreen(room: _filteredRooms[index]),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

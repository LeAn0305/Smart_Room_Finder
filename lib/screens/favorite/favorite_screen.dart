import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/core/l10n/language_provider.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/widgets/room_card.dart';
import 'package:smart_room_finder/widgets/emty_state.dart';
import 'package:smart_room_finder/core/providers/favorite_provider.dart';
import 'package:smart_room_finder/screens/room_detail/room_detail_screen.dart';
import 'package:smart_room_finder/providers/room_provider.dart';

enum FavoriteSortOption { newest, priceLow, priceHigh, rating }

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<RoomModel> _filtered = [];

  RoomType? _selectedType;
  FavoriteSortOption _sortOption = FavoriteSortOption.newest;

  // Search
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Multi-select
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};

  // Group by type
  bool _groupByType = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FavoriteProvider>().fetchFavorites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _removeFromFavorite(RoomModel room) async {
    final lang = context.read<LanguageProvider>();
    final provider = context.read<FavoriteProvider>();

    setState(() {
      _selectedIds.remove(room.id);
    });

    await provider.removeFavorite(room.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${lang.tr('favorite_removed')}: "${room.title}"'),
        backgroundColor: AppColors.tealDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: lang.tr('favorite_undo'),
          textColor: Colors.white,
          onPressed: () {
            provider.addFavorite(room.id);
          },
        ),
      ),
    );
  }

    Future<void> _deleteSelected() async {
      final lang = context.read<LanguageProvider>();
      final provider = context.read<FavoriteProvider>();
      final count = _selectedIds.length;

      for (final id in _selectedIds) {
        await provider.removeFavorite(id);
      }

      setState(() {
        _selectedIds.clear();
        _isSelecting = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${lang.tr('delete_selected')}: $count'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _filtered.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(_filtered.map((r) => r.id));
      }
    });
  }

  void _showSortSheet(LanguageProvider lang) {
    final options = [
      (FavoriteSortOption.newest, Icons.access_time_rounded, lang.tr('sort_newest')),
      (FavoriteSortOption.priceLow, Icons.arrow_upward_rounded, lang.tr('sort_price_low')),
      (FavoriteSortOption.priceHigh, Icons.arrow_downward_rounded, lang.tr('sort_price_high')),
      (FavoriteSortOption.rating, Icons.star_rounded, lang.tr('sort_rating')),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(lang.tr('sort_by'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ...options.map((opt) {
              final selected = _sortOption == opt.$1;
              return GestureDetector(
                onTap: () {
                  setState(() => _sortOption = opt.$1);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.mintSoft : Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selected ? AppColors.teal : Colors.transparent, width: 1.5),
                  ),
                  child: Row(children: [
                    Icon(opt.$2, color: selected ? AppColors.teal : AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text(opt.$3, style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.tealDark : AppColors.textPrimary)),
                    const Spacer(),
                    if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 20),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final roomProvider = context.watch<RoomProvider>();

    final allFavs = roomProvider.allRooms
        .where((r) => favoriteProvider.isFavorite(r.id))
        .toList();

    _filtered = _selectedType == null
        ? List.from(allFavs)
        : allFavs.where((r) => r.type == _selectedType).toList();

    if (_searchQuery.isNotEmpty) {
      _filtered = _filtered.where((r) =>
          r.title.toLowerCase().contains(_searchQuery) ||
          r.address.toLowerCase().contains(_searchQuery)).toList();
    }

    switch (_sortOption) {
      case FavoriteSortOption.priceLow:
        _filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case FavoriteSortOption.priceHigh:
        _filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case FavoriteSortOption.rating:
        _filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case FavoriteSortOption.newest:
        break;
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.mintLight, AppColors.mintSoft, AppColors.mintGreen],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(lang, allFavs.length),
                  _buildSearchBar(lang),
                  _buildFilterBar(lang),
                  if (_isSelecting) _buildSelectionBar(lang),
                  const SizedBox(height: 4),
                  Expanded(child: _buildBody(lang)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LanguageProvider lang, int allFavoritesLength) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 18),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.tr('favorite_title'),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                Text('${allFavoritesLength} ${lang.tr('favorite_saved')}',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Group by type toggle
          GestureDetector(
            onTap: () => setState(() => _groupByType = !_groupByType),
            child: Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _groupByType ? AppColors.teal : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(Icons.category_rounded,
                  color: _groupByType ? Colors.white : AppColors.teal, size: 20),
            ),
          ),
          // Multi-select toggle
          GestureDetector(
            onTap: () => setState(() {
              _isSelecting = !_isSelecting;
              if (!_isSelecting) _selectedIds.clear();
            }),
            child: Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _isSelecting ? AppColors.teal : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(Icons.checklist_rounded,
                  color: _isSelecting ? Colors.white : AppColors.teal, size: 20),
            ),
          ),
          // Sort button
          GestureDetector(
            onTap: () => _showSortSheet(lang),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(children: [
                const Icon(Icons.sort_rounded, color: AppColors.teal, size: 18),
                const SizedBox(width: 6),
                Text(lang.tr('sort_by'),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: lang.tr('search_favorite'),
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.teal, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(LanguageProvider lang) {
    final types = [null, RoomType.studio, RoomType.apartment, RoomType.house, RoomType.villa];
    final labels = [
      lang.tr('filter_all'),
      lang.tr('type_studio'),
      lang.tr('type_apartment'),
      lang.tr('type_house'),
      lang.tr('type_villa'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: types.length,
        itemBuilder: (_, i) {
          final selected = _selectedType == types[i];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedType = types[i]);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.teal : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Text(labels[i],
                  style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectionBar(LanguageProvider lang) {
    final allSelected = _selectedIds.length == _filtered.length && _filtered.isNotEmpty;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.teal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text('${_selectedIds.length} ${lang.tr('selected')}',
              style: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w600, fontSize: 13)),
          const Spacer(),
          GestureDetector(
            onTap: _toggleSelectAll,
            child: Text(allSelected ? lang.tr('deselect_all') : lang.tr('select_all'),
                style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(width: 16),
          if (_selectedIds.isNotEmpty)
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text(lang.tr('delete_selected'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    content: Text('${_selectedIds.length} ${lang.tr('selected')}?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(lang.tr('cancel'),
                              style: const TextStyle(color: AppColors.textSecondary))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(lang.tr('delete'),
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) _deleteSelected();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                child: Text(lang.tr('delete_selected'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(LanguageProvider lang) {
    if (_filtered.isEmpty) {
      return EmptyState(
        title: _searchQuery.isNotEmpty
            ? 'Không tìm thấy kết quả'
            : _selectedType != null
                ? lang.tr('favorite_no_type')
                : lang.tr('favorite_empty_title'),
        message: _searchQuery.isNotEmpty
            ? 'Thử tìm kiếm với từ khóa khác nhé!'
            : _selectedType != null
                ? lang.tr('favorite_no_type_msg')
                : lang.tr('favorite_empty_msg'),
        icon: Icons.favorite_border_rounded,
      );
    }

    if (_groupByType) return _buildGroupedList(lang);
    return _buildFlatList(lang);
  }

  Widget _buildFlatList(LanguageProvider lang) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _filtered.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (_, i) => _buildRoomItem(_filtered[i], lang),
    );
  }

  Widget _buildGroupedList(LanguageProvider lang) {
    final groups = <RoomType, List<RoomModel>>{};
    for (final room in _filtered) {
      groups.putIfAbsent(room.type, () => []).add(room);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      physics: const BouncingScrollPhysics(),
      children: groups.entries.map((entry) {
        final typeLabel = _typeLabel(entry.key, lang);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(typeLabel,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Text('${entry.value.length}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]),
            ),
            ...entry.value.map((room) => _buildRoomItem(room, lang)),
          ],
        );
      }).toList(),
    );
  }

  String _typeLabel(RoomType type, LanguageProvider lang) {
    switch (type) {
      case RoomType.studio: return lang.tr('type_studio');
      case RoomType.apartment: return lang.tr('type_apartment');
      case RoomType.house: return lang.tr('type_house');
      case RoomType.villa: return lang.tr('type_villa');
    }
  }

  Widget _buildRoomItem(RoomModel room, LanguageProvider lang) {
    final isSelected = _selectedIds.contains(room.id);

    if (_isSelecting) {
      return GestureDetector(
        onTap: () => _toggleSelect(room.id),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: isSelected ? AppColors.teal : Colors.transparent, width: 2.5),
              ),
              child: RoomCard(room: room, onTap: () => _toggleSelect(room.id)),
            ),
            Positioned(
              top: 16, right: 16,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.teal : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.teal, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : null,
              ),
            ),
          ],
        ),
      );
    }

    return Dismissible(
      key: Key(room.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(24)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(lang.tr('favorite_delete_confirm'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Text('"${room.title}"'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(lang.tr('cancel'),
                    style: const TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(context, true),
              child: Text(lang.tr('delete'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ) ?? false,
      onDismissed: (_) => _removeFromFavorite(room),
      child: RoomCard(
        room: room,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomDetailScreen(room: room),
            ),
          );
        },
        onFavoriteTap: () => _removeFromFavorite(room),
      ),
    );
  }
}

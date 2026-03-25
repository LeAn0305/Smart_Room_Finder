import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';

class PostRoomScreen extends StatefulWidget {
  final RoomModel? editRoom;
  const PostRoomScreen({super.key, this.editRoom});
  @override
  State<PostRoomScreen> createState() => _PostRoomScreenState();
}

class _PostRoomScreenState extends State<PostRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _areaCtrl;
  RoomType _selectedType = RoomType.studio;
  RoomDirection? _selectedDirection;
  int _bedrooms = 1;
  int _durationDays = 30;
  final List<String> _selectedAmenities = [];
  bool _isLoading = false;
  bool get isEditing => widget.editRoom != null;

  final List<String> _allAmenities = [
    'Wifi', 'May lanh', 'Tu lanh', 'May giat',
    'Bep', 'Cho de xe', 'Ho boi', 'Phong gym',
    'An ninh', 'San vuon', 'Binh nong lanh', 'Giuong nem',
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.editRoom;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _priceCtrl = TextEditingController(text: r != null ? r.price.toInt().toString() : '');
    _addressCtrl = TextEditingController(text: r?.address ?? '');
    _areaCtrl = TextEditingController(text: r?.area?.toInt().toString() ?? '');
    if (r != null) {
      _selectedType = r.type;
      _selectedDirection = r.direction;
      _bedrooms = r.bedrooms ?? 1;
      _selectedAmenities.addAll(r.amenities);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose();
    _priceCtrl.dispose(); _addressCtrl.dispose(); _areaCtrl.dispose();
    super.dispose();
  }

  void _saveDraft() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    final room = _buildRoom(isDraft: true);
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pop(context, room);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Da luu ban nhap'),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    final room = _buildRoom(isDraft: false);
    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context, room);
  }

  RoomModel _buildRoom({required bool isDraft}) {
    return RoomModel(
      id: isEditing ? widget.editRoom!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      address: _addressCtrl.text.trim(),
      imageUrl: isEditing ? widget.editRoom!.imageUrl : 'assets/images/room_studio_luxury.png',
      rating: isEditing ? widget.editRoom!.rating : 0.0,
      type: _selectedType,
      location: 'TP. Ho Chi Minh',
      amenities: _selectedAmenities,
      area: double.tryParse(_areaCtrl.text.trim()),
      bedrooms: _bedrooms,
      direction: _selectedDirection,
      isVerified: false,
      isActive: !isDraft,
      isDraft: isDraft,
      postedAt: DateTime.now(),
      expiresAt: isDraft ? null : DateTime.now().add(Duration(days: _durationDays)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [AppColors.mintLight, AppColors.mintSoft, AppColors.mintGreen]),
        ),
        child: SafeArea(
          child: Column(children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildImagePicker(),
                    const SizedBox(height: 20),
                    _sectionTitle('Thong tin co ban'),
                    const SizedBox(height: 12),
                    _field(_titleCtrl, 'Ten phong / tieu de', Icons.title_rounded,
                        validator: (v) => v!.isEmpty ? 'Vui long nhap ten phong' : null),
                    const SizedBox(height: 12),
                    _field(_descCtrl, 'Mo ta chi tiet', Icons.description_rounded, maxLines: 3,
                        validator: (v) => v!.isEmpty ? 'Vui long nhap mo ta' : null),
                    const SizedBox(height: 20),
                    _sectionTitle('Loai phong'),
                    const SizedBox(height: 12),
                    _buildTypeSelector(),
                    const SizedBox(height: 20),
                    _sectionTitle('Gia & Dia chi'),
                    const SizedBox(height: 12),
                    _field(_priceCtrl, 'Gia thue (VND/thang)', Icons.attach_money_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) => v!.isEmpty ? 'Vui long nhap gia' : null),
                    const SizedBox(height: 12),
                    _field(_addressCtrl, 'Dia chi', Icons.location_on_rounded,
                        validator: (v) => v!.isEmpty ? 'Vui long nhap dia chi' : null),
                    const SizedBox(height: 8),
                    _buildMapPlaceholder(),
                    const SizedBox(height: 20),
                    _sectionTitle('Chi tiet phong'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _field(_areaCtrl, 'Dien tich (m2)', Icons.square_foot_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                      const SizedBox(width: 12),
                      Expanded(child: _buildBedroomSelector()),
                    ]),
                    const SizedBox(height: 12),
                    _buildDirectionSelector(),
                    const SizedBox(height: 20),
                    _sectionTitle('Tien ich'),
                    const SizedBox(height: 12),
                    _buildAmenitiesSelector(),
                    const SizedBox(height: 20),
                    _sectionTitle('Thoi han dang tin'),
                    const SizedBox(height: 12),
                    _buildDurationSelector(),
                    const SizedBox(height: 28),
                    _buildButtons(),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
            child: const Padding(padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 18)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(isEditing ? 'Chinh sua phong' : 'Dang phong moi',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
        if (!isEditing)
          GestureDetector(
            onTap: _saveDraft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
              child: const Row(children: [
                Icon(Icons.drafts_rounded, color: AppColors.textSecondary, size: 16),
                SizedBox(width: 4),
                Text('Luu nhap', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _buildImagePicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Anh phong'),
      const SizedBox(height: 12),
      SizedBox(
        height: 120,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 120, height: 120,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.teal.withOpacity(0.4), width: 2),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AppColors.mintSoft, shape: BoxShape.circle),
                    child: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.teal, size: 24)),
                const SizedBox(height: 6),
                const Text('Them anh', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
            ),
          ),
          if (isEditing)
            Container(
              width: 120, height: 120,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(widget.editRoom!.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.mintSoft)),
                  Positioned(top: 4, right: 4, child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                  )),
                ]),
              ),
            ),
        ]),
      ),
    ]);
  }

  Widget _buildMapPlaceholder() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 120, width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.mintSoft, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.teal.withOpacity(0.3), width: 1.5),
        ),
        child: Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Container(color: const Color(0xFFE8F5E9),
              child: const Center(child: Icon(Icons.map_rounded, size: 60, color: AppColors.mintGreen))),
          ),
          Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(12)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.my_location_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Chon vi tri tren ban do', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _buildBedroomSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Phong ngu', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          GestureDetector(
            onTap: () { if (_bedrooms > 1) setState(() => _bedrooms--); },
            child: Container(padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.remove_rounded, color: AppColors.teal, size: 16)),
          ),
          Text('$_bedrooms', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          GestureDetector(
            onTap: () { if (_bedrooms < 10) setState(() => _bedrooms++); },
            child: Container(padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add_rounded, color: AppColors.teal, size: 16)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildDirectionSelector() {
    final dirs = [
      (RoomDirection.east, 'Dong'), (RoomDirection.west, 'Tay'),
      (RoomDirection.south, 'Nam'), (RoomDirection.north, 'Bac'),
      (RoomDirection.southEast, 'Dong Nam'), (RoomDirection.southWest, 'Tay Nam'),
      (RoomDirection.northEast, 'Dong Bac'), (RoomDirection.northWest, 'Tay Bac'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Huong nha', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: dirs.map((d) {
        final sel = _selectedDirection == d.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedDirection = sel ? null : d.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? AppColors.teal : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? AppColors.teal : AppColors.mintGreen, width: 1.5),
            ),
            child: Text(d.$2, style: TextStyle(
                color: sel ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _buildTypeSelector() {
    final types = [
      (RoomType.studio, 'Phong tro', Icons.single_bed_rounded),
      (RoomType.apartment, 'Chung cu', Icons.apartment_rounded),
      (RoomType.house, 'Nha nguyen can', Icons.house_rounded),
      (RoomType.villa, 'Biet thu', Icons.villa_rounded),
    ];
    return Wrap(spacing: 10, runSpacing: 10, children: types.map((t) {
      final sel = _selectedType == t.$1;
      return GestureDetector(
        onTap: () => setState(() => _selectedType = t.$1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? AppColors.teal : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sel ? AppColors.teal : AppColors.mintGreen, width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(t.$3, color: sel ? Colors.white : AppColors.teal, size: 18),
            const SizedBox(width: 8),
            Text(t.$2, style: TextStyle(color: sel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
      );
    }).toList());
  }

  Widget _buildAmenitiesSelector() {
    return Wrap(spacing: 8, runSpacing: 8, children: _allAmenities.map((a) {
      final sel = _selectedAmenities.contains(a);
      return GestureDetector(
        onTap: () => setState(() => sel ? _selectedAmenities.remove(a) : _selectedAmenities.add(a)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? AppColors.teal.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? AppColors.teal : AppColors.mintGreen, width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (sel) const Icon(Icons.check_rounded, color: AppColors.teal, size: 14),
            if (sel) const SizedBox(width: 4),
            Text(a, style: TextStyle(color: sel ? AppColors.tealDark : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
      );
    }).toList());
  }

  Widget _buildDurationSelector() {
    final options = [7, 15, 30, 60, 90];
    return Wrap(spacing: 8, runSpacing: 8, children: options.map((d) {
      final sel = _durationDays == d;
      return GestureDetector(
        onTap: () => setState(() => _durationDays = d),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? AppColors.teal : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sel ? AppColors.teal : AppColors.mintGreen, width: 1.5),
          ),
          child: Text('$d ngay', style: TextStyle(
              color: sel ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      );
    }).toList());
  }

  Widget _buildButtons() {
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: _isLoading ? null : _saveDraft,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.teal, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Luu nhap', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal, foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(isEditing ? 'Luu thay doi' : 'Dang phong ngay',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
      ),
    ]);
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, {
    int maxLines = 1, TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines, keyboardType: keyboardType,
      inputFormatters: inputFormatters, validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.teal, size: 20),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      ),
    );
  }
}

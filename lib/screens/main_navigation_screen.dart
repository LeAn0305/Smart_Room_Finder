import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/config/ai_config.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/core/l10n/language_provider.dart';
import 'package:smart_room_finder/providers/room_provider.dart';
import 'package:smart_room_finder/screens/home/home_screen.dart';
import 'package:smart_room_finder/screens/map/map_screen.dart';
import 'package:smart_room_finder/screens/favorite/favorite_screen.dart';
import 'package:smart_room_finder/screens/profile/profile_screen.dart';
import 'package:smart_room_finder/screens/ai_chat/ai_chat_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _chatOpen = false;
  String _selectedCity = 'TP. Hồ Chí Minh';
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  List<Widget> get _pages => [
    HomeScreen(onCityChanged: (city) => setState(() => _selectedCity = city)),
    const MapScreen(),
    const FavoriteScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() => _chatOpen = !_chatOpen);
    if (_chatOpen) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      body: Stack(
        children: [
          // ── Main pages ──────────────────────────────────
          _pages[_selectedIndex],

          // ── Chat overlay ────────────────────────────────
          if (_chatOpen)
            FadeTransition(
              opacity: _fadeAnim,
              child: GestureDetector(
                onTap: _toggleChat,
                child: Container(color: Colors.black.withValues(alpha: 0.3)),
              ),
            ),

          if (_chatOpen)
            Positioned(
              bottom: 90,
              left: 16,
              right: 16,
              child: ScaleTransition(
                scale: _scaleAnim,
                alignment: Alignment.bottomRight,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildChatBox(),
                ),
              ),
            ),

          // ── Floating AI button ───────────────────────────
          Positioned(
            bottom: 90,
            right: 20,
            child: _chatOpen
                ? const SizedBox.shrink()
                : _buildFAB(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.mintSoft,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, -2)),
          ],
          border: Border(
              top: BorderSide(
                  color: AppColors.teal.withValues(alpha: 0.08), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) {
            setState(() => _selectedIndex = i);
            if (_chatOpen) _toggleChat();
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.mintSoft,
          selectedItemColor: AppColors.teal,
          unselectedItemColor: const Color(0xFF98A6B5),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded),
                label: lang.tr('nav_home')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.map_rounded),
                label: lang.tr('nav_map')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.favorite_rounded),
                label: lang.tr('nav_favorite')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.person_rounded),
                label: lang.tr('nav_profile')),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: _toggleChat,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Tooltip thông báo
          Container(
            margin: const EdgeInsets.only(bottom: 8, right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.tealDark,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('💬', style: TextStyle(fontSize: 13)),
                SizedBox(width: 6),
                Text(
                  'Hỏi AI tìm phòng nhé!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // FAB button với logo app
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.teal, AppColors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/images/LogoApp.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              // Badge xanh online
              Positioned(
                top: 2,
                right: 2,
                child: _PulseDot(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBox() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.teal, AppColors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Tư vấn phòng trọ',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        Text('Powered by ChatGPT',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleChat,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            // Chat content
            Expanded(child: _InlineChatBody(selectedCity: _selectedCity)),
          ],
        ),
      ),
    );
  }
}

// ── Inline chat body (tách riêng để giữ state) ──────────────────────────────

class _InlineChatBody extends StatefulWidget {
  final String selectedCity;
  const _InlineChatBody({required this.selectedCity});

  @override
  State<_InlineChatBody> createState() => _InlineChatBodyState();
}

class _InlineChatBodyState extends State<_InlineChatBody> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _isTyping = false;

  List<String> get _suggestions => [
    '🏠 Phòng trọ ở ${widget.selectedCity} giá rẻ',
    '🌊 Căn hộ có hồ bơi tại ${widget.selectedCity}',
    '📍 So sánh giá phòng tại ${widget.selectedCity}',
    '🎓 Phòng sinh viên giá rẻ tại ${widget.selectedCity}',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _ctrl.clear();

    setState(() {
      _messages.add(_ChatMsg(text: text.trim(), isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final reply = await _callAI(text.trim());
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg(text: reply, isUser: false));
        _isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('AI Error: $e');
      setState(() {
        _messages.add(_ChatMsg(
            text: 'Lỗi: $e', isUser: false));
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  Future<String> _callAI(String msg) async {
    final roomProvider = context.read<RoomProvider>();
    final activeRooms = roomProvider.activePublicRooms;
    final buf = StringBuffer();
    for (final r in activeRooms) {
      buf.writeln('- ${r.title} | ${r.location} | ${(r.price / 1000000).toStringAsFixed(1)}tr | ${r.typeString} | Tiện ích: ${r.amenities.join(', ')}');
    }
    final roomContext = buf.toString();

    final systemPrompt = '''Bạn là AI tư vấn phòng trọ của Smart Room Finder tại ${widget.selectedCity}.
Trả lời ngắn gọn, thân thiện bằng tiếng Việt, dùng emoji.
Dữ liệu phòng hiện có:
$roomContext
Hãy trả lời dựa trên dữ liệu thật này.''';

    final history = [
      {'role': 'system', 'content': systemPrompt},
      ..._messages.map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text}),
      {'role': 'user', 'content': msg},
    ];

    final res = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AIConfig.openAiApiKey}',
      },
      body: jsonEncode({'model': AIConfig.model, 'messages': history, 'max_tokens': 500}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return data['choices'][0]['message']['content'].toString().trim();
    }
    throw Exception('API error ${res.statusCode}');
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FFFE),
      child: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildSuggestions()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length) return _typingDots();
                      return _bubble(_messages[i]);
                    },
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Hỏi gì đó nhé 👇',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._suggestions.map((s) => GestureDetector(
              onTap: () => _send(s),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6)
                  ],
                ),
                child: Text(s,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
            )),
      ],
    );
  }

  Widget _bubble(_ChatMsg msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.teal : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)
          ],
        ),
        child: Text(msg.text,
            style: TextStyle(
                fontSize: 13,
                color: msg.isUser ? Colors.white : AppColors.textPrimary,
                height: 1.4)),
      ),
    );
  }

  Widget _typingDots() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
              3,
              (i) => Container(
                    margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.5 + i * 0.2),
                        shape: BoxShape.circle),
                  )),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9F8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _ctrl,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Hỏi về phòng trọ...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(_ctrl.text),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.teal, AppColors.blue]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: _anim.value),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMsg {
  final String text;
  final bool isUser;
  _ChatMsg({required this.text, required this.isUser});
}

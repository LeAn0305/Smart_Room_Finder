import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/config/ai_config.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/message_model.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/providers/room_provider.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<MessageModel> _messages = [];
  bool _isTyping = false;

  final List<String> _suggestions = [
    'Tìm phòng trọ giá rẻ gần trường đại học',
    'Phòng có diện tích từ 30m² trở lên',
    'Chung cư có hồ bơi và gym',
    'Phòng trọ Quận 1 dưới 5 triệu',
    'So sánh giá phòng các quận',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      role: MessageRole.user,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _ctrl.clear();
    _scrollToBottom();

    try {
      final response = await _callOpenAI(text.trim());
      if (!mounted) return;
      final aiMsg = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
      );
      setState(() {
        _messages.add(aiMsg);
        _isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;
      final errMsg = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Xin lỗi, mình gặp sự cố kết nối. Vui lòng thử lại nhé!',
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
      );
      setState(() {
        _messages.add(errMsg);
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  Future<String> _callOpenAI(String userMessage) async {
    // Lấy dữ liệu phòng thật từ app
    final rooms = context.read<RoomProvider>().activePublicRooms;
    final roomData = _buildRoomContext(rooms);

    final systemPrompt = '''${AIConfig.systemPrompt}

Dưới đây là danh sách phòng THẬT đang có trong hệ thống Smart Room Finder:

$roomData

Khi người dùng hỏi về phòng, hãy trả lời dựa trên dữ liệu thật này.
Trả lời ngắn gọn, rõ ràng, dùng emoji cho dễ đọc.
Nếu không tìm thấy phòng phù hợp, hãy nói thật và gợi ý tiêu chí khác.''';

    final List<Map<String, String>> chatHistory = [
      {'role': 'system', 'content': systemPrompt},
      ..._messages.map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          }),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AIConfig.openAiApiKey}',
      },
      body: jsonEncode({
        'model': AIConfig.model,
        'messages': chatHistory,
        'max_tokens': 600,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'].toString().trim();
    } else {
      throw Exception('OpenAI error: ${response.statusCode}');
    }
  }

  String _buildRoomContext(List<RoomModel> rooms) {
    final buffer = StringBuffer();
    for (final r in rooms) {
      buffer.writeln('---');
      buffer.writeln('Tên: ${r.title}');
      buffer.writeln('Loại: ${r.typeString}');
      buffer.writeln('Giá: ${(r.price / 1000000).toStringAsFixed(1)} triệu/tháng');
      buffer.writeln('Khu vực: ${r.location}');
      buffer.writeln('Địa chỉ: ${r.address}');
      if (r.area != null) buffer.writeln('Diện tích: ${r.area!.toInt()}m²');
      if (r.bedrooms != null) buffer.writeln('Phòng ngủ: ${r.bedrooms}');
      buffer.writeln('Đánh giá: ${r.rating}/5');
      buffer.writeln('Tiện ích: ${r.amenities.join(', ')}');
      buffer.writeln('Xác thực: ${r.isVerified ? 'Có' : 'Chưa'}');
      buffer.writeln('Mô tả: ${r.description}');
    }
    return buffer.toString();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.mintLight, AppColors.mintSoft, AppColors.mintGreen],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _messages.isEmpty
                    ? _buildWelcome()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _messages.length) return _buildTypingIndicator();
                          return _buildBubble(_messages[i]);
                        },
                      ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.teal, AppColors.blue]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Tư vấn phòng trọ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                Text('Powered by ChatGPT',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (_messages.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _messages.clear()),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.teal, AppColors.blue]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 4)],
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text('Xin chào! 👋',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Mình là AI tư vấn phòng trọ.\nHãy hỏi mình bất cứ điều gì!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Gợi ý câu hỏi:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 12),
          ..._suggestions.map((s) => _suggestionCard(s)),
        ],
      ),
    );
  }

  Widget _suggestionCard(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.teal, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(MessageModel msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.teal, AppColors.blue]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14),
            ),
          ],
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration(
              color: msg.isUser ? AppColors.teal : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                bottomRight: Radius.circular(msg.isUser ? 4 : 18),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
            ),
            child: Text(
              msg.content,
              style: TextStyle(
                fontSize: 14,
                color: msg.isUser ? Colors.white : AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8, bottom: 12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.teal, AppColors.blue]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _animatedDot(i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 150),
      builder: (_, value, __) => Container(
        margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.3 + (value * 0.7)),
          shape: BoxShape.circle,
        ),
      ),
      onEnd: () { if (mounted) setState(() {}); },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.mintSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: const InputDecoration(
                  hintText: 'Hỏi AI về phòng trọ...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_ctrl.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.teal, AppColors.blue]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

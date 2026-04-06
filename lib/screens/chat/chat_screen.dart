import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/chat_model.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conversations = ChatConversation.sampleConversations;
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
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: conversations.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: conversations.length,
                        itemBuilder: (_, i) => _buildConversationCard(context, conversations[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Tin Nhắn',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(BuildContext context, ChatConversation conv) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailScreen(conversation: conv)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                conv.roomImage,
                width: 52, height: 52, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 52, height: 52,
                  color: AppColors.mintSoft,
                  child: const Icon(Icons.home_rounded, color: AppColors.teal),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(conv.otherUserName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(conv.roomTitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(conv.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: conv.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatTime(conv.lastTime),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                if (conv.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(10)),
                    child: Text('${conv.unreadCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    return '${diff.inDays} ngày';
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.teal),
          ),
          const SizedBox(height: 16),
          const Text('Chưa có tin nhắn nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Các cuộc trò chuyện với chủ phòng\nsẽ hiển thị tại đây',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Chat Detail Screen ──────────────────────────────────────────────────────

class ChatDetailScreen extends StatefulWidget {
  final ChatConversation conversation;
  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.conversation.messages);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isMe: true,
        time: DateTime.now(),
      ));
    });
    _ctrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
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
              _buildHeader(context),
              Expanded(child: _buildMessages()),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              widget.conversation.roomImage,
              width: 38, height: 38, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 38, height: 38, color: AppColors.mintSoft,
                child: const Icon(Icons.home_rounded, color: AppColors.teal, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.conversation.otherUserName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(widget.conversation.roomTitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.teal)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: msg.isMe ? AppColors.teal : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            fontSize: 14,
            color: msg.isMe ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2))],
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
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chat_service.dart';

// ─── Message Model ─────────────────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? time,
    this.isError = false,
  }) : time = time ?? DateTime.now();
}

// ─── Quick Questions ───────────────────────────────────────────────────────
const _quickQuestions = [
  '🔴 Which products are low on stock?',
  '💰 What is the total revenue so far?',
  '👥 How many customers do we have?',
  '📦 How many products are in the catalogue?',
  '🏆 Which products sell the most?',
  '📋 Show me the recent bills',
];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Welcome message from AI
    _messages.add(ChatMessage(
      text:
          "Hello! I'm your AI assistant for Balaji Imitation Jewellery. 💎\n\nI have access to live shop data — inventory, sales, customers, and bills.\n\nAsk me anything about your shop!",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: trimmed, isUser: true));
      _isLoading = true;
    });
    _textCtrl.clear();
    _scrollToBottom();

    try {
      final reply = await _chatService.sendMessage(trimmed);
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text:
              '⚠️ ${e.toString().replaceFirst("Exception: ", "")}\n\nMake sure Ollama is running:\n`ollama serve`',
          isUser: false,
          isError: true,
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
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
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Column(
              children: [
                // Chat messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
                ),
                // Quick questions
                if (_messages.length == 1) _buildQuickQuestions(),
                // Input bar
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x331E3A8A), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 24.w),
          ),
          SizedBox(width: 14.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Shop Assistant',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    'Powered by Ollama (llama3) • Live DB',
                    style: GoogleFonts.poppins(
                        fontSize: 10.sp, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32.w,
              height: 32.w,
              margin: EdgeInsets.only(right: 8.w),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16.w),
            ),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF3B82F6)
                    : msg.isError
                        ? const Color(0xFFFEF2F2)
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 18.r : 4.r),
                  topRight: Radius.circular(isUser ? 4.r : 18.r),
                  bottomLeft: Radius.circular(18.r),
                  bottomRight: Radius.circular(18.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: msg.isError
                    ? Border.all(color: Colors.red.shade200)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: isUser
                          ? Colors.white
                          : msg.isError
                              ? Colors.red.shade700
                              : const Color(0xFF1E293B),
                      height: 1.55,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatTime(msg.time),
                    style: GoogleFonts.poppins(
                      fontSize: 9.sp,
                      color: isUser
                          ? Colors.white60
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 32.w,
              height: 32.w,
              margin: EdgeInsets.only(left: 8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_rounded,
                  color: const Color(0xFF1E3A8A), size: 16.w),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            margin: EdgeInsets.only(right: 8.w),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16.w),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                SizedBox(width: 4.w),
                _dot(200),
                SizedBox(width: 4.w),
                _dot(400),
                SizedBox(width: 8.w),
                Text('Thinking...',
                    style: GoogleFonts.poppins(
                        fontSize: 12.sp, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, val, __) => Opacity(
        opacity: val,
        child: Container(
          width: 7.w,
          height: 7.w,
          decoration: const BoxDecoration(
            color: Color(0xFF3B82F6),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('  Quick questions:',
              style: GoogleFonts.poppins(
                  fontSize: 11.sp, color: Colors.grey.shade600)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _quickQuestions.map((q) {
              return InkWell(
                onTap: () => _sendMessage(q),
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6)
                    ],
                  ),
                  child: Text(q,
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: const Color(0xFF1E3A8A),
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _textCtrl,
                focusNode: _focusNode,
                enabled: !_isLoading,
                style: GoogleFonts.poppins(
                    fontSize: 13.sp, color: const Color(0xFF1E293B)),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  hintText: 'Ask about inventory, sales, customers...',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 12.sp, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: () => _sendMessage(_textCtrl.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: _isLoading
                  ? Padding(
                      padding: EdgeInsets.all(12.w),
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.send_rounded, color: Colors.white, size: 20.w),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

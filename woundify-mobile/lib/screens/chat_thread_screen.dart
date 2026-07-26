import 'dart:async';
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models.dart';

/// Percakapan 1-on-1. Pesan di-refresh berkala (polling) tiap 4 detik.
class ChatThreadScreen extends StatefulWidget {
  final User currentUser;
  final DoctorSummary peer;
  const ChatThreadScreen({Key? key, required this.currentUser, required this.peer}) : super(key: key);

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _apiService = ApiService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _sending = false;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _loadMessages(initial: true);
    _poller = Timer.periodic(const Duration(seconds: 4), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _poller?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool initial = false}) async {
    try {
      final msgs = await _apiService.getConversation(widget.peer.id);
      if (!mounted) return;
      final wasAtBottom = !_scrollController.hasClients ||
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 40;
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      if (initial || wasAtBottom) _scrollToBottom();
    } catch (_) {
      if (mounted && initial) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await _apiService.sendMessage(widget.peer.id, text);
      await _loadMessages();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception:', '').trim())),
        );
        _controller.text = text;
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _peerDisplay() {
    final name = widget.peer.name.trim();
    if (widget.peer.role.toUpperCase() == 'DOCTOR' && !name.toLowerCase().startsWith('dr')) {
      return 'dr. $name';
    }
    return name;
  }

  String _time(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_peerDisplay())),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text('Belum ada pesan. Mulai percakapan!',
                            style: TextStyle(color: Color(0xFF64748B))),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final mine = m.senderId == widget.currentUser.id;
                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: mine ? const Color(0xFF1E88E5) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: mine ? null : Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.content,
                                      style: TextStyle(color: mine ? Colors.white : const Color(0xFF1E293B))),
                                  const SizedBox(height: 2),
                                  Text(_time(m.sentAt),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: mine ? Colors.white70 : const Color(0xFF94A3B8))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan...',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1E88E5),
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _sending ? null : _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

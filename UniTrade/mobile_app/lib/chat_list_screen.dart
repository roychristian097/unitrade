import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'chat_detail_screen.dart';
import 'theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<dynamic>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    _chatsFuture = ChatService.getChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        title: Text("Pesan", style: TextStyle(color: context.textColor)),
        iconTheme: IconThemeData(color: context.textColor),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _chatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE67E22)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Belum ada obrolan.", style: TextStyle(color: context.textMuted)));
          }

          final chats = snapshot.data!;
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (context, index) => Divider(color: context.borderColor),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: context.surfaceHighlight,
                  child: Icon(Icons.person, color: context.textMuted),
                ),
                title: Text(chat['other_user_name'] ?? 'Unknown', style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chat['product_name'] ?? 'Barang', style: const TextStyle(color: Color(0xFFE67E22), fontSize: 12)),
                    Text(chat['last_message'] ?? '', style: TextStyle(color: context.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                isThreeLine: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        otherUserId: chat['other_user_id'],
                        otherUserName: chat['other_user_name'],
                        productId: chat['product_id'],
                        productName: chat['product_name'],
                      ),
                    ),
                  ).then((_) {
                    setState(() {
                      _chatsFuture = ChatService.getChats();
                    });
                  });
                },
              ).animate(delay: (50 * index).ms).fade(duration: 300.ms).slideX(begin: 0.1);
            },
          );
        },
      ),
    );
  }
}

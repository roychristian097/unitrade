import 'theme.dart';
import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'chat_detail_screen.dart';

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
      backgroundColor: Color(0xFF0F0F11),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E1E22),
        title: Text("Pesan", style: TextStyle(color: context.colors.textPrimary)),
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _chatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFFE67E22)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Belum ada obrolan.", style: TextStyle(color: Colors.grey)));
          }

          final chats = snapshot.data!;
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey.withValues(alpha: 0.2)),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xFF2A2A30),
                  child: Icon(Icons.person, color: Colors.grey),
                ),
                title: Text(chat['other_user_name'] ?? 'Unknown', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chat['product_name'] ?? 'Barang', style: TextStyle(color: Color(0xFFE67E22), fontSize: 12)),
                    Text(chat['last_message'] ?? '', style: TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
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
              );
            },
          );
        },
      ),
    );
  }
}

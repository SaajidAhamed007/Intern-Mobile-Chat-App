import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<Map<String, String>> chats = [
    {
      'name': 'Alice',
      'message': 'Hey, how are you?',
      'time': '10:30 AM',
    },
    {
      'name': 'Bob',
      'message': 'Let\'s meet tomorrow!',
      'time': '09:15 AM',
    },
    {
      'name': 'Charlie',
      'message': 'Check this out!',
      'time': 'Yesterday',
    },
    {
      'name': 'David',
      'message': 'Flutter is awesome!',
      'time': 'Mon',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurple,
        title: const Text('Hasa'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
            },
            icon: const CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'), // Placeholder
            ),
          ),
          IconButton(
            onPressed: () {
              
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple[200],
              child: Text(chat['name']![0]),
            ),
            title: Text(
              chat['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(chat['message']!),
            trailing: Text(
              chat['time']!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatScreen(userName: chat['name']!),
    ),
  );
},
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: New chat action
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.chat),
      ),
    );
  }
}

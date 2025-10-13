import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String userName;
  const ChatScreen({super.key, required this.userName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> messages = [
    {'type': 'text', 'message': 'Hey, how are you?', 'isMe': false},
    {'type': 'text', 'message': 'I\'m good!', 'isMe': true},
    {'type': 'video', 'message': 'assets/sample_video.mp4', 'isMe': false},
    {'type': 'audio', 'message': 'assets/sample_audio.mp3', 'isMe': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurple,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'),
            ),
            const SizedBox(width: 10),
            Text(widget.userName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment:
                      msg['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: msg['type'] == 'text'
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: msg['isMe'] ? Colors.deepPurple : Colors.grey[300],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              msg['message'],
                              style: TextStyle(
                                  color: msg['isMe'] ? Colors.white : Colors.black),
                            ),
                          )
                        : msg['type'] == 'image'
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  msg['message'],
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : msg['type'] == 'video'
                                ? Container(
                                    width: 200,
                                    height: 120,
                                    color: Colors.black,
                                    child: const Icon(Icons.play_arrow, color: Colors.white),
                                  )
                                : msg['type'] == 'audio'
                                    ? Container(
                                        width: 150,
                                        height: 50,
                                        color: Colors.deepPurple[100],
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.play_arrow),
                                            SizedBox(width: 10),
                                            Text("Audio"),
                                          ],
                                        ),
                                      )
                                    : const SizedBox(),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.grey[200],
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    // TODO: Pick image or video
                  },
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                        hintText: 'Type a message...', border: InputBorder.none),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Send message
                  },
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

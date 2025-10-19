import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as auth_provider;
import '../services/chat_service.dart';
import '../models/chat_list_item.dart';
import '../models/message_model.dart';
import '../widgets/profile_picture.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'contacts_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String searchQuery = '';
  late final ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0.3,
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Hasa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            icon: Consumer<auth_provider.AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.user;
                return SmallProfilePicture(
                  imageUrl: user?.profilePic,
                  name: user?.name,
                  size: 36,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<ChatRoomWithContact>>(
        stream: _chatService.getActiveChatRoomsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Error in active chat rooms stream: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load chats',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }

          final chatRooms = snapshot.data ?? [];

          // Filter based on search query
          final filteredChats = chatRooms.where((chatRoom) {
            return chatRoom.contact.name.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                chatRoom.contact.email.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                );
          }).toList();

          return Column(
            children: [
              // 🔍 Search bar (only show if there are chats)
              if (chatRooms.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search chats...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.primary.withValues(alpha: 0.8),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

              // 💬 Chat rooms list or empty state
              Expanded(
                child: filteredChats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              chatRooms.isEmpty
                                  ? Icons.chat_bubble_outline
                                  : Icons.search_off,
                              size: 80,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              chatRooms.isEmpty
                                  ? 'No messages yet'
                                  : 'No chats match your search',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              chatRooms.isEmpty
                                  ? 'Start chatting with your contacts'
                                  : 'Try a different search term',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            if (chatRooms.isEmpty) ...[
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ContactsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person_add),
                                label: const Text('Add Contacts'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : _buildActiveChatsList(filteredChats, theme),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ContactsScreen()),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  // Build active chats list
  Widget _buildActiveChatsList(
    List<ChatRoomWithContact> chatRooms,
    ThemeData theme,
  ) {
    return ListView.builder(
      itemCount: chatRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = chatRooms[index];
        final contact = chatRoom.contact;

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: StreamBuilder<Map<String, dynamic>>(
            stream: _chatService.getChatSummaryStream(contact.id),
            builder: (context, snapshot) {
              // Handle loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingChatItem(contact, theme);
              }

              // Handle error state
              if (snapshot.hasError) {
                return _buildBasicChatItem(contact, theme);
              }

              // Handle data - provide safe defaults
              final chatData = snapshot.hasData && snapshot.data != null
                  ? snapshot.data!
                  : <String, dynamic>{'lastMessage': null, 'unreadCount': 0};

              final lastMessage = chatData['lastMessage'] as MessageModel?;
              final unreadCount = (chatData['unreadCount'] as int?) ?? 0;

              final chatListItem = ChatListItem(
                contact: contact,
                lastMessage: lastMessage,
                unreadCount: unreadCount,
              );

              final authProvider = Provider.of<auth_provider.AuthProvider>(
                context,
                listen: false,
              );
              final currentUserId = authProvider.user?.uid ?? '';

              return _buildChatItemContent(chatListItem, currentUserId, theme);
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingChatItem(contact, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SmallProfilePicture(
          imageUrl: contact.profilePic,
          name: contact.name,
          size: 52,
        ),
        title: Text(
          contact.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Loading...',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.chat_bubble_outline,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(contact: contact),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicChatItem(contact, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SmallProfilePicture(
          imageUrl: contact.profilePic,
          name: contact.name,
          size: 52,
        ),
        title: Text(
          contact.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Tap to start chatting',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.chat_bubble_outline,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(contact: contact),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatItemContent(
    ChatListItem chatListItem,
    String currentUserId,
    ThemeData theme,
  ) {
    final lastMessage = chatListItem.lastMessage;
    final unreadCount = chatListItem.unreadCount;
    final contact = chatListItem.contact;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SmallProfilePicture(
          imageUrl: contact.profilePic,
          name: contact.name,
          size: 52,
        ),
        title: Text(
          contact.name,
          style: TextStyle(
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        subtitle: lastMessage != null
            ? Row(
                children: [
                  // Message status icons for sent messages (like WhatsApp)
                  if (chatListItem.isLastMessageFromMe(currentUserId)) ...[
                    _buildMessageStatusIcon(lastMessage, theme),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      chatListItem.getLastMessageText(),
                      style: TextStyle(
                        color: unreadCount > 0
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                        fontSize: 14,
                        fontWeight: unreadCount > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Text(
                'Tap to start chatting',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (lastMessage != null) ...[
              Text(
                chatListItem.getLastMessageTime(),
                style: TextStyle(
                  color: unreadCount > 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
            ],
            // Unread count badge (exactly like WhatsApp)
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(contact: contact),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageStatusIcon(MessageModel message, ThemeData theme) {
    switch (message.status) {
      case 'pending':
        return Icon(
          Icons.access_time,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        );
      case 'failed':
        return Icon(
          Icons.error_outline,
          size: 16,
          color: theme.colorScheme.error,
        );
      case 'sent':
        return Icon(
          Icons.done,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        );
      case 'delivered':
        return Icon(
          Icons.done_all,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        );
      case 'seen':
        return Icon(Icons.done_all, size: 16, color: theme.colorScheme.primary);
      default:
        // Fallback to old behavior
        return Icon(
          message.isSeen ? Icons.done_all : Icons.done,
          size: 16,
          color: message.isSeen
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        );
    }
  }
}

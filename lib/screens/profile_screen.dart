import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as auth_provider;
import '../providers/notification_provider.dart';
import '../services/notification_listener_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isEditingBio = false;
  bool _isEditingPhone = false;

  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateBio() async {
    final authProvider = Provider.of<auth_provider.AuthProvider>(
      context,
      listen: false,
    );

    final success = await authProvider.updateUserProfile(
      bio: _bioController.text.trim(),
    );

    if (success && mounted) {
      setState(() {
        _isEditingBio = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bio updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to update bio'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updatePhone() async {
    final authProvider = Provider.of<auth_provider.AuthProvider>(
      context,
      listen: false,
    );

    final success = await authProvider.updateUserProfile(
      phoneNumber: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
    );

    if (success && mounted) {
      setState(() {
        _isEditingPhone = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Failed to update phone number',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<auth_provider.AuthProvider>(
      context,
      listen: false,
    );

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await authProvider.logout();
      // AuthWrapper will automatically handle navigation
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Consumer<auth_provider.AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('No user data available'),
                ],
              ),
            );
          }

          // Initialize bio controller with current bio if not editing
          if (!_isEditingBio &&
              _bioController.text.isEmpty &&
              user.bio != null) {
            _bioController.text = user.bio!;
          }

          // Initialize phone controller with current phone if not editing
          if (!_isEditingPhone &&
              _phoneController.text.isEmpty &&
              user.phoneNumber != null) {
            _phoneController.text = user.phoneNumber!;
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.deepPurple.shade100,
                        child:
                            user.profilePic != null &&
                                user.profilePic!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  user.profilePic!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.deepPurple.shade300,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.deepPurple.shade300,
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () {
                            // TODO: Pick new profile image
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Profile picture update coming soon!',
                                ),
                              ),
                            );
                          },
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.deepPurple,
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // User Information
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.deepPurple),
                  title: const Text('Full Name'),
                  subtitle: Text(user.name),
                ),
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.deepPurple),
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),

                // Phone Number Section
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isEditingPhone ? Icons.close : Icons.edit,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_isEditingPhone) {
                                    // Cancel editing
                                    _phoneController.text =
                                        user.phoneNumber ?? '';
                                    _isEditingPhone = false;
                                  } else {
                                    // Start editing
                                    _phoneController.text =
                                        user.phoneNumber ?? '';
                                    _isEditingPhone = true;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_isEditingPhone)
                          Column(
                            children: [
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: 'Enter your phone number',
                                  prefixIcon: Icon(Icons.phone),
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 1,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _phoneController.text =
                                            user.phoneNumber ?? '';
                                        _isEditingPhone = false;
                                      });
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: _updatePhone,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                    ),
                                    child: const Text(
                                      'Save',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Text(
                            user.phoneNumber?.isNotEmpty == true
                                ? user.phoneNumber!
                                : 'No phone number added. Tap edit to add one.',
                            style: TextStyle(
                              color: user.phoneNumber?.isNotEmpty == true
                                  ? Colors.black87
                                  : Colors.grey[600],
                              fontStyle: user.phoneNumber?.isNotEmpty == true
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Bio Section
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Bio',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            IconButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        if (_isEditingBio) {
                                          // Cancel editing
                                          _isEditingBio = false;
                                          _bioController.text = user.bio ?? '';
                                        } else {
                                          // Start editing
                                          _isEditingBio = true;
                                          _bioController.text = user.bio ?? '';
                                        }
                                      });
                                    },
                              icon: Icon(
                                _isEditingBio ? Icons.close : Icons.edit,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isEditingBio) ...[
                          TextField(
                            controller: _bioController,
                            maxLines: 3,
                            maxLength: 150,
                            decoration: const InputDecoration(
                              hintText: 'Tell us about yourself...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isEditingBio = false;
                                          _bioController.text = user.bio ?? '';
                                        });
                                      },
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _updateBio,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Save',
                                        style: TextStyle(color: Colors.white),
                                      ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            user.bio?.isNotEmpty == true
                                ? user.bio!
                                : 'No bio available. Tap edit to add one.',
                            style: TextStyle(
                              fontSize: 14,
                              color: user.bio?.isNotEmpty == true
                                  ? Colors.black87
                                  : Colors.grey,
                              fontStyle: user.bio?.isNotEmpty == true
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Notification Settings Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notification Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Enable Notifications Toggle
                          SwitchListTile(
                            title: const Text('Enable Notifications'),
                            subtitle: const Text(
                              'Receive message notifications',
                            ),
                            value: notificationProvider.notificationsEnabled,
                            onChanged: (value) {
                              notificationProvider.setNotificationsEnabled(
                                value,
                              );
                            },
                            activeColor: Colors.deepPurple,
                          ),

                          // Sound Toggle
                          SwitchListTile(
                            title: const Text('Sound'),
                            subtitle: const Text(
                              'Play sound for notifications',
                            ),
                            value: notificationProvider.soundEnabled,
                            onChanged: notificationProvider.notificationsEnabled
                                ? (value) {
                                    notificationProvider.setSoundEnabled(value);
                                  }
                                : null,
                            activeColor: Colors.deepPurple,
                          ),

                          // Vibration Toggle
                          SwitchListTile(
                            title: const Text('Vibration'),
                            subtitle: const Text('Vibrate for notifications'),
                            value: notificationProvider.vibrationEnabled,
                            onChanged: notificationProvider.notificationsEnabled
                                ? (value) {
                                    notificationProvider.setVibrationEnabled(
                                      value,
                                    );
                                  }
                                : null,
                            activeColor: Colors.deepPurple,
                          ),

                          // Notification status
                          if (notificationProvider.errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      notificationProvider.errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // FCM Token (for debugging)
                          if (notificationProvider.fcmToken != null)
                            ExpansionTile(
                              title: const Text(
                                'Debug Info',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'FCM Token:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        notificationProvider.debugFCMToken,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Status: ${notificationProvider.isInitialized ? "Initialized" : "Not initialized"}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              notificationProvider.isInitialized
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Debug: Check Notifications Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final notificationListener = NotificationListenerService();
                    await notificationListener.checkPendingNotifications();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Checked for pending notifications - see console'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Check Notifications'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Logout Button
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 50,
                    ),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Logout',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

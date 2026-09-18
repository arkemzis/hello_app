import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мой Мессенджер',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2A5298)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

const String serverIp = '69.46.46.46';
const String serverHost = 'my-messenger-production-063d.up.railway.app';
const String serverUrl = 'https://$serverIp';

int myUserId = 0;
String myEmail = '';
String myName = '';

Map<String, String> get baseHeaders => {'Host': serverHost};
Map<String, String> get jsonHeaders => {
      'Content-Type': 'application/json',
      'Host': serverHost,
    };

const List<String> emojis = [
  '😀', '😁', '😂', '🤣', '😃', '😄', '😅', '😆', '😉', '😊',
  '😋', '😎', '😍', '😘', '🥰', '😗', '😙', '😚', '☺️', '🙂',
  '🤗', '🤩', '🤔', '🤨', '😐', '😑', '😶', '🙄', '😏', '😣',
  '😥', '😮', '🤐', '😯', '😪', '😫', '🥱', '😴', '😌', '😛',
  '😜', '😝', '🤤', '😒', '😓', '😔', '😕', '🙃', '🤑', '😲',
  '☹️', '🙁', '😖', '😞', '😟', '😤', '😢', '😭', '😦', '😧',
  '😨', '😩', '🤯', '😬', '😰', '😱', '🥵', '🥶', '😳', '🤪',
  '😵', '🥴', '😠', '😡', '🤬', '😷', '🤒', '🤕', '🤢', '🤮',
  '🥳', '🥺', '🤠', '🤡', '🤥', '🤫', '🤭', '🧐', '🤓', '😈',
  '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '🤙', '👈', '👉',
  '👆', '👇', '☝️', '✋', '🤚', '🖐', '🖖', '👋', '🤝', '🙏',
  '💪', '🦾', '✍️', '💅', '👏', '🙌', '👐', '🤲', '🤜', '🤛',
  '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
  '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '☮️',
  '🔥', '⭐', '🌟', '✨', '⚡', '💥', '💫', '💦', '💨', '🎉',
  '🎊', '🎁', '🎈', '🏆', '🥇', '🥈', '🥉', '⚽', '🏀', '🎮',
  '🍕', '🍔', '🍟', '🌮', '🍣', '🍩', '🍪', '🎂', '🍰', '🍫',
  '☕', '🍵', '🍺', '🍻', '🥂', '🍷', '🥃', '🍸', '🍹', '🥤',
];

// Быстрые реакции — для меню
const List<String> quickReactions = ['❤️', '👍', '😂', '🔥', '😮', '😢'];

// ============= ЭКРАН ВХОДА =============
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = '';
  bool _isError = false;
  bool _loading = false;

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Заполните оба поля';
        _isError = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _message = '';
    });
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/register'),
        headers: jsonHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (data['ok'] == true) {
        myUserId = data['userId'] ?? 0;
        myEmail = email;
        myName = '';
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NamePage()),
        );
        return;
      }
      setState(() {
        _message = data['message'] ?? 'Ошибка';
        _isError = true;
      });
    } catch (e) {
      setState(() {
        _message = 'Ошибка соединения: $e';
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Заполните оба поля';
        _isError = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _message = '';
    });
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/login'),
        headers: jsonHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (data['ok'] == true) {
        myUserId = data['userId'] ?? 0;
        myEmail = email;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UsersPage()),
        );
        return;
      }
      setState(() {
        _message = data['message'] ?? 'Ошибка';
        _isError = true;
      });
    } catch (e) {
      setState(() {
        _message = 'Ошибка соединения: $e';
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Мой Мессенджер',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3C72),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Войдите, чтобы продолжить',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Пароль',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A5298),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Войти', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A9D5C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Зарегистрироваться',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isError ? Colors.red : Colors.green,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============= ЭКРАН ИМЕНИ =============
class NamePage extends StatefulWidget {
  const NamePage({super.key});

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  final _nameController = TextEditingController();
  String _message = '';
  bool _isError = false;
  bool _loading = false;

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _message = 'Введите имя';
        _isError = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _message = '';
    });
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/set-name'),
        headers: jsonHeaders,
        body: jsonEncode({'userId': myUserId, 'name': name}),
      );
      final data = jsonDecode(response.body);
      if (data['ok'] == true) {
        myName = name;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UsersPage()),
        );
        return;
      }
      setState(() {
        _message = data['message'] ?? 'Ошибка';
        _isError = true;
      });
    } catch (e) {
      setState(() {
        _message = 'Ошибка соединения: $e';
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Как вас зовут?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3C72),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Это имя увидят другие',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Ваше имя',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A5298),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Сохранить', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _message,
                        style: TextStyle(
                          color: _isError ? Colors.red : Colors.green,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============= ЭКРАН ПОЛЬЗОВАТЕЛЕЙ =============
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<dynamic> _users = [];
  bool _loading = true;
  String _error = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadUsers(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsers({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/users'),
        headers: baseHeaders,
      );
      final data = jsonDecode(response.body) as List;
      if (mounted) {
        setState(() {
          _users = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          _error = 'Ошибка загрузки: $e';
          _loading = false;
        });
      }
    }
  }

  Color _avatarColor(String email) {
    final colors = [
      const Color(0xFF2A5298),
      const Color(0xFF2A9D5C),
      const Color(0xFFD9534F),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFF009688),
    ];
    return colors[email.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        backgroundColor: const Color(0xFF2A5298),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : ListView.separated(
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isMe = user['id'] == myUserId;
                    final email = user['email'] as String;
                    final name = (user['name'] as String?) ?? '';
                    final online = user['online'] == true;
                    final displayName = name.isNotEmpty ? name : email;
                    final firstLetter = displayName.substring(0, 1).toUpperCase();

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: _avatarColor(email),
                            child: Text(
                              firstLetter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          if (online && !isMe)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        isMe
                            ? 'это вы'
                            : online
                                ? 'онлайн'
                                : (name.isNotEmpty ? email : 'нажмите, чтобы открыть чат'),
                        style: TextStyle(
                          color: isMe
                              ? Colors.blue
                              : online
                                  ? Colors.green
                                  : Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        if (isMe) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              userId: user['id'],
                              userEmail: displayName,
                              myId: myUserId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

// ============= ЭКРАН ЧАТА =============
class ChatPage extends StatefulWidget {
  final int userId;
  final String userEmail;
  final int myId;

  const ChatPage({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.myId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _loading = true;
  String _error = '';
  late IO.Socket _socket;

  bool _otherOnline = false;
  bool _otherTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectSocket();
  }

  void _connectSocket() {
    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setExtraHeaders({'Host': serverHost})
          .disableAutoConnect()
          .build(),
    );

    _socket.connect();

    _socket.onConnect((_) {
      print('WebSocket подключён');
      _socket.emit('identify', widget.myId);
    });

    _socket.on('message', (data) {
      if (data == null) return;
      final from = data['from'];
      final to = data['to'];

      if ((from == widget.userId && to == widget.myId) ||
          (from == widget.myId && to == widget.userId)) {
        final newId = data['id'];
        setState(() {
          if (!_messages.any((m) => m['id'] == newId)) {
            _messages.add({
              'id': newId,
              'from_user': from,
              'to_user': to,
              'text': data['text'],
              'created_at': data['created_at'],
              'reactions': [],
            });
          }
          if (from == widget.userId) _otherTyping = false;
        });
        _scrollToBottom();
      }
    });

    _socket.on('message_deleted', (data) {
      if (data == null) return;
      final deletedId = data['id'];
      if (deletedId == null) return;
      setState(() {
        _messages.removeWhere((m) => m['id'] == deletedId);
      });
    });

    // Обновление реакции
    _socket.on('reaction_update', (data) {
      if (data == null) return;
      final mid = data['messageId'];
      final uid = data['userId'];
      final emoji = data['emoji'];
      final action = data['action'];

      setState(() {
        final msg = _messages.firstWhere(
          (m) => m['id'] == mid,
          orElse: () => null,
        );
        if (msg == null) return;

        List reactions = (msg['reactions'] as List?) ?? [];
        reactions = List.from(reactions);

        if (action == 'added') {
          if (!reactions.any(
              (r) => r['user_id'] == uid && r['emoji'] == emoji)) {
            reactions.add({'user_id': uid, 'emoji': emoji});
          }
        } else if (action == 'removed') {
          reactions.removeWhere(
              (r) => r['user_id'] == uid && r['emoji'] == emoji);
        }
        msg['reactions'] = reactions;
      });
    });

    _socket.on('online_list', (data) {
      if (data is List) {
        setState(() {
          _otherOnline = data.contains(widget.userId);
        });
      }
    });

    _socket.on('user_online', (data) {
      if (data['userId'] == widget.userId) {
        setState(() => _otherOnline = true);
      }
    });

    _socket.on('user_offline', (data) {
      if (data['userId'] == widget.userId) {
        setState(() {
          _otherOnline = false;
          _otherTyping = false;
        });
      }
    });

    _socket.on('user_typing', (data) {
      if (data['from'] == widget.userId) {
        setState(() {
          _otherTyping = data['typing'] == true;
        });
      }
    });

    _socket.onDisconnect((_) => print('WebSocket отключён'));
    _socket.onConnectError((err) => print('Ошибка WebSocket: $err'));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _socket.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/messages?with=${widget.userId}&me=${widget.myId}'),
        headers: baseHeaders,
      );
      final data = jsonDecode(response.body);
      if (data['ok'] == true) {
        setState(() {
          _messages = data['messages'];
          _loading = false;
          _error = '';
        });
        _scrollToBottom();
      } else {
        setState(() {
          _error = data['message'] ?? 'Ошибка';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка: $e';
        _loading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _socket.emit('typing', {'to': widget.userId, 'typing': false});

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/send'),
        headers: jsonHeaders,
        body: jsonEncode({
          'to': widget.userId,
          'text': text,
          'from': widget.myId,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['ok'] != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Неизвестная ошибка')),
        );
      } else {
        final newId = data['id'];
        final newCreated = data['created_at'];
        setState(() {
          if (!_messages.any((m) => m['id'] == newId)) {
            _messages.add({
              'id': newId,
              'from_user': widget.myId,
              'to_user': widget.userId,
              'text': text,
              'created_at': newCreated,
              'reactions': [],
            });
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки: $e')),
      );
    }
  }

  Future<void> _deleteMessage(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$serverUrl/messages/$id?userId=${widget.myId}'),
        headers: baseHeaders,
      );
      final data = jsonDecode(response.body);
      if (data['ok'] != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Не удалось удалить')),
        );
      } else {
        setState(() {
          _messages.removeWhere((m) => m['id'] == id);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
      );
    }
  }

  Future<void> _react(int messageId, String emoji) async {
    try {
      await http.post(
        Uri.parse('$serverUrl/react'),
        headers: jsonHeaders,
        body: jsonEncode({
          'messageId': messageId,
          'userId': widget.myId,
          'emoji': emoji,
        }),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка реакции: $e')),
      );
    }
  }

  void _showMessageMenu(dynamic msg) {
    final isMe = msg['from_user'] == widget.myId;
    final messageId = msg['id'];

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Быстрые реакции
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: quickReactions.map((emoji) {
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _react(messageId, emoji);
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Удалить сообщение',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteMessage(messageId);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Отмена'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Text(
                    'Смайлики',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A5298),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: emojis.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          final emoji = emojis[index];
                          final text = _messageController.text;
                          final selection = _messageController.selection;
                          final cursorPos = selection.baseOffset >= 0
                              ? selection.baseOffset
                              : text.length;
                          final newText = text.substring(0, cursorPos) +
                              emoji +
                              text.substring(cursorPos);
                          _messageController.text = newText;
                          _messageController.selection =
                              TextSelection.collapsed(
                            offset: cursorPos + emoji.length,
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: Text(
                            emojis[index],
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } catch (_) {
      return '';
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(dt.year, dt.month, dt.day);
      final diff = today.difference(msgDay).inDays;

      if (diff == 0) return 'Сегодня';
      if (diff == 1) return 'Вчера';
      final months = [
        'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
        'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  bool _shouldShowDate(int index) {
    if (index == 0) return true;
    final prev = _messages[index - 1];
    final cur = _messages[index];
    try {
      final p = DateTime.parse(prev['created_at']).toLocal();
      final c = DateTime.parse(cur['created_at']).toLocal();
      return p.day != c.day || p.month != c.month || p.year != c.year;
    } catch (_) {
      return false;
    }
  }

  // Группировка реакций: emoji -> [user_ids]
  Map<String, List<int>> _groupReactions(List reactions) {
    final map = <String, List<int>>{};
    for (final r in reactions) {
      final emoji = r['emoji'] as String? ?? '';
      final uid = r['user_id'] as int? ?? 0;
      if (emoji.isEmpty) continue;
      map.putIfAbsent(emoji, () => []);
      map[emoji]!.add(uid);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: const Color(0xFF2A5298),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  child: Text(
                    widget.userEmail.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_otherOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.userEmail,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_otherTyping)
                    const Text(
                      'печатает...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else if (_otherOnline)
                    const Text(
                      'онлайн',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Text(
                          _error,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : _messages.isEmpty
                        ? const Center(
                            child: Text(
                              'Начните переписку',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMe = msg['from_user'] == widget.myId;
                              final showDate = _shouldShowDate(index);
                              final reactions =
                                  (msg['reactions'] as List?) ?? [];
                              final grouped = _groupReactions(reactions);

                              return Column(
                                children: [
                                  if (showDate)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _formatDate(msg['created_at']),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  GestureDetector(
                                    onLongPress: () => _showMessageMenu(msg),
                                    child: Align(
                                      alignment: isMe
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment: isMe
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 2,
                                              horizontal: 4,
                                            ),
                                            padding: const EdgeInsets.fromLTRB(
                                              12,
                                              8,
                                              12,
                                              6,
                                            ),
                                            constraints: const BoxConstraints(
                                              maxWidth: 300,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isMe
                                                  ? const Color(0xFFDCF8C6)
                                                  : Colors.white,
                                              borderRadius: BorderRadius.only(
                                                topLeft:
                                                    const Radius.circular(12),
                                                topRight:
                                                    const Radius.circular(12),
                                                bottomLeft: Radius.circular(
                                                    isMe ? 12 : 4),
                                                bottomRight: Radius.circular(
                                                    isMe ? 4 : 12),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.06),
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  msg['text'] ?? '',
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 15,
                                                    height: 1.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      _formatTime(
                                                          msg['created_at']),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    if (isMe) ...[
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        Icons.done_all,
                                                        size: 14,
                                                        color: Colors.blue[600],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Реакции под сообщением
                                          if (grouped.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      left: 8, right: 8),
                                              child: Wrap(
                                                spacing: 4,
                                                children: grouped.entries
                                                    .map((entry) {
                                                  final emoji = entry.key;
                                                  final users = entry.value;
                                                  final iReacted = users
                                                      .contains(widget.myId);
                                                  return GestureDetector(
                                                    onTap: () => _react(
                                                        msg['id'], emoji),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: iReacted
                                                            ? const Color(
                                                                0xFFDCF8C6)
                                                            : Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color: iReacted
                                                              ? const Color(
                                                                  0xFF2A5298)
                                                              : Colors
                                                                  .grey
                                                                  .shade300,
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        users.length > 1
                                                            ? '$emoji ${users.length}'
                                                            : emoji,
                                                        style: const TextStyle(
                                                            fontSize: 14),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.emoji_emotions_outlined,
                    color: Color(0xFF2A5298),
                    size: 26,
                  ),
                  onPressed: _showEmojiPicker,
                  tooltip: 'Смайлики',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: (text) {
                      _socket.emit('typing', {
                        'to': widget.userId,
                        'typing': text.trim().isNotEmpty,
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Сообщение...',
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A5298),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
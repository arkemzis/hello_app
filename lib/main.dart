import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'e2ee.dart';
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

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'ARKZIS',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
                    theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7C3AED),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Inter',
            pageTransitionsTheme:  PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7C3AED),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'Inter',
            pageTransitionsTheme:  PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
                    home: const SplashScreen(),
        );
      },
    );
  }
}

const String serverIp = '69.46.46.46';
const String serverHost = 'my-messenger-production-063d.up.railway.app';
const String serverUrl = 'https://$serverIp';

int myUserId = 0;
Future<void> _saveSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('myUserId', myUserId);
  await prefs.setString('myEmail', myEmail);
  await prefs.setString('myName', myName);
  await prefs.setString('myAvatarUrl', myAvatarUrl);
}

Future<bool> _loadSession() async {
  final prefs = await SharedPreferences.getInstance();
  final uid = prefs.getInt('myUserId');
  if (uid == null || uid == 0) return false;
  myUserId = uid;
  myEmail = prefs.getString('myEmail') ?? '';
  myName = prefs.getString('myName') ?? '';
  myAvatarUrl = prefs.getString('myAvatarUrl') ?? '';
  return true;
}

Future<void> _clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  myUserId = 0;
  myEmail = '';
  myName = '';
  myAvatarUrl = '';
}

String myEmail = '';
String myName = '';
String myAvatarUrl = '';

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

const List<String> quickReactions = ['❤️', '👍', '😂', '🔥', '😮', '😢'];

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      tooltip: isDark ? 'Светлая тема' : 'Тёмная тема',
      onPressed: () {
        themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
      },
    );
  }
}

class AvatarWidget extends StatelessWidget {
  final String avatarUrl;
  final String displayName;
  final String email;
  final double radius;
  final bool online;
  final bool showOnline;
  final bool showStoryRing;
  final IconData? customIcon;

  const AvatarWidget({
    super.key,
    required this.avatarUrl,
    required this.displayName,
    required this.email,
    this.radius = 26,
    this.online = false,
    this.showOnline = false,
    this.showStoryRing = false,
    this.customIcon,
  });

  Color _avatarColor(String email) {
    final colors = [
      const Color(0xFF7C3AED),
      const Color(0xFFA855F7),
      const Color(0xFFD9534F),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFF009688),
    ];
    return colors[email.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl.isNotEmpty;
    final firstLetter = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : '?';

    Widget avatarContent = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: _avatarColor(email),
        shape: BoxShape.circle,
        image: hasAvatar
            ? DecorationImage(
                image: NetworkImage(
                  '$serverUrl$avatarUrl',
                  headers: {'Host': serverHost},
                ),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasAvatar
          ? null
          : (customIcon != null
              ? Icon(customIcon, color: Colors.white, size: radius * 0.9)
              : Text(
                  firstLetter,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.77,
                  ),
                )),
    );

    if (showStoryRing) {
      avatarContent = Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: avatarContent,
        ),
      );
    }

    return Stack(
      children: [
        avatarContent,
        if (showOnline && online)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.5,
              height: radius * 0.5,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============= ПРОСМОТР СТОРИС =============
class StoryViewerPage extends StatefulWidget {
  final List<dynamic> stories;
  final int initialIndex;
  final String userName;
  final String userAvatar;

  const StoryViewerPage({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage> {
  late PageController _pageController;
  late int _currentIndex;
  Timer? _timer;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 0.05 / 100;
        if (_progress >= 1.0) {
          _progress = 0.0;
          _nextStory();
        }
      });
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _pageController.jumpToPage(_currentIndex);
      });
      _startTimer();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _pageController.jumpToPage(_currentIndex);
      });
      _startTimer();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final imageUrl = story['image_url'] as String;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                '$serverUrl$imageUrl',
                headers: {'Host': serverHost},
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 80),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _prevStory,
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _nextStory,
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8, left: 8, right: 8,
              child: Row(
                children: List.generate(widget.stories.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: i < _currentIndex ? 1.0 : i == _currentIndex ? _progress : 0.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              top: 24, left: 12, right: 12,
              child: Row(
                children: [
                  AvatarWidget(
                    avatarUrl: widget.userAvatar,
                    displayName: widget.userName,
                    email: widget.userName,
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.userName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= СОЗДАНИЕ ГРУППЫ / КАНАЛА =============
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameController = TextEditingController();
  List<dynamic> _allUsers = [];
  Set<int> _selectedIds = {};
  bool _loading = true;
  bool _creating = false;
  bool _isChannel = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/users'),
        headers: baseHeaders,
      );
      final data = jsonDecode(response.body) as List;
      if (mounted) {
        setState(() {
          _allUsers = data.where((u) => u['id'] != myUserId).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _message = 'Введите название');
      return;
    }
    setState(() {
      _creating = true;
      _message = '';
    });
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/create-group'),
        headers: jsonHeaders,
        body: jsonEncode({
          'userId': myUserId,
          'name': name,
          'memberIds': _selectedIds.toList(),
          'isChannel': _isChannel,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['ok'] == true) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        setState(() => _message = data['message'] ?? 'Ошибка');
      }
    } catch (e) {
      setState(() => _message = 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isChannel ? 'Новый канал' : 'Новая группа'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _creating ? null : _create,
            child: const Text(
              'Создать',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Переключатель Группа / Канал
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Группа'),
                        icon: Icon(Icons.groups),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Канал'),
                        icon: Icon(Icons.campaign),
                      ),
                    ],
                    selected: {_isChannel},
                    onSelectionChanged: (s) {
                      setState(() {
                        _isChannel = s.first;
                        _selectedIds.clear();
                      });
                    },
                  ),
                ),
                // Подсказка
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _isChannel
                        ? 'В канале писать можете только вы. Остальные подпишутся сами.'
                        : 'Выберите участников группы.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: _isChannel ? 'Название канала' : 'Название группы',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(_isChannel ? Icons.campaign : Icons.group),
                    ),
                  ),
                ),
                // Список участников — только для групп
                if (!_isChannel) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Выбрано: ${_selectedIds.length}',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _allUsers.length,
                      itemBuilder: (context, index) {
                        final user = _allUsers[index];
                        final id = user['id'] as int;
                        final email = user['email'] as String;
                        final name = (user['name'] as String?) ?? '';
                        final avatar = (user['avatar_url'] as String?) ?? '';
                        final displayName = name.isNotEmpty ? name : email;
                        final selected = _selectedIds.contains(id);

                        return CheckboxListTile(
                          value: selected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedIds.add(id);
                              } else {
                                _selectedIds.remove(id);
                              }
                            });
                          },
                          secondary: AvatarWidget(
                            avatarUrl: avatar,
                            displayName: displayName,
                            email: email,
                            radius: 22,
                          ),
                          title: Text(displayName),
                          subtitle: name.isNotEmpty ? Text(email) : null,
                        );
                      },
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox()),
                if (_message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
    );
  }
}


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
      setState(() { _message = 'Заполните оба поля'; _isError = true; });
      return;
    }
    setState(() { _loading = true; _message = ''; });
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
        myAvatarUrl = '';
                await _saveSession();
        if (!mounted) return;
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const NamePage()));
        return;
      }
      setState(() { _message = data['message'] ?? 'Ошибка'; _isError = true; });
    } catch (e) {
      setState(() { _message = 'Ошибка соединения: $e'; _isError = true; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() { _message = 'Заполните оба поля'; _isError = true; });
      return;
    }
    setState(() { _loading = true; _message = ''; });
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
                await _saveSession();
        if (!mounted) return;
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const UsersPage()));
        return;
      }
      setState(() { _message = data['message'] ?? 'Ошибка'; _isError = true; });
    } catch (e) {
      setState(() { _message = 'Ошибка соединения: $e'; _isError = true; });
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
            colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ARKZIS',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED), letterSpacing: 2)),
                    const SizedBox(height: 8),
                    const Text('Connect without limits',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Пароль',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _loading
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Войти', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA855F7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Зарегистрироваться', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(_message, textAlign: TextAlign.center,
                        style: TextStyle(color: _isError ? Colors.red : Colors.green, fontSize: 14)),
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

// ============= ЭКРАН ИМЕНИ И АВАТАРКИ =============
class NamePage extends StatefulWidget {
  const NamePage({super.key});

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String _message = '';
  bool _isError = false;
  bool _loading = false;
  bool _uploading = false;
  String _avatarUrl = '';

  Future<void> _pickAvatar() async {
    if (_uploading) return;
    try {
      setState(() => _uploading = true);
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (picked == null) {
        if (mounted) setState(() => _uploading = false);
        return;
      }

      final uri = Uri.parse('$serverUrl/upload');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Host'] = serverHost;
      request.files.add(await http.MultipartFile.fromPath('image', picked.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true && data['imageUrl'] != null) {
          setState(() { _avatarUrl = data['imageUrl']; _message = ''; _isError = false; });
        }
      }
    } on PlatformException catch (e) {
      if (mounted) setState(() => _uploading = false);
      print('Picker error: ${e.code}');
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() { _message = 'Введите имя'; _isError = true; });
      return;
    }
    setState(() { _loading = true; _message = ''; });
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/set-name'),
        headers: jsonHeaders,
        body: jsonEncode({'userId': myUserId, 'name': name}),
      );
      final data = jsonDecode(response.body);
      if (data['ok'] != true) {
        setState(() { _message = data['message'] ?? 'Ошибка'; _isError = true; });
        return;
      }
      myName = name;
            await _saveSession();
      // E2EE: генерируем ключи и отправляем публичный на сервер
      try {
        await E2EE.init();
        final pubKey = await E2EE.getMyPublicKeyBase64();
        if (pubKey != null) {
          await http.post(
            Uri.parse('$serverUrl/set-public-key'),
            headers: jsonHeaders,
            body: jsonEncode({'userId': myUserId, 'publicKey': pubKey}),
          );
        }
      } catch (e) {
        print('E2EE init error: $e');
      }
      if (_avatarUrl.isNotEmpty) {
        final avatarResponse = await http.post(
          Uri.parse('$serverUrl/set-avatar'),
          headers: jsonHeaders,
          body: jsonEncode({'userId': myUserId, 'avatarUrl': _avatarUrl}),
        );
        final avatarData = jsonDecode(avatarResponse.body);
        if (avatarData['ok'] == true) {
          myAvatarUrl = _avatarUrl;
        }
      }

      await _saveSession();                                // ← НОВОЕ
      if (!mounted) return;
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const UsersPage()));
    } catch (e) {
      setState(() { _message = 'Ошибка соединения: $e'; _isError = true; });
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
            colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ваш профиль',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _uploading ? null : _pickAvatar,
                      child: Stack(
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 120, height: 120,
                              child: _avatarUrl.isNotEmpty
                                  ? Image.network(
                                      '$serverUrl$_avatarUrl',
                                      headers: {'Host': serverHost},
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return Container(
                                          color: const Color(0xFF7C3AED),
                                          alignment: Alignment.center,
                                          child: const CircularProgressIndicator(color: Colors.white),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: const Color(0xFF7C3AED),
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.person, size: 60, color: Colors.white),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: const Color(0xFF7C3AED),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.person, size: 60, color: Colors.white),
                                    ),
                            ),
                          ),
                          Positioned(
                            right: 0, bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFA855F7), shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            ),
                          ),
                          if (_uploading)
                            const Positioned.fill(
                              child: Center(child: CircularProgressIndicator(color: Colors.white)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_avatarUrl.isEmpty ? 'Нажмите, чтобы выбрать фото' : 'Нажмите, чтобы изменить',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Ваше имя',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _loading
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Сохранить', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(_message, style: TextStyle(color: _isError ? Colors.red : Colors.green, fontSize: 14)),
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

// ============= ЭКРАН ПОЛЬЗОВАТЕЛЕЙ + ГРУППЫ + КАНАЛЫ =============
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  List<dynamic> _groups = [];
  List<dynamic> _stories = [];
  bool _loading = true;
  String _error = '';
  Timer? _refreshTimer;
  final _searchController = TextEditingController();
  bool _searchVisible = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadAll(silent: true));
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    // Скрытые чаты: hidden_at != null И unread_count == 0 → не показывать
    final visible = _users.where((u) {
      final hidden = u['hidden_at'];
      if (hidden == null) return true;
      final unread = int.tryParse(u['unread_count']?.toString() ?? '0') ?? 0;
      return unread > 0;
    }).toList();

    setState(() {
      if (q.isEmpty) {
        _filteredUsers = List.from(visible);
      } else {
        _filteredUsers = visible.where((u) {
          final email = (u['email'] as String? ?? '').toLowerCase();
          final name = (u['name'] as String? ?? '').toLowerCase();
          return email.contains(q) || name.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = ''; });
    await Future.wait([_loadUsers(silent: silent), _loadStories(), _loadGroups()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadUsers({bool silent = false}) async {
    try {
            final response = await http.get(
        Uri.parse('$serverUrl/users?me=$myUserId'), headers: baseHeaders);
      final data = jsonDecode(response.body) as List;
      if (mounted) {
        setState(() => _users = data);
        _applyFilter();
      }
    } catch (e) {
      if (!silent && mounted) setState(() => _error = 'Ошибка загрузки: $e');
    }
  }

  Future<void> _loadStories() async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/stories'), headers: baseHeaders);
      final data = jsonDecode(response.body);
      if (data['ok'] == true && mounted) setState(() => _stories = data['stories']);
    } catch (e) {}
  }

  Future<void> _loadGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/my-chats?userId=$myUserId&me=$myUserId'), headers: baseHeaders);
      final data = jsonDecode(response.body);
      if (data['ok'] == true && mounted) {
        final allChats = data['chats'] as List;
        final visibleChats = allChats.where((c) {
          final hidden = c['hidden_at'];
          if (hidden == null) return true;
          final unread = int.tryParse(c['unread_count']?.toString() ?? '0') ?? 0;
          return unread > 0;
        }).toList();
        setState(() => _groups = visibleChats);
      }
    } catch (e) {}
  }

  Future<void> _addStory() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, requestFullMetadata: false);
      if (picked == null) return;

      final uri = Uri.parse('$serverUrl/upload');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Host'] = serverHost;
      request.files.add(await http.MultipartFile.fromPath('image', picked.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      if (data['ok'] == true && data['imageUrl'] != null) {
        await http.post(
          Uri.parse('$serverUrl/add-story'),
          headers: jsonHeaders,
          body: jsonEncode({'userId': myUserId, 'imageUrl': data['imageUrl']}),
        );
        _loadStories();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сторис добавлена!')));
      }
    } on PlatformException catch (e) {
      print('Picker error: ${e.code}');
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Map<int, List<dynamic>> _groupStories() {
    final map = <int, List<dynamic>>{};
    for (final s in _stories) {
      final uid = s['user_id'] as int;
      map.putIfAbsent(uid, () => []);
      map[uid]!.add(s);
    }
    return map;
  }

  void _openStories(int userId, int initialIndex) {
    final grouped = _groupStories();
    final userStories = grouped[userId] ?? [];
    if (userStories.isEmpty) return;
    final user = userStories.first;
    final name = (user['name'] as String?) ?? (user['email'] as String);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => StoryViewerPage(
        stories: userStories, initialIndex: initialIndex,
        userName: name, userAvatar: (user['avatar_url'] as String?) ?? '',
      ),
    ));
  }
  Future<void> _deleteChat({
    required int? peerId,
    required int? chatId,
    required String displayName,
  }) async {
    final isGroup = chatId != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Удалить чат «$displayName»?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_remove, color: Color(0xFF7C3AED)),
                title: const Text('Удалить у себя'),
                subtitle: const Text('У собеседника останется'),
                onTap: () => Navigator.pop(ctx, 'me'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Удалить у всех', style: TextStyle(color: Colors.red)),
                subtitle: Text(isGroup
                    ? 'Удалить для всех участников (только админ)'
                    : 'Удалить переписку у обоих'),
                onTap: () => Navigator.pop(ctx, 'all'),
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

    if (action == null) return;

    try {
      if (action == 'me') {
        final body = (chatId != null)
            ? {'userId': myUserId, 'chatId': chatId}
            : {'userId': myUserId, 'peerId': peerId};
        await http.post(
          Uri.parse('$serverUrl/hide-chat'),
          headers: jsonHeaders,
          body: jsonEncode(body),
        );
      } else if (action == 'all') {
        final body = (chatId != null)
            ? {'userId': myUserId, 'chatId': chatId}
            : {'userId': myUserId, 'peerId': peerId};
        final resp = await http.post(
          Uri.parse('$serverUrl/delete-chat-for-all'),
          headers: jsonHeaders,
          body: jsonEncode(body),
        );
        final data = jsonDecode(resp.body);
        if (data['ok'] != true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Не удалось удалить')),
          );
          return;
        }
      }
      await _loadAll(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _openCreateGroup() async {
    final result = await Navigator.push(context,
      MaterialPageRoute(builder: (_) => const CreateGroupPage()));
    if (result == true) _loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grouped = _groupStories();

    return Scaffold(
      appBar: AppBar(
        title: _searchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Поиск...', hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text('Чаты'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Создать группу или канал',
            onPressed: _openCreateGroup,
          ),
          IconButton(
            icon: Icon(_searchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) _searchController.clear();
              });
            },
          ),
                    IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Настройки',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: _loading
          ? const _ChatListSkeleton()
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    if (!_searchVisible)
                      Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                          border: Border(bottom: BorderSide(
                            color: isDark ? Colors.white12 : Colors.grey.shade300)),
                        ),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (grouped.containsKey(myUserId)) {
                                            _openStories(myUserId, 0);
                                          } else {
                                            _addStory();
                                          }
                                        },
                                        child: AvatarWidget(
                                          avatarUrl: myAvatarUrl,
                                          displayName: myName.isNotEmpty ? myName : 'Я',
                                          email: myEmail, radius: 32,
                                          showStoryRing: grouped.containsKey(myUserId),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0, bottom: 0,
                                        child: GestureDetector(
                                          onTap: _addStory,
                                          child: Container(
                                            width: 22, height: 22,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFA855F7), shape: BoxShape.circle),
                                            child: const Icon(Icons.add, size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Моя', style: TextStyle(fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.black87)),
                                ],
                              ),
                            ),
                            ...grouped.entries.where((e) => e.key != myUserId).map((entry) {
                              final uid = entry.key;
                              final userStories = entry.value;
                              final firstStory = userStories.first;
                              final name = (firstStory['name'] as String?) ?? (firstStory['email'] as String);
                              final avatar = (firstStory['avatar_url'] as String?) ?? '';
                              final shortName = name.split('@')[0];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                child: GestureDetector(
                                  onTap: () => _openStories(uid, 0),
                                  child: Column(
                                    children: [
                                      AvatarWidget(
                                        avatarUrl: avatar, displayName: name,
                                        email: firstStory['email'], radius: 32, showStoryRing: true,
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 74,
                                        child: Text(shortName,
                                          style: TextStyle(fontSize: 12,
                                            color: isDark ? Colors.white70 : Colors.black87),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView(
                        children: [
                          if (!_searchVisible && _groups.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text('Группы и каналы',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white54 : Colors.grey[700])),
                            ),
                            ..._groups.map((chat) {
                              final name = chat['name'] as String;
                              final membersCount = chat['members_count'] ?? 0;
                              final isChannel = chat['is_channel'] == true;
                              return ListTile(
                                leading: AvatarWidget(
                                  avatarUrl: '', displayName: name, email: name,
                                  radius: 26, customIcon: isChannel ? Icons.campaign : Icons.groups,
                                ),
                                title: Text(name, style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                                subtitle: Text(
                                  isChannel ? '$membersCount подписчик(ов)' : '$membersCount участник(ов)',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                                                               trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                                                        if ((int.tryParse(chat['unread_count']?.toString() ?? '0') ?? 0) > 0)
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${chat['unread_count']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      userId: 0, userEmail: name, myId: myUserId,
                                      chatId: chat['id'], isGroup: true, isChannel: isChannel,
                                    ),
                                  )).then((_) => _loadGroups());
                                },
                                onLongPress: () => _deleteChat(
                                  peerId: null,
                                  chatId: chat['id'],
                                  displayName: name,
                                ),
                              );
                            }),
                            const Divider(),
                          ],
                          if (_filteredUsers.isEmpty && _groups.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(40),
                              child: Center(child: Text(
                                _searchController.text.isEmpty ? 'Нет пользователей' : 'Ничего не найдено',
                                style: TextStyle(fontSize: 16,
                                  color: isDark ? Colors.white70 : Colors.grey[600]))),
                            ),
                          ..._filteredUsers.map((user) {
                            final isMe = user['id'] == myUserId;
                            final email = user['email'] as String;
                            final name = (user['name'] as String?) ?? '';
                            final avatar = (user['avatar_url'] as String?) ?? '';
                            final online = user['online'] == true;
                            final displayName = name.isNotEmpty ? name : email;
                            final hasStory = grouped.containsKey(user['id']);
                            return ListTile(
                              leading: AvatarWidget(
                                avatarUrl: avatar, displayName: displayName, email: email,
                                radius: 26, online: online, showOnline: !isMe, showStoryRing: hasStory,
                              ),
                                                            title: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (online && !isMe)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  Flexible(
                                    child: Text(displayName, style: TextStyle(
                                      fontWeight: (int.tryParse(user['unread_count']?.toString() ?? '0') ?? 0) > 0
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                isMe ? 'это вы'
                                  : online ? 'онлайн'
                                  : (name.isNotEmpty ? email : 'нажмите, чтобы открыть чат'),
                                style: TextStyle(
                                  color: isMe ? Colors.blue : online ? Colors.green : Colors.grey[600],
                                  fontSize: 13),
                              ),
                                                                                          trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if ((int.tryParse(user['unread_count']?.toString() ?? '0') ?? 0) > 0)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C3AED),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${user['unread_count']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                              onTap: () {
                                if (isMe) return;
                                Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      userId: user['id'],
                                      userEmail: displayName,
                                      myId: myUserId,
                                      userAvatar: avatar,
                                      userPublicKey: (user['public_key'] as String?) ?? '',
                                    ),
                                    
                                ));
                              },
                              onLongPress: () {
                                if (isMe) return;
                                _deleteChat(
                                  peerId: user['id'],
                                  chatId: null,
                                  displayName: displayName,
                                );
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}


// ============= ЭКРАН ЧАТА (личный / группа / канал) =============
class ChatPage extends StatefulWidget {
  final int userId;
  final String userEmail;
  final int myId;
  final String userAvatar;
  final String userPublicKey;
  final int? chatId;
  final bool isGroup;
  final bool isChannel;

  const ChatPage({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.myId,
    this.userAvatar = '',
    this.userPublicKey = '',
    this.chatId,
    this.isGroup = false,
    this.isChannel = false,
  });
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _uploading = false;
  String _error = '';
  late IO.Socket _socket;

    bool _otherOnline = false;
  bool _otherTyping = false;
  Map<int, dynamic> _membersMap = {};
  dynamic _replyingTo;
  bool _isAdmin = false;
  bool _searchVisible = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    if (widget.isGroup || widget.isChannel) _loadMembers();
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
      _socket.emit('identify', widget.myId);
    });

        _socket.on('message', (data) async {
      if (data == null) return;

      if (widget.isGroup || widget.isChannel) {
        if (data['chat_id'] == widget.chatId) {
          final newId = data['id'];
          setState(() {
            if (!_messages.any((m) => m['id'] == newId)) {
              _messages.add({
                'id': newId,
                'from_user': data['from'],
                'chat_id': data['chat_id'],
                'text': data['text'] ?? '',
                'image_url': data['image_url'] ?? '',
                'created_at': data['created_at'],
                'sender_name': data['sender_name'],
                'sender_email': data['sender_email'],
                'sender_avatar': data['sender_avatar'],
                'reactions': [],
              });
            }
            if (data['from'] != widget.myId) _otherTyping = false;
          });
          _scrollToBottom();
        }
            } else {
        final from = data['from'];
        final to = data['to'];
        if ((from == widget.userId && to == widget.myId) ||
            (from == widget.myId && to == widget.userId)) {
          final newId = data['id'];
          if (_messages.any((m) => m['id'] == newId)) return;
                    final newMsg = {
            'id': newId,
            'from_user': from,
            'to_user': to,
            'text': data['text'] ?? '',
            'image_url': data['image_url'] ?? '',
            'created_at': data['created_at'],
            'reactions': [],
            'reply_to_id': data['reply_to_id'],
            'reply_text': data['reply_text'],
            'reply_image_url': data['reply_image_url'],
            'reply_sender_name': data['reply_sender_name'],
            'reply_sender_email': data['reply_sender_email'],
          };
          final disp = await _prepareMessageDisplay(newMsg);
          newMsg['display_text'] = disp;
          await _prepareReplyDisplay(newMsg);
                    setState(() {
            _messages.add(newMsg);
            if (from == widget.userId) _otherTyping = false;
          });
          _scrollToBottom();
          if (from == widget.userId) _markChatRead();
        }
      }
    });
    _socket.on('message_edited', (data) async {
      if (data == null) return;
      final editedId = data['id'];
      final newText = data['newText'];
      if (editedId == null || newText == null) return;

      final idx = _messages.indexWhere((m) => m['id'] == editedId);
      if (idx == -1) return;

      final msg = _messages[idx];
      final isFromOther = msg['from_user'] != widget.myId;

      String display = newText;
      if (isFromOther && widget.userPublicKey.isNotEmpty && !widget.isGroup && !widget.isChannel) {
        if (newText.startsWith('E2EE:')) {
          final dec = await E2EE.decrypt(newText.substring(5), widget.userPublicKey);
          if (dec != null) display = dec;
        }
      }

      setState(() {
        msg['text'] = newText;
        msg['display_text'] = display;
        msg['edited'] = true;    // ← ДОБАВИЛИ: пометка «изм.»
      });
      _scrollToBottom();
    });
        _socket.on('messages_read', (data) {
      if (data == null) return;

      final chatId = data['chatId'];
      final by = data['by'];
      final withUserId = data['withUserId'];

      setState(() {
        for (final m in _messages) {
          if (m['from_user'] == widget.myId && m['read_at'] == null) {
            final matchChat = chatId != null && m['chat_id'] == chatId;
            final matchPersonal = withUserId != null &&
                m['chat_id'] == null &&
                m['to_user'] == by;
            if (matchChat || matchPersonal) {
              m['read_at'] = DateTime.now().toIso8601String();
            }
          }
        }
      });
    });

    _socket.on('message_deleted', (data) {
      if (data == null) return;
      final deletedId = data['id'];
      if (deletedId == null) return;
      setState(() {
        _messages.removeWhere((m) => m['id'] == deletedId);
      });
    });

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
          if (!reactions.any((r) => r['user_id'] == uid && r['emoji'] == emoji)) {
            reactions.add({'user_id': uid, 'emoji': emoji});
          }
        } else if (action == 'removed') {
          reactions.removeWhere((r) => r['user_id'] == uid && r['emoji'] == emoji);
        }
        msg['reactions'] = reactions;
      });
    });

    _socket.on('online_list', (data) {
      if (!widget.isGroup && !widget.isChannel && data is List) {
        setState(() {
          _otherOnline = data.contains(widget.userId);
        });
      }
    });

    _socket.on('user_online', (data) {
      if (!widget.isGroup && !widget.isChannel && data['userId'] == widget.userId) {
        setState(() => _otherOnline = true);
      }
    });

    _socket.on('user_offline', (data) {
      if (!widget.isGroup && !widget.isChannel && data['userId'] == widget.userId) {
        setState(() {
          _otherOnline = false;
          _otherTyping = false;
        });
      }
    });

    _socket.on('user_typing', (data) {
      if (widget.isGroup || widget.isChannel) {
        if (data['chatId'] == widget.chatId && data['from'] != widget.myId) {
          setState(() => _otherTyping = data['typing'] == true);
        }
      } else {
        if (data['from'] == widget.userId) {
          setState(() => _otherTyping = data['typing'] == true);
        }
      }
    });

    _socket.onDisconnect((_) {});
    _socket.onConnectError((err) {});
  }

  Future<void> _loadMembers() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/chat-members/${widget.chatId}'),
        headers: baseHeaders,
      );
      final data = jsonDecode(response.body);
      if (data['ok'] == true && mounted) {
        final map = <int, dynamic>{};
        for (final m in data['members']) {
          map[m['id'] as int] = m;
        }
        setState(() => _membersMap = map);
      }
    } catch (e) {}

    // Проверяем, админ ли я
    try {
      final infoRes = await http.get(
        Uri.parse('$serverUrl/chat-info/${widget.chatId}'),
        headers: baseHeaders,
      );
      final info = jsonDecode(infoRes.body);
      if (info['ok'] == true && mounted) {
        setState(() {
          _isAdmin = info['chat']['created_by'] == widget.myId;
        });
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _socket.dispose();
    super.dispose();
  }
  Future<String> _prepareMessageDisplay(dynamic msg) async {
final text = (msg['display_text'] as String?) ?? (msg['text'] as String?) ?? '';
    if (text.startsWith('E2EE:') &&
        widget.userPublicKey.isNotEmpty &&
        !widget.isGroup &&
        !widget.isChannel) {
      final dec = await E2EE.decrypt(
        text.substring(5),
        widget.userPublicKey,
      );
      return dec ?? '🔒 Не удалось расшифровать';
    }
    return text;
  }

    Future<void> _prepareReplyDisplay(dynamic msg) async {
    final replyText = (msg['reply_text'] as String?) ?? '';
    if (replyText.startsWith('E2EE:') &&
        widget.userPublicKey.isNotEmpty &&
        !widget.isGroup &&
        !widget.isChannel) {
      final dec = await E2EE.decrypt(
        replyText.substring(5),
        widget.userPublicKey,
      );
      msg['reply_display_text'] = dec ?? replyText;
    } else {
      msg['reply_display_text'] = replyText;
    }
  }

    Future<void> _markChatRead() async {
    try {
      final body = (widget.isGroup || widget.isChannel)
          ? {'userId': widget.myId, 'chatId': widget.chatId}
          : {'userId': widget.myId, 'withUserId': widget.userId};
      await http.post(
        Uri.parse('$serverUrl/mark-read'),
        headers: jsonHeaders,
        body: jsonEncode(body),
      );
    } catch (e) {}
  }

  Future<void> _loadMessages() async {
    try {
      final url = (widget.isGroup || widget.isChannel)
          ? '$serverUrl/messages?chatId=${widget.chatId}&me=${widget.myId}'
          : '$serverUrl/messages?with=${widget.userId}&me=${widget.myId}';
      final response = await http.get(Uri.parse(url), headers: baseHeaders);
      final data = jsonDecode(response.body);
      if (data['ok'] == true) {
        final raw = data['messages'] as List;
        final processed = <dynamic>[];
                for (final m in raw) {
          m['display_text'] = await _prepareMessageDisplay(m);
          await _prepareReplyDisplay(m);
          processed.add(m);
        }
                setState(() {
          _messages = processed;
          _loading = false;
          _error = '';
        });
        _scrollToBottom();
        _markChatRead();
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
    final replySnapshot = _replyingTo;
    setState(() => _replyingTo = null);
    if (widget.isGroup || widget.isChannel) {
      _socket.emit('typing', {'chatId': widget.chatId, 'typing': false});
    } else {
      _socket.emit('typing', {'to': widget.userId, 'typing': false});
    }

    // Шифруем личные сообщения
    String sendText = text;
    if (!widget.isGroup &&
        !widget.isChannel &&
        widget.userPublicKey.isNotEmpty) {
      final enc = await E2EE.encrypt(text, widget.userPublicKey);
      if (enc != null) {
        sendText = 'E2EE:$enc';
      }
    }

    try {
            final body = (widget.isGroup || widget.isChannel)
          ? {
              'chatId': widget.chatId,
              'text': text,
              'from': widget.myId,
              if (replySnapshot != null) 'replyToId': replySnapshot['id'],
            }
          : {
              'to': widget.userId,
              'text': sendText,
              'from': widget.myId,
              if (replySnapshot != null) 'replyToId': replySnapshot['id'],
            };
      final response = await http.post(
        Uri.parse('$serverUrl/send'),
        headers: jsonHeaders,
        body: jsonEncode(body),
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
              'to_user': (widget.isGroup || widget.isChannel) ? null : widget.userId,
              'chat_id': (widget.isGroup || widget.isChannel) ? widget.chatId : null,
              'text': sendText,
              'display_text': text,
              'image_url': '',
              'created_at': newCreated,
              'sender_name': myName.isNotEmpty ? myName : myEmail,
              'sender_email': myEmail,
              'sender_avatar': myAvatarUrl,
                            'reactions': [],
              if (replySnapshot != null) 'reply_to_id': replySnapshot['id'],
              if (replySnapshot != null) 'reply_text': replySnapshot['display_text'] ?? replySnapshot['text'] ?? '',
              if (replySnapshot != null) 'reply_image_url': replySnapshot['image_url'] ?? '',
              if (replySnapshot != null) 'reply_sender_name': replySnapshot['sender_name'] ?? myName,
              if (replySnapshot != null) 'reply_sender_email': replySnapshot['sender_email'] ?? myEmail,
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

  Future<void> _pickAndSendFile() async {
    if (_uploading) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      setState(() => _uploading = true);

      final uri = Uri.parse('$serverUrl/upload-file');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Host'] = serverHost;
      request.files.add(await http.MultipartFile.fromPath('file', file.path!));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200) {
        if (mounted) setState(() => _uploading = false);
        return;
      }

      final data = jsonDecode(response.body);
      if (data['ok'] != true || data['fileUrl'] == null) {
        if (mounted) setState(() => _uploading = false);
        return;
      }

      final fileUrl = data['fileUrl'];
      final fileName = data['fileName'] ?? file.name;
      final fileSize = data['fileSize'] ?? file.size;
      final fileType = data['fileType'] ?? '';

      final body = (widget.isGroup || widget.isChannel)
          ? {
              'chatId': widget.chatId,
              'text': '',
              'from': widget.myId,
              'fileUrl': fileUrl,
              'fileName': fileName,
              'fileSize': fileSize,
              'fileType': fileType,
            }
          : {
              'to': widget.userId,
              'text': '',
              'from': widget.myId,
              'fileUrl': fileUrl,
              'fileName': fileName,
              'fileSize': fileSize,
              'fileType': fileType,
            };

      final sendResponse = await http.post(
        Uri.parse('$serverUrl/send'),
        headers: jsonHeaders,
        body: jsonEncode(body),
      );
      final sendData = jsonDecode(sendResponse.body);
      if (sendData['ok'] == true) {
        final newId = sendData['id'];
        final newCreated = sendData['created_at'];
        setState(() {
          if (!_messages.any((m) => m['id'] == newId)) {
            _messages.add({
              'id': newId,
              'from_user': widget.myId,
              'to_user': (widget.isGroup || widget.isChannel) ? null : widget.userId,
              'chat_id': (widget.isGroup || widget.isChannel) ? widget.chatId : null,
              'text': '',
              'display_text': '',
              'image_url': '',
              'file_url': fileUrl,
              'file_name': fileName,
              'file_size': fileSize,
              'file_type': fileType,
              'created_at': newCreated,
              'sender_name': myName.isNotEmpty ? myName : myEmail,
              'sender_email': myEmail,
              'sender_avatar': myAvatarUrl,
              'reactions': [],
            });
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }


  Future<void> _pickAndSendImage() async {
    if (_uploading) return;
    try {
      setState(() => _uploading = true);
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (picked == null) {
        if (mounted) setState(() => _uploading = false);
        return;
      }

      final uri = Uri.parse('$serverUrl/upload');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Host'] = serverHost;
      request.files.add(await http.MultipartFile.fromPath('image', picked.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200) {
        if (mounted) setState(() => _uploading = false);
        return;
      }

      final data = jsonDecode(response.body);
      if (data['ok'] != true || data['imageUrl'] == null) {
        if (mounted) setState(() => _uploading = false);
        return;
      }

      final imageUrl = data['imageUrl'];

      final body = (widget.isGroup || widget.isChannel)
          ? {'chatId': widget.chatId, 'text': '', 'from': widget.myId, 'imageUrl': imageUrl}
          : {'to': widget.userId, 'text': '', 'from': widget.myId, 'imageUrl': imageUrl};

      final sendResponse = await http.post(
        Uri.parse('$serverUrl/send'),
        headers: jsonHeaders,
        body: jsonEncode(body),
      );
      final sendData = jsonDecode(sendResponse.body);
      if (sendData['ok'] == true) {
        final newId = sendData['id'];
        final newCreated = sendData['created_at'];
        setState(() {
          if (!_messages.any((m) => m['id'] == newId)) {
            _messages.add({
              'id': newId,
              'from_user': widget.myId,
              'to_user': (widget.isGroup || widget.isChannel) ? null : widget.userId,
              'chat_id': (widget.isGroup || widget.isChannel) ? widget.chatId : null,
              'text': '',
              'image_url': imageUrl,
              'created_at': newCreated,
              'sender_name': myName.isNotEmpty ? myName : myEmail,
              'sender_email': myEmail,
              'sender_avatar': myAvatarUrl,
              'reactions': [],
            });
          }
        });
        _scrollToBottom();
      }
    } on PlatformException catch (e) {
      if (mounted) setState(() => _uploading = false);
      print('Picker error: ${e.code}');
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
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

    Future<void> _editMessage(dynamic msg) async {
    final currentDisplay = (msg['display_text'] as String?) ?? '';
    final imageUrl = (msg['image_url'] as String?) ?? '';

    if (currentDisplay.isEmpty && imageUrl.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя редактировать изображение')),
      );
      return;
    }

    final controller = TextEditingController(text: currentDisplay);
    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактировать сообщение'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'Новый текст'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (newText == null || newText.isEmpty || newText == currentDisplay) return;

    String sendText = newText;
    if (!widget.isGroup && !widget.isChannel && widget.userPublicKey.isNotEmpty) {
      final enc = await E2EE.encrypt(newText, widget.userPublicKey);
      if (enc != null) sendText = 'E2EE:$enc';
    }

    try {
      final resp = await http.post(
        Uri.parse('$serverUrl/edit-message'),
        headers: jsonHeaders,
        body: jsonEncode({
          'messageId': msg['id'],
          'userId': widget.myId,
          'newText': sendText,
        }),
      );
      final data = jsonDecode(resp.body);
      if (data['ok'] == true) {
        setState(() {
          msg['text'] = sendText;
          msg['display_text'] = newText;
          msg['edited'] = true;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Не удалось отредактировать')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
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
    } catch (e) {}
  }

  void _showMessageMenu(dynamic msg) {    HapticFeedback.mediumImpact();
    final isMe = msg['from_user'] == widget.myId;
    final messageId = msg['id'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                        child: Text(emoji, style: const TextStyle(fontSize: 30)),
                      ),
                    );
                  }).toList(),
                ),
              ),
             
                            const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.reply, color: Color(0xFF7C3AED)),
                title: const Text('Ответить'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _replyingTo = msg);
                },
              ),
                            if ((msg['display_text'] as String?)?.isNotEmpty == true)
                ListTile(
                  leading: const Icon(Icons.copy, color: Color(0xFF7C3AED)),
                  title: const Text('Копировать'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg['display_text']));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Скопировано'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.forward, color: Color(0xFF7C3AED)),
                title: const Text('Переслать'),
                onTap: () {
                  Navigator.pop(ctx);
                  _forwardMessage(msg);
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.edit, color: Color(0xFF7C3AED)),
                  title: const Text('Редактировать'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _editMessage(msg);
                  },
                ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Удалить сообщение', style: TextStyle(color: Colors.red)),
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

  Future<void> _forwardMessage(dynamic msg) async {
    final displayText = (msg['display_text'] as String?) ?? '';
    final imageUrl = (msg['image_url'] as String?) ?? '';
    if (displayText.isEmpty && imageUrl.isEmpty) return;

    try {
      final usersResp = await http.get(
        Uri.parse('$serverUrl/users'), headers: baseHeaders);
      final allUsers = jsonDecode(usersResp.body) as List;
      final otherUsers = allUsers.where((u) => u['id'] != widget.myId).toList();

      final chatsResp = await http.get(
        Uri.parse('$serverUrl/my-chats?userId=${widget.myId}'), headers: baseHeaders);
      final chatsData = jsonDecode(chatsResp.body);
      final groups = (chatsData['ok'] == true) ? (chatsData['chats'] as List) : [];

      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Text('Переслать в...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED))),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final chat in groups)
                        ListTile(
                          leading: AvatarWidget(
                            avatarUrl: '',
                            displayName: chat['name'] ?? '',
                            email: chat['name'] ?? '',
                            radius: 22,
                            customIcon: chat['is_channel'] == true
                                ? Icons.campaign
                                : Icons.groups,
                          ),
                          title: Text(chat['name'] ?? ''),
                          onTap: () {
                            Navigator.pop(ctx);
                            _sendForwarded(
                              text: displayText,
                              imageUrl: imageUrl,
                              chatId: chat['id'],
                              toUserId: null,
                              toPublicKey: null,
                            );
                          },
                        ),
                      for (final user in otherUsers)
                        ListTile(
                          leading: AvatarWidget(
                            avatarUrl: (user['avatar_url'] as String?) ?? '',
                            displayName: (user['name'] as String?)?.isNotEmpty == true
                                ? user['name'] : (user['email'] as String? ?? ''),
                            email: (user['email'] as String?) ?? '',
                            radius: 22,
                          ),
                          title: Text((user['name'] as String?)?.isNotEmpty == true
                              ? user['name'] : (user['email'] as String? ?? '')),
                          onTap: () {
                            Navigator.pop(ctx);
                            _sendForwarded(
                              text: displayText,
                              imageUrl: imageUrl,
                              chatId: null,
                              toUserId: user['id'],
                              toPublicKey: user['public_key'] as String?,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _sendForwarded({
    required String text,
    required String imageUrl,
    required int? chatId,
    required int? toUserId,
    required String? toPublicKey,
  }) async {
    String sendText = text;

    if (toUserId != null && toPublicKey != null && toPublicKey.isNotEmpty && text.isNotEmpty) {
      final enc = await E2EE.encrypt(text, toPublicKey);
      if (enc != null) sendText = 'E2EE:$enc';
    }

    final body = (chatId != null)
        ? {
            'chatId': chatId,
            'text': text,
            'from': widget.myId,
            if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
          }
        : {
            'to': toUserId,
            'text': sendText,
            'from': widget.myId,
            if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
          };

    try {
      final resp = await http.post(
        Uri.parse('$serverUrl/send'),
        headers: jsonHeaders,
        body: jsonEncode(body),
      );
      final data = jsonDecode(resp.body);
      if (data['ok'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Переслано'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // тихо
    }
  }

  void _openProfile() {
    final isGroupOrChannel = widget.isGroup || widget.isChannel;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AvatarWidget(
                  avatarUrl: widget.userAvatar,
                  displayName: widget.userEmail,
                  email: widget.userEmail,
                  radius: 60,
                  online: _otherOnline,
                  showOnline: !isGroupOrChannel,
                  customIcon: widget.isChannel
                      ? Icons.campaign
                      : (widget.isGroup ? Icons.groups : null),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.userEmail,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (isGroupOrChannel)
                  Text(
                    widget.isChannel
                        ? '${_membersMap.length} подписчик(ов)'
                        : '${_membersMap.length} участник(ов)',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _otherOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _otherOnline ? 'онлайн' : 'не в сети',
                        style: TextStyle(
                          fontSize: 14,
                          color: _otherOnline
                              ? Colors.green
                              : (isDark ? Colors.white70 : Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Закрыть', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAttachMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Text(
                  'Прикрепить',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.image, color: Color(0xFF7C3AED)),
                title: const Text('Фото'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file, color: Color(0xFF7C3AED)),
                title: const Text('Файл'),
                subtitle: const Text('PDF, документы, архивы, до 25 МБ'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendFile();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
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
                  child: const Text('Смайлики',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED))),
                ),
                const Divider(height: 1),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8, mainAxisSpacing: 4, crossAxisSpacing: 4),
                    itemCount: emojis.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          final emoji = emojis[index];
                          final text = _messageController.text;
                          final selection = _messageController.selection;
                          final cursorPos = selection.baseOffset >= 0 ? selection.baseOffset : text.length;
                          final newText = text.substring(0, cursorPos) + emoji + text.substring(cursorPos);
                          _messageController.text = newText;
                          _messageController.selection = TextSelection.collapsed(
                            offset: cursorPos + emoji.length);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: Text(emojis[index], style: const TextStyle(fontSize: 26)),
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

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Icons.audiotrack;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'txt':
        return Icons.text_snippet;
      case 'apk':
        return Icons.android;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(dynamic sizeRaw) {
    final size = int.tryParse(sizeRaw?.toString() ?? '0') ?? 0;
    if (size < 1024) return '$size Б';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} КБ';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} МБ';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} ГБ';
  }


  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } catch (_) { return ''; }
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
      final months = ['янв','фев','мар','апр','мая','июн','июл','авг','сен','окт','ноя','дек'];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) { return ''; }
  }

  bool _shouldShowDate(int index) {
    if (index == 0) return true;
    final prev = _messages[index - 1];
    final cur = _messages[index];
    try {
      final p = DateTime.parse(prev['created_at']).toLocal();
      final c = DateTime.parse(cur['created_at']).toLocal();
      return p.day != c.day || p.month != c.month || p.year != c.year;
    } catch (_) { return false; }
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatBg = isDark ? const Color(0xFF09090B) : const Color(0xFFECE5DD);
    final filteredMessages = _searchQuery.isEmpty
        ? _messages
        : _messages.where((m) {
            final t = ((m['display_text'] as String?) ?? '').toLowerCase();
            return t.contains(_searchQuery);
          }).toList();
    final myBubble = isDark ? const Color(0xFF4C1D95) : const Color(0xFFE9D5FF);
    final myText = isDark ? Colors.white : Colors.black87;
    final otherBubble = isDark ? const Color(0xFF18181B) : Colors.white;
    final otherText = isDark ? Colors.white : Colors.black87;
    final canWrite = !widget.isChannel || _isAdmin;

    return Scaffold(
      backgroundColor: chatBg,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
                title: Row(
          children: [
            GestureDetector(
              onTap: _openProfile,
              child: AvatarWidget(
                avatarUrl: widget.userAvatar,
                displayName: widget.userEmail,
                email: widget.userEmail,
                radius: 18,
                online: _otherOnline,
                showOnline: !widget.isGroup && !widget.isChannel,
                customIcon: widget.isChannel ? Icons.campaign : (widget.isGroup ? Icons.groups : null),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.userEmail,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis),
                  if (_otherTyping)
                    const Text('печатает...', style: TextStyle(fontSize: 12,
                      color: Colors.white70, fontStyle: FontStyle.italic))
                  else if (_otherOnline && !widget.isGroup && !widget.isChannel)
                    const Text('онлайн', style: TextStyle(fontSize: 12, color: Colors.white70))
                  else if ((widget.isGroup || widget.isChannel) && _membersMap.isNotEmpty)
                    Text(
                      widget.isChannel
                          ? '${_membersMap.length} подписчик(ов)'
                          : '${_membersMap.length} участник(ов)',
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
              if (_searchVisible)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _searchVisible = false;
                    _searchQuery = '';
                  });
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => _searchVisible = true),
              ),
            const ThemeToggleButton(),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_searchVisible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Поиск в чате...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const _ChatListSkeleton()
                : _error.isNotEmpty
                    ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                    : _messages.isEmpty
                        ? Center(child: Text(
                            widget.isChannel ? 'Пока нет постов' : 'Начните переписку',
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey, fontSize: 16)))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            itemCount: filteredMessages.length,
                            itemBuilder: (context, index) {
                              final msg = filteredMessages[index];
                              final isMe = msg['from_user'] == widget.myId;
                              final showDate = _searchQuery.isEmpty
                                  ? _shouldShowDate(index)
                                  : false;
                              final reactions = (msg['reactions'] as List?) ?? [];
                              final grouped = _groupReactions(reactions);
                              final imageUrl = (msg['image_url'] as String?) ?? '';
                              final text = (msg['display_text'] as String?) ?? (msg['text'] as String?) ?? '';

                              String senderName = '';
                              if ((widget.isGroup || widget.isChannel) && !isMe) {
                                senderName = (msg['sender_name'] as String?) ??
                                    (msg['sender_email'] as String?) ?? '';
                                if (senderName.contains('@')) {
                                  senderName = senderName.split('@')[0];
                                }
                              }

                              return Column(
                                children: [
                                  if (showDate)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
                                          borderRadius: BorderRadius.circular(12)),
                                        child: Text(_formatDate(msg['created_at']),
                                          style: const TextStyle(color: Colors.white,
                                            fontSize: 12, fontWeight: FontWeight.w500)),
                                      ),
                                    ),
                                  GestureDetector(
                                    onLongPress: () => _showMessageMenu(msg),
                                    onDoubleTap: () {
                                      HapticFeedback.lightImpact();
                                      _react(msg['id'], '❤️');
                                    },
                                    onHorizontalDragEnd: (details) {
                                      if (details.primaryVelocity == null) return;
                                      final v = details.primaryVelocity!;
                                      if (v > 400) {
                                        // Свайп вправо → ответить
                                        HapticFeedback.mediumImpact();
                                        setState(() => _replyingTo = msg);
                                      } else if (v < -400) {
                                        // Свайп влево → удалить (только свои)
                                        if (!isMe) {
                                          HapticFeedback.lightImpact();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Можно удалять только свои сообщения'),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                          return;
                                        }
                                        HapticFeedback.mediumImpact();
                                        _deleteMessage(msg['id']);
                                      }
                                    },
                                    child: Align(
                                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment: isMe
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                            padding: imageUrl.isEmpty
                                                ? const EdgeInsets.fromLTRB(12, 8, 12, 6)
                                                : const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(maxWidth: 300),
                                            decoration: BoxDecoration(
                                              color: isMe ? myBubble : otherBubble,
                                              borderRadius: BorderRadius.only(
                                                                                                topLeft: const Radius.circular(18),
                                                topRight: const Radius.circular(18),
                                                bottomLeft: Radius.circular(isMe ? 18 : 6),
                                                bottomRight: Radius.circular(isMe ? 6 : 18),
                                              ),
                                              boxShadow: [BoxShadow(
                                                color: Colors.black.withOpacity(0.06),
                                                blurRadius: 2, offset: const Offset(0, 1))],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [                                                if (msg['reply_to_id'] != null)
                                                  Container(
                                                    margin: EdgeInsets.fromLTRB(
                                                      imageUrl.isEmpty ? 0 : 8,
                                                      0,
                                                      imageUrl.isEmpty ? 0 : 8,
                                                      4,
                                                    ),
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.08),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: const Border(
                                                        left: BorderSide(
                                                          color: Color(0xFF7C3AED), width: 3),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          (msg['reply_sender_name'] as String?)?.isNotEmpty == true
                                                              ? msg['reply_sender_name']
                                                              : (msg['reply_sender_email'] as String? ?? ''),
                                                          style: const TextStyle(
                                                            color: Color(0xFF7C3AED),
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 2),
                                                                                                                Text(
                                                          (msg['reply_display_text'] as String?)?.isNotEmpty == true
                                                              ? msg['reply_display_text']
                                                              : ((msg['reply_image_url'] as String?)?.isNotEmpty == true
                                                                  ? '📷 Фото'
                                                                  : ''),
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: isMe ? myText : otherText,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if ((widget.isGroup || widget.isChannel) && !isMe && senderName.isNotEmpty)
                                                  Padding(
                                                    padding: EdgeInsets.fromLTRB(
                                                      imageUrl.isEmpty ? 0 : 8,
                                                      imageUrl.isEmpty ? 0 : 4,
                                                      imageUrl.isEmpty ? 0 : 8, 0),
                                                    child: Text(senderName,
                                                      style: const TextStyle(
                                                        color: Color(0xFF7C3AED),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13)),
                                                  ),
                                                if (imageUrl.isNotEmpty)
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.network(
                                                      '$serverUrl$imageUrl',
                                                      headers: {'Host': serverHost},
                                                      width: 260, fit: BoxFit.cover,
                                                      loadingBuilder: (context, child, progress) {
                                                        if (progress == null) return child;
                                                        return Container(width: 260, height: 200,
                                                          alignment: Alignment.center,
                                                          child: const CircularProgressIndicator());
                                                      },
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(width: 260, height: 200,
                                                          alignment: Alignment.center,
                                                          child: const Icon(Icons.broken_image,
                                                            size: 50, color: Colors.grey));
                                                      },
                                                    ),
                                                  ),

                                                if ((msg['file_url'] as String?)?.isNotEmpty == true)
                                                  Padding(
                                                    padding: EdgeInsets.fromLTRB(
                                                      imageUrl.isEmpty ? 0 : 8,
                                                      imageUrl.isEmpty ? 0 : 4,
                                                      imageUrl.isEmpty ? 0 : 8,
                                                      4,
                                                    ),
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        final url = '$serverUrl${msg['file_url']}';
                                                        Clipboard.setData(ClipboardData(text: url));
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text('Ссылка на файл скопирована'),
                                                            duration: Duration(seconds: 1),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.all(10),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withOpacity(0.08),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              _fileIcon((msg['file_name'] as String?) ?? ''),
                                                              color: const Color(0xFF7C3AED),
                                                              size: 32,
                                                            ),
                                                            const SizedBox(width: 10),
                                                            Flexible(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Text(
                                                                    (msg['file_name'] as String?) ?? 'файл',
                                                                    style: TextStyle(
                                                                      fontSize: 14,
                                                                      fontWeight: FontWeight.w600,
                                                                      color: isMe ? myText : otherText,
                                                                    ),
                                                                    maxLines: 1,
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                  const SizedBox(height: 2),
                                                                  Text(
                                                                    _formatFileSize((msg['file_size'] ?? 0)),
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      color: isMe
                                                                          ? (isDark ? Colors.white70 : Colors.grey[600])
                                                                          : Colors.grey[600],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                if (text.isNotEmpty)
                                                  Padding(
                                                    padding: EdgeInsets.fromLTRB(
                                                      imageUrl.isEmpty ? 0 : 8,
                                                      imageUrl.isEmpty ? 0 : 4,
                                                      imageUrl.isEmpty ? 0 : 8, 0),
                                                    child: Text(text,
                                                      style: TextStyle(
                                                        color: isMe ? myText : otherText,
                                                        fontSize: 15, height: 1.3)),
                                                  ),
                                                Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                    imageUrl.isEmpty ? 0 : 8, 2,
                                                    imageUrl.isEmpty ? 0 : 8,
                                                    imageUrl.isEmpty ? 0 : 4),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [                                                      if (msg['edited'] == true) ...[
                                                        Text('изм.',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontStyle: FontStyle.italic,
                                                            color: isMe
                                                                ? (isDark ? Colors.white70 : Colors.grey[600])
                                                                : Colors.grey[600],
                                                          )),
                                                        const SizedBox(width: 4),
                                                      ],
                                                      Text(_formatTime(msg['created_at']),
                                                        style: TextStyle(fontSize: 11,
                                                          color: isMe
                                                              ? (isDark ? Colors.white70 : Colors.grey[600])
                                                              : Colors.grey[600])),
                                                                                                            if (isMe) ...[
                                                        const SizedBox(width: 4),
                                                        Icon(
                                                          Icons.done_all,
                                                          size: 14,
                                                          color: msg['read_at'] != null
                                                              ? (isDark ? Colors.lightBlue : Colors.blue[600])
                                                              : Colors.grey,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (grouped.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8, right: 8),
                                              child: Wrap(
                                                spacing: 4,
                                                children: grouped.entries.map((entry) {
                                                  final emoji = entry.key;
                                                  final users = entry.value;
                                                  final iReacted = users.contains(widget.myId);
                                                  return GestureDetector(
                                                    onTap: () => _react(msg['id'], emoji),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: iReacted
                                                            ? (isDark ? const Color(0xFF4C1D95) : const Color(0xFFE9D5FF))
                                                            : (isDark ? const Color(0xFF18181B) : Colors.white),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                          color: iReacted ? const Color(0xFF7C3AED) : Colors.grey.shade400,
                                                          width: 1),
                                                      ),
                                                      child: Text(
                                                        users.length > 1 ? '$emoji ${users.length}' : emoji,
                                                        style: const TextStyle(fontSize: 14)),
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
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
              boxShadow: [BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: const Offset(0, -1))],
            ),
            child: canWrite
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [                      if (_replyingTo != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                            border: const Border(
                              left: BorderSide(color: Color(0xFF7C3AED), width: 3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Ответ на: ${(_replyingTo['sender_name'] as String?) ?? (_replyingTo['sender_email'] as String?) ?? "сообщение"}',
                                      style: const TextStyle(
                                        color: Color(0xFF7C3AED),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _replyingTo['display_text'] != null &&
                                              (_replyingTo['display_text'] as String).isNotEmpty
                                          ? _replyingTo['display_text']
                                          : (_replyingTo['image_url'] != null &&
                                                  (_replyingTo['image_url'] as String).isNotEmpty
                                              ? '📷 Фото'
                                              : ''),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.white70 : Colors.grey[700],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _replyingTo = null),
                                tooltip: 'Отменить ответ',
                              ),
                            ],
                          ),
                        ),
                      if (_uploading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: LinearProgressIndicator(),
                        ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file, color: Color(0xFF7C3AED), size: 24),
                                                        onPressed: _uploading ? null : _showAttachMenu,
                            tooltip: 'Прикрепить фото',
                          ),
                          IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined, color: Color(0xFF7C3AED), size: 26),
                            onPressed: _showEmojiPicker,
                            tooltip: 'Смайлики',
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              onChanged: (text) {
                                if (widget.isGroup || widget.isChannel) {
                                  _socket.emit('typing', {
                                    'chatId': widget.chatId,
                                    'typing': text.trim().isNotEmpty,
                                  });
                                } else {
                                  _socket.emit('typing', {
                                    'to': widget.userId,
                                    'typing': text.trim().isNotEmpty,
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                hintText: widget.isChannel ? 'Новый пост...' : 'Сообщение...',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF7C3AED), shape: BoxShape.circle),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white, size: 22),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign, color: isDark ? Colors.white54 : Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Text('Только админ может публиковать',
                          style: TextStyle(fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.grey[600])),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============= НАСТРОЙКИ =============
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _logout() async {
    await _clearSession();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: AvatarWidget(
              avatarUrl: myAvatarUrl,
              displayName: myName.isNotEmpty ? myName : myEmail,
              email: myEmail,
              radius: 50,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              myName.isNotEmpty ? myName : myEmail,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              myEmail,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),

          SwitchListTile(
            secondary: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: const Color(0xFF7C3AED),
            ),
            title: const Text('Тёмная тема'),
            subtitle: Text(isDark ? 'Включена' : 'Выключена'),
            value: isDark,
            activeColor: const Color(0xFF7C3AED),
            onChanged: (v) {
              themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
              setState(() {});
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF7C3AED)),
            title: const Text('О приложении'),
            subtitle: const Text('ARKZIS v1.0'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('ARKZIS'),
                  content: const Text(
                    'ARKZIS v1.0\n\n'
                    'Connect without limits.\n\n'
                    'E2EE-шифрование, группы, каналы, сторис, реакции, ответы, пересылка.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Выйти из аккаунта',
              style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Выйти?'),
                  content: const Text(
                    'Ты выйдешь из аккаунта. Ключи E2EE останутся '
                    'на телефоне — войдёшь обратно, они восстановятся.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _logout();
                      },
                      child: const Text('Выйти',
                        style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============= ЭКРАН ЗАГРУЗКИ ARKZIS =============
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      final hasSession = await _loadSession();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => hasSession ? const UsersPage() : const LoginPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/icon.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'ARKZIS',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect without limits',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============= SHIMMER ЗАГРУЗКИ =============
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5);
    final highlight = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 - 2 * _controller.value, 0),
              end: Alignment(1.0 - 2 * _controller.value, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class _ChatListSkeleton extends StatelessWidget {
  const _ChatListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 8,
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        final width = 140.0 + (index * 20) % 100;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              _ShimmerBox(width: 80, height: 12, radius: 6),
              const SizedBox(height: 6),
              _ShimmerBox(width: width, height: 40, radius: 14),
            ],
          ),
        );
      },
    );
  }
}
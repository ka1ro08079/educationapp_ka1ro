import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/quiz_screen.dart';
import 'screens/record_screen.dart';
import 'screens/review_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBZ1Efm4igKW8pHS1wS-ImZnGLKZsR1RHY",
      authDomain: "chaekjikpiti.firebaseapp.com",
      projectId: "chaekjikpiti",
      storageBucket: "chaekjikpiti.firebasestorage.app",
      messagingSenderId: "615082165748",
      appId: "1:615082165748:web:2c1401c7569cb0501125a1",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _onThemeChanged(bool val) {
    setState(() => _isDarkMode = val);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '채찍피티',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D2D2D)),
        textTheme: GoogleFonts.notoSansKrTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D2D2D),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.notoSansKrTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        isDarkMode: _isDarkMode,
        onThemeChanged: _onThemeChanged,
      ),
    );
  }
}

// ───────────────────────────────────────────
// 홈 화면
// ───────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<Map<String, String>> _quotes = [
    {'quote': '"불가능이란 아무것도 하지 않으려는\n사람들이 찾아낸 변명에 불과하다."', 'author': '나폴레옹'},
    {'quote': '"지금 이 순간에도 당신의 경쟁자는\n책을 읽고 있다."', 'author': '빌 게이츠'},
    {'quote': '"오늘 걷지 않으면\n내일은 뛰어야 한다."', 'author': '작자 미상'},
    {'quote': '"고통 없이는 얻는 것도 없다."', 'author': '벤저민 프랭클린'},
    {'quote': '"천재는 1%의 영감과\n99%의 노력으로 이루어진다."', 'author': '토마스 에디슨'},
    {'quote': '"지금 자면 꿈을 꾸지만,\n지금 공부하면 꿈을 이룬다."', 'author': '작자 미상'},
    {'quote': '"포기하기엔 아직 이르다.\n시작하기엔 절대 늦지 않았다."', 'author': '작자 미상'},
    {
      'quote': '"한 번도 실수를 해본 적 없는 사람은\n한 번도 새로운 것을 시도하지 않은 사람이다."',
      'author': '알베르트 아인슈타인',
    },
    {'quote': '"낙망은 청년의 죽음이요,\n청년이 낙망하면 그 나라는 죽는다."', 'author': '도산 안창호'},
    {'quote': '"진실은 반드시 따르는 자가 있고\n정의는 반드시 이루는 날이 있다."', 'author': '도산 안창호'},
    {'quote': '"성패는 일하는 사람의 자세에 달린 거야."', 'author': '정주영'},
    {'quote': '"이봐, 해봤어?"', 'author': '정주영'},
    {'quote': '"시련은 있어도 실패는 없다."', 'author': '정주영'},
    {'quote': '"길을 모르면 길을 찾고,\n길이 없으면 길을 닦아야지."', 'author': '정주영'},
    {'quote': '"아무라도 신념에 노력을 더하면\n뭐든지 해낼 수 있는 거야."', 'author': '정주영'},
  ];

  late Map<String, String> _currentQuote;

  @override
  void initState() {
    super.initState();
    _pickQuote();
  }

  void _pickQuote() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final random = Random(seed);
    setState(() {
      _currentQuote = _quotes[random.nextInt(_quotes.length)];
    });
  }

  void _navigate(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = widget.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE8E8E8),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3A3A3A)
                    : const Color(0xFFEEEEEE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDark ? Colors.white70 : const Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF2D2D2D),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDark ? Colors.white30 : const Color(0xFFBBBBBB),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '채찍피티',
          style: GoogleFonts.montserrat(
            color: isDark ? Colors.white : const Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEEEEEE),
            height: 1,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // 왼쪽 — 명언 카드
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 28,
                      color: isDark ? Colors.white70 : const Color(0xFF2D2D2D),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '오늘의 명언',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11,
                        color: Colors.grey,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentQuote['quote']!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '— ${_currentQuote['author']!}',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 오른쪽 — 버튼 4개
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMenuButton(
                    icon: Icons.quiz_outlined,
                    label: '단어 퀴즈',
                    onTap: () => _navigate(const QuizScreen()),
                  ),
                  _buildMenuButton(
                    icon: Icons.book_outlined,
                    label: '공부 기록',
                    onTap: () => _navigate(const RecordScreen()),
                  ),
                  _buildMenuButton(
                    icon: Icons.alarm_outlined,
                    label: '복습 알람',
                    onTap: () => _navigate(const ReviewScreen()),
                  ),
                  _buildMenuButton(
                    icon: Icons.settings_outlined,
                    label: '설정',
                    onTap: () => _navigate(
                      SettingsScreen(
                        isDarkMode: widget.isDarkMode,
                        onThemeChanged: widget.onThemeChanged,
                      ),
                    ),
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

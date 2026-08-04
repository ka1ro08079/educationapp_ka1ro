import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_record.dart';

const String _prefsKey = 'study_records';
const String _reviewDaysKey = 'review_days';
const String _completedKey = 'completed_reviews';
const List<int> kDefaultReviewDays = [1, 3, 7, 14, 30];

const List<Color> kSubjectColors = [
  Color(0xFF5C6BC0),
  Color(0xFF26A69A),
  Color(0xFFEF5350),
  Color(0xFFFFA726),
  Color(0xFF66BB6A),
  Color(0xFF8D6E63),
];

const List<String> kSubjects = ['수학', '영어', '국어', '과학', '사회', '기타'];

class ReviewItem {
  final StudyRecord record;
  final int reviewDay;
  final DateTime reviewDate;
  ReviewItem({
    required this.record,
    required this.reviewDay,
    required this.reviewDate,
  });
  String get completionKey =>
      '${record.id}_${reviewDay}_${reviewDate.year}${reviewDate.month.toString().padLeft(2, '0')}${reviewDate.day.toString().padLeft(2, '0')}';
}

class CompletedItem {
  final ReviewItem item;
  final DateTime completedAt;
  CompletedItem({required this.item, required this.completedAt});
}

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReviewItem> _todayItems = [];
  List<CompletedItem> _todayCompleted = [];
  List<ReviewItem> _upcomingItems = [];
  List<int> _reviewDays = [...kDefaultReviewDays];
  Map<String, String> _completedMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await _loadReviewDays();
    await _loadCompleted();
    await _loadRecords();
  }

  Future<void> _loadReviewDays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_reviewDaysKey);
    if (raw != null)
      setState(() => _reviewDays = raw.map((e) => int.parse(e)).toList());
  }

  Future<void> _saveReviewDays() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _reviewDaysKey,
      _reviewDays.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _loadCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_completedKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      setState(
        () => _completedMap = decoded.map((k, v) => MapEntry(k, v as String)),
      );
    }
  }

  Future<void> _saveCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_completedKey, jsonEncode(_completedMap));
  }

  Future<void> _markComplete(ReviewItem item) async {
    final now = DateTime.now();
    _completedMap[item.completionKey] = now.toIso8601String();
    await _saveCompleted();
    setState(() {
      _todayItems.removeWhere((i) => i.completionKey == item.completionKey);
      _todayCompleted.add(CompletedItem(item: item, completedAt: now));
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                '${item.record.subject} 복습 완료!',
                style: GoogleFonts.notoSans(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2D2D2D),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    final records = raw
        .map((e) => StudyRecord.fromJson(jsonDecode(e)))
        .toList();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final todayStr =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    final todayItems = <ReviewItem>[];
    final todayCompleted = <CompletedItem>[];
    final upcomingItems = <ReviewItem>[];

    final Map<String, StudyRecord> uniqueRecords = {};
    for (final r in records) {
      final key =
          '${r.subject}_${r.createdAt.year}_${r.createdAt.month}_${r.createdAt.day}';
      if (!uniqueRecords.containsKey(key) ||
          r.createdAt.isAfter(uniqueRecords[key]!.createdAt)) {
        uniqueRecords[key] = r;
      }
    }

    for (final r in uniqueRecords.values) {
      final studyDate = DateTime(
        r.createdAt.year,
        r.createdAt.month,
        r.createdAt.day,
      );
      for (final day in _reviewDays) {
        final reviewDate = studyDate.add(Duration(days: day));
        final diff = reviewDate.difference(todayDate).inDays;
        final item = ReviewItem(
          record: r,
          reviewDay: day,
          reviewDate: reviewDate,
        );
        final completedAt = _completedMap[item.completionKey];
        if (completedAt != null) {
          final completedDate = DateTime.parse(completedAt);
          final completedDateStr =
              '${completedDate.year}${completedDate.month.toString().padLeft(2, '0')}${completedDate.day.toString().padLeft(2, '0')}';
          if (completedDateStr == todayStr)
            todayCompleted.add(
              CompletedItem(item: item, completedAt: completedDate),
            );
          continue;
        }
        if (diff == 0)
          todayItems.add(item);
        else if (diff > 0 && diff <= 7)
          upcomingItems.add(item);
      }
    }

    todayItems.sort((a, b) => a.record.subject.compareTo(b.record.subject));
    todayCompleted.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    upcomingItems.sort((a, b) => a.reviewDate.compareTo(b.reviewDate));

    setState(() {
      _todayItems = todayItems;
      _todayCompleted = todayCompleted;
      _upcomingItems = upcomingItems;
    });
  }

  void _showSettingsDialog(
    Color textColor,
    Color cardColor,
    Color borderColor,
    bool isDark,
  ) {
    final controllers = _reviewDays
        .map((d) => TextEditingController(text: d.toString()))
        .toList();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            '복습 주기 설정',
            style: GoogleFonts.notoSans(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '복습할 날짜(일)를 입력해주세요',
                  style: GoogleFonts.notoSans(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ...controllers.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          '${i + 1}차 복습  ',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: c,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              color: textColor,
                            ),
                            decoration: InputDecoration(
                              suffixText: '일',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (controllers.length > 1)
                          GestureDetector(
                            onTap: () =>
                                setDialogState(() => controllers.removeAt(i)),
                            child: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => setDialogState(
                    () => controllers.add(TextEditingController(text: '')),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    '주기 추가',
                    style: GoogleFonts.notoSans(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                '취소',
                style: GoogleFonts.notoSans(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final days =
                    controllers
                        .map((c) => int.tryParse(c.text.trim()) ?? 0)
                        .where((d) => d > 0)
                        .toList()
                      ..sort();
                if (days.isEmpty) return;
                setState(() => _reviewDays = days);
                await _saveReviewDays();
                Navigator.pop(ctx);
                _loadRecords();
              },
              style: ElevatedButton.styleFrom(backgroundColor: textColor),
              child: Text(
                '저장',
                style: GoogleFonts.notoSans(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _subjectColor(String subject) {
    final i = kSubjects.indexOf(subject);
    return i >= 0 ? kSubjectColors[i] : Colors.grey;
  }

  String _reviewLabel(int day) => '$day일 후 복습';
  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}';
  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _daysUntil(DateTime reviewDate) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final diff = reviewDate.difference(todayDate).inDays;
    if (diff == 1) return '내일';
    return '$diff일 후';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final cardColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF7F7F7);
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final borderColor = isDark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFE8E8E8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '복습 알람',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: textColor),
            onPressed: () =>
                _showSettingsDialog(textColor, cardColor, borderColor, isDark),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: textColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: textColor,
          labelStyle: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('오늘', style: TextStyle(color: textColor)),
                  if (_todayItems.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_todayItems.length}',
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('완료', style: TextStyle(color: textColor)),
                  if (_todayCompleted.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_todayCompleted.length}',
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Text('7일 이내', style: TextStyle(color: textColor)),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildToday(textColor, cardColor, borderColor, isDark),
          _buildCompleted(textColor, cardColor, borderColor),
          _buildUpcoming(textColor, cardColor, borderColor),
        ],
      ),
    );
  }

  Widget _buildToday(
    Color textColor,
    Color cardColor,
    Color borderColor,
    bool isDark,
  ) {
    if (_todayItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.grey.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              '오늘 복습할 항목이 없어요!',
              style: GoogleFonts.notoSans(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '공부 기록을 추가하면 복습 일정이 생성돼요',
              style: GoogleFonts.notoSans(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showSettingsDialog(
                textColor,
                cardColor,
                borderColor,
                isDark,
              ),
              icon: const Icon(Icons.tune, size: 16),
              label: Text(
                '복습 주기 설정',
                style: GoogleFonts.notoSans(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: textColor),
                foregroundColor: textColor,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _todayItems.length,
      itemBuilder: (_, i) {
        final item = _todayItems[i];
        final color = _subjectColor(item.record.subject);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(10),
            color: color.withOpacity(0.05),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.record.subject,
                            style: GoogleFonts.notoSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _reviewLabel(item.reviewDay),
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (item.record.content != item.record.subject)
                      Text(
                        item.record.content,
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDate(item.record.createdAt)}에 공부한 내용',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _markComplete(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: textColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '완료',
                    style: GoogleFonts.notoSans(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompleted(Color textColor, Color cardColor, Color borderColor) {
    if (_todayCompleted.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Colors.grey.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              '오늘 완료한 복습이 없어요',
              style: GoogleFonts.notoSans(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '복습 완료하면 여기에 기록돼요!',
              style: GoogleFonts.notoSans(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _todayCompleted.length,
      itemBuilder: (_, i) {
        final ci = _todayCompleted[i];
        final item = ci.item;
        final color = _subjectColor(item.record.subject);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(10),
            color: cardColor,
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.record.subject,
                            style: GoogleFonts.notoSans(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _reviewLabel(item.reviewDay),
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (item.record.content != item.record.subject) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.record.content,
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          color: textColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                _formatTime(ci.completedAt),
                style: GoogleFonts.notoSans(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcoming(Color textColor, Color cardColor, Color borderColor) {
    if (_upcomingItems.isEmpty) {
      return Center(
        child: Text(
          '7일 이내 복습 예정이 없어요',
          style: GoogleFonts.notoSans(color: Colors.grey, fontSize: 15),
        ),
      );
    }
    final Map<String, List<ReviewItem>> grouped = {};
    for (final item in _upcomingItems) {
      final key = _formatDate(item.reviewDate);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        final items = entry.value;
        final daysUntil = _daysUntil(items.first.reviewDate);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    entry.key,
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      daysUntil,
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...items.map((item) {
              final color = _subjectColor(item.record.subject);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(10),
                  color: cardColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.record.subject,
                            style: GoogleFonts.notoSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _reviewLabel(item.reviewDay),
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_formatDate(item.record.createdAt)} 공부분',
                          style: GoogleFonts.notoSans(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (item.record.content != item.record.subject) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.record.content,
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          color: textColor,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}

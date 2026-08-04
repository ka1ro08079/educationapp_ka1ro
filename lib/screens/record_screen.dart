import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_record.dart';

const List<String> kSubjects = ['수학', '영어', '국어', '과학', '사회', '기타'];
const String _prefsKey = 'study_records';
const List<String> kWeekDays = ['월', '화', '수', '목', '금', '토', '일'];

const List<Color> kSubjectColors = [
  Color(0xFF5C6BC0),
  Color(0xFF26A69A),
  Color(0xFFEF5350),
  Color(0xFFFFA726),
  Color(0xFF66BB6A),
  Color(0xFF8D6E63),
];

class RecordScreen extends StatefulWidget {
  final int initialTab;
  const RecordScreen({super.key, this.initialTab = 0});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<StudyRecord> _records = [];
  bool _showForm = false;

  final _contentController = TextEditingController();
  String _selectedSubject = kSubjects[0];
  int _selectedHour = 0;
  int _selectedMinute = 30;
  DateTime _selectedDate = DateTime.now();
  DateTime _calendarMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    setState(() {
      _records = raw.map((e) => StudyRecord.fromJson(jsonDecode(e))).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D2D2D)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveRecord() async {
    final content = _contentController.text.trim();
    final totalMinutes = _selectedHour * 60 + _selectedMinute;
    if (totalMinutes == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공부 시간을 입력해주세요!')));
      return;
    }
    final now = DateTime.now();
    final recordDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
    );
    final record = StudyRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: _selectedSubject,
      content: content.isEmpty ? _selectedSubject : content,
      createdAt: recordDate,
      minutes: totalMinutes,
    );
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    raw.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_prefsKey, raw);
    _contentController.clear();
    setState(() {
      _showForm = false;
      _selectedSubject = kSubjects[0];
      _selectedHour = 0;
      _selectedMinute = 30;
      _selectedDate = DateTime.now();
    });
    _loadRecords();
  }

  Future<void> _deleteRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    raw.removeWhere((e) {
      final decoded = jsonDecode(e) as Map<String, dynamic>;
      return decoded['id'] == id;
    });
    await prefs.setStringList(_prefsKey, raw);
    _loadRecords();
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '$minutes분';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h시간' : '$h시간 $m분';
  }

  String _formatDate(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDateShort(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  List<DateTime> _getThisWeekDays() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );
  }

  List<StudyRecord> _recordsForDay(DateTime day) => _records
      .where(
        (r) =>
            r.createdAt.year == day.year &&
            r.createdAt.month == day.month &&
            r.createdAt.day == day.day,
      )
      .toList();

  int _minutesForDay(DateTime day) =>
      _recordsForDay(day).fold(0, (sum, r) => sum + r.minutes);

  int _monthlyMinutes() {
    final now = DateTime.now();
    return _records
        .where(
          (r) => r.createdAt.year == now.year && r.createdAt.month == now.month,
        )
        .fold(0, (sum, r) => sum + r.minutes);
  }

  Map<String, int> _monthlyBySubject() {
    final now = DateTime.now();
    final map = <String, int>{};
    for (final s in kSubjects) {
      map[s] = _records
          .where(
            (r) =>
                r.subject == s &&
                r.createdAt.year == now.year &&
                r.createdAt.month == now.month,
          )
          .fold(0, (sum, r) => sum + r.minutes);
    }
    return map;
  }

  void _showDayRecords(
    DateTime day,
    List<StudyRecord> records,
    Color textColor,
    Color cardColor,
    Color borderColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${day.month}월 ${day.day}일 공부 기록',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '총 ${_formatTime(_minutesForDay(day))}',
                  style: GoogleFonts.notoSans(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...records.map((r) {
              final color = kSubjectColors[kSubjects.indexOf(r.subject)];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(8),
                  color: cardColor,
                ),
                child: Row(
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
                        r.subject,
                        style: GoogleFonts.notoSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (r.content != r.subject)
                            Text(
                              r.content,
                              style: GoogleFonts.notoSans(
                                fontSize: 13,
                                color: textColor,
                              ),
                            ),
                          Text(
                            _formatTime(r.minutes),
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
          '공부 기록',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.close : Icons.add, color: textColor),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: textColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: textColor,
          labelStyle: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '기록'),
            Tab(text: '주간'),
            Tab(text: '달력'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_showForm) _buildForm(isDark, cardColor, textColor, borderColor),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(isDark, cardColor, textColor, borderColor),
                _buildWeekly(isDark, cardColor, textColor, borderColor),
                _buildCalendar(isDark, cardColor, textColor, borderColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color borderColor,
  ) {
    final isTodaySelected = _isToday(_selectedDate);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isTodaySelected ? borderColor : textColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 14, color: textColor),
                  const SizedBox(width: 6),
                  Text(
                    isTodaySelected ? '오늘' : _formatDateShort(_selectedDate),
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: kSubjects.map((s) {
              final selected = s == _selectedSubject;
              return ChoiceChip(
                label: Text(
                  s,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: selected
                        ? (isDark ? const Color(0xFF1A1A1A) : Colors.white)
                        : textColor,
                  ),
                ),
                selected: selected,
                selectedColor: textColor,
                backgroundColor: isDark
                    ? const Color(0xFF1A1A1A)
                    : Colors.white,
                onSelected: (_) => setState(() => _selectedSubject = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '공부 시간',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 16),
              _timeDropdown(
                value: _selectedHour,
                items: List.generate(13, (i) => i),
                label: '시간',
                onChanged: (v) => setState(() => _selectedHour = v!),
                isDark: isDark,
                textColor: textColor,
              ),
              const SizedBox(width: 8),
              _timeDropdown(
                value: _selectedMinute,
                items: [0, 10, 15, 20, 30, 40, 45, 50],
                label: '분',
                onChanged: (v) => setState(() => _selectedMinute = v!),
                isDark: isDark,
                textColor: textColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 2,
            style: GoogleFonts.notoSans(fontSize: 14, color: textColor),
            decoration: InputDecoration(
              hintText: '공부 내용 (선택)',
              hintStyle: GoogleFonts.notoSans(color: Colors.grey),
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                '저장',
                style: GoogleFonts.notoSans(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeDropdown({
    required int value,
    required List<int> items,
    required String label,
    required ValueChanged<int?> onChanged,
    required bool isDark,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: value,
        underline: const SizedBox(),
        isDense: true,
        dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        items: items
            .map(
              (i) => DropdownMenuItem(
                value: i,
                child: Text(
                  '$i$label',
                  style: GoogleFonts.notoSans(fontSize: 13, color: textColor),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildList(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color borderColor,
  ) {
    final now = DateTime.now();
    final todayRecords = _records
        .where(
          (r) =>
              r.createdAt.year == now.year &&
              r.createdAt.month == now.month &&
              r.createdAt.day == now.day,
        )
        .toList();
    if (todayRecords.isEmpty) {
      return Center(
        child: Text(
          '오늘 기록이 없어요.\n+ 버튼으로 추가해보세요!',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSans(color: Colors.grey, fontSize: 15),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: todayRecords.length,
      itemBuilder: (_, i) {
        final r = todayRecords[i];
        final color = kSubjectColors[kSubjects.indexOf(r.subject)];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(10),
            color: cardColor,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  r.subject,
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(r.minutes),
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    if (r.content != r.subject) ...[
                      const SizedBox(height: 2),
                      Text(
                        r.content,
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          color: textColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(r.createdAt),
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _deleteRecord(r.id),
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekly(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color borderColor,
  ) {
    final weekDays = _getThisWeekDays();
    final dayMinutes = weekDays.map(_minutesForDay).toList();
    final maxMinutes = dayMinutes.reduce((a, b) => a > b ? a : b);
    final monthly = _monthlyMinutes();
    final bySubject = _monthlyBySubject();
    final now = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: textColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${now.month}월 총 공부 시간',
                  style: GoogleFonts.notoSans(
                    color: isDark ? Colors.black54 : Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(monthly),
                  style: GoogleFonts.notoSans(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '이번 주',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final mins = dayMinutes[i];
              final isToday =
                  weekDays[i].day == now.day && weekDays[i].month == now.month;
              final barH = maxMinutes == 0
                  ? 4.0
                  : (mins / maxMinutes * 120).clamp(4.0, 120.0);
              return Expanded(
                child: Column(
                  children: [
                    if (mins > 0)
                      Text(
                        _formatTime(mins),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSans(
                          fontSize: 9,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      height: barH,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isToday
                            ? textColor
                            : (isDark
                                  ? const Color(0xFF3A3A3A)
                                  : const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      kWeekDays[i],
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        fontWeight: isToday
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: isToday ? textColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Text(
            '${now.month}월 과목별',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          ...kSubjects.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final mins = bySubject[s] ?? 0;
            if (mins == 0) return const SizedBox.shrink();
            final ratio = monthly == 0 ? 0.0 : mins / monthly;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s,
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        _formatTime(mins),
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: borderColor,
                      color: kSubjectColors[i],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCalendar(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color borderColor,
  ) {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startOffset = (firstDay.weekday - 1) % 7;
    final rows = ((startOffset + lastDay.day) / 7).ceil();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: textColor),
                onPressed: () =>
                    setState(() => _calendarMonth = DateTime(year, month - 1)),
              ),
              Text(
                '$year년 $month월',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: textColor),
                onPressed: () =>
                    setState(() => _calendarMonth = DateTime(year, month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: kWeekDays
                .map(
                  (d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          ...List.generate(rows, (row) {
            return Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNum = cellIndex - startOffset + 1;
                if (dayNum < 1 || dayNum > lastDay.day)
                  return const Expanded(child: SizedBox(height: 56));
                final day = DateTime(year, month, dayNum);
                final mins = _minutesForDay(day);
                final dayRecords = _recordsForDay(day);
                final isToday = _isToday(day);
                Color bgColor = Colors.transparent;
                if (mins > 0) {
                  final intensity = (mins / 240).clamp(0.1, 1.0);
                  bgColor = textColor.withOpacity(intensity * 0.15 + 0.05);
                }
                return Expanded(
                  child: GestureDetector(
                    onTap: dayRecords.isNotEmpty
                        ? () => _showDayRecords(
                            day,
                            dayRecords,
                            textColor,
                            cardColor,
                            borderColor,
                          )
                        : null,
                    child: Container(
                      height: 56,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(color: textColor, width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                          if (mins > 0)
                            Text(
                              _formatTime(mins),
                              style: GoogleFonts.notoSans(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
          const SizedBox(height: 8),
          Text(
            '날짜를 탭하면 해당 날 기록을 확인할 수 있어요',
            style: GoogleFonts.notoSans(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/word_data.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<WordQuiz> _quizWords;
  late List<String> _currentOptions;
  int _currentIndex = 0;
  int _score = 0;
  int _wrongCount = 0;
  bool _answered = false;
  String? _selectedOption;
  bool _isFinished = false;
  final List<Map<String, dynamic>> _wrongAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  void _loadQuiz() {
    final shuffled = [...wordList]..shuffle(Random());
    _quizWords = shuffled.take(20).toList();
    _currentIndex = 0;
    _score = 0;
    _wrongCount = 0;
    _answered = false;
    _selectedOption = null;
    _isFinished = false;
    _wrongAnswers.clear();
    _currentOptions = getOptions(_quizWords[0].answer);
  }

  void _selectAnswer(String option) {
    if (_answered) return;
    final correct = _quizWords[_currentIndex].answer;
    setState(() {
      _answered = true;
      _selectedOption = option;
      if (option == correct) {
        _score++;
      } else {
        _wrongCount++;
        _wrongAnswers.add({
          'word': _quizWords[_currentIndex].word,
          'answer': correct,
          'selected': option,
        });
      }
    });
  }

  void _next() {
    if (_currentIndex + 1 >= _quizWords.length) {
      setState(() => _isFinished = true);
      return;
    }
    setState(() {
      _currentIndex++;
      _answered = false;
      _selectedOption = null;
      _currentOptions = getOptions(_quizWords[_currentIndex].answer);
    });
  }

  void _startReview() {
    final reviewList = _wrongAnswers
        .map((e) => WordQuiz(word: e['word'], answer: e['answer']))
        .toList();
    setState(() {
      _quizWords = reviewList;
      _currentIndex = 0;
      _score = 0;
      _wrongCount = 0;
      _answered = false;
      _selectedOption = null;
      _isFinished = false;
      _wrongAnswers.clear();
      _currentOptions = getOptions(_quizWords[0].answer);
    });
  }

  void _reset() {
    setState(() => _loadQuiz());
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

    if (_isFinished)
      return _buildResult(bgColor, cardColor, textColor, borderColor, isDark);
    final quiz = _quizWords[_currentIndex];
    final progress = (_currentIndex + 1) / _quizWords.length;

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
          '단어 퀴즈',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: textColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: borderColor,
              color: textColor,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            Text(
              '${_currentIndex + 1} / ${_quizWords.length}',
              textAlign: TextAlign.right,
              style: GoogleFonts.notoSans(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                quiz.word,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 28),
            ..._currentOptions.map((opt) {
              Color bg = isDark ? const Color(0xFF2A2A2A) : Colors.white;
              Color border = borderColor;
              Color text = textColor;
              if (_answered) {
                if (opt == quiz.answer) {
                  bg = const Color(0xFFE8F5E9);
                  border = Colors.green;
                  text = Colors.green;
                } else if (opt == _selectedOption) {
                  bg = const Color(0xFFFFEBEE);
                  border = Colors.red;
                  text = Colors.red;
                }
              }
              return GestureDetector(
                onTap: () => _selectAnswer(opt),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    opt,
                    style: GoogleFonts.notoSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: text,
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            if (_answered)
              ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _currentIndex + 1 >= _quizWords.length ? '결과 보기' : '다음',
                  style: GoogleFonts.notoSans(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(
    Color bgColor,
    Color cardColor,
    Color textColor,
    Color borderColor,
    bool isDark,
  ) {
    final total = _quizWords.length;
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
          '결과',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: textColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '$_score / $total',
                    style: GoogleFonts.notoSans(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '정답 $_score개 · 오답 $_wrongCount개',
                    style: GoogleFonts.notoSans(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (_wrongCount > 0) ...[
              const SizedBox(height: 20),
              Text(
                '틀린 단어',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _wrongAnswers.length,
                  itemBuilder: (_, i) {
                    final w = _wrongAnswers[i];
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
                          Expanded(
                            child: Text(
                              w['word'],
                              style: GoogleFonts.notoSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                          ),
                          Text(
                            w['answer'],
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Spacer(),
            const SizedBox(height: 12),
            if (_wrongCount > 0)
              ElevatedButton(
                onPressed: _startReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  '오답 복습하기',
                  style: GoogleFonts.notoSans(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: textColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                '새 퀴즈 풀기',
                style: GoogleFonts.notoSans(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

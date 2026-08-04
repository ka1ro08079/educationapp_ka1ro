import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        backgroundColor: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: _isDarkMode ? Colors.white : const Color(0xFF2D2D2D),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '설정',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: _isDarkMode ? Colors.white : const Color(0xFF2D2D2D),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: _isDarkMode
                ? const Color(0xFF2D2D2D)
                : const Color(0xFFEEEEEE),
            height: 1,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 계정 섹션
          _buildSectionHeader('계정'),
          const SizedBox(height: 8),
          _buildCard(
            child: _buildListTile(
              icon: Icons.person_outline,
              title: '로그인',
              subtitle: '로그인하면 데이터가 클라우드에 저장돼요',
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? const Color(0xFF2D2D2D)
                      : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '준비 중',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: _isDarkMode ? Colors.white60 : Colors.grey,
                  ),
                ),
              ),
              onTap: null,
            ),
          ),
          const SizedBox(height: 24),
          // 화면 섹션
          _buildSectionHeader('화면'),
          const SizedBox(height: 8),
          _buildCard(
            child: _buildSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: '다크 모드',
              subtitle: '어두운 테마로 전환해요',
              value: _isDarkMode,
              onChanged: (val) {
                setState(() => _isDarkMode = val);
                widget.onThemeChanged(val);
              },
            ),
          ),
          const SizedBox(height: 24),
          // 앱 정보
          _buildSectionHeader('앱 정보'),
          const SizedBox(height: 8),
          _buildCard(
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.info_outline,
                  title: '버전',
                  trailing: Text(
                    '1.0.0',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  onTap: null,
                ),
                Divider(
                  height: 1,
                  color: _isDarkMode
                      ? const Color(0xFF2D2D2D)
                      : const Color(0xFFEEEEEE),
                ),
                _buildListTile(
                  icon: Icons.school_outlined,
                  title: '채찍피티',
                  subtitle: '열공하는 당신을 응원합니다 💪',
                  onTap: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.notoSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode
              ? const Color(0xFF3A3A3A)
              : const Color(0xFFE8E8E8),
        ),
      ),
      child: child,
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? const Color(0xFF3A3A3A)
              : const Color(0xFFEEEEEE),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: _isDarkMode ? Colors.white70 : const Color(0xFF2D2D2D),
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _isDarkMode ? Colors.white : const Color(0xFF2D2D2D),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: _isDarkMode ? Colors.white30 : Colors.grey,
                )
              : null),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? const Color(0xFF3A3A3A)
              : const Color(0xFFEEEEEE),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: _isDarkMode ? Colors.white70 : const Color(0xFF2D2D2D),
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _isDarkMode ? Colors.white : const Color(0xFF2D2D2D),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: _isDarkMode ? Colors.white : const Color(0xFF2D2D2D),
        activeTrackColor: _isDarkMode
            ? const Color(0xFF555555)
            : const Color(0xFF2D2D2D),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: _isDarkMode
            ? const Color(0xFF3A3A3A)
            : const Color(0xFFE0E0E0),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:amarnamovil/data/local/database_helper.dart';
import 'package:amarnamovil/features/interview/presentation/screens/interview_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Map<String, dynamic> _currentUser;
  List<Map<String, dynamic>> _interviewLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = Map<String, dynamic>.from(widget.user);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = DatabaseHelper();
      final freshUser = await db.getUserById(_currentUser['id']);
      final logs = await db.getInterviewLogs(_currentUser['id']);
      if (mounted) {
        setState(() {
          if (freshUser != null) _currentUser = Map<String, dynamic>.from(freshUser);
          _interviewLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _currentUser['name'] ?? 'Candidato';
    final hasCv = (_currentUser['cv_path'] ?? '').isNotEmpty;
    final cvContent = (_currentUser['cv_content'] ?? '') as String;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Buenos dÃ­as' : hour < 20 ? 'Buenas tardes' : 'Buenas noches';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(greeting, name)),
                SliverToBoxAdapter(child: _buildCvCard(hasCv, cvContent)),
                SliverToBoxAdapter(child: _buildStatsRow()),
                SliverToBoxAdapter(child: _buildInterviewHistory()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  Widget _buildHeader(String greeting, String name) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, Color(0xFF1E3A5F)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: GoogleFonts.lato(color: AppTheme.secondaryColor, fontSize: 14, fontWeight: FontWeight.w600)).animate().fadeIn(),
                const SizedBox(height: 4),
                Text(name, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 2),
                Text(_currentUser['email'] ?? '', style: GoogleFonts.lato(color: Colors.white60, fontSize: 12)).animate().fadeIn(delay: 150.ms),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.secondaryColor, width: 2)),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white12,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ).animate().slideX(begin: -0.1, end: 0, duration: 400.ms),
    );
  }

  Widget _buildCvCard(bool hasCv, String cvContent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tu CurrÃ­culum', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 6))],
            ),
            child: hasCv
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CV cargado y analizado', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('Vinculado al Entrenador IA', style: GoogleFonts.lato(color: Colors.grey.shade500, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      if (cvContent.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text('Extracto del contenido:', style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 12)),
                        const SizedBox(height: 6),
                        Text(
                          cvContent.length > 350 ? '${cvContent.substring(0, 350)}...' : cvContent,
                          style: GoogleFonts.lato(color: Colors.grey.shade600, fontSize: 12, height: 1.6),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.upload_file_rounded, color: Colors.orange, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sin CV todavÃ­a', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('Ve a la pestaÃ±a JobMatch para subir el tuyo', style: GoogleFonts.lato(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildStatsRow() {
    final total = _interviewLogs.length;
    int avgComm = 0;
    int avgTech = 0;
    if (total > 0) {
      for (final log in _interviewLogs) {
        try {
          final raw = log['stats_json'] as String? ?? {};
          final stats = jsonDecode(raw as String) as Map<String, dynamic>;
          avgComm += (stats['comunicacion'] as num?)?.toInt() ?? 0;
          avgTech += (stats['tecnologia'] as num?)?.toInt() ?? 0;
        } catch (_) {}
      }
      avgComm = (avgComm / total).round();
      avgTech = (avgTech / total).round();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(child: _statChip('Entrevistas', '$total', Icons.record_voice_over_rounded, AppTheme.secondaryColor, 250)),
          const SizedBox(width: 12),
          Expanded(child: _statChip('ComunicaciÃ³n', total > 0 ? '$avgComm%' : '--', Icons.chat_rounded, const Color(0xFF8B5CF6), 350)),
          const SizedBox(width: 12),
          Expanded(child: _statChip('TÃ©cnico', total > 0 ? '$avgTech%' : '--', Icons.code_rounded, const Color(0xFF14B8A6), 450)),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, IconData icon, Color color, int delayMs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.lato(fontSize: 10, color: Colors.grey.shade500), textAlign: TextAlign.center),
        ],
      ),
    ).animate().fadeIn(delay: delayMs.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInterviewHistory() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ãšltimas Entrevistas', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(height: 12),
          if (_interviewLogs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Icon(Icons.history_edu_rounded, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Sin entrevistas aÃºn', style: GoogleFonts.lato(color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Completa tu primera sesiÃ³n con el Entrenador IA', textAlign: TextAlign.center,
                      style: GoogleFonts.lato(color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
            )
          else
            ...List.generate(_interviewLogs.take(3).length, (i) {
              final log = _interviewLogs[i];
              final dateRaw = log['interview_date'] as String? ?? '';
              final date = dateRaw.isNotEmpty ? DateTime.tryParse(dateRaw) : null;
              final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : 'Reciente';
              int? comm;
              int? tech;
              try {
                final stats = jsonDecode(log['stats_json'] as String) as Map<String, dynamic>;
                comm = (stats['comunicacion'] as num?)?.toInt();
                tech = (stats['tecnologia'] as num?)?.toInt();
              } catch (_) {}
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InterviewDetailScreen(log: log),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.mic_rounded, color: AppTheme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Entrevista del $dateStr', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14)),
                            if (comm != null && tech != null)
                              Text('ComunicaciÃ³n: $comm% Â· TÃ©cnico: $tech%', style: GoogleFonts.lato(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ).animate().fadeIn(delay: (300 + i * 100).ms).slideX(begin: 0.1, end: 0),
              );
            }),
        ],
      ).animate().fadeIn(delay: 400.ms),
    );
  }
}


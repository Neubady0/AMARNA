import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';

class InterviewDetailScreen extends StatelessWidget {
  final Map<String, dynamic> log;

  const InterviewDetailScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    // Parse Date
    final dateRaw = log['interview_date'] as String? ?? '';
    final date = dateRaw.isNotEmpty ? DateTime.tryParse(dateRaw) : null;
    final dateStr = date != null ? '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}' : 'Reciente';

    // Parse Stats
    Map<String, dynamic> stats = {};
    try {
      stats = jsonDecode(log['stats_json'] as String);
    } catch (_) {}
    final comm = (stats['comunicacion'] ?? stats['communication'] ?? 0).toDouble();
    final tech = (stats['tecnico'] ?? stats['tecnologia'] ?? stats['technical'] ?? 0).toDouble();
    final feedback = stats['feedback'] ?? stats['resumen'] ?? 'Sin feedback disponible.';

    // Parse Messages
    List<Map<String, dynamic>> messages = [];
    try {
      final rawMsgs = jsonDecode(log['messages_json'] as String) as List<dynamic>;
      messages = rawMsgs.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          children: [
            Text('Detalle de Entrevista', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(dateStr, style: GoogleFonts.lato(color: Colors.white70, fontSize: 12)),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildStatsSection(comm, tech, feedback)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text('Historial de Chat', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildMessageBubble(messages[index], context),
                childCount: messages.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildStatsSection(double comm, double tech, String feedback) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildScoreCard('Comunicación', comm, AppTheme.secondaryColor)),
              const SizedBox(width: 14),
              Expanded(child: _buildScoreCard('Técnico', tech, const Color(0xFF818CF8))),
            ],
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),
          Row(children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            Text('Feedback de Amarna', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          ]),
          const SizedBox(height: 12),
          Text(feedback, style: GoogleFonts.lato(color: Colors.grey.shade700, fontSize: 13, height: 1.6)).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, double score, Color color) {
    final pct = score.clamp(0, 100) / 100;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text('${score.toStringAsFixed(0)}%', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.lato(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, BuildContext context) {
    final isUser = msg['role'] == 'user';
    final isSystem = msg['role'] == 'system' || msg['role'] == 'system'; // Handle potential variations

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(msg['content'] ?? '', style: GoogleFonts.lato(color: Colors.orange.shade800, fontSize: 12)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.smart_toy_rounded, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                gradient: isUser ? const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF1E3A5F)]) : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Text(
                msg['content'] ?? '',
                style: GoogleFonts.lato(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14, height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.secondaryColor,
              child: Icon(Icons.person, size: 14, color: Colors.white),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

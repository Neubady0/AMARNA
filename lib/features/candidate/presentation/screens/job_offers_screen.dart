import 'package:amarnamovil/data/local/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class JobOffersScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const JobOffersScreen({super.key, required this.user});

  @override
  State<JobOffersScreen> createState() => _JobOffersScreenState();
}

class _JobOffersScreenState extends State<JobOffersScreen> {
  late Future<List<Map<String, dynamic>>> _jobOffersFuture;

  @override
  void initState() {
    super.initState();
    _jobOffersFuture = _loadJobOffers();
  }

  Future<List<Map<String, dynamic>>> _loadJobOffers() async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getAllJobOffers();
  }

  Future<void> _applyToJob(int jobOfferId) async {
    final dbHelper = DatabaseHelper();
    final userId = widget.user['id'];

    final hasApplied = await dbHelper.hasUserApplied(userId, jobOfferId);

    if (hasApplied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ya has aplicado a esta oferta.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    await dbHelper.applyToJobOffer({
      'user_id': userId,
      'job_offer_id': jobOfferId,
      'application_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'status': 'Pendiente',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Aplicación enviada con éxito!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    setState(() {
      _jobOffersFuture = _loadJobOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Ofertas Laborales'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: AppTheme.primaryColor,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _jobOffersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.work_off_outlined, size: 60, color: Colors.grey.shade400),
                   const SizedBox(height: 16),
                   const Text('No hay ofertas disponibles por el momento.'),
                ],
              ),
            );
          } else {
            return ListView.separated(
              padding: const EdgeInsets.all(20.0),
              itemCount: snapshot.data!.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final offer = snapshot.data![index];
                return _buildJobCard(offer, index);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> offer, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business_center_outlined, color: AppTheme.secondaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer['title'] ?? 'Oferta sin título',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            offer['location'] ?? 'Remoto',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              offer['description'] ?? 'Sin descripción.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag('Full Time'),
                _buildTag('Senior'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _applyToJob(offer['id']),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Aplicar Ahora'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}


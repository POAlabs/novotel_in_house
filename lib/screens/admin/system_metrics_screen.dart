import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/usage_metrics_service.dart';

/// System Metrics Screen - Shows API usage and estimated costs
/// Only accessible to IT admins and System Admins
class SystemMetricsScreen extends StatefulWidget {
  const SystemMetricsScreen({super.key});

  @override
  State<SystemMetricsScreen> createState() => _SystemMetricsScreenState();
}

class _SystemMetricsScreenState extends State<SystemMetricsScreen> {
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kLightGrey = Color(0xFF94A3B8);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kBlue = Color(0xFF3B82F6);
  static const Color kPurple = Color(0xFF8B5CF6);
  static const Color kAmber = Color(0xFFF59E0B);

  final UsageMetricsService _metricsService = UsageMetricsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'System Metrics',
          style: GoogleFonts.inter(
            color: kDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<UsageMetrics>(
        stream: _metricsService.getCurrentMonthMetrics(),
        builder: (context, snapshot) {
          final metrics = snapshot.data ?? UsageMetrics(monthKey: 'Loading...');
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month header
                _buildMonthHeader(metrics),
                const SizedBox(height: 24),
                
                // Total cost card
                _buildTotalCostCard(metrics),
                const SizedBox(height: 24),
                
                // Service breakdown
                _buildSectionHeader('Service Breakdown'),
                const SizedBox(height: 12),
                
                // WhatsApp metrics
                _buildServiceCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'WhatsApp Messages',
                  subtitle: 'Whapi.cloud API (\$40/mo subscription)',
                  count: metrics.whatsAppMessages,
                  cost: metrics.whatsAppCost,
                  color: kGreen,
                  costPerUnit: '\$0.008/msg',
                ),
                const SizedBox(height: 12),
                
                // Firebase Firestore metrics
                _buildServiceCard(
                  icon: Icons.storage_outlined,
                  title: 'Firestore Operations',
                  subtitle: 'Reads: ${metrics.firestoreReads} • Writes: ${metrics.firestoreWrites}',
                  count: metrics.firestoreReads + metrics.firestoreWrites + metrics.firestoreDeletes,
                  cost: metrics.firestoreCost,
                  color: kAmber,
                  costPerUnit: 'Variable',
                ),
                const SizedBox(height: 12),
                
                // FCM metrics (free)
                _buildServiceCard(
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Firebase Cloud Messaging',
                  count: metrics.fcmNotifications,
                  cost: 0.0,
                  color: kBlue,
                  costPerUnit: 'Free',
                ),
                
                const SizedBox(height: 32),
                
                // WhatsApp logs section
                _buildSectionHeader('Recent WhatsApp Messages'),
                const SizedBox(height: 12),
                _buildWhatsAppLogs(),
                
                const SizedBox(height: 32),
                
                // Pricing info
                _buildPricingInfo(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthHeader(UsageMetrics metrics) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Period',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kGrey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              metrics.monthDisplayName,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: kDark,
              ),
            ),
          ],
        ),
        if (metrics.lastUpdated != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.sync, size: 14, color: kGreen),
                const SizedBox(width: 4),
                Text(
                  'Live',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kGreen,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // WhatsApp monthly subscription cost
  static const double kWhatsAppMonthlyCost = 40.0;

  Widget _buildTotalCostCard(UsageMetrics metrics) {
    // Calculate total including WhatsApp monthly subscription
    final totalWithWhatsApp = metrics.totalCost + kWhatsAppMonthlyCost;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kDark, kDark.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimated Monthly Cost',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${totalWithWhatsApp.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'USD',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Cost breakdown
          Text(
            'Includes \$40/mo WhatsApp subscription',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: kLightGrey,
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
    required double cost,
    required Color color,
    required String costPerUnit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: kGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                count.toString(),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kDark,
                ),
              ),
              Text(
                costPerUnit,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: kGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppLogs() {
    return StreamBuilder<List<WhatsAppLogEntry>>(
      stream: _metricsService.getCurrentMonthWhatsAppLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final logs = snapshot.data ?? [];
        
        if (logs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 32, color: kLightGrey),
                  const SizedBox(height: 8),
                  Text(
                    'No messages this month',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: kGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: logs.take(10).map((log) => _buildLogItem(log)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildLogItem(WhatsAppLogEntry log) {
    final timeStr = log.timestamp != null
        ? '${log.timestamp!.day}/${log.timestamp!.month} ${log.timestamp!.hour}:${log.timestamp!.minute.toString().padLeft(2, '0')}'
        : 'Unknown';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: kGreen,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.department,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kDark,
                  ),
                ),
                Text(
                  log.messageType.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: kGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${log.cost.toStringAsFixed(3)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kDark,
                ),
              ),
              Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: kLightGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: kBlue),
              const SizedBox(width: 8),
              Text(
                'Pricing Information',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPricingRow('WhatsApp Subscription', '\$40.00 per month'),
          _buildPricingRow('WhatsApp Messages', '\$0.008 per message'),
          _buildPricingRow('Firestore Reads', '\$0.06 per 100K'),
          _buildPricingRow('Firestore Writes', '\$0.18 per 100K'),
          _buildPricingRow('FCM Notifications', 'Free'),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String service, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            service,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: kDark,
            ),
          ),
          Text(
            price,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kDark,
            ),
          ),
        ],
      ),
    );
  }
}

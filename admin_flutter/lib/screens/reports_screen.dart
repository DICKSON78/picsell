import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/theme.dart';
import '../services/firestore_service.dart';
import '../services/pdf_report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  final PdfReportService _pdfService = PdfReportService();
  bool _isGeneratingPdf = false;
  bool _isLoading = true;

  String _selectedPeriod = 'This Week';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'This Year'];

  Map<String, dynamic> _reportData = {};
  List<Map<String, dynamic>> _topCustomers = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final period = _selectedPeriod.toLowerCase().replaceAll('this ', '');
      final stats = await _firestoreService.getDashboardStats(period: period);
      final customers = await _firestoreService.getTopCustomers();

      if (mounted) {
        setState(() {
          _reportData = stats;
          _topCustomers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // Error loading report
    }
  }

  String _formatAmount(dynamic amount) {
    double val = (amount as num?)?.toDouble() ?? 0.0;
    if (val >= 1000000) {
      return 'TZS ${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return 'TZS ${(val / 1000).toStringAsFixed(0)}K';
    }
    return 'TZS ${val.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.arrow_back, color: Colors.white)),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(child: Text('Reports & Analytics', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                          GestureDetector(
                            onTap: _generatePdfReport,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: _isGeneratingPdf ? Colors.white.withAlpha(30) : Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(12)),
                              child: _isGeneratingPdf
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.file_download_outlined, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/report-history'),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.history, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: _periods.map((period) {
                            final isSelected = _selectedPeriod == period;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () { setState(() => _selectedPeriod = period); _loadReportData(); },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                                  child: Text(period, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? AppTheme.primaryColor : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          if (_isLoading)
            _buildShimmerBody()
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Key Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('Period Revenue', _formatAmount(_reportData['periodRevenue']), Icons.attach_money, Colors.green, 0)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMetricCard('Total Users', '${_reportData['totalUsers']}', Icons.people, AppTheme.primaryColor, 0)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('Photos Done', '${_reportData['totalPhotos']}', Icons.photo_library, AppTheme.accentColor, 0)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMetricCard('Revenue Today', _formatAmount(_reportData['revenueToday']), Icons.stars, Colors.orange, 0)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trending Packages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 150,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: (_reportData['trendingPackages'] as List? ?? []).map((pkg) {
                            final val = ((pkg['value'] as num?) ?? 0).toDouble();
                            final height = (val / 10.0) * 120; // Simplified scale
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(height: height.clamp(5, 120), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.primaryColor, AppTheme.primaryColor.withAlpha(150)]), borderRadius: BorderRadius.circular(6))),
                                    const SizedBox(height: 8),
                                    Text(pkg['name'].toString().length > 3 ? pkg['name'].toString().substring(0, 3) : pkg['name'].toString(), style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Top Customers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          TextButton(onPressed: () => Navigator.pushNamed(context, '/customers'), child: const Text('View All')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._topCustomers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final customer = entry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(border: index < _topCustomers.length - 1 ? Border(bottom: BorderSide(color: Colors.grey[200]!)) : null),
                          child: Row(
                            children: [
                              Container(width: 32, height: 32, decoration: BoxDecoration(color: index < 3 ? [Colors.amber, Colors.grey[400], Colors.orange[300]][index] : Colors.grey[200], shape: BoxShape.circle), child: Center(child: Text('${index + 1}', style: TextStyle(color: index < 3 ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 14)))),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.w600)), Text('${customer['photos']} photos', style: TextStyle(color: Colors.grey[500], fontSize: 12))])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(_formatAmount(customer['spent']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)), Text('${customer['credits']} credits', style: TextStyle(color: Colors.grey[500], fontSize: 12))]),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildShimmerBody() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [Expanded(child: _buildShimmerCard()), const SizedBox(width: 12), Expanded(child: _buildShimmerCard())]),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: _buildShimmerCard()), const SizedBox(width: 12), Expanded(child: _buildShimmerCard())]),
            const SizedBox(height: 24),
            _buildShimmerCard(height: 200),
            const SizedBox(height: 24),
            _buildShimmerCard(height: 300),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard({double height = 100}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(height: height, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, double growth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _generatePdfReport() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final customers = await _firestoreService.getCustomers(limit: 1000);
      if (customers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No customer data available', style: GoogleFonts.poppins()), backgroundColor: AppTheme.warning));
          setState(() => _isGeneratingPdf = false);
        }
        return;
      }
      await _pdfService.generateDetailedReport(
        customers: customers,
        revenue: (_reportData['periodRevenue'] as num?)?.toDouble() ?? 0.0,
        apiTokens: (_reportData['apiTokenUsage'] as num?)?.toInt() ?? 0,
        trendingPackages: (_reportData['trendingPackages'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        period: _selectedPeriod,
      );
      
      // Save report history
      await _firestoreService.saveReport({
        'period': _selectedPeriod,
        'revenue': (_reportData['periodRevenue'] as num?)?.toDouble() ?? 0.0,
        'photos': (_reportData['totalPhotos'] as num?)?.toInt() ?? 0,
        'users': (_reportData['totalUsers'] as num?)?.toInt() ?? 0,
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Report generated and saved!'), backgroundColor: AppTheme.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }
}

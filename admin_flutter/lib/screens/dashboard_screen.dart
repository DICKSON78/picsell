import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/customers_provider.dart';
import '../services/pdf_report_service.dart';
import 'notifications_screen.dart';
import 'transactions_screen.dart';
import 'packages_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PdfReportService _pdfService = PdfReportService();
  final PageController _promoController = PageController();
  int _currentPromoIndex = 0;

  final List<Map<String, String>> _promoSlides = [
    {
      'title': 'AI Business Growth',
      'subtitle': 'Manage your photo processing studio efficiently.',
      'image': 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800',
    },
    {
      'title': 'Customer Engagement',
      'subtitle': 'Track your most active customers and their spending.',
      'image': 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=800',
    },
    {
      'title': 'Revenue Insights',
      'subtitle': 'Detailed reports to help you scale your business.',
      'image': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).loadStats();
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0).format(amount);
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = Provider.of<DashboardProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final customers = Provider.of<CustomersProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () => dashboard.loadStats(),
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          slivers: [
            _buildDynamicHero(auth, dashboard),

            // Stats Grid or Shimmer
            dashboard.isLoading
              ? _buildStatsShimmer()
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Total Users', '${dashboard.totalUsers}', Icons.people_rounded, AppTheme.primaryColor, '+${dashboard.newUsersToday} today')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('API Tokens Left', '${_formatNumber(dashboard.apiTokensRemaining)}', Icons.toll_rounded, AppTheme.accent, 'Used: ${_formatNumber(dashboard.apiTokensUsed)} / ${_formatNumber(dashboard.totalApiTokens)}')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: _buildStatCard('Revenue Today', _formatCurrency(dashboard.revenueToday), Icons.trending_up, AppTheme.accentGreen, 'Daily target'),
                        ),
                      ],
                    ),
                  ),
                ),

            // Quick Actions
            _buildQuickActions(context, dashboard, customers),

            // Chart Section
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: _buildTrendingChart(dashboard),
              ),
            ),

            // Recent Activity or Shimmer
            dashboard.isLoading
              ? _buildActivityShimmer()
              : _buildRecentActivitySection(dashboard),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, DashboardProvider dashboard, CustomersProvider customers) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildActionCard('Add Package', Icons.add_circle_rounded, AppTheme.primaryColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PackagesScreen()));
                })),
                const SizedBox(width: 12),
                Expanded(child: _buildActionCard('Download PDF', Icons.picture_as_pdf_rounded, AppTheme.accent, () async {
                   _showPdfLoadingDialog(context, dashboard, customers);
                })),
                const SizedBox(width: 12),
                Expanded(child: _buildActionCard('Transactions', Icons.receipt_long_rounded, AppTheme.accentGreen, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionsScreen()));
                })),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfLoadingDialog(BuildContext context, DashboardProvider dashboard, CustomersProvider customers) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _PdfLoadingDialog(
        onComplete: () async {
          if (customers.customers.isEmpty) await customers.loadCustomers();
          await _pdfService.generateDetailedReport(
            customers: customers.customers,
            revenue: dashboard.revenueMonth,
            apiTokens: dashboard.apiTokensUsed,
            trendingPackages: dashboard.trendingPackages,
            period: dashboard.currentPeriod,
            totalPhotosProcessed: dashboard.totalPhotos,
          );
        },
      ),
    );
  }


  Widget _buildDynamicHero(AuthProvider auth, DashboardProvider dashboard) {
    final adminName = auth.admin?.name ?? 'Admin';
    
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          SizedBox(
            height: 380,
            width: double.infinity,
            child: PageView.builder(
              controller: _promoController,
              onPageChanged: (index) => setState(() => _currentPromoIndex = index),
              itemCount: _promoSlides.length,
              itemBuilder: (context, index) {
                final slide = _promoSlides[index];
                return Image.network(
                  slide['image']!,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0, height: 280,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 0.7, 1.0],
                  colors: [
                    Colors.transparent,
                    AppTheme.primaryDark.withAlpha(100),
                    AppTheme.primaryDark.withAlpha(200),
                    AppTheme.backgroundColor,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                    ),
                    const Icon(Icons.security, color: Colors.white, size: 24),
                    GestureDetector(
                      onTap: () {
                         Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 130, left: 20, right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _promoSlides[_currentPromoIndex]['title']!,
                  style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  _promoSlides[_currentPromoIndex]['subtitle']!,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(_promoSlides.length, (index) => Container(
                    width: _currentPromoIndex == index ? 24 : 8, height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(color: _currentPromoIndex == index ? Colors.white : Colors.white24, borderRadius: BorderRadius.circular(4)),
                  )),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24), boxShadow: AppTheme.shadowLg, border: Border.all(color: AppTheme.border.withAlpha(50))),
              child: Row(
                children: [
                  Container(width: 50, height: 50, decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(30), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Month Revenue', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                        Flexible(
                          child: Text(
                            _formatCurrency(dashboard.revenueMonth),
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.text),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.accentGreen.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                    child: Text('Live', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentGreen)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingChart(DashboardProvider dashboard) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Sales Trend',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Revenue by month',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              _buildChartYearDropdown(dashboard),
            ],
          ),
          const SizedBox(height: 24),
          dashboard.monthlySales.isEmpty
            ? _buildNoDataState()
            : SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppTheme.border.withAlpha(80),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < dashboard.monthlySales.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  dashboard.monthlySales[value.toInt()]['name'].toString(),
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text('');
                            return Text(
                              '${(value / 1000).toStringAsFixed(0)}k',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.border, width: 1),
                        left: BorderSide(color: AppTheme.border, width: 1),
                      ),
                    ),
                    minX: 0,
                    maxX: 11,
                    minY: 0,
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          dashboard.monthlySales.length,
                          (index) => FlSpot(
                            index.toDouble(),
                            ((dashboard.monthlySales[index]['value'] as num?) ?? 0).toDouble(),
                          ),
                        ),
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: AppTheme.primaryColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: AppTheme.whiteColor,
                              strokeWidth: 2.5,
                              strokeColor: AppTheme.primaryColor,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withAlpha(80),
                              AppTheme.primaryColor.withAlpha(20),
                              AppTheme.primaryColor.withAlpha(0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => AppTheme.primaryDark,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            final idx = touchedSpot.x.toInt().clamp(0, dashboard.monthlySales.length - 1);
                            final monthData = dashboard.monthlySales[idx];
                            final monthName = monthData['name'];
                            final amount = touchedSpot.y;
                            return LineTooltipItem(
                              '$monthName\nTZS ${amount.toStringAsFixed(0)}',
                              GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList();
                        },
                      ),
                      handleBuiltInTouches: true,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildChartYearDropdown(DashboardProvider dashboard) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - index);

    return PopupMenuButton<int>(
      initialValue: dashboard.chartYear,
      onSelected: (year) => dashboard.setChartYear(year),
      itemBuilder: (context) {
        return years.map((year) {
          return PopupMenuItem<int>(
            value: year,
            child: Row(
              children: [
                if (year == dashboard.chartYear)
                  Icon(Icons.check, color: AppTheme.primaryColor, size: 18),
                if (year == dashboard.chartYear) const SizedBox(width: 8),
                Text(
                  year.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: year == dashboard.chartYear ? FontWeight.bold : FontWeight.normal,
                    color: year == dashboard.chartYear ? AppTheme.primaryColor : AppTheme.text,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dashboard.chartYear.toString(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return SizedBox(
      height: 150,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_rounded, color: Colors.grey, size: 40),
            const SizedBox(height: 8),
            Text('No data available', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      sliver: SliverToBoxAdapter(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            children: List.generate(3, (i) => Container(height: 70, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(DashboardProvider dashboard) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Activity', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('See All')),
              ],
            ),
            const SizedBox(height: 12),
            ...dashboard.activities.map((act) => _buildActivityItem(
              act['title'],
              act['subtitle'],
              _getIconForActivity(act['icon']),
              _getColorForActivity(act['color']),
              act['createdAt'],
            )),
          ],
        ),
      ),
    );
  }

  IconData _getIconForActivity(String iconName) {
    switch (iconName) {
      case 'person_add': return Icons.person_add_rounded;
      case 'payment': return Icons.payment_rounded;
      case 'auto_awesome': return Icons.auto_awesome;
      default: return Icons.info_outline;
    }
  }

  Color _getColorForActivity(String colorName) {
    switch (colorName) {
      case 'primary': return AppTheme.primaryColor;
      case 'success': return AppTheme.accentGreen;
      case 'accent': return AppTheme.accent;
      default: return Colors.grey;
    }
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color, dynamic timestamp) {
    final timeStr = timestamp is Timestamp ? DateFormat('HH:mm').format(timestamp.toDate()) : 'Now';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border.withAlpha(100))),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)), Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary))])),
          Text(timeStr, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: color.withAlpha(20), blurRadius: 15, offset: const Offset(0, 5))], 
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.text), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(8)), child: Text(subtitle, style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
        child: Column(
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withAlpha(150)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: color.withAlpha(50), blurRadius: 8, offset: const Offset(0, 4))]), child: Icon(icon, color: Colors.white, size: 24)),
            const SizedBox(height: 10),
            Text(title, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.text), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PdfLoadingDialog extends StatefulWidget {
  final Future<void> Function() onComplete;
  const _PdfLoadingDialog({required this.onComplete});

  @override
  State<_PdfLoadingDialog> createState() => _PdfLoadingDialogState();
}

class _PdfLoadingDialogState extends State<_PdfLoadingDialog> {
  double _progress = 0;
  String _statusText = 'Preparing your detailed report...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _handleGeneration();
  }

  void _handleGeneration() async {
    try {
      // Animate progress bar
      for (int i = 0; i <= 7; i++) {
        if (!mounted) return;
        setState(() => _progress = i / 10);
        await Future.delayed(const Duration(milliseconds: 150));
      }

      if (!mounted) return;
      setState(() => _statusText = 'Generating PDF document...');

      // Actual PDF generation
      await widget.onComplete();

      // Complete the progress
      if (!mounted) return;
      setState(() {
        _progress = 1.0;
        _statusText = 'PDF generated successfully!';
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // PDF generation failed
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _statusText = 'Failed to generate PDF. Please try again.';
      });
      // Auto-close after showing error
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          if (_hasError)
            const Icon(Icons.error_outline, color: Colors.red, size: 24)
          else if (_progress >= 1.0)
            const Icon(Icons.check_circle, color: Colors.green, size: 24)
          else
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
            ),
          const SizedBox(width: 12),
          Text(
            _hasError ? 'Error' : (_progress >= 1.0 ? 'Done!' : 'Generating PDF'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_statusText, style: GoogleFonts.poppins(fontSize: 13, color: _hasError ? Colors.red : AppTheme.textSecondary)),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              color: _hasError ? Colors.red : AppTheme.primaryColor,
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 8),
          Text('${(_progress * 100).toInt()}%', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

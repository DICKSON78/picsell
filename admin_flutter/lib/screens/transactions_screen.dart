import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/theme.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedType = 'All';

  final List<String> _filters = ['All', 'Today', 'This Week', 'This Month'];
  final List<String> _types = ['All', 'Purchase', 'Usage', 'Refund', 'Bonus'];

  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        _loadMoreTransactions();
      }
    });
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _transactions = [];
      _lastDocument = null;
      _hasMore = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _transactions = snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(10)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final more = snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
        if (mounted) setState(() => _transactions.addAll(more));
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Error loading more transactions: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  List<TransactionModel> get _filteredTransactions {
    return _transactions.where((tx) {
      final matchesSearch = tx.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _selectedType == 'All' || tx.typeString.toLowerCase() == _selectedType.toLowerCase();
      // Period filtering simplified for now as Firestore does filtering better
      return matchesSearch && matchesType;
    }).toList();
  }

  String _formatAmount(double amount) {
    return NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0).format(amount);
  }

  String _formatFullAmount(double? amount) {
    if (amount == null) return 'N/A';
    return NumberFormat.currency(symbol: 'TZS ', decimalDigits: 2).format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM, HH:mm').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'failed': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Hero Section
          SliverToBoxAdapter(
            child: Container(
              height: 230,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryDark,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            ),
                          ),
                          Text(
                            'Transaction History',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Stats
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Transactions',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_transactions.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Completed',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                '${_transactions.where((t) => t.status.toLowerCase() == 'completed').length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                '${_transactions.where((t) => t.status.toLowerCase() == 'pending').length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This Month',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                '${_transactions.where((t) => t.createdAt.month == DateTime.now().month).length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _types.map((type) {
                    final isSelected = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                                  )
                                : null,
                            color: isSelected ? null : AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected ? null : Border.all(color: AppTheme.border),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withAlpha(60),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            type,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isSelected ? AppTheme.whiteColor : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // List
          _isLoading 
            ? _buildShimmerList()
            : _filteredTransactions.isEmpty
              ? const SliverFillRemaining(child: Center(child: Text('No transactions found')))
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == _filteredTransactions.length) {
                           return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                        }
                        final tx = _filteredTransactions[index];
                        return _buildTransactionItem(tx);
                      },
                      childCount: _filteredTransactions.length + (_isLoadingMore ? 1 : 0),
                    ),
                  ),
                ),
           const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverToBoxAdapter(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            children: List.generate(10, (i) => Container(height: 80, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(tx.status).withAlpha(50),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showTransactionDetail(tx),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getTypeColor(tx.typeString).withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getTypeIcon(tx.typeString),
                                color: _getTypeColor(tx.typeString),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.id.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.text,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tx.userName ?? 'Customer',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        tx.typeString == 'usage' ? '-${tx.credits}' : '+${tx.credits}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: tx.typeString == 'usage' ? Colors.red : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(tx.status).withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tx.status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: _getStatusColor(tx.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(tx.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    tx.typeString.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetail(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Container(width: 64, height: 64, decoration: BoxDecoration(color: _getTypeColor(tx.typeString).withAlpha(30), shape: BoxShape.circle), child: Icon(_getTypeIcon(tx.typeString), color: _getTypeColor(tx.typeString), size: 32)),
            const SizedBox(height: 16),
            Text(tx.typeString == 'usage' ? '-${tx.credits} Credits' : '+${tx.credits} Credits', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: tx.typeString == 'usage' ? Colors.red : Colors.green)),
            if (tx.amount != null) Text(_formatAmount(tx.amount!), style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: _getStatusColor(tx.status).withAlpha(30), borderRadius: BorderRadius.circular(20)), child: Text(tx.status.toUpperCase(), style: TextStyle(color: _getStatusColor(tx.status), fontWeight: FontWeight.bold, fontSize: 12))),
            const SizedBox(height: 24),
            _buildDetailRow('Transaction ID', tx.id.toUpperCase()),
            _buildDetailRow('Customer', tx.userName ?? 'N/A'),
            _buildDetailRow('Type', tx.typeString.toUpperCase()),
            if (tx.paymentMethod != null) _buildDetailRow('Payment Method', tx.paymentMethod!),
            _buildDetailRow('Date', _formatDate(tx.createdAt)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _printReceipt(tx);
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Print Receipt'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'purchase': return Colors.green;
      case 'usage': return AppTheme.primaryColor;
      case 'bonus': return AppTheme.accentColor;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'purchase': return Icons.add_circle;
      case 'usage': return Icons.remove_circle;
      case 'bonus': return Icons.card_giftcard;
      default: return Icons.swap_horiz;
    }
  }

  Future<void> _printReceipt(TransactionModel tx) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'PICSELL',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Payment Receipt',
                        style: const pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Manage It, Grow It',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),

                // Transaction Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfRow('Transaction ID', tx.id.toUpperCase(), bold: true),
                      pw.Divider(color: PdfColors.grey300),
                      _buildPdfRow('Customer', tx.userName ?? 'N/A'),
                      _buildPdfRow('Date', DateFormat('dd MMMM yyyy, HH:mm').format(tx.createdAt)),
                      _buildPdfRow('Type', tx.typeString.toUpperCase()),
                      if (tx.paymentMethod != null)
                        _buildPdfRow('Payment Method', tx.paymentMethod!),
                      _buildPdfRow('Status', tx.status.toUpperCase()),
                      pw.Divider(color: PdfColors.grey300),
                      _buildPdfRow(
                        'Credits',
                        tx.typeString == 'usage' ? '-${tx.credits}' : '+${tx.credits}',
                        valueColor: tx.typeString == 'usage' ? PdfColors.red : PdfColors.green,
                      ),
                      if (tx.amount != null)
                        _buildPdfRow(
                          'Amount',
                          _formatFullAmount(tx.amount),
                          bold: true,
                          valueColor: PdfColors.blue,
                        ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 40),

                // QR Code
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Scan for verification',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: 'PICSELL-TX-${tx.id.toUpperCase()}-${tx.createdAt.millisecondsSinceEpoch}',
                        width: 150,
                        height: 150,
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        tx.id.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Thank you for using PicSell',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'This is a computer-generated receipt',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey500,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated on ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Print or share the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfRow(
    String label,
    String value, {
    bool bold = false,
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: valueColor ?? PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }
}

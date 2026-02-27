import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/customer_model.dart';

class PdfReportService {
  // Generate detailed business report PDF
  Future<void> generateDetailedReport({
    required List<CustomerModel> customers,
    required double revenue,
    required int apiTokens,
    required List<Map<String, dynamic>> trendingPackages,
    required String period,
    int totalPhotosProcessed = 0,
    int totalCreditsGiven = 0,
    double totalBonusValue = 0,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('HH:mm');

    // Calculate totals
    final totalCustomers = customers.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PicSell Studio',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.purple700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Customer Report',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated: ${dateFormat.format(now)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Time: ${timeFormat.format(now)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Summary Cards - Financial Overview
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryCard(
                'Revenue ($period)',
                'TZS ${_formatPrice(revenue.toInt())}',
                PdfColors.green,
              ),
              _buildSummaryCard(
                'Photos Processed',
                _formatNumber(totalPhotosProcessed),
                PdfColors.blue,
              ),
              _buildSummaryCard(
                'API Tokens Used',
                _formatNumber(apiTokens),
                PdfColors.orange,
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Financial Breakdown
          pw.Text(
            'Financial Breakdown',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildFinancialRow('Revenue from Photos (800 TZS/photo)', 'TZS ${_formatPrice(revenue.toInt())}', PdfColors.green),
                pw.SizedBox(height: 8),
                _buildFinancialRow('Total Credits Given as Bonus', '$totalCreditsGiven credits', PdfColors.blue),
                pw.SizedBox(height: 8),
                _buildFinancialRow('Bonus Value (400 TZS/credit)', 'TZS ${_formatPrice(totalBonusValue.toInt())}', PdfColors.orange),
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.SizedBox(height: 8),
                _buildFinancialRow('Net Revenue', 'TZS ${_formatPrice((revenue - totalBonusValue).toInt())}', PdfColors.purple, isBold: true),
              ],
            ),
          ),

          pw.SizedBox(height: 30),

          // Package Performance
          pw.Text(
            'Package Performance',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Package Name', isHeader: true),
                  _buildTableCell('Sales Count', isHeader: true),
                ],
              ),
              ...trendingPackages.map((p) => pw.TableRow(
                children: [
                  _buildTableCell(p['name']),
                  _buildTableCell(p['value'].toInt().toString()),
                ],
              )),
            ],
          ),

          pw.SizedBox(height: 30),

          // Table Header
          pw.Text(
            'Customer Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          // Customer Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.purple50,
                ),
                children: [
                  _buildTableCell('Name', isHeader: true),
                  _buildTableCell('Email', isHeader: true),
                  _buildTableCell('Credits', isHeader: true),
                  _buildTableCell('Spent (TZS)', isHeader: true),
                  _buildTableCell('Status', isHeader: true),
                ],
              ),
              // Data Rows
              ...customers.map((customer) {
                return pw.TableRow(
                  children: [
                    _buildTableCell(customer.name),
                    _buildTableCell(customer.email),
                    _buildTableCell(customer.credits.toString()),
                    _buildTableCell(_formatPrice(customer.totalSpent.toInt())),
                    _buildTableCell(
                      customer.isActive ? 'Active' : 'Inactive',
                      color: customer.isActive ? PdfColors.green : PdfColors.red,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),

          pw.SizedBox(height: 30),

          // Footer
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'PicSell Studio - Admin Report',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Share/Download PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'customer_report_${dateFormat.format(now)}.pdf',
    );
  }

  pw.Widget _buildSummaryCard(String label, String value, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.purple900 : PdfColors.black),
        ),
      ),
    );
  }

  pw.Widget _buildFinancialRow(String label, String value, PdfColor color, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.grey800,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatPrice(int price) {
    final String priceStr = price.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      buffer.write(priceStr[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(',');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/bill.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'database_service.dart';

class PDFService {
  static final PDFService _instance = PDFService._internal();
  factory PDFService() => _instance;
  PDFService._internal();

  final DatabaseService _databaseService = DatabaseService();

  Future<Uint8List> generateBillPDF(Bill bill, List<BillItem> billItems) async {
    final pdf = pw.Document();

    // Get customer details
    final customer = await _databaseService.getCustomerById(bill.customerId);

    // Get product details for each bill item
    final List<Map<String, dynamic>> productDetails = [];
    for (final item in billItems) {
      final product = await _databaseService.getProductById(item.productId);
      final category = product != null
          ? await _databaseService.getCategoryById(product.categoryId)
          : null;
      productDetails.add({
        'product': product,
        'category': category,
        'item': item,
      });
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              pw.SizedBox(height: 20),

              // Bill Information
              _buildBillInfo(bill),
              pw.SizedBox(height: 20),

              // Customer Information
              if (customer != null) _buildCustomerInfo(customer),
              pw.SizedBox(height: 20),

              // Items Table
              _buildItemsTable(productDetails),
              pw.SizedBox(height: 20),

              // Totals
              _buildTotals(bill),
              pw.SizedBox(height: 30),

              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'BALAJI IMITATION JEWELRY',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Admin Management System',
            style: pw.TextStyle(fontSize: 16, color: PdfColors.blue700),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Your Trusted Jewelry Partner',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.blue600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBillInfo(Bill bill) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Bill Number: ${bill.billNumber}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Date: ${_formatDate(bill.billDate)}',
              style: pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Status: ${bill.paymentStatus.toUpperCase()}',
              style: pw.TextStyle(
                fontSize: 12,
                color: bill.paymentStatus == 'paid'
                    ? PdfColors.green
                    : PdfColors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCustomerInfo(Customer customer) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Customer Details',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Name: ${customer.name}', style: pw.TextStyle(fontSize: 12)),
          pw.Text(
            'Email: ${customer.email}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Phone: ${customer.phoneNumber}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Address: ${customer.address}',
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(List<Map<String, dynamic>> productDetails) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('S.No', isHeader: true),
            _buildTableCell('Product', isHeader: true),
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Qty', isHeader: true),
            _buildTableCell('Price', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Items
        ...productDetails.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final data = entry.value;
          final product = data['product'] as Product?;
          final category = data['category'] as Category?;
          final item = data['item'] as BillItem;

          return pw.TableRow(
            children: [
              _buildTableCell('$index'),
              _buildTableCell(product?.name ?? 'N/A'),
              _buildTableCell(category?.name ?? 'N/A'),
              _buildTableCell('${item.quantity}'),
              _buildTableCell('₹${item.unitPrice.toStringAsFixed(2)}'),
              _buildTableCell('₹${item.totalPrice.toStringAsFixed(2)}'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildTotals(Bill bill) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 12)),
              pw.Text(
                '₹${bill.subtotal.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Tax:', style: pw.TextStyle(fontSize: 12)),
              pw.Text(
                '₹${bill.taxAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Discount:', style: pw.TextStyle(fontSize: 12)),
              pw.Text(
                '-₹${bill.discountAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.Divider(color: PdfColors.grey400),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Amount:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '₹${bill.totalAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'For any queries, please contact us.',
            style: pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> printBill(Bill bill, List<BillItem> billItems) async {
    final pdfBytes = await generateBillPDF(bill, billItems);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  Future<String> saveBillPDF(Bill bill, List<BillItem> billItems) async {
    final pdfBytes = await generateBillPDF(bill, billItems);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/bill_${bill.billNumber}.pdf');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }
}

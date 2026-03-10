import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:open_filex/open_filex.dart';
import '../models/transaction_model.dart';

class ExportService {
  static final ExportService instance = ExportService._init();
  ExportService._init();

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Future<String> _getExportDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  String _safeFileName(String prefix, String ext) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${prefix}_$timestamp.$ext';
  }

  // === PDF Export ===
  Future<void> exportPdf({
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in transactions) {
      if (t.type == 'income') {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }
    final balance = totalIncome - totalExpense;

    final dateRange =
        '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(dateRange, context),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Summary
          _buildPdfSummary(totalIncome, totalExpense, balance),
          pw.SizedBox(height: 20),

          // Transaction table
          if (transactions.isNotEmpty) _buildPdfTable(transactions),
          if (transactions.isEmpty)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Text(
                  'Tidak ada transaksi pada periode ini',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final exportDir = await _getExportDir();
    final fileName = _safeFileName('Laporan_Refinance', 'pdf');
    final file = File('$exportDir/$fileName');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  pw.Widget _buildPdfHeader(String dateRange, pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Refinance#',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.Text(
              'Laporan Keuangan',
              style: pw.TextStyle(
                fontSize: 14,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Periode: $dateRange',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.Divider(thickness: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Diekspor: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
        pw.Text(
          'Halaman ${context.pageNumber}/${context.pagesCount}',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ],
    );
  }

  pw.Widget _buildPdfSummary(
      double income, double expense, double balance) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildPdfSummaryItem(
              'Pemasukan', income, PdfColors.green700),
          _buildPdfSummaryItem(
              'Pengeluaran', expense, PdfColors.red700),
          _buildPdfSummaryItem(
            'Saldo',
            balance,
            balance >= 0 ? PdfColors.green800 : PdfColors.red800,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSummaryItem(
      String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _currencyFormat.format(amount),
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfTable(List<Transaction> transactions) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerLeft,
      },
      headers: ['No', 'Tanggal', 'Kategori', 'Jumlah', 'Keterangan'],
      data: transactions.asMap().entries.map((entry) {
        final i = entry.key;
        final t = entry.value;
        return [
          '${i + 1}',
          DateFormat('dd/MM/yyyy').format(DateTime.parse(t.date)),
          t.category,
          '${t.type == 'income' ? '+' : '-'} ${_currencyFormat.format(t.amount)}',
          t.description,
        ];
      }).toList(),
    );
  }

  // === Excel Export ===
  Future<void> exportExcel({
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final excel = xl.Excel.createExcel();

    // Rename default sheet
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.rename(defaultSheet, 'Laporan');
    }
    final sheet = excel['Laporan'];

    final dateRange =
        '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}';

    // Title style
    final titleStyle = xl.CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: xl.ExcelColor.fromHexString('#1B5E20'),
    );
    final headerStyle = xl.CellStyle(
      bold: true,
      fontSize: 10,
      backgroundColorHex: xl.ExcelColor.fromHexString('#1B5E20'),
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: xl.HorizontalAlign.Center,
    );
    final incomeStyle = xl.CellStyle(
      fontColorHex: xl.ExcelColor.fromHexString('#2E7D32'),
    );
    final expenseStyle = xl.CellStyle(
      fontColorHex: xl.ExcelColor.fromHexString('#C62828'),
    );
    final summaryLabelStyle = xl.CellStyle(
      bold: true,
      fontSize: 10,
    );
    final summaryIncomeStyle = xl.CellStyle(
      bold: true,
      fontColorHex: xl.ExcelColor.fromHexString('#2E7D32'),
    );
    final summaryExpenseStyle = xl.CellStyle(
      bold: true,
      fontColorHex: xl.ExcelColor.fromHexString('#C62828'),
    );

    // Title
    var cell = sheet.cell(xl.CellIndex.indexByString('A1'));
    cell.value = xl.TextCellValue('Laporan Keuangan - Refinance#');
    cell.cellStyle = titleStyle;

    cell = sheet.cell(xl.CellIndex.indexByString('A2'));
    cell.value = xl.TextCellValue('Periode: $dateRange');

    cell = sheet.cell(xl.CellIndex.indexByString('A3'));
    cell.value = xl.TextCellValue(
        'Diekspor: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}');

    // Headers at row 5
    final headers = ['No', 'Tanggal', 'Tipe', 'Kategori', 'Jumlah', 'Keterangan'];
    for (var i = 0; i < headers.length; i++) {
      final headerCell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4),
      );
      headerCell.value = xl.TextCellValue(headers[i]);
      headerCell.cellStyle = headerStyle;
    }

    // Set column widths
    sheet.setColumnWidth(0, 6);   // No
    sheet.setColumnWidth(1, 14);  // Tanggal
    sheet.setColumnWidth(2, 12);  // Tipe
    sheet.setColumnWidth(3, 18);  // Kategori
    sheet.setColumnWidth(4, 20);  // Jumlah
    sheet.setColumnWidth(5, 30);  // Keterangan

    // Data rows
    double totalIncome = 0;
    double totalExpense = 0;

    for (var i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      final row = i + 5;

      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = xl.IntCellValue(i + 1);

      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = xl.TextCellValue(
              DateFormat('dd/MM/yyyy').format(DateTime.parse(t.date)));

      final typeCell = sheet.cell(
          xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
      typeCell.value = xl.TextCellValue(
          t.type == 'income' ? 'Pemasukan' : 'Pengeluaran');
      typeCell.cellStyle =
          t.type == 'income' ? incomeStyle : expenseStyle;

      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = xl.TextCellValue(t.category);

      final amountCell = sheet.cell(
          xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));
      amountCell.value = xl.DoubleCellValue(t.amount);
      amountCell.cellStyle =
          t.type == 'income' ? incomeStyle : expenseStyle;

      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = xl.TextCellValue(t.description);

      if (t.type == 'income') {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    // Summary rows
    final summaryRow = transactions.length + 6;

    var labelCell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRow));
    labelCell.value = xl.TextCellValue('Total Pemasukan:');
    labelCell.cellStyle = summaryLabelStyle;
    var valCell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryRow));
    valCell.value = xl.DoubleCellValue(totalIncome);
    valCell.cellStyle = summaryIncomeStyle;

    labelCell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRow + 1));
    labelCell.value = xl.TextCellValue('Total Pengeluaran:');
    labelCell.cellStyle = summaryLabelStyle;
    valCell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryRow + 1));
    valCell.value = xl.DoubleCellValue(totalExpense);
    valCell.cellStyle = summaryExpenseStyle;

    labelCell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRow + 2));
    labelCell.value = xl.TextCellValue('Saldo:');
    labelCell.cellStyle = summaryLabelStyle;
    final balance = totalIncome - totalExpense;
    valCell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryRow + 2));
    valCell.value = xl.DoubleCellValue(balance);
    valCell.cellStyle = balance >= 0 ? summaryIncomeStyle : summaryExpenseStyle;

    final exportDir = await _getExportDir();
    final fileName = _safeFileName('Laporan_Refinance', 'xlsx');
    final file = File('$exportDir/$fileName');
    await file.writeAsBytes(excel.encode()!);
    await OpenFilex.open(file.path);
  }
}

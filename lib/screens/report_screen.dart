import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  List<Transaction> _transactions = [];
  Map<String, double> _summary = {
    'income': 0.0,
    'expense': 0.0,
    'balance': 0.0,
  };
  Map<String, double> _incomeByCategory = {};
  Map<String, double> _expenseByCategory = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    // Get all transactions
    final allTransactions =
        await TransactionService.instance.getTransactions();

    // Filter by date range
    final filteredTransactions = allTransactions.where((transaction) {
      final transDate = DateTime.parse(transaction.date);
      return transDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          transDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    // Calculate summary
    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> incomeCategories = {};
    Map<String, double> expenseCategories = {};

    for (var transaction in filteredTransactions) {
      if (transaction.type == 'income') {
        totalIncome += transaction.amount;
        incomeCategories[transaction.category] =
            (incomeCategories[transaction.category] ?? 0) + transaction.amount;
      } else {
        totalExpense += transaction.amount;
        expenseCategories[transaction.category] =
            (expenseCategories[transaction.category] ?? 0) + transaction.amount;
      }
    }

    setState(() {
      _transactions = filteredTransactions;
      _summary = {
        'income': totalIncome,
        'expense': totalExpense,
        'balance': totalIncome - totalExpense,
      };
      _incomeByCategory = incomeCategories;
      _expenseByCategory = expenseCategories;
      _isLoading = false;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReport();
    }
  }

  void _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, 1);
        _endDate = DateTime(picked.year, picked.month + 1, 0);
      });
      _loadReport();
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonth,
            tooltip: 'Pilih Bulan',
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Pilih Rentang Tanggal',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date range card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Periode',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary cards
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_downward,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Pemasukan',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatCurrency(_summary['income']!),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            color: Colors.red.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Pengeluaran',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatCurrency(_summary['expense']!),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Balance card
                    Card(
                      color: _summary['balance']! >= 0
                          ? Colors.blue.shade50
                          : Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Saldo Periode Ini',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatCurrency(_summary['balance']!),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _summary['balance']! >= 0
                                    ? Colors.blue
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Income by category
                    if (_incomeByCategory.isNotEmpty) ...[
                      Text(
                        'Pemasukan per Kategori',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: _incomeByCategory.entries.map((entry) {
                              final percentage =
                                  (entry.value / _summary['income']!) * 100;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _formatCurrency(entry.value),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: percentage / 100,
                                      backgroundColor: Colors.grey.shade200,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(height: 2),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Expense by category
                    if (_expenseByCategory.isNotEmpty) ...[
                      Text(
                        'Pengeluaran per Kategori',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: _expenseByCategory.entries.map((entry) {
                              final percentage =
                                  (entry.value / _summary['expense']!) * 100;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _formatCurrency(entry.value),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: percentage / 100,
                                      backgroundColor: Colors.grey.shade200,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 2),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Transaction list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detail Transaksi',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          '${_transactions.length} transaksi',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _transactions.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Tidak ada transaksi\npada periode ini',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _transactions[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        transaction.type == 'income'
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                    child: Icon(
                                      transaction.type == 'income'
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: transaction.type == 'income'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  title: Text(transaction.category),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (transaction.imagePath != null)
                                        const Row(
                                          children: [
                                            Icon(Icons.image,
                                                size: 12, color: Colors.grey),
                                            SizedBox(width: 4),
                                            Text(
                                              'Ada foto',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatCurrency(transaction.amount),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: transaction.type == 'income'
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('dd MMM').format(
                                            DateTime.parse(transaction.date)),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    _showTransactionDetail(transaction);
                                  },
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showTransactionDetail(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Transaksi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    transaction.type == 'income'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: transaction.type == 'income'
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    transaction.type == 'income' ? 'Pemasukan' : 'Pengeluaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: transaction.type == 'income'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Jumlah', _formatCurrency(transaction.amount)),
              _buildDetailRow('Kategori', transaction.category),
              _buildDetailRow(
                'Tanggal',
                DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                    .format(DateTime.parse(transaction.date)),
              ),
              _buildDetailRow('Deskripsi', transaction.description),
              if (transaction.imagePath != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Foto',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(transaction.imagePath!),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import '../widgets/encrypted_image.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
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
  late TabController _tabController;

  static const List<Color> _chartColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFE91E63),
    Color(0xFF607D8B),
    Color(0xFFFFEB3B),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    final allTransactions =
        await TransactionService.instance.getTransactions();

    final filteredTransactions = allTransactions.where((transaction) {
      final transDate = DateTime.parse(transaction.date);
      return transDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          transDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

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

  String _formatCompact(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return _formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, size: 22),
            onPressed: _selectMonth,
            tooltip: 'Pilih Bulan',
          ),
          IconButton(
            icon: const Icon(Icons.date_range_outlined, size: 22),
            onPressed: _selectDateRange,
            tooltip: 'Pilih Rentang',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Period indicator
                    Container(
                      width: double.infinity,
                      color: cardColor,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Text(
                        '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Summary overview
                    _buildSummarySection(),

                    const SizedBox(height: 8),

                    // Chart section with tabs
                    _buildChartSection(),

                    const SizedBox(height: 8),

                    // Transaction list
                    _buildTransactionSection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummarySection() {
    final balance = _summary['balance']!;
    final isPositive = balance >= 0;

    return Container(
      color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Balance
          Text(
            _formatCurrency(balance),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Saldo Periode',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),

          // Income & Expense row
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Pemasukan',
                  _summary['income']!,
                  const Color(0xFF4CAF50),
                  Icons.south_west_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: Colors.grey.shade200,
              ),
              Expanded(
                child: _buildMiniStat(
                  'Pengeluaran',
                  _summary['expense']!,
                  const Color(0xFFE53935),
                  Icons.north_east_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double amount, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    final hasIncome = _incomeByCategory.isNotEmpty;
    final hasExpense = _expenseByCategory.isNotEmpty;

    if (!hasIncome && !hasExpense) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
      child: Column(
        children: [
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.grey.shade200,
            tabs: const [
              Tab(text: 'Pemasukan'),
              Tab(text: 'Pengeluaran'),
            ],
          ),

          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [
                hasIncome
                    ? _buildDonutChart(
                        _incomeByCategory, _summary['income']!, true)
                    : _buildEmptyChart('Belum ada pemasukan'),
                hasExpense
                    ? _buildDonutChart(
                        _expenseByCategory, _summary['expense']!, false)
                    : _buildEmptyChart('Belum ada pengeluaran'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(
      Map<String, double> data, double total, bool isIncome) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Donut chart
          Expanded(
            flex: 5,
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: entries.asMap().entries.map((mapEntry) {
                    final index = mapEntry.key;
                    final entry = mapEntry.value;
                    final percentage = (entry.value / total) * 100;
                    return PieChartSectionData(
                      color: _chartColors[index % _chartColors.length],
                      value: entry.value,
                      title: '${percentage.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      radius: 45,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Legend
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((mapEntry) {
                final index = mapEntry.key;
                final entry = mapEntry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _chartColors[index % _chartColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatCompact(entry.value),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSection() {
    return Container(
      color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_transactions.length} transaksi',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          if (_transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada transaksi',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 68,
                color: Colors.grey.shade100,
              ),
              itemBuilder: (context, index) {
                final t = _transactions[index];
                final isIncome = t.type == 'income';
                return InkWell(
                  onTap: () => _showTransactionDetail(t),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isIncome
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isIncome
                                ? Icons.south_west_rounded
                                : Icons.north_east_rounded,
                            size: 18,
                            color: isIncome
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFE53935),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.category,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd MMM yyyy')
                                    .format(DateTime.parse(t.date)),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isIncome ? '+' : '-'} ${_formatCurrency(t.amount)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isIncome
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showTransactionDetail(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Amount
            Center(
              child: Text(
                _formatCurrency(transaction.amount),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: transaction.type == 'income'
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFE53935),
                ),
              ),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: transaction.type == 'income'
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  transaction.type == 'income' ? 'Pemasukan' : 'Pengeluaran',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: transaction.type == 'income'
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE53935),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),

            _buildDetailItem(
                Icons.category_outlined, 'Kategori', transaction.category),
            _buildDetailItem(
              Icons.calendar_today_outlined,
              'Tanggal',
              DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                  .format(DateTime.parse(transaction.date)),
            ),
            _buildDetailItem(Icons.notes_outlined, 'Deskripsi',
                transaction.description),

            if (transaction.imagePath != null &&
                transaction.imagePath!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: EncryptedImage(
                  imagePath: transaction.imagePath!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/pin_service.dart';
import '../services/theme_service.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import 'add_transaction_screen.dart';
import 'transaction_list_screen.dart';
import 'report_screen.dart';
import 'pin_entry_screen.dart';
import 'edit_transaction_screen.dart';
import '../widgets/encrypted_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = '';
  Map<String, double> _financialSummary = {
    'income': 0.0,
    'expense': 0.0,
    'balance': 0.0,
  };
  List<Transaction> _recentTransactions = [];
  bool _isLoading = true;
  bool _isBalanceVisible = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final username = await PinService.instance.getUsername();
    final summary =
        await TransactionService.instance.getFinancialSummary();
    final transactions =
        await TransactionService.instance.getTransactions();

    setState(() {
      _username = username;
      _financialSummary = summary;
      _recentTransactions = transactions.take(5).toList();
      _isLoading = false;
    });
  }

  Future<void> _lockApp() async {
    final isBiometricAvailable =
        await PinService.instance.isBiometricAvailable();
    final isFingerprintEnabled =
        await PinService.instance.isFingerprintEnabled();

    if (!mounted) return;

    bool fpEnabled = isFingerprintEnabled;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Konfirmasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Kunci aplikasi?'),
              if (isBiometricAvailable) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sidik Jari',
                      style: TextStyle(fontSize: 14)),
                  secondary: const Icon(Icons.fingerprint, size: 22),
                  value: fpEnabled,
                  onChanged: (value) {
                    setDialogState(() => fpEnabled = value);
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kunci'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await PinService.instance.setFingerprintEnabled(fpEnabled);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PinEntryScreen()),
      );
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

  Future<void> _showTransactionDetail(Transaction transaction) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: transaction.type == 'income'
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            transaction.type == 'income'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: transaction.type == 'income'
                                ? Colors.green
                                : Colors.red,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.type == 'income'
                                    ? 'Pemasukan'
                                    : 'Pengeluaran',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatCurrency(transaction.amount),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: transaction.type == 'income'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Category
                    Text(
                      'Kategori',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      transaction.category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Deskripsi',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      transaction.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),

                    // Date
                    Text(
                      'Tanggal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                          .format(DateTime.parse(transaction.date)),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),

                    // Image
                    if (transaction.imagePath != null &&
                        transaction.imagePath!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Foto',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: EncryptedImage(
                              imagePath: transaction.imagePath!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditTransactionScreen(
                                    transaction: transaction,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _loadData();
                              }
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteTransaction(transaction);
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Hapus'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await TransactionService.instance
          .deleteTransaction(transaction.id!);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(
              ThemeService.instance.isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              ThemeService.instance.toggleTheme();
            },
            tooltip: 'Ganti Tema',
          ),
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportScreen()),
              );
              _loadData();
            },
            tooltip: 'Laporan',
          ),
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: _lockApp,
            tooltip: 'Kunci',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    Text(
                      'Halo, $_username!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),

                    // Balance card
                    Card(
                      elevation: 4,
                      color: Theme.of(context).primaryColor,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Saldo',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isBalanceVisible = !_isBalanceVisible;
                                    });
                                  },
                                  child: Icon(
                                    _isBalanceVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isBalanceVisible
                                  ? _formatCurrency(_financialSummary['balance']!)
                                  : 'Rp ***',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Income
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.arrow_downward,
                                            color: Colors.greenAccent,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Pemasukan',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatCurrency(
                                            _financialSummary['income']!),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Expense
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.arrow_upward,
                                            color: Colors.redAccent,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Pengeluaran',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatCurrency(
                                            _financialSummary['expense']!),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
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
                    ),
                    const SizedBox(height: 24),

                    // Quick actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddTransactionScreen(
                                    type: 'income',
                                  ),
                                ),
                              );
                              _loadData();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Pemasukan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddTransactionScreen(
                                    type: 'expense',
                                  ),
                                ),
                              );
                              _loadData();
                            },
                            icon: const Icon(Icons.remove),
                            label: const Text('Pengeluaran'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaksi Terakhir',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TransactionListScreen(),
                              ),
                            );
                            _loadData();
                          },
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Transaction list
                    _recentTransactions.isEmpty
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
                                      'Belum ada transaksi',
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
                            itemCount: _recentTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _recentTransactions[index];
                              return Card(
                                child: ListTile(
                                  onTap: () => _showTransactionDetail(transaction),
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
                                  subtitle: Text(
                                    transaction.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                        DateFormat('dd MMM yyyy')
                                            .format(DateTime.parse(transaction.date)),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
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
}

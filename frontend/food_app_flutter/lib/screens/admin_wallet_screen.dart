import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdminWalletScreen extends StatefulWidget {
  const AdminWalletScreen({super.key});

  @override
  State<AdminWalletScreen> createState() => _AdminWalletScreenState();
}

class _AdminWalletScreenState extends State<AdminWalletScreen> {
  double _balance = 0.0;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWalletInfo();
  }

  Future<void> _loadWalletInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String historyString = prefs.getString('admin_wallet_history') ?? '[]';
    
    setState(() {
      _balance = prefs.getDouble('admin_wallet_balance') ?? 0.0;
      try {
        _transactions = jsonDecode(historyString);
      } catch (e) {
        _transactions = [];
      }
    });
  }

  Future<void> _withdrawFunds() async {
    if (_balance <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    
    // Create withdrawal record
    final newTransaction = {
      'title': 'Withdrawal to Bank Account',
      'amount': -_balance,
      'date': DateTime.now().toString(),
      'type': 'debit',
      'method': 'NEFT/IMPS'
    };

    _transactions.insert(0, newTransaction); // Add to top
    
    // Clear balance and update history
    await prefs.setDouble('admin_wallet_balance', 0.0);
    await prefs.setString('admin_wallet_history', jsonEncode(_transactions));

    setState(() {
      _balance = 0.0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal request initiated successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Admin Wallet', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: Column(
        children: [
          _buildBalanceCard(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _showReceivePaymentBottomSheet,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Show Payment QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                backgroundColor: Colors.white,
                foregroundColor: Colors.green.shade800,
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.green.shade600, width: 1.5)),
              ),
            ),
          ),
          Expanded(
            child: _buildTransactionHistory(),
          ),
        ],
      ),
    );
  }

  void _showReceivePaymentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Receive Payments', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Show this QR to customers to receive payments directly to your wallet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, spreadRadius: 5)],
                  border: Border.all(color: Colors.grey.shade200, width: 2)
                ),
                child: const Icon(Icons.qr_code_2, size: 180, color: Colors.black87),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _simulateIncomingPayment(150.0);
                  },
                  icon: const Icon(Icons.touch_app),
                  label: const Text('Simulate ₹150 Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  Future<void> _simulateIncomingPayment(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    
    final newTransaction = {
      'title': 'Payment Received via QR',
      'amount': amount,
      'date': DateTime.now().toString(),
      'type': 'credit',
      'method': 'App Scanner'
    };

    _transactions.insert(0, newTransaction);
    _balance += amount;
    
    await prefs.setDouble('admin_wallet_balance', _balance);
    await prefs.setString('admin_wallet_history', jsonEncode(_transactions));

    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Received ₹$amount via QR code! 🎉'), backgroundColor: Colors.green),
      );
    }
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 16)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹ ${_balance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _balance > 0 ? _withdrawFunds : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green.shade800,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Withdraw Funds to Bank', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Recent Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text("No transactions yet.", style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _transactions.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final txn = _transactions[index];
                      final isDebit = txn['type'] == 'debit';
                      final amount = txn['amount'] as double ?? 0.0;
                      final dateString = txn['date'] ?? '';
                      final method = txn['method'] ?? 'Unknown';

                      String formattedDate = "Recently";
                      if (dateString.isNotEmpty) {
                        try {
                           final dt = DateTime.parse(dateString);
                           formattedDate = "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute}";
                        } catch(e) {}
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDebit ? Colors.red.shade100 : Colors.green.shade100,
                          child: Icon(
                            isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isDebit ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(txn['title'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$formattedDate | via $method', style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          '${isDebit ? '' : '+'}₹${amount.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isDebit ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}

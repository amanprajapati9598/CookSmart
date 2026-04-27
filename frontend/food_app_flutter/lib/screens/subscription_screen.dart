import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isPro = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPro = prefs.getBool('isPro') ?? false;
    });
  }

  Future<void> _openCheckout([String? preferredUpi]) async {
    setState(() => _isLoading = true);
    
    // Simulate network delay for realistic prototype feel
    await Future.delayed(const Duration(seconds: 2));
    
    _handlePaymentSuccess();
    
    if (mounted) setState(() => _isLoading = false);
  }

  void _handlePaymentSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPro', true);
    
    // Add amount to admin wallet for prototype purposes
    double currentBalance = prefs.getDouble('admin_wallet_balance') ?? 0.0;
    await prefs.setDouble('admin_wallet_balance', currentBalance + 5.00);

    // Save transaction to admin history
    String historyString = prefs.getString('admin_wallet_history') ?? '[]';
    List<dynamic> history;
    try {
      history = jsonDecode(historyString);
    } catch (_) {
      history = [];
    }
    
    final newTransaction = {
      'title': 'PRO Subscription Check (Trial)',
      'amount': 5.00,
      'date': DateTime.now().toString(),
      'type': 'credit',
      'method': 'App Payment / UPI'
    };
    
    history.insert(0, newTransaction);
    await prefs.setString('admin_wallet_history', jsonEncode(history));

    setState(() => _isPro = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful! You are now a PRO User 🎉'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Upgrade to PRO', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.workspace_premium, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Unlock CookSmart Pro',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate up to 30+ recipes at once using advanced AI and get rid of limits.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            _buildPlanCard('Free Plan', '15 Recipes / search', 'Basic AI Filters', 'Standard speed', false),
            const SizedBox(height: 16),
            _buildPlanCard('Pro Plan', '30+ Recipes / search', 'Advanced AI & Image matching', 'Lightning fast speed', true, price: '₹299/mo'),
            const SizedBox(height: 48),
            if (_isPro)
              Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(16)),
                 child: const Center(child: Text("You are a PRO subscriber! 🎉", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))),
              )
            else
              _isLoading 
                 ? const CircularProgressIndicator()
                 : Column(
                     children: [
                       const Text("Select your active UPI to start ₹5 Trial:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                       const SizedBox(height: 12),
                       _paymentBtn('PhonePe', 'phonepe', Colors.purple, logoUrl: 'https://img.icons8.com/color/48/000000/phone-pe.png'),
                       const SizedBox(height: 12),
                       _paymentBtn('Google Pay', 'google_pay', Colors.blue, logoUrl: 'https://img.icons8.com/color/48/000000/google-pay-india.png'),
                       const SizedBox(height: 12),
                       _paymentBtn('Paytm', 'paytm', Colors.lightBlue, logoUrl: 'https://img.icons8.com/color/48/000000/paytm.png'),
                       const SizedBox(height: 12),
                       _paymentBtn('Other UPI / Cards', null, Colors.orange.shade700, icon: Icons.credit_card),
                     ],
                   ),
          ],
        ),
      ),
    );
  }

  Widget _paymentBtn(String name, String? upiCode, Color bg, {String? logoUrl, IconData? icon}) {
    return ElevatedButton(
      onPressed: () => _openCheckout(upiCode),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (logoUrl != null)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Image.network(logoUrl, height: 24, width: 24, fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.payment, size: 24, color: Colors.blue)),
            )
          else if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          Text('Pay with $name', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String title, String feat1, String feat2, String feat3, bool isPro, {String? price}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPro ? Colors.black87 : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isPro ? Border.all(color: Colors.orange, width: 2) : Border.all(color: Colors.grey.shade300),
        boxShadow: [if (isPro) BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isPro ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color)),
              if (price != null) Text(price, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 16),
          _featRow(feat1, isPro),
          const SizedBox(height: 8),
          _featRow(feat2, isPro),
          const SizedBox(height: 8),
          _featRow(feat3, isPro),
        ],
      ),
    );
  }

  Widget _featRow(String text, bool isPro) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: isPro ? Colors.orange : Colors.green, size: 20),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: isPro ? Colors.grey.shade300 : Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16)),
      ],
    );
  }
}

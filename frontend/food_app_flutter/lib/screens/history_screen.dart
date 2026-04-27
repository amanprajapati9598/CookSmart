import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/history_manager.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final hist = await HistoryManager.getHistory();
    if (mounted) {
      setState(() {
        _history = hist;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String isoString) {
    DateTime dt = DateTime.parse(isoString);
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(lang.t('history'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(lang.t('delete_history')),
                    content: Text(lang.t('delete_history_confirm')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.t('cancel'))),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await HistoryManager.clearHistory();
                          _loadHistory();
                        },
                        child: Text(lang.t('clear'), style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _history.isEmpty 
          ? Center(child: Text(lang.t('no_search_history'), style: TextStyle(color: Colors.grey.shade600)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                String query = item['query'] ?? '';
                List<dynamic> ings = item['ingredients'] ?? [];
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: const Icon(Icons.history, color: Colors.orange),
                    ),
                    title: Text(
                      query.isEmpty ? lang.t('ingredient_search_label') : query,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (ings.isNotEmpty)
                          Text("${lang.t('ingredients_label')}${ings.join(', ')}", style: TextStyle(color: Colors.grey.shade700)),
                        const SizedBox(height: 4),
                        Text(_formatDate(item['timestamp']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

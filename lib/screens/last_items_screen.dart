import 'package:flutter/material.dart';
import '../utils/api_service.dart';

class LastItemsScreen extends StatefulWidget {
  const LastItemsScreen({super.key});

  @override
  State<LastItemsScreen> createState() => _LastItemsScreenState();
}

class _LastItemsScreenState extends State<LastItemsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final items = await ApiService.fetchLastItems();
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذّر تحميل البيانات';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F9),
      appBar: AppBar(
        title: const Text('آخر 10 شحنات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.grey, size: 48),
                      const SizedBox(height: 12),
                      Text(_error,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined,
                              color: Colors.grey, size: 60),
                          SizedBox(height: 12),
                          Text('لا توجد شحنات بعد',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 18)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final isDelivered = item['status'] == 'delivered';
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ],
                            border: Border(
                              right: BorderSide(
                                color: isDelivered
                                    ? const Color(0xFF1f9d55)
                                    : const Color(0xFFe53935),
                                width: 4,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['item_id'] ?? '-',
                                      style: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        if (item['office_cd'] != null)
                                          _chip(
                                              '📍 ${item['office_cd']}',
                                              Colors.blue.shade50,
                                              Colors.blue),
                                        if (item['time'] != null)
                                          _chip(
                                              '🕐 ${item['time']}',
                                              Colors.grey.shade100,
                                              Colors.grey),
                                        if (item['reason'] != null &&
                                            item['reason'].toString().isNotEmpty)
                                          _chip(
                                              'السبب: ${item['reason']}',
                                              Colors.orange.shade50,
                                              Colors.orange),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDelivered
                                      ? const Color(0xFF1f9d55)
                                      : const Color(0xFFe53935),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isDelivered ? 'تم' : 'لم يتم',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _conversations = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  bool _isLoading = true;
  String _currentQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  Future<void> _fetchHistoryData() async {
    setState(() {
      _isLoading = true;
    });

    final res = await _apiService.fetchConversationHistory(
      page: _currentPage,
      limit: 10,
      query: _currentQuery,
    );

    setState(() {
      _conversations = List<Map<String, dynamic>>.from(res["items"] ?? []);
      _totalCount = res["total"] ?? 0;
      _totalPages = res["pages"] ?? 1;
      _currentPage = res["page"] ?? 1;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String val) {
    setState(() {
      _currentQuery = val;
      _currentPage = 1;
    });
    _fetchHistoryData();
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
      _fetchHistoryData();
    }
  }

  void _showDetailDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundCard,
          title: Text(
            item["title"] ?? "Conversation",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enfant: ${item['child_name'] ?? 'Léo'}",
                  style: const TextStyle(color: AppTheme.accentLime, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item["transcript"] ?? "Pas de détails.",
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentLime, foregroundColor: Colors.black),
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text("Historique des Conversations"),
        backgroundColor: AppTheme.backgroundPrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              // Search Bar with Search Icon
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Rechercher une conversation par titre ou mot cle...",
                  hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.accentLime),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged("");
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.backgroundCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),

              const SizedBox(height: 16),

              // Total Count Header Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total: $_totalCount conversations",
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  Text(
                    "Page $_currentPage sur $_totalPages",
                    style: const TextStyle(color: AppTheme.accentLime, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Scrollable Conversation List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.accentLime),
                      )
                    : _conversations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.history, size: 48, color: AppTheme.textSecondary),
                                SizedBox(height: 12),
                                Text(
                                  "Aucune conversation trouvee",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _conversations.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _conversations[index];
                              return GestureDetector(
                                onTap: () => _showDetailDialog(item),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundCard,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.accentLime,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 18),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item["title"] ?? "Conversation",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item["transcript"] ?? "",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              const SizedBox(height: 12),

              // Google-Style Pagination Bar (1, 2, 3, 4...)
              if (_totalPages > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous Button
                      IconButton(
                        onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                        color: _currentPage > 1 ? AppTheme.accentLime : Colors.white24,
                      ),

                      // Page Numbers (1, 2, 3...)
                      Row(
                        children: List.generate(_totalPages, (i) {
                          final pageNum = i + 1;
                          final isSelected = pageNum == _currentPage;
                          return GestureDetector(
                            onTap: () => _goToPage(pageNum),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.accentLime : AppTheme.backgroundCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppTheme.accentLime : Colors.white10,
                                ),
                              ),
                              child: Text(
                                "$pageNum",
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      // Next Button
                      IconButton(
                        onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        color: _currentPage < _totalPages ? AppTheme.accentLime : Colors.white24,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

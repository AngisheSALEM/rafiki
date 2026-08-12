import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_service.dart';

class HomeDashboardScreen extends StatefulWidget {
  final VoidCallback onStartTalk;
  final VoidCallback onOpenPiConnect;
  final VoidCallback onOpenOwnerDashboard;
  final VoidCallback onOpenAuth;
  final VoidCallback onOpenHistory;
  final String parentName;

  const HomeDashboardScreen({
    super.key,
    required this.onStartTalk,
    required this.onOpenPiConnect,
    required this.onOpenOwnerDashboard,
    required this.onOpenAuth,
    required this.onOpenHistory,
    required this.parentName,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _dbHistoryItems = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadLatestHistoryFromDb();
  }

  Future<void> _loadLatestHistoryFromDb() async {
    final res = await _apiService.fetchConversationHistory(page: 1, limit: 3);
    setState(() {
      _dbHistoryItems = List<Map<String, dynamic>>.from(res["items"] ?? []);
      _isLoadingHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Menu Button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
                  ),

                  // Center Greeting
                  Text(
                    "Bonjour, ${widget.parentName}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),

                  // Right Avatar (Account Auth Login Shortcut)
                  GestureDetector(
                    onTap: widget.onOpenAuth,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.black, size: 22),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Main Section Heading
              const Text(
                "Comment puis-je\nt'aider aujourd'hui ?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  height: 1.25,
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 20),

              // Asymmetric Quick Actions Grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tall Card: Talk with Bot (Rafiki Mouth & Ears) - Accent Lime
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onStartTalk,
                      child: Container(
                        height: 220,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLime,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.black,
                                  child: Icon(Icons.mic, color: AppTheme.accentLime, size: 20),
                                ),
                                Icon(Icons.north_east, color: Colors.black, size: 22),
                              ],
                            ),
                            const Spacer(),
                            const Text(
                              "Parler avec\nRafiki",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Bouche & Oreilles Whisper",
                              style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Right 2 Stacked Cards
                  Expanded(
                    child: Column(
                      children: [
                        // Rafiki Robot Sync - EXCLUSIVELY COULEUR SABLE (#E6D5B8)
                        GestureDetector(
                          onTap: widget.onOpenPiConnect,
                          child: Container(
                            height: 103,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.accentSand,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Icon(Icons.smart_toy_outlined, color: Colors.black, size: 22),
                                    Icon(Icons.north_east, color: Colors.black, size: 20),
                                  ],
                                ),
                                const Spacer(),
                                const Text(
                                  "Rafiki Robot",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Parents Portal - Accent Bleu Canard (#005F73)
                        GestureDetector(
                          onTap: widget.onOpenOwnerDashboard,
                          child: Container(
                            height: 103,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPeacock,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
                                    Icon(Icons.north_east, color: Colors.white, size: 20),
                                  ],
                                ),
                                const Spacer(),
                                const Text(
                                  "Espace Parents",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // History Section Title with "Voir tout" button opening HistoryScreen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Historique",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: widget.onOpenHistory,
                    child: const Text(
                      "Voir tout",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.accentLime),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Real DB History Item List (No Mock Data!)
              if (_isLoadingHistory)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: AppTheme.accentLime),
                  ),
                )
              else if (_dbHistoryItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundCard,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      "Aucune conversation enregistree dans la BD",
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                Column(
                  children: List.generate(_dbHistoryItems.length, (index) {
                    final item = _dbHistoryItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: GestureDetector(
                        onTap: widget.onOpenHistory,
                        child: _buildHistoryCard(
                          title: item["title"] ?? "Conversation",
                          iconColor: index == 0 ? AppTheme.accentLime : (index == 1 ? AppTheme.accentSand : AppTheme.accentPeacock),
                          iconTextColor: index == 2 ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard({required String title, required Color iconColor, Color iconTextColor = Colors.black}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline, color: iconTextColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 20),
        ],
      ),
    );
  }
}

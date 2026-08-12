import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/tts_service.dart';
import '../../../services/api_service.dart';
import '../../../services/token_service.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const OwnerDashboardScreen({super.key, this.onLogout});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final ApiService _apiService = ApiService();
  double _pitchValue = 1.2;
  double _rateValue = 0.45;
  int _selectedChildIndex = 0;
  bool _isLoadingChildren = true;
  List<Map<String, dynamic>> _children = [];

  @override
  void initState() {
    super.initState();
    _loadChildrenFromDatabase();
  }

  Future<void> _loadChildrenFromDatabase() async {
    setState(() {
      _isLoadingChildren = true;
    });

    final children = await _apiService.fetchChildrenList();

    setState(() {
      _children = children;
      _isLoadingChildren = false;
      if (_selectedChildIndex >= _children.length && _children.isNotEmpty) {
        _selectedChildIndex = 0;
      }
    });
  }

  void _showAddChildDialog() {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final topicsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundCard,
          title: const Text("Ajouter un Enfant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Prénom de l'enfant",
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.backgroundPrimary,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Âge (ans)",
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.backgroundPrimary,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topicsController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Sujets préférés (ex: Animaux, Contes)",
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.backgroundPrimary,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler", style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final age = int.tryParse(ageController.text.trim()) ?? 5;
                final topics = topicsController.text.trim().isEmpty ? "Histoire, Contes" : topicsController.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(context);

                  final result = await _apiService.createChildProfile(
                    name: name,
                    age: age,
                    preferredTopics: topics,
                  );

                  if (result["success"] == true) {
                    await _loadChildrenFromDatabase();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result["error"] ?? "Erreur d'enregistrement.")),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLime,
                foregroundColor: Colors.black,
              ),
              child: const Text("Enregistrer dans la BD"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tts = Provider.of<TTSService>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text("Espace Parents"),
        backgroundColor: AppTheme.backgroundPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Se déconnecter",
            onPressed: () async {
              await TokenService.clearSession();
              if (widget.onLogout != null) widget.onLogout!();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card (Bleu Canard accent)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.accentPeacock.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentPeacock),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.accentPeacock,
                    child: Icon(Icons.security, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Compte Parent Connecté",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        Text(
                          "Profils réels enregistrés en Base de Données",
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Profile Switcher & Add Child Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Profils Enfants (Base de Données)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                TextButton.icon(
                  onPressed: _showAddChildDialog,
                  icon: const Icon(Icons.add, color: AppTheme.accentLime, size: 20),
                  label: const Text(
                    "Ajouter Enfant",
                    style: TextStyle(color: AppTheme.accentLime, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoadingChildren)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: AppTheme.accentLime),
                ),
              )
            else if (_children.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.child_care, size: 40, color: AppTheme.textSecondary),
                    const SizedBox(height: 10),
                    const Text(
                      "Aucun profil enfant enregistré dans la BD",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Cliquez sur '+ Ajouter Enfant' ci-dessus pour enregistrer votre premier enfant.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _showAddChildDialog,
                      icon: const Icon(Icons.add, color: Colors.black, size: 18),
                      label: const Text("Créer un Profil Enfant", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentLime),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: List.generate(_children.length, (index) {
                  final child = _children[index];
                  final isSelected = index == _selectedChildIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedChildIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.accentLime.withOpacity(0.2) : AppTheme.backgroundCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.accentLime : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.face, size: 32, color: isSelected ? AppTheme.accentLime : AppTheme.textSecondary),
                            const SizedBox(height: 8),
                            Text(
                              child["name"] ?? "Enfant",
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                            ),
                            Text(
                              "${child['age']} ans",
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),

            const SizedBox(height: 28),

            // Voice Pitch & Rate Controls
            const Text(
              "Réglages de la Voix de Rafiki (Bouche)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.backgroundCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Hauteur de Voix (Pitch)", style: TextStyle(color: Colors.white)),
                      Text(_pitchValue.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentLime)),
                    ],
                  ),
                  Slider(
                    value: _pitchValue,
                    min: 0.5,
                    max: 2.0,
                    activeColor: AppTheme.accentLime,
                    onChanged: (val) {
                      setState(() => _pitchValue = val);
                      tts.setPitch(val);
                    },
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Vitesse de Parole (Rate)", style: TextStyle(color: Colors.white)),
                      Text(_rateValue.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Slider(
                    value: _rateValue,
                    min: 0.1,
                    max: 1.0,
                    activeColor: Colors.white,
                    onChanged: (val) {
                      setState(() => _rateValue = val);
                      tts.setRate(val);
                    },
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        tts.speak("Bonjour ! Voici un test de ma voix Rafiki !");
                      },
                      icon: const Icon(Icons.volume_up, color: Colors.black),
                      label: const Text("Tester la Voix", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentLime,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

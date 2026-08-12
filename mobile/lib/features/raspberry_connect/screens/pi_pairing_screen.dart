import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/raspberry_service.dart';
import '../../../services/tts_service.dart';

class PiPairingScreen extends StatefulWidget {
  const PiPairingScreen({super.key});

  @override
  State<PiPairingScreen> createState() => _PiPairingScreenState();
}

class _PiPairingScreenState extends State<PiPairingScreen> {
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.100");
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final pi = Provider.of<RaspberryPiService>(context, listen: false);
    _ipController.text = pi.piIpAddress;
  }

  Future<void> _handleConnectToggle(RaspberryPiService pi, TTSService tts) async {
    setState(() {
      _errorMessage = null;
    });

    if (pi.isConnected) {
      pi.disconnect();
    } else {
      await pi.connectToPi();
      if (pi.isConnected) {
        await tts.speak("Bonjour ! Je suis connecté et prêt à discuter !");
      } else {
        setState(() {
          _errorMessage = "Erreur de connexion : Impossible de joindre le robot Rafiki sur l'adresse ${_ipController.text}. Veuillez vérifier que le robot est sous tension et sur le même réseau Wi-Fi.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pi = Provider.of<RaspberryPiService>(context);
    final tts = Provider.of<TTSService>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text("Connexion Rafiki Robot"),
        backgroundColor: AppTheme.backgroundPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card (Sand accent reflecting Rafiki Robot color)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: pi.isConnected ? AppTheme.accentLime.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: pi.isConnected ? AppTheme.accentLime : Colors.red),
              ),
              child: Row(
                children: [
                  Icon(
                    pi.isConnected ? Icons.check_circle : Icons.error_outline,
                    color: pi.isConnected ? AppTheme.accentLime : Colors.redAccent,
                    size: 36,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pi.isConnected ? "Rafiki Robot Connecte" : "Rafiki Robot Deconnecte",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: pi.isConnected ? AppTheme.accentLime : Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pi.isConnected
                              ? "Batterie: ${pi.batteryLevel}% | Temperature: ${pi.temperature}°C"
                              : "Statut: Hors ligne. Entrez l'adresse IP ci-dessous.",
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null || !pi.isConnected) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage ?? "Avertissement: Rafiki Robot ne repond pas. Assurez-vous que le robot est sous tension et connecte au Wi-Fi.",
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            const Text(
              "Configuration Reseau Robot",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Adresse IP du Rafiki Robot",
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                hintText: "ex: 192.168.1.100",
                prefixIcon: const Icon(Icons.wifi, color: Colors.white),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: AppTheme.backgroundCard,
              ),
              onChanged: (val) => pi.setIpAddress(val),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _handleConnectToggle(pi, tts),
                icon: Icon(pi.isConnected ? Icons.power_settings_new : Icons.link, color: Colors.black),
                label: Text(
                  pi.isConnected ? "Deconnecter le Robot" : "Connecter au Rafiki Robot",
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pi.isConnected ? Colors.redAccent : AppTheme.accentLime,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

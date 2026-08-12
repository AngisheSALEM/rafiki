import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/tts_service.dart';
import '../../../services/stt_service.dart';
import '../../../services/raspberry_service.dart';
import '../../../services/api_service.dart';

class RafikiMouthScreen extends StatefulWidget {
  const RafikiMouthScreen({super.key});

  @override
  State<RafikiMouthScreen> createState() => _RafikiMouthScreenState();
}

class _RafikiMouthScreenState extends State<RafikiMouthScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  String _currentRafikiResponse = "Bonjour ! Je suis Rafiki ! Clique sur le microphone pour ouvrir le micro et parler avec moi !";
  String _lastChildInput = "Dis-moi une histoire !";
  bool _isTranscribing = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  /// Triggers real OpenAI Whisper transcription pipeline & sends speech to FastAPI backend
  Future<void> _handleUserSpeech(String recognizedText) async {
    if (recognizedText.trim().isEmpty) return;

    setState(() {
      _lastChildInput = recognizedText;
      _isTranscribing = true;
    });

    final tts = Provider.of<TTSService>(context, listen: false);
    final pi = Provider.of<RaspberryPiService>(context, listen: false);

    // Call FastAPI backend with OpenAI Whisper 30s Log-Mel Spectrogram pipeline
    final result = await _apiService.sendUserSpeech(
      speechText: recognizedText,
      childName: "Léo",
    );

    final String speechToSay = result["rafiki_speech"] ?? "Je t'écoute !";
    final Map<String, dynamic> piAction = result["pi_movement"] ?? {};

    setState(() {
      _currentRafikiResponse = speechToSay;
      _isTranscribing = false;
    });

    // Trigger physical movement on Raspberry Pi if connected
    if (piAction.containsKey("movement")) {
      pi.sendMovement(piAction["movement"]);
    }

    // Rafiki Speaks out of phone speaker!
    await tts.speak(speechToSay);
  }

  @override
  Widget build(BuildContext context) {
    final tts = Provider.of<TTSService>(context);
    final stt = Provider.of<STTService>(context);
    final pi = Provider.of<RaspberryPiService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: Stack(
        children: [
          // Background Top Concentric Contour Lines Grid Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 260,
            child: CustomPaint(
              painter: ConcentricContourLinesPainter(),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),

                            // Top Center Pill Badge: "Rafiki • Online" (#D4FF00 bg, black text)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentLime,
                                  borderRadius: BorderRadius.circular(9999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accentLime.withOpacity(0.35),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      pi.isConnected ? "Rafiki • Robot Connecte" : "Rafiki • En Ligne",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Spacer(),

                            // Center AI Vocal Orb: Spherical Iridescent Fluid Blob (Bleu Canard & Sable)
                            Center(
                              child: AnimatedBuilder(
                                animation: _waveController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    size: const Size(200, 200),
                                    painter: FluidIridescentOrbPainter(
                                      animationValue: _waveController.value,
                                      isSpeaking: tts.isSpeaking,
                                      isListening: stt.isListening || _isTranscribing,
                                    ),
                                  );
                                },
                              ),
                            ).animate(
                              target: tts.isSpeaking || stt.isListening ? 1 : 0,
                              onComplete: (c) => c.repeat(reverse: true),
                            ).scaleXY(begin: 0.98, end: 1.05, duration: 2.seconds),

                            const Spacer(),

                            // Transcript & Microphone Hardware Status Display
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                children: [
                                  Text(
                                    stt.isListening
                                        ? "Microphone du téléphone actif - Écoute en cours..."
                                        : _isTranscribing
                                            ? "Transcription et traitement en cours..."
                                            : "Cliquez sur le micro pour parler :",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: (stt.isListening || _isTranscribing)
                                          ? AppTheme.accentLime
                                          : const Color(0xFFA1A1AA),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    stt.isListening
                                        ? (stt.recognizedText.isEmpty ? "Parlez maintenant dans le micro..." : "\"${stt.recognizedText}\"")
                                        : tts.isSpeaking
                                            ? "\"$_currentRafikiResponse\""
                                            : "\"$_lastChildInput\"",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Center Floating Microphone Button (HARDWARE MIC TRIGGER)
                            Center(
                              child: GestureDetector(
                                onTap: () async {
                                  if (stt.isListening) {
                                    await stt.stopListening();
                                  } else {
                                    await stt.startListening(onResultCompleted: _handleUserSpeech);
                                  }
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Pulsing Ring Effect
                                    Container(
                                      width: 86,
                                      height: 86,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.accentLime.withOpacity((stt.isListening || _isTranscribing) ? 0.8 : 0.25),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: stt.isListening ? Colors.redAccent : AppTheme.accentLime,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (stt.isListening ? Colors.redAccent : AppTheme.accentLime).withOpacity(0.6),
                                            blurRadius: 24,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        stt.isListening ? Icons.graphic_eq : Icons.mic,
                                        color: Colors.black,
                                        size: 34,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter for Fluid Iridescent Liquid Blob Orb featuring Bleu Canard & Sable
class FluidIridescentOrbPainter extends CustomPainter {
  final double animationValue;
  final bool isSpeaking;
  final bool isListening;

  FluidIridescentOrbPainter({
    required this.animationValue,
    required this.isSpeaking,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 - 15;

    final glowPaint = Paint()
      ..color = (isSpeaking
              ? const Color(0xFF00F0FF)
              : isListening
                  ? AppTheme.accentLime
                  : AppTheme.accentPeacock)
          .withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35);

    canvas.drawCircle(center, baseRadius, glowPaint);

    final path = Path();
    const int pointsCount = 180;
    final double angleStep = (math.pi * 2) / pointsCount;

    for (int i = 0; i <= pointsCount; i++) {
      final angle = i * angleStep;

      final wave1 = math.sin(angle * 3 + animationValue * math.pi * 2) * (isSpeaking ? 10 : 6);
      final wave2 = math.cos(angle * 5 - animationValue * math.pi * 4) * (isSpeaking ? 6 : 4);
      final wave3 = math.sin(angle * 2 + animationValue * math.pi * 2) * 3;

      final radius = baseRadius + wave1 + wave2 + wave3;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final gradient = SweepGradient(
      colors: const [
        AppTheme.accentPeacock,
        AppTheme.accentSand,
        AppTheme.accentLime,
        Color(0xFF00F0FF),
        AppTheme.accentPeacock,
      ],
      transform: GradientRotation(animationValue * math.pi * 2),
    );

    final orbPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: baseRadius))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, orbPaint);

    final innerHighlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.65),
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
        center: const Alignment(-0.35, -0.4),
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius));

    canvas.drawPath(path, innerHighlightPaint);

    final highlightPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(center.dx - 15, center.dy - 20), radius: baseRadius * 0.65),
        -math.pi * 0.75,
        math.pi * 0.5,
      );

    final strokeHighlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(highlightPath, strokeHighlightPaint);
  }

  @override
  bool shouldRepaint(covariant FluidIridescentOrbPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isSpeaking != isSpeaking ||
        oldDelegate.isListening != isListening;
  }
}

class ConcentricContourLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentLime.withOpacity(0.06)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, -20);
    for (double r = 40; r < size.width * 1.2; r += 28) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

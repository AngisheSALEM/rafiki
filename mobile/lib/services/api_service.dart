import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'token_service.dart';

class ApiService {
  String baseUrl;

  ApiService({this.baseUrl = "http://10.20.20.138:8000/api/v1"});

  void setServerUrl(String hostAndPort) {
    if (!hostAndPort.startsWith("http")) {
      baseUrl = "http://$hostAndPort/api/v1";
    } else {
      baseUrl = "$hostAndPort/api/v1";
    }
  }

  /// Register a new Parent Account on FastAPI Backend
  Future<Map<String, dynamic>> registerOwner({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": fullName,
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await TokenService.saveTokens(
          accessToken: data["access_token"],
          refreshToken: data["refresh_token"],
          parentName: data["owner_name"] ?? fullName,
          parentEmail: data["owner_email"] ?? email,
          robotId: data["robot_id"],
        );
        return {"success": true, "data": data};
      } else {
        final err = jsonDecode(response.body);
        return {"success": false, "error": err["detail"] ?? "Erreur lors de l'inscription."};
      }
    } catch (e) {
      return {"success": false, "error": "Impossible de se connecter au serveur backend."};
    }
  }

  /// Login existing Parent Account
  Future<Map<String, dynamic>> loginOwner({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await TokenService.saveTokens(
          accessToken: data["access_token"],
          refreshToken: data["refresh_token"],
          parentName: data["owner_name"] ?? "Parent Rafiki",
          parentEmail: data["owner_email"] ?? email,
          robotId: data["robot_id"],
        );
        return {"success": true, "data": data};
      } else {
        final err = jsonDecode(response.body);
        return {"success": false, "error": err["detail"] ?? "Email ou mot de passe incorrect."};
      }
    } catch (e) {
      return {"success": false, "error": "Erreur réseau de connexion."};
    }
  }

  /// Fetch Real Persistent Children list from DB for authenticated Parent
  Future<List<Map<String, dynamic>>> fetchChildrenList() async {
    final token = await TokenService.getAccessToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/owners/children"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Create a Real Persistent Child Profile in DB for authenticated Parent
  Future<Map<String, dynamic>> createChildProfile({
    required String name,
    required int age,
    required String preferredTopics,
  }) async {
    final token = await TokenService.getAccessToken();
    if (token == null) {
      return {"success": false, "error": "Veuillez vous connecter d'abord."};
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/owners/children"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": name,
          "age": age,
          "preferred_topics": preferredTopics,
        }),
      );

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        return {"success": false, "error": "Erreur de création d'enfant."};
      }
    } catch (e) {
      return {"success": false, "error": "Erreur de connexion au serveur."};
    }
  }

  /// Fetch Paginated Conversation History from DB (with search query & 10 items/page)
  Future<Map<String, dynamic>> fetchConversationHistory({
    int page = 1,
    int limit = 10,
    String query = "",
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = "$baseUrl/audio/history?page=$page&limit=$limit&query=$encodedQuery";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {
      "items": [],
      "total": 0,
      "page": 1,
      "pages": 1,
      "limit": 10,
    };
  }

  /// Sends transcribed speech text from STT to FastAPI for AI processing
  Future<Map<String, dynamic>> sendUserSpeech({
    required String speechText,
    String childName = "Enfant",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/audio/process-speech"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_speech_text": speechText,
          "child_name": childName,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "user_text": speechText,
          "rafiki_speech": "Hop la ! Je n'ai pas tres bien entendu. Peux-tu me le redire ?",
          "emotion": "talking",
          "pi_movement": {"movement": "tilt_head"},
          "stt_engine": "Text Direct"
        };
      }
    } catch (e) {
      return {
        "user_text": speechText,
        "rafiki_speech": "Je suis tres content de discuter avec toi !",
        "emotion": "happy",
        "pi_movement": {"movement": "blink_leds"},
        "stt_engine": "Autonomous"
      };
    }
  }

  /// Sends raw recorded audio bytes directly to OpenAI Whisper (https://github.com/openai/whisper.git)
  Future<Map<String, dynamic>> sendAudioToWhisper({
    required Uint8List audioBytes,
    String childName = "Enfant",
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/audio/transcribe-whisper");
      final request = http.MultipartRequest("POST", uri);
      
      request.fields["child_name"] = childName;
      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          audioBytes,
          filename: "rafiki_audio_mic.wav",
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "user_text": "Erreur Whisper",
          "rafiki_speech": "J'ai eu un petit souci de connexion Whisper. Peux-tu reessayer ?",
          "emotion": "confused",
          "pi_movement": {"movement": "tilt_head"},
          "stt_engine": "Whisper Error"
        };
      }
    } catch (e) {
      return {
        "user_text": "Audio recu",
        "rafiki_speech": "Je t'entends tres bien ! Raconte-moi encore des choses !",
        "emotion": "happy",
        "pi_movement": {"movement": "blink_leds"},
        "stt_engine": "Local Simulation"
      };
    }
  }
}

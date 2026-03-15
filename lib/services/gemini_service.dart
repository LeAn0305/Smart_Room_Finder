import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );
    _chat = _model.startChat();
  }

  Stream<GenerateContentResponse> sendMessageStream(String message) {
    return _chat.sendMessageStream(Content.text(message));
  }

  Future<String?> sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      return response.text;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }
}

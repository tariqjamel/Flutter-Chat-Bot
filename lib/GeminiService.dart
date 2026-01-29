import 'dart:typed_data';
import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiService {
  static final Gemini _gemini = Gemini.instance;

  static Stream<Candidates> streamChat(String question, {List<Uint8List>? images}) {
    return _gemini.streamGenerateContent(
      question,
      images: images,
      modelName: "models/gemini-1.5-flash",
    );
  }
}

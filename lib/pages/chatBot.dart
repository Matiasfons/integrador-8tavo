import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({Key? key}) : super(key: key);

  @override
  _ChatBotState createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Especialista en Ejercicio y Alimentación")),
      body: SafeArea(child: LlmChatView(
        provider: GeminiProvider(
          model: GenerativeModel(
            systemInstruction: Content("assistant", [TextPart("Eres un ChatBot Especialista en Ejercicio y Alimentación. Debes responder solo en español y con el estilo del anime de solo leveling pero con enfoque a una app de ejercicio")]),
            model: 'gemini-2.0-flash',
            apiKey: 'AIzaSyAIqU843chmqWkjakXENo54f2D5ilFvbyY',
          ),
        ),
      ),),
    );
  }
}
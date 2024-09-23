import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceChat extends StatefulWidget {
  @override
  _VoiceChatState createState() => _VoiceChatState();
}

class _VoiceChatState extends State<VoiceChat>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final Gemini gemini = Gemini.instance;
  FlutterTts flutterTts = FlutterTts();
  List<ChatMessage> messages = [];

  late stt.SpeechToText speechToText;
  bool _isListening = false;
  bool isTyping = false;
  bool isGenerating = false;
  String _text = '';
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Gemini",
    profileImage:
    "https://seeklogo.com/images/G/google-gemini-logo-A5787B2669-seeklogo.com.png",
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    speechToText = stt.SpeechToText();
    _initSpeech();

    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
    _listen();
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    try {
      String question = chatMessage.text;
      StringBuffer responseBuffer = StringBuffer();

      setState(() {
        isGenerating = true;
      });

      gemini
          .streamGenerateContent(
        question,
      )
          .listen((event) async {
        String responsePart = event.content?.parts?.fold(
            "", (previous, current) => "$previous ${current.text}") ?? "";

        responseBuffer.write(responsePart);

        setState(() {
          if (messages.isNotEmpty && messages.first.user == geminiUser) {
            messages[0] = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: responseBuffer.toString(),
            );
          } else {
            messages = [
              ChatMessage(
                user: geminiUser,
                createdAt: DateTime.now(),
                text: responseBuffer.toString(),
              ),
              ...messages,
            ];
          }
        });
      }, onDone: () async {
        String finalResponse = responseBuffer.toString();
        await flutterTts.speak(finalResponse);

        // setState(() {
        //   isGenerating = false;
        // });

        flutterTts.setCompletionHandler(() {
          // setState(() {
          //   isGenerating = false;
          // });
          _listen();
        });
      });
    } catch (e) {
      print(e);
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await speechToText.initialize(
        onStatus: (status) => print('Status: $status'),
        onError: (error) => print('Error: $error'),
      );
      if (available) {
        print('Starting to listen...');
        setState(() {
          isGenerating = false;
          _isListening = true;
          _text = '';  // Reset the text
        });

        // Start listening
        speechToText.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
            });
            print('Speech recognized: $_text');
            if (result.finalResult) {
              ChatMessage chatMessage = ChatMessage(
                user: currentUser,
                createdAt: DateTime.now(),
                text: _text,
              );
              _sendMessage(chatMessage);
              setState(() => _isListening = false);
            }
          },
        );

        // Add a timeout to stop listening if there's no input
        Future.delayed(Duration(seconds: 5), () {
          if (_text.isEmpty && _isListening) {
            speechToText.stop();
            setState(() {
              _isListening = false;
            });
          }
        });
      } else {
        print('Speech recognition not available');
      }
    } else {
      speechToText.stop();
      setState(() => _isListening = false);
    }
  }


  void _stopTTS() async {
    if (isGenerating) {
      await flutterTts.stop();
      setState(() {
        isGenerating = false;
        _isListening = false;
      });
    }
  }


  Future<void> _initSpeech() async {
    bool available = await speechToText.initialize(
      onStatus: (val) => print('Speech Status: $val'),
      onError: (val) => print('Speech Error: $val'),
    );
    print('Speech Recognition available: $available');
  }

  @override
  void dispose() {
    _controller.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                // Handle the back action, e.g., Navigator.pop(context);
                Navigator.pop(context);
              },
              tooltip: 'Back',
            ),
          ],
        ),

        SizedBox(height: 240),
        Text(
          _isListening ? 'Listening...' : (isGenerating ? 'Generating...' : ''),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
              color: Colors.white,
              decoration: TextDecoration.none
          ),
        ),
        SizedBox(height: 20),

        SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Box(0.8, 0.8, 4, _controller, Colors.grey.withOpacity(0.2)),
              Box(0.6, 0.6, 3, _controller, Colors.grey.withOpacity(0.4)),
              Box(0.4, 0.4, 2, _controller, Colors.grey.withOpacity(0.6)),
              Box(0.2, 0.2, 1, _controller, Colors.grey.withOpacity(0.8)),
              Box(0.1, 0.1, 0, _controller, Colors.grey),
              LogoBox(_controller),
            ],
          ),
        ),

        SizedBox(height: 80),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.stop, color: Colors.red),
              onPressed: isGenerating  ? _stopTTS : null,
              tooltip: 'Stop',
              iconSize: 28,
            ),
            SizedBox(width: 40),
            IconButton(
              icon: Icon(Icons.mic, color: Colors.green),
              onPressed: !_isListening && !isGenerating ? _listen : null,
              tooltip: 'Start Listening',
              iconSize: 28,
            ),
          ],
        )
      ],
    );
  }
}

class Box extends StatelessWidget {
  final double scaleFactor;
  final double borderFactor;
  final int delay;
  final AnimationController controller;
  final Color borderColor;

  Box(this.scaleFactor, this.borderFactor, this.delay, this.controller,
      this.borderColor);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double animationValue =
            sin((controller.value + delay * 0.2) * pi * 2) * 0.15 + 1.0;
        return Transform.scale(
          scale: animationValue,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: 2,
              ),
            ),
            width: 250 * scaleFactor,
            height: 250 * scaleFactor,
          ),
        );
      },
    );
  }
}

class LogoBox extends StatelessWidget {
  final AnimationController controller;

  LogoBox(this.controller);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Icon(
          Icons.music_note, // Replace with your desired icon or SVG.
          color: controller.value < 0.5 ? Colors.grey : Colors.white,
          size: 80,
        );
      },
    );
  }
}

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'styles.dart';
import 'GeminiService.dart';
import 'components/AnimatedOrb.dart';

class VoiceChat extends StatefulWidget {
  const VoiceChat({super.key});

  @override
  State<VoiceChat> createState() => _VoiceChatState();
}

class _VoiceChatState extends State<VoiceChat> with TickerProviderStateMixin {
  late AnimationController _controller;
  FlutterTts flutterTts = FlutterTts();
  List<ChatMessage> messages = [];

  late stt.SpeechToText speechToText;
  bool _isListening = false;
  bool isGenerating = false;
  String _text = '';
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Gemini",
    profileImage: "https://seeklogo.com/images/G/google-gemini-logo-A5787B2669-seeklogo.com.png",
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
      isGenerating = true;
    });

    try {
      String question = chatMessage.text;
      StringBuffer responseBuffer = StringBuffer();

      GeminiService.streamChat(question).listen((event) {
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

        flutterTts.setCompletionHandler(() {
          if (mounted) {
            setState(() => isGenerating = false);
            _listen();
          }
        });
      });
    } catch (e) {
      print(e);
      if (mounted) setState(() => isGenerating = false);
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await speechToText.initialize();
      if (available) {
        setState(() {
          isGenerating = false;
          _isListening = true;
          _text = '';
        });

        speechToText.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
            });
            if (result.finalResult) {
              _sendMessage(ChatMessage(
                user: currentUser,
                createdAt: DateTime.now(),
                text: _text,
              ));
              setState(() => _isListening = false);
            }
          },
        );

        Future.delayed(const Duration(seconds: 5), () {
          if (_text.isEmpty && _isListening) {
            speechToText.stop();
            if (mounted) setState(() => _isListening = false);
          }
        });
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.black)),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),

                  /// MAIN CENTER CONTENT (slightly down)
                  Expanded(
                    child: Align(
                      alignment: Alignment(0, 0.2), // 👈 move DOWN (0 = center)
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatusText(),
                          const SizedBox(height: 10),
                          _buildRecognizedText(),
                          const SizedBox(height: 40),
                          AnimatedOrb(
                            controller: _controller,
                            isListening: _isListening,
                            isGenerating: isGenerating,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildModernControls(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(
            decoration: AppStyles.glassDecoration(radius: 50),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: AppStyles.glassDecoration(radius: 20),
            child: Text("VOICE MODE", style: AppStyles.secondaryStyle.copyWith(letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    return Text(
      _isListening ? 'LISTENING' : (isGenerating ? 'GEMINI IS THINKING' : 'TAP MIC TO START'),
      style: AppStyles.headingStyle.copyWith(
        fontSize: 14,
        letterSpacing: 2,
        color: _isListening ? AppStyles.primaryColor : Colors.white38,
      ),
    );
  }

  Widget _buildRecognizedText() {
    return Text(
      _text.isEmpty ? "Speak to Gemini" : '"$_text"',
      textAlign: TextAlign.center,
      style: AppStyles.bodyStyle.copyWith(
        fontSize: 18,
        fontStyle: FontStyle.italic,
        color: Colors.white70,
      ),
    );
  }

  Widget _buildModernControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircularActionButton(
          icon: Icons.stop_rounded,
          color: Colors.redAccent.withOpacity(0.2),
          iconColor: Colors.redAccent,
          onTap: isGenerating ? _stopTTS : null,
          isActive: isGenerating,
        ),
        const SizedBox(width: 40),
        _buildCircularActionButton(
          icon: _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
          color: AppStyles.primaryColor.withOpacity(0.2),
          iconColor: AppStyles.primaryColor,
          onTap: !isGenerating ? _listen : null,
          isActive: true,
          size: 80,
          innerIconSize: 35,
        ),
      ],
    );
  }

  Widget _buildCircularActionButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback? onTap,
    required bool isActive,
    double size = 60,
    double innerIconSize = 24,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white12,
          shape: BoxShape.circle,
          border: Border.all(color: isActive ? iconColor.withOpacity(0.4) : Colors.transparent),
          boxShadow: isActive ? [
            BoxShadow(color: iconColor.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)
          ] : [],
        ),
        child: Icon(icon, color: isActive ? iconColor : Colors.white24, size: innerIconSize),
      ),
    );
  }
}

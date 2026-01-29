import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'VoiceChat.dart';
import 'styles.dart';
import 'ModernDrawer.dart';
import 'HistoryManager.dart';
import 'GeminiService.dart';
import 'components/ChatBubble.dart';
import 'components/ChatInput.dart';
import 'components/AppGlassContainer.dart';

class HomePage extends StatefulWidget {
  final ChatSession? session;
  const HomePage({super.key, this.session});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlutterTts flutterTts = FlutterTts();
  List<ChatMessage> messages = [];
  String? _currentSessionId;

  final ScrollController scrollController = ScrollController();
  final TextEditingController controller = TextEditingController();

  late stt.SpeechToText speechToText;
  bool _isListening = false;
  bool _isGenerating = false;
  bool isTyping = false;
  String? _selectedImagePath;

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
    speechToText = stt.SpeechToText();
    _requestPermission();
    _initSpeech();

    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);

    flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isGenerating = false);
    });

    if (widget.session != null) {
      messages = widget.session!.messages;
      _currentSessionId = widget.session!.id;
    }

    controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    flutterTts.stop();
    controller.removeListener(_onTextChanged);
    controller.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        await Permission.microphone.request();
      }
    }
  }

  Future<void> _initSpeech() async {
    bool available = await speechToText.initialize(
      onStatus: (val) => print('Speech Status: $val'),
      onError: (val) => print('Speech Error: $val'),
    );
    print('Speech Recognition available: $available');
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
      isTyping = true;
    });

    try {
      String question = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }

      GeminiService.streamChat(question, images: images).listen((event) {
        if (!mounted) return;
        
        String response = event.content?.parts?.fold(
                "", (previous, current) => "$previous ${current.text}") ??
            "";

        setState(() {
          isTyping = false;
          ChatMessage? lastMessage = messages.firstOrNull;
          if (lastMessage != null && lastMessage.user == geminiUser) {
            // Update the existing Gemini response bubble
            messages.removeAt(0);
            String updatedText = lastMessage.text + response;
            messages = [
              ChatMessage(
                user: geminiUser,
                createdAt: lastMessage.createdAt,
                text: updatedText,
              ),
              ...messages
            ];
          } else {
            // Create a new response bubble
            ChatMessage message = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: response,
            );
            messages = [message, ...messages];
          }
        });
        _persistSession();
      }, onDone: () {
        if (mounted) {
          setState(() => isTyping = false);
          _persistSession();
        }
      });
    } catch (e) {
      print(e);
      if (mounted) setState(() => isTyping = false);
    }
  }

  void _persistSession() {
    if (messages.isEmpty) return;
    _currentSessionId ??= DateTime.now().millisecondsSinceEpoch.toString();
    String title = messages.last.text;
    if (title.length > 30) title = "${title.substring(0, 30)}...";
    
    HistoryManager.saveSession(ChatSession(
      id: _currentSessionId!,
      title: title,
      messages: messages,
    ));
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        speechToText.listen(
          onResult: (result) {
            setState(() {
              controller.text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _selectedImagePath = file.path);
    }
  }

  void _readAloud(String message) async {
    await flutterTts.speak(message);
    setState(() => _isGenerating = true);
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
        drawer: ModernDrawer(),
        body: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.black)),
            SafeArea(
              child: Stack(
                children: [
                  _chatUI(),
                  _topToolbar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topToolbar() {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(builder: (context) {
            return IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: AppGlassContainer(
                width: 40,
                height: 40,
                borderRadius: 50,
                child: const Icon(Icons.menu_rounded, color: Colors.white70, size: 24),
              ),
            );
          }),
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (c) => const HomePage()),
              );
            },
            icon: AppGlassContainer(
              width: 40,
              height: 40,
              borderRadius: 50,
              child: const Icon(Icons.add_rounded, color: Colors.white70, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatUI() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: messages.length + (isTyping ? 1 : 0),
            reverse: true,
            padding: const EdgeInsets.fromLTRB(8, 70, 8, 10),
            itemBuilder: (context, index) {
              if (index == 0 && isTyping) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: ChatBubble(text: "Typing...", isSender: false),
                );
              }
              final message = messages[index - (isTyping ? 1 : 0)];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: message.user.id == currentUser.id
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (message.medias != null && message.medias!.isNotEmpty)
                      _imageMessage(message.medias!.first.url),
                    
                    ChatBubble(
                      text: message.text,
                      isSender: message.user.id == currentUser.id,
                      actions: message.user.id == geminiUser.id ? [
                        IconButton(
                          icon: Icon(
                            _isGenerating ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white38,
                            size: 18,
                          ),
                          onPressed: () => _isGenerating ? flutterTts.stop() : _readAloud(message.text),
                        )
                      ] : null,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_selectedImagePath != null) _buildImagePreview(),
        ChatInput(
          controller: controller,
          isEmpty: controller.text.isEmpty && _selectedImagePath == null,
          isListening: _isListening,
          onSend: () {
             if (controller.text.isNotEmpty || _selectedImagePath != null) {
                _sendMessage(ChatMessage(
                  user: currentUser,
                  createdAt: DateTime.now(),
                  text: controller.text.isEmpty ? "Describe this picture?" : controller.text,
                  medias: _selectedImagePath != null ? [
                    ChatMedia(url: _selectedImagePath!, fileName: "", type: MediaType.image)
                  ] : null,
                ));
                controller.clear();
                setState(() => _selectedImagePath = null);
              }
          },
          onMedia: _sendMediaMessage,
          onVoiceMode: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VoiceChat())),
          onListen: _listen,
          onStopListen: () {
            speechToText.stop();
            setState(() => _isListening = false);
          },
        ),
      ],
    );
  }

  Widget _imageMessage(String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(url), height: 180, width: 180, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      padding: const EdgeInsets.all(6),
      decoration: AppStyles.glassDecoration(radius: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(_selectedImagePath!), height: 100, width: 100, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImagePath = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

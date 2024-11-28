import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:chat_bubbles/bubbles/bubble_normal.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'VoiceChat.dart';
import 'Waveform.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;
  FlutterTts flutterTts = FlutterTts();
  List<ChatMessage> messages = [];

  final ScrollController scrollController = ScrollController();
  final TextEditingController controller = TextEditingController();

  late stt.SpeechToText speechToText;
  bool _isListening = false;
  bool _isGenerating = false;
  bool isTyping = false;
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
    speechToText = stt.SpeechToText();
    _requestPermission();
    _initSpeech();

    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);

    flutterTts.setCompletionHandler(() {
      setState(() {
        _isGenerating = false;
      });
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
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
    });
    try {
      String question = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }
      gemini
          .streamGenerateContent(
        question,
        images: images,
      )
          .listen((event) async {
        ChatMessage? lastMessage = messages.firstOrNull;
        String response = event.content?.parts?.fold(
                "", (previous, current) => "$previous ${current.text}") ??
            "";
        if (lastMessage != null && lastMessage.user == geminiUser) {
          lastMessage = messages.removeAt(0);
          lastMessage.text += response;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          ChatMessage message = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: response,
          );
          setState(() {
            messages = [message, ...messages];
          });
        }

        // await flutterTts.speak(response);
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
        setState(() => _isListening = true);
        speechToText.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
            });
            print('Speech recognized: $_text');
            controller.text = _text;
            // if (result.finalResult) {
            //   ChatMessage chatMessage = ChatMessage(
            //     user: currentUser,
            //     createdAt: DateTime.now(),
            //     text: _text,
            //   );
            //    _sendMessage(chatMessage);
            setState(() => _isListening = false);
            // }
          },
        );
      } else {
        print('Speech recognition not available');
      }
    } else {
      speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe this picture?",
        medias: [
          ChatMedia(
            url: file.path,
            fileName: "",
            type: MediaType.image,
          )
        ],
      );
      _sendMessage(chatMessage);
    }
  }

  void _readAloud(String message) async {
    await flutterTts.speak(message);
    setState(() {
      _isGenerating = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black87,
        drawer: _drawerUI(),
        appBar: AppBar(
          leading: Builder(builder: (BuildContext context) {
            return IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: const Icon(Icons.vertical_split_outlined));
          }),
          title: const Text('Ask Gemini'),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 22),
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: _chatUI());
  }

  Widget _drawerUI() {
    return Drawer(
      child: Container(
        color: Colors.black87,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 44),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 37,
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  cursorColor: Colors.white,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (text) {
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search",
                      hintStyle: TextStyle(
                        color: Colors.grey
                      ),
                      suffixIcon: Icon(
                        Icons.search,
                        color: Colors.white60,
                      )),
                ),
              ),
              Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.home_outlined, color: Colors.white),
                    title:
                        Text('New Chat', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.update, color: Colors.white),
                    title:
                        Text('History', style: TextStyle(color: Colors.white)),
                    onTap: () {},
                  ),
                  const Divider(color: Colors.white),
                ],
              )
            ],
          ),
        ),
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
            itemBuilder: (context, index) {
              if (index == 0 && isTyping) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BubbleNormal(
                      text: "Typing...",
                      isSender: false,
                      color: Colors.grey,
                    ),
                  ],
                );
              }
              final message = messages[index - (isTyping ? 1 : 0)];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: message.user.id == currentUser.id
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (message.medias != null &&
                            message.medias!.isNotEmpty)
                          Image.file(
                            File(message.medias!.first.url),
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        BubbleNormal(
                          text: message.text,
                          textStyle: TextStyle(color: Colors.white),
                          isSender: message.user.id == currentUser.id,
                          color: message.user.id == currentUser.id
                              ? Colors.grey.shade800
                              : Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  if (message.user.id == geminiUser.id)
                    IconButton(
                      icon: _isGenerating
                          ? const Icon(
                              Icons.volume_off,
                              color: Colors.white60,
                            )
                          : const Icon(
                              Icons.volume_up,
                              color: Colors.white60,
                            ),
                      onPressed: () {
                        if (_isGenerating) {
                          flutterTts.stop();
                          setState(() {
                            _isGenerating = false;
                          });
                        } else {
                          _readAloud(message.text);
                        }
                      },
                    ),
                ],
              );
            },
          ),
        ),
        _textFieldUI(),
      ],
    );
  }

  Widget _textFieldUI() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo),
                    onPressed: _sendMediaMessage,
                    color: Colors.white,
                    constraints: BoxConstraints(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      cursorColor: Colors.white,
                      style: TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (text) {
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter text",
                      ),
                    ),
                  ),
                  const VerticalDivider(color: Colors.black, width: 8),
                  GestureDetector(
                    onLongPressStart: (_) {
                      _listen();
                    },
                    onLongPressEnd: (_) {
                      speechToText.stop();
                      setState(() => _isListening = false);
                    },
                    child: _isListening
                        ? Waveform()
                        : IconButton(
                            icon: Icon(
                              controller.text.isEmpty ? Icons.mic : Icons.send,
                              color: Colors.white,
                            ),
                            onPressed: controller.text.isEmpty
                                ? null
                                : () {
                                    if (controller.text.isNotEmpty) {
                                      _sendMessage(ChatMessage(
                                        user: currentUser,
                                        createdAt: DateTime.now(),
                                        text: controller.text,
                                      ));
                                      controller.clear();
                                      setState(() {});
                                    }
                                  },
                            constraints: BoxConstraints(),
                          ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.headset),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VoiceChat()),
              );
            },
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

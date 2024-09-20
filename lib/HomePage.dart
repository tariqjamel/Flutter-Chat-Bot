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

import 'CustomLoader.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;
  FlutterTts flutterTts = FlutterTts();
  List<ChatMessage> messages = [];

  late stt.SpeechToText speechToText;
  bool _isListening = false;
  bool isTyping = false;
  String _text = '';
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Gemini",
    profileImage:
        "https://seeklogo.com/images/G/google-gemini-logo-A5787B2669-seeklogo.com.png",
  );

  final ScrollController scrollController = ScrollController();
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    speechToText = stt.SpeechToText();
    _requestPermission();
    _initSpeech();

    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _drawer(),
        appBar: AppBar(
          title: const Text('Ask Gemini'),
          backgroundColor: Colors.blue.shade100,
        ),
        body:  _builtUI()
    );
  }

  Widget _drawer(){
    return  Drawer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.blue.shade100,
              child: InkWell(
                onTap: (){
                  Navigator.pop(context);
               //   Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfile()),);
                },
                child: Container(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      bottom: 24
                  ),
                  child: const Column(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundImage: NetworkImage("https://seeklogo.com/images/G/google-gemini-logo-A5787B2669-seeklogo.com.png"),
                      ),
                      SizedBox(height: 12,),
                      Text('Ask Gemini',
                        style: TextStyle(
                            fontSize: 28,
                            color: Colors.white
                        ),),
                      Text('',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Column(
              children: [
                ListTile(
                  leading: Icon(Icons.home_outlined),
                  title: Text('New Chat'),
                  onTap: (){
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()),);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: Text('Favourites'),
                  onTap: (){
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CustomLoader()),);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.workspaces),
                  title: Text('Workflow'),
                  onTap: (){},
                ),
                ListTile(
                  leading: Icon(Icons.update),
                  title: Text('History'),
                  onTap: (){},
                ),
                const Divider(color: Colors.black45,),
                ListTile(
                  leading: Icon(Icons.account_tree_outlined),
                  title: Text('Plugins'),
                  onTap: (){},
                ),
                ListTile(
                  leading: Icon(Icons.notifications_outlined),
                  title: Text('Notifications'),
                  onTap: (){},
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _builtUI(){
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
                        if (message.medias != null && message.medias!.isNotEmpty)
                          Image.file(
                            File(message.medias!.first.url),
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        BubbleNormal(
                          text: message.text,
                          isSender: message.user.id == currentUser.id,
                          color: message.user.id == currentUser.id
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                        ),
                      ],
                    ),
                  ),
                  if (message.user.id == geminiUser.id)
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () {
                        _readAloud(message.text);
                      },
                    ),
                ],
              );
            },
          ),
        ),

        _buildInputField(),
      ],
    );
  }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo),
                    onPressed: _sendMediaMessage,
                    color: Colors.blue,
                    constraints: BoxConstraints(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (text) {
                        setState(() {});
                      },
                      onSubmitted: (text) {
                        if (text.isNotEmpty) {
                          _sendMessage(ChatMessage(
                            user: currentUser,
                            createdAt: DateTime.now(),
                            text: text,
                          ));
                          controller.clear();
                        }
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter text",
                      ),
                    ),
                  ),
                  VerticalDivider(color: Colors.black, width: 8),
                  IconButton(
                    onPressed: controller.text.isEmpty ? _listen : () {
                      if (controller.text.isNotEmpty) {
                        _sendMessage(ChatMessage(
                          user: currentUser,
                          createdAt: DateTime.now(),
                          text: controller.text,
                        ));
                        controller.clear();
                      }
                    },
                    icon: Icon(
                      controller.text.isEmpty ? Icons.mic : Icons.send,
                      color: Colors.blue,
                      size: 22,
                    ),
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.headset), // Headphone icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CustomLoader()),
              );
            },
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}
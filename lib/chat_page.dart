import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatefulWidget {
  static const routeName = '/chat';

  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();

  final List<String> _questions = [
    'Bagaimana cara melacak status pengiriman pesanan?',
    'Bagaimana cara membatalkan pesanan ShopeeFood?',
    'Apa yang harus dilakukan jika restoran tutup saat mengambil?',
    'Bagaimana cara mengaktifkan fitur SPayLater?',
  ];

  @override
  void initState() {
    super.initState();
    _sendBotQuestions();
  }

  void _sendMessage(String userMessage) {
    if (userMessage.isNotEmpty) {
      setState(() {
        // Insert the user's message at the top
        _messages.insert(0, {'text': userMessage, 'isMe': true});
        _controller.clear();
        _sendBotResponse(userMessage);
      });
    }
  }

  void _sendBotResponse(String userMessage) {
    String botMessage;

    if (userMessage.toLowerCase().contains('melacak status')) {
      botMessage = 'Anda dapat melacak status pengiriman pesanan Anda di halaman pesanan.';
    } else if (userMessage.toLowerCase().contains('membatalkan pesanan')) {
      botMessage = 'Anda bisa membatalkan pesanan ShopeeFood melalui aplikasi sebelum pesanan diproses.';
    } else if (userMessage.toLowerCase().contains('restoran tutup')) {
      botMessage = 'Jika restoran tutup, Anda dapat menghubungi layanan pelanggan untuk bantuan lebih lanjut.';
    } else if (userMessage.toLowerCase().contains('mengaktifkan spaylater')) {
      botMessage = 'Untuk mengaktifkan fitur SPayLater, buka menu SPayLater di aplikasi dan ikuti petunjuknya.';
    } else {
      botMessage = 'Maaf, saya tidak mengerti itu. Bisakah Anda mengulanginya?';
    }

    // Add the bot response after a delay to simulate typing
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        // Insert the bot's response after the user's message
        _messages.insert(0, {'text': botMessage, 'isMe': false});
      });
    });
  }

  void _sendBotQuestions() {
    setState(() {
      _messages.add({
        'text': 'Silahkan pilih topik yang ingin kamu tanyakan:',
        'isMe': false,
        'isQuestion': true
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Choki'),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: InkWell(
                child: Image.asset('assets/icons/WA.jpg', width: 20, height: 20),
                onTap: () async {
                  await launch('https://wa.me/6281292303471');
                },
              ),
            ),
            InkWell(
              child: const Icon(Icons.email, size: 20),
              onTap: () async {
                await launch('mailto:acepmictominay@gmail.com');
              },
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        iconTheme: const IconThemeData(color: Colors.orange), // Adjust back button color
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Show the latest messages at the bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final messageData = _messages[index];
                return messageData['isQuestion'] == true
                    ? ChatQuestionBubble(
                        questions: _questions,
                        onQuestionSelected: (selectedQuestion) {
                          _sendMessage(selectedQuestion);
                        },
                      )
                    : ChatBubble(
                        message: messageData['text'],
                        isMe: messageData['isMe'],
                      );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan di sini (maks. 30 kata)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color.fromRGBO(49, 159, 67, 1.0)),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;

  const ChatBubble({
    required this.message,
    required this.isMe,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75, // Limit the width of the chat bubble
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              color: isMe ? Colors.orange[300] : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(0),
                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(15),
              ),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatQuestionBubble extends StatelessWidget {
  final List<String> questions;
  final Function(String) onQuestionSelected;

  const ChatQuestionBubble({
    required this.questions,
    required this.onQuestionSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75, // Limit the width of the chat bubble
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Silahkan pilih topik yang ingin kamu tanyakan:',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                ...questions.map((question) {
                  return GestureDetector(
                    onTap: () => onQuestionSelected(question),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey), // Add border
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              question,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

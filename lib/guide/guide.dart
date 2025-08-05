import 'package:flutter/material.dart';
import 'package:bidyaai/theme.dart';

/*
This is guide screen it contains how to use app and interact with ai .


 */
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  String _currentLanguage = 'en';

  void _toggleLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'en' ? 'ne' : 'en';
    });
  }

  // Content for the guide in both English and Nepali
  final Map<String, dynamic> _content = {
    'en': {
      'title': 'BidyaAI Guide',
      'intro':
          'Hello! I am BidyaAI, your friendly educational assistant. I am here to help you learn and explore subjects from class 1 to 10. Here are some of the things you can do:',
      'commands_title': 'Useful Commands',
      'commands': [
        {
          'command': '/language [language_code]',
          'description':
              'Type /language followed by a language code (e.g., "en-US", "ne") to change the language I speak. This makes learning easier!',
        },
        {
          'command': '/quiz [topic]',
          'description':
              'Want a fun test? Type /quiz followed by a topic (like "math" or "science") to get a 3-question quiz to test your knowledge.',
        },
        {
          'command': '/reader',
          'description':
              'This command opens a special reader where I can help you understand documents. It\'s like having a smart tutor for your notes!',
        },
        {
          'command': '/aware',
          'description':
              'This makes me remember our conversation. It\'s helpful when we are discussing a big topic and you don\'t want to repeat yourself.',
        },
        {
          'command': '/clear',
          'description':
              'Use this to clear our chat history. It\'s like starting a brand new conversation.',
        },
      ],
      'video_chat':
          'You can also use the video chat feature! Just tap the video camera icon on the top-right of the chat screen. I can look at things through your phone camera and help you with your homework or a problem in front of you.',
    },
    'ne': {
      'title': 'बिद्याएआई गाइड',
      'intro':
          'नमस्ते! म बिद्याएआई हुँ, तपाईंको सहयोगी शैक्षिक सहायक। म तपाईंलाई कक्षा १ देखि १० सम्मका विषयहरू सिक्न र अन्वेषण गर्न मद्दत गर्न यहाँ छु। यहाँ तपाईंले गर्न सक्ने केही कुराहरू छन्:',
      'commands_title': 'उपयोगी आदेशहरू',
      'commands': [
        {
          'command': '/language [भाषा कोड]',
          'description':
              'मलाई बोल्ने भाषा परिवर्तन गर्न /language र त्यसपछि भाषा कोड (जस्तै: "en-US", "ne") टाइप गर्नुहोस्। यसले सिक्न सजिलो बनाउँछ!',
        },
        {
          'command': '/quiz [विषय]',
          'description':
              'रमाइलो परीक्षा दिन चाहनुहुन्छ? आफ्नो ज्ञान परीक्षण गर्नको लागि /quiz र त्यसपछि एउटा विषय (जस्तै "गणित" वा "विज्ञान") टाइप गरेर ३-प्रश्नको क्विज पाउनुहोस्।',
        },
        {
          'command': '/reader',
          'description':
              'यो आदेशले एउटा विशेष रिडर खोल्छ जहाँ म तपाईंलाई कागजातहरू बुझ्न मद्दत गर्न सक्छु। यो तपाईंको नोटहरूको लागि एक स्मार्ट ट्यूटर जस्तै हो!',
        },
        {
          'command': '/aware',
          'description':
              'यसले मलाई हाम्रो कुराकानी सम्झन लगाउँछ। हामी कुनै ठूलो विषयमा छलफल गर्दा र तपाईंले आफैलाई दोहोर्याउन नपर्दा यो उपयोगी हुन्छ।',
        },
        {
          'command': '/clear',
          'description':
              'हाम्रो कुराकानी इतिहास मेटाउन यो प्रयोग गर्नुहोस्। यो नयाँ कुराकानी सुरु गरेजस्तै हो।',
        },
      ],
      'video_chat':
          'तपाईं भिडियो च्याट सुविधा पनि प्रयोग गर्न सक्नुहुन्छ! च्याट स्क्रिनको माथिल्लो-दायाँ कुनामा रहेको भिडियो क्यामेरा आइकनमा ट्याप गर्नुहोस्। म तपाईंको फोनको क्यामेराबाट चीजहरू हेर्न सक्छु र तपाईंको गृहकार्य वा तपाईंको अगाडि भएको समस्यामा मद्दत गर्न सक्छु।',
    },
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final content = _content[_currentLanguage]!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(content['title']),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Text(
              _currentLanguage == 'en' ? 'नेपाली' : 'English',
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: _toggleLanguage,
            tooltip: 'Change Language',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content['intro'], style: textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text(
              content['commands_title'],
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._buildCommands(content['commands'] as List<Map<String, String>>),
            const SizedBox(height: 24),
            Text(
              'Live Video Chat',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(content['video_chat'], style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCommands(List<Map<String, String>> commands) {
    final textTheme = Theme.of(context).textTheme;
    return commands.map((command) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              command['command']!,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(command['description']!, style: textTheme.bodyMedium),
          ],
        ),
      );
    }).toList();
  }
}

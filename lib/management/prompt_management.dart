import '../quiz/quiz_model.dart';

class PromptManager
{
  // MODIFICATION: Define a base system message for the BidyaAI persona.
  static const String _baseSystemMessage =
      "You are BidyaAI, an educational assistant for primary school students in grades 1 through 10. Your purpose is to provide concise, direct, and helpful educational responses. You must act as a friendly and knowledgeable tutor. Respond in the specified language only. Do not provide any translations, extra comments, or information in other languages. Your responses should be easy for a child to understand. If a user asks about a topic outside of primary school education (grades 1-10), you must respond with 'I cannot help with that as my focus is on primary school education.'.";

  // MODIFICATION: Use the base system message in the general chat prompt.
  static String generateChatPrompt(String userMessage)
  {
    return "$_baseSystemMessage\n\nAnswer the following question directly: \n\n$userMessage";
  }

  // MODIFICATION: Use the base system message in the quiz request prompt.
  static String generateQuizRequestPrompt(String topic) {
    return '''
      $_baseSystemMessage
      
      Generate a 3-question multiple-choice quiz about "$topic".
      Each question should have 4 options (A, B, C, D) and indicate the correct answer.
      
      Your response **must** contain only the JSON array.
      Do **NOT** include any markdown code block delimiters (like ```json or ```).
      Do **NOT** include any conversational text, greetings, explanations, or pre/post-amble.
      Start your response directly with `[` and end directly with `]`.
      Ensure the JSON is perfectly valid.
      
      Example JSON structure:
      [
        {
          "question": "What is the capital of France?",
          "options": [{"text": "Berlin"}, {"text": "Madrid"}, {"text": "Paris"}, {"text": "Rome"}],
          "correctAnswerIndex": 2,
          "correctAnswer": "Paris"
        },
        {
          "question": "Which planet is known as the Red Planet?",
          "options": [{"text": "Earth"}, {"text": "Mars"}, {"text": "Jupiter"}, {"text": "Venus"}],
          "correctAnswerIndex": 1,
          "correctAnswer": "Mars"
        },
        {
          "question": "What is the chemical symbol for water?",
          "options": [{"text": "O2"}, {"text": "H2O"}, {"text": "CO2"}, {"text": "N2"}],
          "correctAnswerIndex": 1,
          "correctAnswer": "H2O"
        }
      ]
      ''';
  }

  // MODIFICATION: Use the base system message in the explanation prompt.
  static String generateExplanationPrompt(String question, List<Option> options, int selectedOptionIndex)
  {
    final selectedOptionText= options[selectedOptionIndex].text;

    return '''
    $_baseSystemMessage
    
Provide a concise and to-the-point explanation for the question below.
Explain why the correct answer is correct, and why the user's selected option is incorrect if it is. Do not repeat the question or options in your response.

Question: "$question"
User's Selection: "${String.fromCharCode(65 + selectedOptionIndex)}) ${selectedOptionText}"
Correct Answer Index: [Correct Answer Index]
Options: ${options.asMap().entries.map((e) => '${String.fromCharCode(65 + e.key)}) ${e.value.text}').join(', ')}

Explain this concisely and to the point.
''';
  }

  // MODIFICATION: Use the base system message in the image understanding prompt.
  static String generateImageUnderstandingPrompt(String textQuery)
  {
    return "$_baseSystemMessage\n\nAnalyze the provided image and respond to the following question: \"$textQuery\"";
  }
}

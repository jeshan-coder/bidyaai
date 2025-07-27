import '../quiz/quiz_model.dart';

class PromptManager
{

//   for general chat messages
  static String generateChatPrompt(String userMessage)
  {
    return userMessage;
  }

  static String generateQuizRequestPrompt(String topic) {
    return '''
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

  static String generateExplanationPrompt(String question, List<Option> options, int selectedOptionIndex)
  {
    final selectedOptionText= options[selectedOptionIndex].text;

    return '''
      Explain why the answer to the following question is correct or incorrect, considering the user selected option "${String.fromCharCode(65 + selectedOptionIndex)} (${selectedOptionText})".
      
      Question: "$question"
      Options: ${options.asMap().entries.map((e) => '${String.fromCharCode(65 + e.key)}) ${e.value}').join(', ')}
      
      Provide a concise explanation.
          ''';
  }

  static String generateImageUnderstandingPrompt(String textQuery)
  {
    return "Analyze the provided image and respond to the following question: \"$textQuery\"";
  }


}
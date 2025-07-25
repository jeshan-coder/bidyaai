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
      generate a 3-question multiple-choice quiz about "$topic".
    Each question should have 4 options (A, B, C, D) and indicate the correct answer.
    Provide the output in a JSON array format.
    
    Example JSON structure:
    [
      {
        "question": "What is the capital of France?",
        "options": ["Berlin", "Madrid", "Paris", "Rome"],
        "correctAnswerIndex": 2,
        "correctAnswer": "Paris"
      },
      {
        "question": "Which planet is known as the Red Planet?",
        "options": ["Earth", "Mars", "Jupiter", "Venus"],
        "correctAnswerIndex": 1,
        "correctAnswer": "Mars"
      }
    ]
    Please ensure the JSON is valid and only contains the quiz data.
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


}
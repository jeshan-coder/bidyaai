class Quiz
{
  final List<Question> questions;

  Quiz({required this.questions});


  factory Quiz.fromJson(List<dynamic> json)
  {
    return Quiz(
      questions:json.map((q)=>Question.fromJson(q as Map<String,dynamic>)).toList()
    );
  }

  List<Map<String,dynamic>> toJson()
  {
    return questions.map((q)=>q.toJson()).toList();
  }

}





class Question
{
  final String questionText;
  final List<Option> options;
  final int correctAnswerIndex;
  final String correctAnswerText;

  Question({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.correctAnswerText
  });


  factory Question.fromJson(Map<String,dynamic> json)
  {
    final List<dynamic> optionsJson= json['options'] as List<dynamic>;
    final List<Option> parsedOptions= optionsJson.map((o)=>Option.fromJson(o as Map<String,dynamic>)).toList();


    final int correctIndex= json['correctAnswerIndex'] as int;

    final String correctText=parsedOptions[correctIndex].text;

    return Question(questionText:json['question'] as String,
        options: parsedOptions,
        correctAnswerIndex: correctIndex,
        correctAnswerText: correctText);

  }

  Map<String,dynamic> toJson()
  {
    return {
      'question':questionText,
      'options':options.map((o)=>o.toJson()).toList(),
      'correctAnswerIndex':correctAnswerText,
      'correctAnswer':correctAnswerText
    };
  }



}





class Option
{
  final String text;
  final bool isCorrect;

  Option({required this.text, this.isCorrect=false});

  factory Option.fromJson(Map<String,dynamic> json)
  {
    return Option(
      text: json['text'] as String,
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }

  Map<String,dynamic> toJson()
  {
    return {
      'text':text,
      'isCorrect':isCorrect
    };
  }
}
class RagAnswer {
  final String encounterId;
  final String question;
  final String answer;

  const RagAnswer({
    required this.encounterId,
    required this.question,
    required this.answer,
  });

  factory RagAnswer.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return RagAnswer(
      encounterId: data['encounter_id'] as String? ?? '',
      question: data['question'] as String? ?? '',
      answer: data['answer'] as String? ?? 'No answer available.',
    );
  }
}

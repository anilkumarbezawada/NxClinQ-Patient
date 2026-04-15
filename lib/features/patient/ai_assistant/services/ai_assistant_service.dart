import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../models/rag_appointment.dart';
import '../models/rag_answer.dart';

class AiAssistantService {
  AiAssistantService._();
  static final AiAssistantService instance = AiAssistantService._();

  /// Fetches the list of appointments that have RAG-ready transcripts.
  Future<List<RagAppointment>> getRagAppointments() async {
    final rawJson = await ApiClient.instance.get(ApiConstants.ragContext);

    final success = rawJson['success'] as bool? ?? false;
    final dataList = rawJson['data'] as List<dynamic>?;

    if (!success || dataList == null) {
      throw ApiException.fromApiError(
        code: 'RAG_CONTEXT_ERROR',
        message: rawJson['message'] as String? ??
            'Failed to load AI-ready appointments.',
      );
    }

    return RagAppointment.listFromJson(dataList);
  }

  /// Asks a question against a specific encounter's clinical context.
  Future<RagAnswer> askQuestion({
    required String encounterId,
    required String question,
  }) async {
    final rawJson = await ApiClient.instance.post(
      ApiConstants.ragAsk(encounterId),
      data: {'question': question},
    );

    final success = rawJson['success'] as bool? ?? false;
    if (!success || rawJson['data'] == null) {
      throw ApiException.fromApiError(
        code: 'RAG_ASK_ERROR',
        message: 'Unable to get an answer. Please try again.',
      );
    }

    return RagAnswer.fromJson(rawJson);
  }
}

class AiGenerationJob {
  const AiGenerationJob({
    required this.id,
    required this.status,
    this.progress,
    this.message,
    this.error,
    this.outputImageId,
    this.request = const {},
    this.parameters = const {},
  });
  final String id, status;
  final double? progress;
  final String? message, error, outputImageId;
  final Map<String, dynamic> request, parameters;
  bool get terminal => ['completed', 'failed', 'cancelled'].contains(status);
  factory AiGenerationJob.fromJson(Map<String, dynamic> json) =>
      AiGenerationJob(
        id: json['id'] as String,
        status: json['status'] as String,
        progress: (json['progress'] as num?)?.toDouble(),
        message: json['message'] as String?,
        error: json['error'] as String?,
        outputImageId: json['output_image_id'] as String?,
        request: Map<String, dynamic>.from(json['request'] as Map? ?? {}),
        parameters: Map<String, dynamic>.from(json['parameters'] as Map? ?? {}),
      );
}

enum DocumentStatus {
  pending,
  uploading,
  processing,
  awaitingReview,
  reviewed,
  error;

  String get label {
    switch (this) {
      case DocumentStatus.pending:
        return 'Pendente';
      case DocumentStatus.uploading:
        return 'Enviando';
      case DocumentStatus.processing:
        return 'Processando IA';
      case DocumentStatus.awaitingReview:
        return 'Aguardando Conferência';
      case DocumentStatus.reviewed:
        return 'Conferido';
      case DocumentStatus.error:
        return 'Erro';
    }
  }
}

class DocumentModel {
  final String id;
  final String clientId;
  final String originalName;
  final String? standardizedName;
  final String fileType;
  final int fileSizeBytes;
  final DocumentStatus status;
  final String? previewUrl;
  final DateTime createdAt;
  final Map<String, dynamic>? extractedData;
  final String? errorMessage;

  const DocumentModel({
    required this.id,
    required this.clientId,
    required this.originalName,
    this.standardizedName,
    required this.fileType,
    required this.fileSizeBytes,
    this.status = DocumentStatus.pending,
    this.previewUrl,
    required this.createdAt,
    this.extractedData,
    this.errorMessage,
  });

  bool get isProcessed =>
      status == DocumentStatus.awaitingReview ||
      status == DocumentStatus.reviewed;

  bool get isReviewed => status == DocumentStatus.reviewed;

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      originalName: json['original_name']?.toString() ?? '',
      standardizedName: json['standardized_name']?.toString(),
      fileType: json['file_type']?.toString() ?? 'pdf',
      fileSizeBytes: json['file_size_bytes'] is int
          ? json['file_size_bytes'] as int
          : int.tryParse(json['file_size_bytes']?.toString() ?? '0') ?? 0,
      status: _parseStatus(json['status']?.toString()),
      previewUrl: json['preview_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      extractedData: json['extracted_data'] is Map
          ? Map<String, dynamic>.from(json['extracted_data'] as Map)
          : null,
      errorMessage: json['error_message']?.toString(),
    );
  }

  static DocumentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'uploading':
        return DocumentStatus.uploading;
      case 'processing':
        return DocumentStatus.processing;
      case 'awaitingreview':
      case 'awaiting_review':
      case 'aguardando_conferencia':
        return DocumentStatus.awaitingReview;
      case 'reviewed':
      case 'conferido':
        return DocumentStatus.reviewed;
      case 'error':
        return DocumentStatus.error;
      case 'pending':
      default:
        return DocumentStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'original_name': originalName,
      if (standardizedName != null) 'standardized_name': standardizedName,
      'file_type': fileType,
      'file_size_bytes': fileSizeBytes,
      'status': status.name,
      if (previewUrl != null) 'preview_url': previewUrl,
      'created_at': createdAt.toIso8601String(),
      if (extractedData != null) 'extracted_data': extractedData,
      if (errorMessage != null) 'error_message': errorMessage,
    };
  }

  DocumentModel copyWith({
    String? id,
    String? clientId,
    String? originalName,
    String? standardizedName,
    String? fileType,
    int? fileSizeBytes,
    DocumentStatus? status,
    String? previewUrl,
    DateTime? createdAt,
    Map<String, dynamic>? extractedData,
    String? errorMessage,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      originalName: originalName ?? this.originalName,
      standardizedName: standardizedName ?? this.standardizedName,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      previewUrl: previewUrl ?? this.previewUrl,
      createdAt: createdAt ?? this.createdAt,
      extractedData: extractedData ?? this.extractedData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

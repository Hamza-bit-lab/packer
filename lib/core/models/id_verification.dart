import 'user.dart';

enum DocumentType { cnic, passport }

extension DocumentTypeApi on DocumentType {
  String get apiValue => name;

  String get label => this == DocumentType.cnic ? 'CNIC' : 'Passport';
}

DocumentType _documentTypeFromString(String value) =>
    value == 'passport' ? DocumentType.passport : DocumentType.cnic;

class IdVerification {
  IdVerification({
    required this.id,
    required this.documentType,
    required this.status,
    required this.rejectionReason,
    required this.createdAt,
  });

  factory IdVerification.fromJson(Map<String, dynamic> json) {
    return IdVerification(
      id: json['id'] as int,
      documentType: _documentTypeFromString(json['document_type'] as String),
      status: IdVerificationStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => IdVerificationStatus.none,
      ),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final DocumentType documentType;
  final IdVerificationStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
}

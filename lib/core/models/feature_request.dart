enum FeatureRequestStatus { open, inProgress, completed }

FeatureRequestStatus _statusFromString(String? value) {
  return switch (value) {
    'in_progress' => FeatureRequestStatus.inProgress,
    'completed' => FeatureRequestStatus.completed,
    _ => FeatureRequestStatus.open,
  };
}

enum VoteDirection { up, down }

VoteDirection? _voteFromString(String? value) {
  return switch (value) {
    'up' => VoteDirection.up,
    'down' => VoteDirection.down,
    _ => null,
  };
}

class FeatureRequest {
  FeatureRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.submittedBy,
    required this.isMine,
    required this.upvotes,
    required this.downvotes,
    required this.myVote,
    required this.createdAt,
  });

  factory FeatureRequest.fromJson(Map<String, dynamic> json) {
    return FeatureRequest(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      status: _statusFromString(json['status'] as String?),
      submittedBy: json['submitted_by'] as String?,
      isMine: json['is_mine'] as bool? ?? false,
      upvotes: json['upvotes_count'] as int? ?? 0,
      downvotes: json['downvotes_count'] as int? ?? 0,
      myVote: _voteFromString(json['my_vote'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final String title;
  final String description;
  final FeatureRequestStatus status;
  final String? submittedBy;
  final bool isMine;
  final int upvotes;
  final int downvotes;
  final VoteDirection? myVote;
  final DateTime createdAt;
}

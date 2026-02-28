class AutoReplyRule {
  final String keyword;
  final String replyMessage;
  final bool isExactMatch;
  final bool isActive;

  AutoReplyRule({
    required this.keyword,
    required this.replyMessage,
    this.isExactMatch = false,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'keyword': keyword,
    'replyMessage': replyMessage,
    'isExactMatch': isExactMatch,
    'isActive': isActive,
  };

  factory AutoReplyRule.fromJson(Map<String, dynamic> json) {
    return AutoReplyRule(
      keyword: json['keyword'] ?? '',
      replyMessage: json['replyMessage'] ?? '',
      isExactMatch: json['isExactMatch'] ?? false,
      isActive: json['isActive'] ?? true,
    );
  }
}

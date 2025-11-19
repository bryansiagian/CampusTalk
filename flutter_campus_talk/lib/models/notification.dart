import 'package:flutter/foundation.dart';

class AppNotification {
  final int id;
  final int userId;
  final String type;
  final int? sourceId;
  final String? sourceType;
  final String message;
  final bool isRead;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    this.sourceId,
    this.sourceType,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'], 
      userId: json['userId'], 
      type: json['type'], 
      sourceId: json['source_id'],
      sourceType: json['source_type'],
      message: json['message'], 
      isRead: json['isRead'] ?? false, 
      createdAt: json['created_at'],
    );
  }
}
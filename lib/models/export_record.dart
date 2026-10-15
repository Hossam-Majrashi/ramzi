import 'platform_target.dart';

/// One entry in a project's export history.
class ExportRecord {
  final PlatformTarget target;
  final DateTime timestamp;

  /// Where the export went (folder path on IO platforms, "download" on web).
  final String destination;

  /// Number of files written.
  final int fileCount;

  const ExportRecord({
    required this.target,
    required this.timestamp,
    required this.destination,
    required this.fileCount,
  });

  Map<String, dynamic> toJson() => {
    'target': target.name,
    'timestamp': timestamp.toIso8601String(),
    'destination': destination,
    'fileCount': fileCount,
  };

  factory ExportRecord.fromJson(Map<String, dynamic> json) {
    return ExportRecord(
      target:
          PlatformTarget.values.asNameMap()[json['target'] as String? ?? ''] ??
          PlatformTarget.android,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      destination: json['destination'] as String? ?? '',
      fileCount: (json['fileCount'] as num?)?.toInt() ?? 0,
    );
  }
}

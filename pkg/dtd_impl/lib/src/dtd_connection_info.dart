// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Metadata regarding a running Dart Tooling Daemon instance.
///
/// This metadata is serialized and written to a pid-file in the dart-data-home
/// directory whenever a DTD instance is started. This allows
/// `dart tooling-daemon --list`
/// to discover locally running instances.
class DTDConnectionInfo {
  /// Parses the [DTDConnectionInfo] from a json map.
  factory DTDConnectionInfo.fromJson(Map<String, Object?> json) {
    return DTDConnectionInfo(
      wsUri: json[_kWsUri] as String? ?? '',
      epoch: json[_kEpoch] as int? ?? 0,
      pid: json[_kPid] as int? ?? 0,
      dartVersion: json[_kDartVersion] as String? ?? '',
      workingDirectory:
          json[_kWorkingDirectory] as String? ??
          // Fall back to `_kWorkspaceRoot` for backwards compatibility with PID
          // files written by older SDKs.
          json[_kWorkspaceRoot] as String? ??
          '',
      workspaceRoots: <String>[
        ...?(json[_kWorkspaceRoots] as List<Object?>?)?.whereType<String>(),
      ],
      ideName: json[_kIdeName] as String?,
    );
  }

  DTDConnectionInfo({
    required this.dartVersion,
    required this.epoch,
    required this.pid,
    required this.workingDirectory,
    required this.wsUri,
    this.ideName,
    this.workspaceRoots = const <String>[],
  });

  /// The WebSocket URI of this DTD instance.
  final String wsUri;

  /// The milliseconds since epoch when this DTD instance was started.
  final int epoch;

  /// The system process ID of the running DTD daemon.
  final int pid;

  /// The version of Dart running the DTD instance.
  final String dartVersion;

  /// The working directory the DTD instance was launched from.
  final String workingDirectory;

  /// The workspace roots configured for this DTD instance via
  /// `FileSystem.setIDEWorkspaceRoots`.
  final List<String> workspaceRoots;

  /// The name of the IDE that owns this DTD instance, if any.
  final String? ideName;

  static const String _kWsUri = 'wsUri';
  static const String _kEpoch = 'epoch';
  static const String _kPid = 'pid';
  static const String _kDartVersion = 'dartVersion';
  static const String _kWorkingDirectory = 'workingDirectory';
  static const String _kWorkspaceRoots = 'workspaceRoots';
  static const String _kIdeName = 'ideName';

  // Legacy keys retained for backwards compatibility with older SDKs.
  static const String _kWorkspaceRoot = 'workspaceRoot';

  /// Serializes the observation to a json object.
  ///
  /// Note: Because PID files are read across different Dart SDK versions,
  /// this format must remain backwards compatible (only add new fields,
  /// never remove or alter existing ones).
  Map<String, Object?> toJson() {
    return <String, Object?>{
      _kWsUri: wsUri,
      _kEpoch: epoch,
      _kPid: pid,
      _kDartVersion: dartVersion,
      _kWorkingDirectory: workingDirectory,
      _kWorkspaceRoots: workspaceRoots,
      _kIdeName: ?ideName,
      // Legacy fields retained for backwards compatibility with older SDKs.
      _kWorkspaceRoot: workspaceRoots.firstOrNull ?? workingDirectory,
    };
  }

  @override
  String toString() {
    final duration = Duration(
      milliseconds: DateTime.now().millisecondsSinceEpoch - epoch,
    );
    return <String>[
      '  WS URI:            $wsUri',
      '  Working Directory: $workingDirectory',
      if (workspaceRoots.isNotEmpty)
        '  Workspace Roots:   ${workspaceRoots.join(', ')}',
      '  Dart Version:      $dartVersion',
      '  PID:               $pid',
      if (ideName != null) '  IDE:               $ideName',
      '  Started:           ${duration.ago()}',
      '',
    ].join('\n');
  }
}

/// Simple "X (months|days|hours|minutes) ago" [Duration] converter.
extension _DurationAgo on Duration {
  String ago() {
    if (inDays > 31) {
      return '${inDays ~/ 31} months ago';
    }
    if (inDays > 1) {
      return '$inDays days ago';
    }
    if (inHours > 1) {
      return '$inHours hours ago';
    }
    if (inMinutes > 1) {
      return '$inMinutes minutes ago';
    }
    if (inMinutes == 1) {
      return '1 minute ago';
    }
    return 'less than a minute ago';
  }
}

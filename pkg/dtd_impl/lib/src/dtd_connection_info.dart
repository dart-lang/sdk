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
      workspaceRoot: json[_kWorkspaceRoot] as String? ?? '',
    );
  }

  DTDConnectionInfo({
    required this.wsUri,
    required this.epoch,
    required this.pid,
    required this.dartVersion,
    required this.workspaceRoot,
  });

  /// The WebSocket URI of this DTD instance.
  final String wsUri;

  /// The milliseconds since epoch when this DTD instance was started.
  final int epoch;

  /// The system process ID of the running DTD daemon.
  final int pid;

  /// The version of Dart running the DTD instance.
  final String dartVersion;

  /// The workspace root of the directory the DTD instance was launched from.
  final String workspaceRoot;

  static const String _kWsUri = 'wsUri';
  static const String _kEpoch = 'epoch';
  static const String _kPid = 'pid';
  static const String _kDartVersion = 'dartVersion';
  static const String _kWorkspaceRoot = 'workspaceRoot';

  /// Serializes the observation to a json object.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      _kWsUri: wsUri,
      _kEpoch: epoch,
      _kPid: pid,
      _kDartVersion: dartVersion,
      _kWorkspaceRoot: workspaceRoot,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('  WS URI:         $wsUri');
    buffer.writeln('  Workspace Root: $workspaceRoot');
    buffer.writeln('  Dart Version:   $dartVersion');
    buffer.writeln('  PID:            $pid');

    final duration = Duration(
      milliseconds: DateTime.now().millisecondsSinceEpoch - epoch,
    );

    buffer.writeln('  Started:        ${duration.ago()}');
    return buffer.toString();
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

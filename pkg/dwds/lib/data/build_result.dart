// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum BuildStatus {
  started,
  succeeded,
  failed;

  factory BuildStatus.fromJson(String json) {
    return BuildStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () {
        throw ArgumentError('Unknown BuildStatus: $json');
      },
    );
  }

  String toJson() => name;
}

class BuildResult {
  final BuildStatus status;

  BuildResult({required this.status});

  factory BuildResult.fromJson(Map<String, dynamic> json) {
    return BuildResult(status: BuildStatus.fromJson(json['status'] as String));
  }

  Map<String, dynamic> toJson() {
    return {'status': status.toJson()};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildResult &&
          runtimeType == other.runtimeType &&
          status == other.status;

  @override
  int get hashCode => status.hashCode;

  @override
  String toString() => 'BuildResult(status: $status)';
}

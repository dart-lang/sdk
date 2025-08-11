// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';

import 'helper.dart';

/// Metadata attached to a recorded usages file.
///
/// Whatever [Metadata] should be added to the usage recording. Care should be
/// applied to not include non-deterministic or dynamic data such as timestamps,
/// as this would mess with the usage recording caching.
class Metadata {
  /// The underlying data.
  ///
  /// Together with the metadata extension [MetadataExt], this makes the
  /// metadata extensible by the user implementing the recording. For example,
  /// dart2js might want to store different metadata than the Dart VM.
  final Map<String, Object?> json;

  const Metadata._({required this.json});

  factory Metadata.fromJson(Map<String, Object?> json) =>
      Metadata._(json: json);

  @override
  bool operator ==(covariant Metadata other) {
    if (identical(this, other)) return true;

    return deepEquals(other.json, json);
  }

  @override
  int get hashCode => deepHash(json);
}

extension MetadataExt on Metadata {
  Version get version => Version.parse(json['version'] as String);
  String get comment => json['comment'] as String;
}

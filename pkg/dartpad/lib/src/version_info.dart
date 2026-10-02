// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

/// Version and capability metadata for a _DartPad SDK_.
final class VersionInfo {
  /// Major version of the worker protocol.
  final int workerProtocolMajor;

  /// Minor version of the worker protocol.
  final int workerProtocolMinor;

  /// Run modes supported by this DartPad SDK (e.g. `['console']`).
  final List<String> modes;

  /// Version of the Dart SDK in this DartPad SDK.
  final String dartVersion;

  /// Git commit revision of the Dart SDK.
  final String dartRevision;

  /// Additional key-value metadata properties for this DartPad SDK.
  final Map<String, String> properties;

  VersionInfo._({
    required this.workerProtocolMajor,
    required this.workerProtocolMinor,
    required List<String> modes,
    required this.dartVersion,
    required this.dartRevision,
    Map<String, String> properties = const {},
  }) : modes = List.unmodifiable(modes),
       properties = Map.unmodifiable(properties);

  factory VersionInfo.fromJson(Map<String, Object?> json) {
    if (json
        case {
          'workerProtocolMajor': final num workerProtocolMajor,
          'workerProtocolMinor': final num workerProtocolMinor,
          'modes': final List<Object?> modes,
          'dartVersion': final String dartVersion,
          'dartRevision': final String dartRevision,
          'properties': final Map<Object?, Object?> properties,
        }
        when modes.every((m) => m is String) &&
            properties.entries.every(
              (e) => e.key is String && e.value is String,
            )) {
      return VersionInfo._(
        workerProtocolMajor: workerProtocolMajor.toInt(),
        workerProtocolMinor: workerProtocolMinor.toInt(),
        modes: modes.cast<String>(),
        dartVersion: dartVersion,
        dartRevision: dartRevision,
        properties: properties.cast<String, String>(),
      );
    }
    throw FormatException('Invalid VersionInfo JSON: $json');
  }

  Map<String, Object?> toJson() => {
    'workerProtocolMajor': workerProtocolMajor,
    'workerProtocolMinor': workerProtocolMinor,
    'modes': modes,
    'dartVersion': dartVersion,
    'dartRevision': dartRevision,
    'properties': properties,
  };

  @override
  String toString() => 'VersionInfo(${jsonEncode(toJson())})';
}

/// Creates a [VersionInfo] instance.
VersionInfo createVersionInfo({
  required int workerProtocolMajor,
  required int workerProtocolMinor,
  required List<String> modes,
  required String dartVersion,
  required String dartRevision,
  Map<String, String> properties = const {},
}) => VersionInfo._(
  workerProtocolMajor: workerProtocolMajor,
  workerProtocolMinor: workerProtocolMinor,
  modes: modes,
  dartVersion: dartVersion,
  dartRevision: dartRevision,
  properties: properties,
);

/// Extracts Flutter version properties from a parsed `flutter.version.json`.
Map<String, String> extractFlutterVersionProperties(
  Map<String, Object?> flutterVersionJson,
) => {
  if (flutterVersionJson['flutterVersion'] ??
          flutterVersionJson['frameworkVersion']
      case final String v)
    'flutterVersion': v,
  if (flutterVersionJson['frameworkRevision'] case final String r)
    'flutterRevision': r,
  if (flutterVersionJson['engineRevision'] case final String r)
    'engineRevision': r,
};

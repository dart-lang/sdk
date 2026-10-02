// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Version and capability metadata for a _DartPad SDK_.
final class VersionInfo {
  /// Run modes supported by this DartPad SDK (e.g. `['console']`).
  final List<String> modes;

  /// Version of the Dart SDK in this DartPad SDK.
  final String dartVersion;

  /// Git commit revision of the Dart SDK.
  final String dartRevision;

  /// Additional key-value metadata properties for this DartPad SDK.
  final Map<String, String> properties;

  VersionInfo._({
    required List<String> modes,
    required this.dartVersion,
    required this.dartRevision,
    Map<String, String> properties = const {},
  }) : modes = List.unmodifiable(modes),
       properties = Map.unmodifiable(properties);
}

/// Creates a [VersionInfo] instance.
VersionInfo createVersionInfo({
  required List<String> modes,
  required String dartVersion,
  required String dartRevision,
  Map<String, String> properties = const {},
}) => VersionInfo._(
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

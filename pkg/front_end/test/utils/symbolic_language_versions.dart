// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Symbolic language versions for use in testing.
enum SymbolicLanguageVersion {
  /// A valid language version the opts out of null safety.
  legacyVersion("%LEGACY_VERSION_MARKER%", const Version(2, 6)),

  /// A valid language version the opts in to null safety.
  nnbdVersion("%NNBD_VERSION_MARKER%", const Version(2, 12)),

  /// An invalid language version that is lower than [lowestVersion].
  // TODO(johnniwinther): Report error on this.
  tooLowVersion("%TOO_LOW_VERSION_MARKER%", const Version(1, 0)),

  /// The lowest supported language version.
  lowestVersion("%LOWEST_VERSION_MARKER%", const Version(2, 0)),

  /// A valid language version larger than [lowestVersion] and lower than
  /// [version1].
  version0("%VERSION_MARKER0%", const Version(2, 4)),

  /// A valid language version larger than [version0] and lower than
  /// [version2].
  version1("%VERSION_MARKER1%", const Version(2, 5)),

  /// A valid language version larger than [version1] and lower than
  /// [currentVersion].
  version2("%VERSION_MARKER2%", const Version(2, 6)),

  /// The current language version. This is also the highest supported version.
  currentVersion("%CURRENT_VERSION_MARKER%", const Version(2, 8)),

  /// An invalid language version that is higher than [currentVersion].
  tooHighVersion("%TOO_HIGH_VERSION_MARKER%", const Version(2, 9999));

  final String marker;
  final Version version;

  const SymbolicLanguageVersion(this.marker, this.version);
}

late final bool _validMarkers = _checkMarkers();

bool _checkMarkers() {
  return SymbolicLanguageVersion.tooLowVersion.version <
          SymbolicLanguageVersion.lowestVersion.version &&
      SymbolicLanguageVersion.lowestVersion.version <
          SymbolicLanguageVersion.version0.version &&
      SymbolicLanguageVersion.version0.version <
          SymbolicLanguageVersion.version1.version &&
      SymbolicLanguageVersion.version1.version <
          SymbolicLanguageVersion.version2.version &&
      SymbolicLanguageVersion.version2.version <
          SymbolicLanguageVersion.currentVersion.version &&
      SymbolicLanguageVersion.currentVersion.version <
          SymbolicLanguageVersion.tooHighVersion.version;
}

/// Replaces all occurrences of symbolic language markers in [text] with their
/// corresponding version as text.
String replaceMarkersWithVersions(String text) {
  assert(_validMarkers);
  for (SymbolicLanguageVersion symbolicVersion
      in SymbolicLanguageVersion.values) {
    String marker = symbolicVersion.marker;
    Version version = symbolicVersion.version;
    text = text.replaceAll(marker, version.toText());
  }
  return text;
}

/// Replaces all occurrences language versions as text in [text] with the
/// corresponding symbolic language markers.
String replaceVersionsWithMarkers(String text) {
  assert(_validMarkers);
  for (SymbolicLanguageVersion symbolicVersion
      in SymbolicLanguageVersion.values) {
    String marker = symbolicVersion.marker;
    Version version = symbolicVersion.version;
    text = text.replaceAll(version.toText(), marker);
  }
  return text;
}

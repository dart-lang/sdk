// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Operations relative to the user's installed Dart SDK.
library pub.sdk;

import 'dart:io';

import 'package:path/path.dart' as path;

import 'io.dart';
import 'version.dart';

/// Matches an Eclipse-style SDK version number. This is four dotted numbers
/// (major, minor, patch, build) with an optional suffix attached to the build
/// number.
final _versionPattern = new RegExp(r'^(\d+)\.(\d+)\.(\d+)\.(\d+.*)$');

/// Gets the path to the root directory of the SDK.
String get rootDirectory {
  // Assume the Dart executable is always coming from the SDK.
  return path.dirname(path.dirname(Platform.executable));
}

/// The SDK's revision number formatted to be a semantic version.
///
/// This can be set so that the version solver tests can artificially select
/// different SDK versions.
Version version = _getVersion();

/// Is `true` if the current SDK is an unreleased bleeding edge version.
bool get isBleedingEdge {
  // The live build is locked to the magical old number "0.1.2+<stuff>".
  return version.major == 0 && version.minor == 1 && version.patch == 2;
}

/// Parse an Eclipse-style version number using the SDK's versioning convention.
Version parseVersion(String version) {
  // Given a version file like: 0.1.2.0_r17495
  // We create a semver like:   0.1.2+0.r17495
  var match = _versionPattern.firstMatch(version);
  if (match == null) {
    throw new FormatException("The Dart SDK's 'version' file was not in a "
        "format pub could recognize. Found: $version");
  }

  // Semantic versions cannot use "_".
  var build = match[4].replaceAll('_', '.');

  return new Version(
      int.parse(match[1]), int.parse(match[2]), int.parse(match[3]),
      build: build);
}

/// Determine the SDK's version number.
Version _getVersion() {
  // Some of the pub integration tests require an SDK version number, but the
  // tests on the bots are not run from a built SDK so this lets us avoid
  // parsing the missing version file.
  var sdkVersion = Platform.environment["_PUB_TEST_SDK_VERSION"];
  if (sdkVersion != null) return new Version.parse(sdkVersion);

  // Read the "version" file.
  var revisionPath = path.join(rootDirectory, "version");
  var version = readTextFile(revisionPath).trim();
  return parseVersion(version);
}

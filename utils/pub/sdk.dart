// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Operations relative to the user's installed Dart SDK.
library sdk;

import 'dart:io';

import '../../pkg/path/lib/path.dart' as path;
import 'log.dart' as log;
import 'version.dart';

/// Matches an Eclipse-style SDK version number. This is four dotted numbers
/// (major, minor, patch, build) with an optional suffix attached to the build
/// number.
final _versionPattern = new RegExp(r'^(\d+)\.(\d+)\.(\d+)\.(\d+)(.*)$');

/// Gets the path to the root directory of the SDK.
String get rootDirectory {
  // If the environment variable was provided, use it. This is mainly used for
  // the pub tests.
  var dir = Platform.environment["DART_SDK"];
  if (dir != null) {
    log.fine("Using DART_SDK to find SDK at $dir");
    return dir;
  }

  var pubDir = path.dirname(new Options().script);
  dir = path.normalize(path.join(pubDir, "../../"));
  log.fine("Located SDK at $dir");
  return dir;
}

/// Gets the SDK's revision number formatted to be a semantic version.
Version version = _getVersion();

/// Determine the SDK's version number.
Version _getVersion() {
  var revisionPath = path.join(rootDirectory, "version");
  var version = new File(revisionPath).readAsStringSync().trim();

  // Given a version file like: 0.1.2.0_r17495
  // We create a semver like:   0.1.2+0._r17495
  var match = _versionPattern.firstMatch(version);
  if (match == null) {
    throw new FormatException("The Dart SDK's 'version' file was not in a "
        "format pub could recognize. Found: $version");
  }

  var build = match[4];
  if (match[5].length > 0) build = '$build.${match[5]}';

  return new Version(
      int.parse(match[1]), int.parse(match[2]), int.parse(match[3]),
      build: build);
}
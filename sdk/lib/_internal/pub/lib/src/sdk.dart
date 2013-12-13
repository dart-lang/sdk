// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Operations relative to the user's installed Dart SDK.
library pub.sdk;

import 'dart:io';

import 'package:path/path.dart' as path;

import 'io.dart';
import 'version.dart';

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
  return new Version.parse(version);
}

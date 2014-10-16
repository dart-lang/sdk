// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Operations relative to the user's installed Dart SDK.
library pub.sdk;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

import 'io.dart';

/// Gets the path to the root directory of the SDK.
///
/// When running from the actual built SDK, this will be the SDK that contains
/// the running Dart executable. When running from the repo, it will be the
/// "sdk" directory in the Dart repository itself.
final String rootDirectory =
    runningFromSdk ? _rootDirectory : path.join(repoRoot, "sdk");

/// Gets the path to the root directory of the SDK, assuming that the currently
/// running Dart executable is within it.
final String _rootDirectory =
    path.dirname(path.dirname(Platform.executable));

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

  if (runningFromSdk) {
    // Read the "version" file.
    var version = readTextFile(path.join(_rootDirectory, "version")).trim();
    return new Version.parse(version);
  }

  // When running from the repo, read the canonical VERSION file in tools/.
  // This makes it possible to run pub without having built the SDK first.
  var contents = readTextFile(path.join(repoRoot, "tools/VERSION"));

  parseField(name) {
    var pattern = new RegExp("^$name ([a-z0-9]+)", multiLine: true);
    var match = pattern.firstMatch(contents);
    return match[1];
  }

  var channel = parseField("CHANNEL");
  var major = parseField("MAJOR");
  var minor = parseField("MINOR");
  var patch = parseField("PATCH");
  var prerelease = parseField("PRERELEASE");
  var prereleasePatch = parseField("PRERELEASE_PATCH");

  var version = "$major.$minor.$patch";
  if (channel == "be") {
    // TODO(rnystrom): tools/utils.py includes the svn commit here. Should we?
    version += "-edge";
  } else if (channel == "dev") {
    version += "-dev.$prerelease.$prereleasePatch";
  }

  return new Version.parse(version);
}

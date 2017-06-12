// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

/// Utility for locating the patched_sdk. This is temporarily used to run fasta
/// until patching support is added.
library fasta.testing.patched_sdk_location;

import 'dart:async';
import 'dart:io' show File, Platform;

import 'environment_variable.dart' show EnvironmentVariable;

Future<Uri> computePatchedSdk() async {
  String config = await testConfigVariable.value;
  String path;
  switch (Platform.operatingSystem) {
    case "linux":
      path = "out/$config/patched_sdk";
      break;

    case "macos":
      path = "xcodebuild/$config/patched_sdk";
      break;

    case "windows":
      path = "build/$config/patched_sdk";
      break;

    default:
      throw "Unsupported operating system: '${Platform.operatingSystem}'.";
  }
  Uri sdk = Uri.base.resolve("$path/");
  const String asyncDart = "lib/async/async.dart";
  if (!await fileExists(sdk, asyncDart)) {
    throw "Couldn't find '$asyncDart' in '$sdk'.";
  }
  const String asyncSources = "lib/async/async_sources.gypi";
  if (await fileExists(sdk, asyncSources)) {
    throw "Found '$asyncSources' in '$sdk', so it isn't a patched SDK.";
  }
  return sdk;
}

Uri computeDartVm(Uri patchedSdk) {
  return patchedSdk.resolve(Platform.isWindows ? "../dart.exe" : "../dart");
}

Future<bool> fileExists(Uri base, String path) async {
  return await new File.fromUri(base.resolve(path)).exists();
}

final EnvironmentVariable testConfigVariable = new EnvironmentVariable(
    "DART_CONFIGURATION",
    "It should be something like 'ReleaseX64', depending on which"
    " configuration you're testing.");

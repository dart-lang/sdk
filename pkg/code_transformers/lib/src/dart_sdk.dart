// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_transformers.src.dart_sdk;

import 'dart:convert' as convert;
import 'dart:io' show Directory, File, Platform, Process;
import 'package:path/path.dart' as path;


/// Attempts to provide the current Dart SDK directory.
///
/// This will return null if the SDK cannot be found
///
/// Note that this may not be correct when executing outside of `pub`.
String get dartSdkDirectory {

  bool isSdkDir(String dirname) =>
      new File(path.join(dirname, 'lib', '_internal', 'libraries.dart'))
        .existsSync();

  if (path.split(Platform.executable).length == 1) {
    // TODO(blois): make this cross-platform.
    // HACK: A single part, hope it's on the path.
    var result = Process.runSync('which', ['dart'],
        stdoutEncoding: convert.UTF8);

    var sdkDir = path.dirname(path.dirname(result.stdout));
    if (isSdkDir(sdkDir)) return sdkDir;
  }
  var dartDir = path.dirname(path.absolute(Platform.executable));
  // If there's a sub-dir named dart-sdk then we're most likely executing from
  // a dart enlistment build directory.
  if (isSdkDir(path.join(dartDir, 'dart-sdk'))) {
    return path.join(dartDir, 'dart-sdk');
  }
  // If we can find libraries.dart then it's the root of the SDK.
  if (isSdkDir(dartDir)) return dartDir;

  var parts = path.split(dartDir);
  // If the dart executable is within the sdk dir then get the root.
  if (parts.contains('dart-sdk')) {
    var dartSdkDir = path.joinAll(parts.take(parts.indexOf('dart-sdk') + 1));
    if (isSdkDir(dartSdkDir)) return dartSdkDir;
  }

  return null;
}

/// Variant of [dartSdkDirectory] which includes additional cases only
/// typically encountered in Dart's testing environment.
String get testingDartSdkDirectory {
  var sdkDir = dartSdkDirectory;
  if (sdkDir == null) {
    // If we cannot find the SDK dir, then assume this is being run from Dart's
    // source directory and this script is the main script.
    sdkDir = path.join(
        path.dirname(path.fromUri(Platform.script)), '..', '..', '..', 'sdk');
  }
  return sdkDir;
}

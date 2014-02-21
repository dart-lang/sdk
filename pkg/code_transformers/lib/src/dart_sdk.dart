// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_transformers.src.dart_sdk;

import 'dart:convert' as convert;
import 'dart:io' show Directory, File, Platform, Process;
import 'package:path/path.dart' as path;


/// Attempts to provide the current Dart SDK directory.
///
/// Note that this may not be correct when executing outside of `pub`.
String get dartSdkDirectory {
  if (path.split(Platform.executable).length == 1) {
    // TODO(blois): make this cross-platform.
    // HACK: A single part, hope it's on the path.
    var result = Process.runSync('which', ['dart'],
        stdoutEncoding: convert.UTF8);
    return path.dirname(path.dirname(result.stdout));
  }
  var sdkDir = path.dirname(path.absolute(Platform.executable));
  // If there's a sub-dir named dart-sdk then we're most likely executing from
  // a dart enlistment build directory.
  if (new Directory(path.join(sdkDir, 'dart-sdk')).existsSync()) {
    return path.join(sdkDir, 'dart-sdk');
  }
  // If we can find libraries.dart then it's the root of the SDK.
  if (new File(path.join(sdkDir, 'lib', '_internal', 'libraries.dart'))
      .existsSync()) {
    return sdkDir;
  }

  var parts = path.split(sdkDir);
  // If the dart executable is within the sdk dir then get the root.
  if (parts.contains('dart-sdk')) {
    return path.joinAll(parts.take(parts.indexOf('dart-sdk') + 1));
  }

  return sdkDir;
}

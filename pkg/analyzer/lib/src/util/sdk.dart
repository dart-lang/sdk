// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

/// Return `true` if the given [sdkPath] is valid, i.e. has all required
/// artifacts.
String computePlatformBinariesPath(String sdkPath) {
  // Try the given SDK path.
  {
    String location = path.join(sdkPath, 'lib', '_internal');
    if (new File(path.join(location, 'vm_platform_strong.dill')).existsSync()) {
      return location;
    }
  }

  // The given SDK path does not work.
  // Then we're probably running on bots, in 'xcodebuild/ReleaseX64'.
  // In this case 'vm_platform.dill' is next to the 'dart'.
  return path.dirname(Platform.resolvedExecutable);
}

String getSdkPath([List<String> args]) {
  // Look for --dart-sdk on the command line.
  if (args != null) {
    int index = args.indexOf('--dart-sdk');

    if (index != -1 && (index + 1 < args.length)) {
      return args[index + 1];
    }

    for (String arg in args) {
      if (arg.startsWith('--dart-sdk=')) {
        return arg.substring('--dart-sdk='.length);
      }
    }
  }

  // Look in env['DART_SDK']
  if (Platform.environment['DART_SDK'] != null) {
    return Platform.environment['DART_SDK'];
  }

  // Use Platform.resolvedExecutable.
  return path.dirname(path.dirname(Platform.resolvedExecutable));
}

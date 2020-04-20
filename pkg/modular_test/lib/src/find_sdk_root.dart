// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// Helper method to locate the root of the SDK repository.
///
/// The `modular_test` package is only intended to be used within the SDK at
/// this time. We need the ability to find the sdk root in order to locate the
/// default set of packages that are available to all modular tests.
Future<Uri> findRoot() async {
  Uri current = Platform.script;
  while (true) {
    var segments = current.pathSegments;
    var index = segments.lastIndexOf('sdk');
    if (index == -1) {
      print("error: cannot find the root of the Dart SDK");
      exitCode = 1;
      return null;
    }
    current = current.resolve("../" * (segments.length - index - 1));
    if (await File.fromUri(current.resolve("sdk/DEPS")).exists()) {
      break;
    }
  }
  return current.resolve("sdk/");
}

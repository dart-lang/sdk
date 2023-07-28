// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// Helper method to locate the root of the SDK repository.
///
/// The `modular_test` package is only intended to be used within the SDK at
/// this time. We need the ability to find the sdk root in order to locate the
/// default set of packages that are available to all modular tests.
///
/// Note: we don't search for the directory "sdk" because this may not be
/// available when running this test in a shard.
Future<Uri> findRoot() async {
  Uri script = Platform.script;
  var segments = script.pathSegments;
  var index = segments.lastIndexOf('pkg');
  if (index == -1) {
    exitCode = 1;
    throw "error: cannot find the root of the Dart SDK";
  }
  return script.resolve("../" * (segments.length - index - 1));
}

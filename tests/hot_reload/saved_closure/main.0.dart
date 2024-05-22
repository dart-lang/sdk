// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/36c0788137d55c6c77f4b9a8be12e557bc764b1c/runtime/vm/isolate_reload_test.cc#L422

magic() {
  var x = 'ante';
  return x + 'diluvian';
}

var closure;

validate() {
  closure = () {
    return magic().toString() + '!';
  };
  return closure();
}

Future<void> main() async {
  // Create a closure in main which only exists in the original source.
  Expect.equals('antediluvian!', validate());

  await hotReload();

  // Remove the original closure from the source code.  The closure is
  // able to be recompiled because its source is preserved in a
  // special patch class.
  Expect.equals('postapocalyptic!', validate());
}

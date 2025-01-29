// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'lib.dart' show ImportedMixin;
import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/1a486499bf73ee5b007abbe522b94869a1f36d02/runtime/vm/isolate_reload_test.cc#L1222

// Verifies that we assign the correct patch classes for imported
// mixins when we reload.

class A extends Object with ImportedMixin {}

var func = new A().mixinFunc;

Future<void> main() async {
  Expect.equals('mixin', func());
  await hotReload();
  Expect.equals('mixin', func());
}

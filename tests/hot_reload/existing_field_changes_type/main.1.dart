// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/bc58f69e532960a2f1d88f4b282869d6e2ad7cbe/runtime/vm/isolate_reload_test.cc#L5674

class Foo {
  String x = '42';
}

helper() => Foo().x;

Future<void> main() async {
  Expect.type<int>(helper());
  Expect.equals(42, helper());
  await hotReload();

  Expect.type<String>(helper());
  Expect.equals('42', helper());
}

/** DIFF **/
/*
 // https://github.com/dart-lang/sdk/blob/bc58f69e532960a2f1d88f4b282869d6e2ad7cbe/runtime/vm/isolate_reload_test.cc#L5674
 
 class Foo {
-  int x = 42;
+  String x = '42';
 }
 
 helper() => Foo().x;
*/

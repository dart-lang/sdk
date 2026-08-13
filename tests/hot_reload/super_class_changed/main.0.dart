// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/bc58f69e532960a2f1d88f4b282869d6e2ad7cbe/runtime/vm/isolate_reload_test.cc#L760

class A {}

class B extends A {}

expectHelper() {
  Expect.type<A>(A());
  Expect.type<A>(B());
  Expect.notType<B>(A());
  Expect.type<B>(B());
}

Future<void> main() async {
  expectHelper();
  await hotReload();
  expectHelper();
}

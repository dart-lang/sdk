// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/1a486499bf73ee5b007abbe522b94869a1f36d02/runtime/vm/isolate_reload_test.cc#L4110

// Tests reload fails when type arguments change.
// Change: Baz extends Foo<String> -> Baz extends Bar<String, double>
// Validate: the right error message is returned.

class Foo<A> {
  var a;
}

class Bar<B, C> extends Foo<B> {}

class Baz extends Foo<String> {}

Future<void> main() async {
  Baz();
  await hotReload(expectRejection: true);

  Baz();
}

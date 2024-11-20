// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

class Foo {
  int x;
  Foo(this.x);
}

late Foo foo;

helper() {
  foo = Foo(42);
}

Future<void> main() async {
  helper();
  Expect.type<int>(foo.x);
  Expect.equals(42, foo.x);

  await hotReload();

  Expect.throws<TypeError>(() => foo.x);
}

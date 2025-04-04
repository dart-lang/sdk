// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Tests reload succeeds when super getter are updated.

class Bar {
  method<T>() {
    return 42;
  }
}

class Foo extends Bar {
  get tearoff => super.method<String>;
  get tearoff2 => super.method;
}

Future<void> main() async {
  var tearoff = Foo().tearoff;
  var tearoff2 = Foo().tearoff2;
  Expect.equals(42, tearoff());
  Expect.equals(42, tearoff2<String>());
  await hotReload();

  Expect.equals(100, tearoff());
  Expect.equals(100, tearoff2());
}

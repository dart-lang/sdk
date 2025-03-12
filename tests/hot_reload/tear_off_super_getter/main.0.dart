// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Tests reload succeeds when super getter are updated.

class Bar {
  method() {
    return 42;
  }
}

class Foo extends Bar {
  get tearoff => super.method;
}

Future<void> main() async {
  var tearoff = Foo().tearoff;
  Expect.equals(42, tearoff());
  await hotReload();

  Expect.equals(100, tearoff());
}

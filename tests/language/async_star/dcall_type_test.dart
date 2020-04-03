// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that TypeErrors for async* methods happen without using returned Stream.

import 'dart:async';
import 'package:expect/expect.dart';

Stream<int> iota(int n) async* {
  yield n;
}

class C {
  Stream<int> add(int n) async* {
    yield n;
  }
}

main() async {
  dynamic f = iota;
  Expect.throwsTypeError(() => f('ten'));
  Expect.throwsTypeError(() => f(4.7));

  dynamic o = new C();
  Expect.throwsTypeError(() => o.add('ten'));
  Expect.throwsTypeError(() => o.add(4.7));
}

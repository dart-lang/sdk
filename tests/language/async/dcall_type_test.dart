// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that TypeErrors happen for async methods without using returned Future.

import 'dart:async';
import 'package:expect/expect.dart';

Future<int> iota(int n) async {
  await null;
  return n;
}

class C {
  Future<int> add(int n) async {
    await null;
    return n;
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

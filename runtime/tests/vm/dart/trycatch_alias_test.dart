// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Foo {
  get value => 42;
}

class Bar {
  get value => 43;
}

call() {
  print('call');
  throw 'foo';
}

try1() {
  var n = Foo();
  var k;
  try {
    k = n;
    call();
    k = Bar();
  } catch (_) {}
  // k might be pointing to n => n is aliased
  Expect.equals(k.value, 42);
}

main() {
  try1();
}

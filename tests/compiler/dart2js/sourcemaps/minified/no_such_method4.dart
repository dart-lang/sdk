// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error pattern: NoSuchMethodError: method not found: '([^']*)' .*
// Kind of minified name: instance
// Expected deobfuscated name: g1=

import 'package:expect/expect.dart';

main() {
  try {
    confuse(new A());
    dynamic x = confuse(new B());
    x.g1 = 0;
  } catch (e) {
    throw e;
  }
}

@AssumeDynamic()
@NoInline()
confuse(x) => x;

class A {
  set g1(int x) {}
}

class B {}

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error pattern: NoSuchMethodError: method not found: '[^']*'\r?\nReceiver: Instance of '([^']*)'
// Kind of minified name: global
// Expected deobfuscated name: B

import 'package:expect/expect.dart';

main() {
  confuse(new A());
  dynamic x = confuse(new B());
  x.m1();
}

@AssumeDynamic()
@NoInline()
confuse(x) => x;

class A {
  noSuchMethod(i) => null;
}

class B {
  m2() {}
}

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Error pattern: NoSuchMethodError: method not found: '[^']*'\r?\nReceiver: Instance of '([^']*)'
// Kind of minified name: global
// Expected deobfuscated name: B

main() {
  confuse(new A());
  dynamic x = confuse(new B());
  x.m1();
}

@pragma('dart2js:assumeDynamic')
@pragma('dart2js:noInline')
confuse(x) => x;

class A {
  @override
  noSuchMethod(i) => null;
}

class B {
  m2() {}
}

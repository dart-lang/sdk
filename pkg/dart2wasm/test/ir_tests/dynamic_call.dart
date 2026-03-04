// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=forwarder|\$main
// compilerOption=-O0

dynamic confuse(dynamic a) => a;

class Foo {
  String toString({bool a = false}) => 'foo$a';
}

class Bar {
  String toString({int a = 0}) => 'bar$a';
}

void main() {
  print(confuse(Foo()).toString(a: true));
  print(confuse(Bar()).toString(a: 1));
}

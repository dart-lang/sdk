// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Foo {
  late int a;
  late final int b;
  late int c = -1;
  late final int d = -2;
}

class Bar {
  final String a = 'a';
  final String b = 'b';
  final String c = 'c';
  final String d = 'd';
}

void main() {
  dynamic x = fetch(false);
  Expect.equals('a', x.a);
  Expect.equals('b', x.b);
  Expect.equals('c', x.c);
  Expect.equals('d', x.d);

  x = fetch(true);
  Expect.equals(-1, x.c);
  Expect.equals(-2, x.d);

  x.a = 1;
  x.b = 2;
  x.c = 3;

  x = fetch(false);
  Expect.equals('a', x.a);
  Expect.equals('b', x.b);
  Expect.equals('c', x.c);
  Expect.equals('d', x.d);

  x = fetch(true);
  Expect.equals(1, x.a);
  Expect.equals(2, x.b);
  Expect.equals(3, x.c);
  Expect.equals(-2, x.d);
}

final foo = Foo();
final bar = Bar();

@pragma('dart2js:noInline')
dynamic fetch(bool getFoo) => getFoo ? foo : bar;

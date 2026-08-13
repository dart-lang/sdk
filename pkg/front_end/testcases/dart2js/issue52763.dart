// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class B {
  final bool autofocus;
  const B({required this.autofocus});
}

class O1 extends B {
  const O1({bool autofocus = true}) : super(autofocus: autofocus);
}

class O2 extends B {
  const O2({super.autofocus = true});
}

abstract class C {
  final bool a;
  final bool b;
  const C({this.a = true, this.b = false});
}

class P1 extends C {
  final int c;
  const P1(this.c, {super.a, super.b});
}

class P2 extends C {
  const P2({super.b, super.a});
}

main() {
  var tearoff1 = O1.new;
  var tearoff2 = O2.new;
  var tearoff3 = P1.new;
  var tearoff4 = P2.new;
  expect(true, tearoff1().autofocus);
  expect(true, tearoff2().autofocus);
  expect(true, tearoff3(0).a);
  expect(false, tearoff3(0).b);
  expect(0, tearoff3(0).c);
  expect(true, tearoff4().a);
  expect(false, tearoff4().b);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

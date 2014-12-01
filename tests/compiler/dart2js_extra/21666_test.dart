// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Regression test for issue 21666 - problems with method that has super calls.
//
// Use a method and getter with super calls in various ways.

import 'package:expect/expect.dart';

@MirrorsUsed(targets: const [A, B, Object])
import 'dart:mirrors';

class X { const X(); }
class Y { const Y(); }

typedef fInt(int x);
typedef fString(String x);

class A {
  @X()
  foo(int x) => x + 1;
  int get bar => A.g;

  static int g = 0;
}

class B extends A {
  @Y()
  foo(int x) => 100 * super.foo(x);
  int get bar => 1000 * super.bar;
}

String dump(ClassMirror cm) {
  var sb = new StringBuffer();
  sb.write('$cm\n');
  for (var mm in cm.declarations.values) {
    sb.write('  $mm\n');
    // Walking declaration metadata triggers issue 21666.
    for (var a in mm.metadata) {
      sb.write('    $a\n');
    }
  }
  print(sb);
  return '$sb';
}

main() {
  var cmB = reflectClass(B);
  var cmBdump = dump(cmB);
  var cmAdump = dump(cmB.superclass);

  Expect.equals(dump(reflectClass(A)), cmAdump);
  Expect.isTrue(cmAdump.contains("'foo'"));
  Expect.isTrue(cmAdump.contains("'bar'"));
  Expect.isTrue(cmBdump.contains("'foo'"));
  Expect.isTrue(cmBdump.contains("'bar'"));

  A.g = 123;
  var a = new A();
  var am = reflect(a);
  var agfoo = am.getField(#foo);
  var agbar = am.getField(#bar);

  Expect.equals(3, agfoo.reflectee(2));
  Expect.equals(4, am.invoke(#foo, [3]).reflectee);
  Expect.equals(123, agbar.reflectee);
  Expect.isTrue(a.foo is fInt);
  Expect.isTrue(a.foo is! fString);
  Expect.isTrue(agfoo.reflectee is fInt);
  Expect.isTrue(agfoo.reflectee is! fString);

  var b = new B();
  var bm = reflect(b);
  var bgfoo = bm.getField(#foo);
  var bgbar = bm.getField(#bar);

  Expect.equals(300, bgfoo.reflectee(2));
  Expect.equals(400, bm.invoke(#foo, [3]).reflectee);
  Expect.equals(123000, bgbar.reflectee);
  Expect.isTrue(b.foo is fInt);
  Expect.isTrue(b.foo is! fString);
  Expect.isTrue(bgfoo.reflectee is fInt);
  Expect.isTrue(bgfoo.reflectee is! fString);
}

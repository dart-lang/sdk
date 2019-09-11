// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This regression test targets AotCallSpecializer::TryExpandCallThroughGetter,
// which previously would create bad references in environments to either
// push arguments that came later than the environment's instruction or, worse,
// references to push arguments whose values had not already been calculated at
// the environment's instruction.

import 'getter_closure_call_generic_test.dart' as test;

main() {
  final x = test.kTrue ? Sub1() : Sub2();
  barbar(test.kTrue, x);
  print('states = ${test.states}');
}

@pragma('vm:never-inline')
barbar(bool kTrue, Base base) {
  var a = test.foo();
  var b = test.foo2();
  var c = test.foo3();
  var d = test.foo4();
  try {
    // rotate
    final t = a;
    if (kTrue) a = b;
    if (kTrue) b = c;
    if (kTrue) c = d;
    if (kTrue) d = t;

    if (!kTrue) b = test.foo();

    base.barGetter(a = test.addState(1), b = test.addState(2),
        c = test.addState(3), d = test.addState(4));
  } catch (e) {
    print('got $e');
    print('$a $b $c $d');
  }
}

class Base {
  FT get barGetter => test.doit;
}

class Sub1 extends Base {}

class Sub2 extends Base {}

typedef dynamic FT(dynamic a, dynamic b, dynamic c, dynamic d);

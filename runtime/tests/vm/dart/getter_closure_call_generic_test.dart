// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This regression test targets AotCallSpecializer::TryExpandCallThroughGetter,
// which previously would create bad references in environments to either
// push arguments that came later than the environment's instruction or, worse,
// references to push arguments whose values had not already been calculated at
// the environment's instruction.

final states = <int>[];
main() {
  final x = kTrue ? Sub1() : Sub2();
  barbar(kTrue, x);
  print('states = $states');
}

@pragma('vm:never-inline')
void barbar(bool kTrue, Base base) {
  var a = foo();
  var b = foo2();
  var c = foo3();
  var d = foo4();

  try {
    // rotate
    final t = a;
    if (kTrue) a = b;
    if (kTrue) b = c;
    if (kTrue) c = d;
    if (kTrue) d = t;

    base.barGetter(
        a = addState(c), b = addState(d), c = addState(a), d = addState(b));
  } catch (e) {
    print('got $e');
    print('$a $b $c $d');
  }
}

final bool kTrue = int.parse('1') == 1;

@pragma('vm:never-inline')
int foo() => kTrue ? 1 : 2;

@pragma('vm:never-inline')
int foo2() => kTrue ? 2 : 3;

@pragma('vm:never-inline')
int foo3() => kTrue ? 3 : 4;

@pragma('vm:never-inline')
int foo4() => kTrue ? 4 : 5;

@pragma('vm:never-inline')
int addState(int i) {
  states.add(i);
  return i;
}

@pragma('vm:never-inline')
void doit<A>(A x, A x2, A x3, A x4) => throw 'a';

class Base {
  void Function<A>(A, A, A, A) get barGetter => doit;
}

class Sub1 extends Base {}

class Sub2 extends Base {}

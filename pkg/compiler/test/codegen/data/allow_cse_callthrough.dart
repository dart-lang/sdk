// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:ignore*/
void main() {
  for (final f in [test1, test2, test3, test4]) {
    f();
    print([sink1, sink2]);
  }
}

Object? sink1;
Object? sink2;

@pragma('dart2js:never-inline')
@pragma('dart2js:allow-cse')
/*member: foo:ignore*/
int foo(int n) => n;

/*member: test1:function() {
  $.sink2 = $.sink1 = A.foo(1);
}*/
void test1() {
  // Expect one call that is reused.
  sink1 = foo(1);
  sink2 = foo(1);
}

/*member: test2:function() {
  $.sink2 = $.sink1 = A.foo(2);
}*/
void test2() {
  // Expect one direct call that is reused.

  // The optimizer replaces the indirect (closure) call `(fa)(2)` with a direct
  // call `foo(2)`. If the call attributes on the direct call are set correctly
  // for the known target, allow-cse will be enabled.

  final fa = foo;
  sink1 = fa(2);
  final fb = foo;
  sink2 = fb(2);
}

/*member: test3:function() {
  $.sink2 = $.sink1 = A.foo(3);
}*/
void test3() {
  // Variation on test2.
  sink1 = foo(3);
  final fb = foo;
  sink2 = fb(3);
}

/*member: test4:function() {
  $.sink2 = $.sink1 = A.foo(4);
}*/
void test4() {
  // Variation on test2.
  final fa = foo;
  sink1 = fa(4);
  sink2 = foo(4);
}

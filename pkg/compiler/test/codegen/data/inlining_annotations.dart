// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: foo1:ignore*/
@pragma('dart2js:tryInline')
int foo1() => bar1();

/*member: foo2:ignore*/
@pragma('dart2js:tryInline')
@pragma('dart2js:disable-inlining')
int foo2() => bar2();

/*member: foo3:ignore*/
@pragma('dart2js:noInline')
int foo3() => bar3();

/*member: bar1:ignore*/
int bar1() => 1;

/*member: bar2:ignore*/
int bar2() => 2;

/*member: bar3:ignore*/
int bar3() => 3;

// All calls to `barN` are inlined because this improves size and performance.
/*member: test1:function() {
  A.use(1, 2, 3);
}*/
@pragma('dart2js:noInline')
void test1() {
  use(bar1(), bar2(), bar3());
}

// No calls to `barN` are inlined due to `disable-inlining`.
/*member: test2:function() {
  A.use(A.bar1(), A.bar2(), A.bar3());
}*/
@pragma('dart2js:noInline')
@pragma('dart2js:disable-inlining')
void test2() {
  use(bar1(), bar2(), bar3());
}

// `foo` and `bar1` are inlined. `foo2` is inlined, but the contained call to
// `bar2` is not inlined due to `disable-inlining` on `foo2`.
/*member: test3:function() {
  A.use(1, A.bar2(), A.foo3());
}*/
@pragma('dart2js:noInline')
void test3() {
  use(foo1(), foo2(), foo3());
}

// None of the `fooN` calls are inlined due to `disable-inlining`.
/*member: test4:function() {
  A.use(A.foo1(), A.foo2(), A.foo3());
}*/
@pragma('dart2js:noInline')
@pragma('dart2js:disable-inlining')
void test4() {
  use(foo1(), foo2(), foo3());
}

/*member: use:ignore*/
@pragma('dart2js:noInline')
void use(int a, int b, int c) {}

/*member: main:ignore*/
main() {
  test1();
  test2();
  test3();
  test4();
}

// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B<X> {
  B();
  B.foo();
  factory B.bar() => new B<X>();
}

typedef DA1 = A;

typedef DA2<X extends num> = A;

typedef DB1 = B<String>;

typedef DB2<X extends num> = B<X>;

typedef DB3<X extends num, Y extends String> = B<X>;

DA1 Function() test1() => DA1.new; // Ok.
A Function() test2() => DA1.new; // Ok.

DA2<num> Function() test3() => DA2.new; // Ok.
A Function() test4() => DA2.new; // Ok.
A Function() test5() => DA2<String>.new; // Error.
A Function() test6() => DA2<int>.new; // Ok.

DB1 Function() test7() => DB1.new; // Ok.
B<String> Function() test8() => DB1.new; // Ok.
B<num> Function() test9() => DB1.new; // Error.
B<String> Function() test10() => DB1.foo; // Ok.
B<String> Function() test11() => DB1.bar; // Ok.

B<num> Function() test12() => DB2<num>.new; // Ok.
B<num> Function() test13() => DB2<num>.foo; // Ok.
B<num> Function() test14() => DB2<num>.bar; // Ok.
B<num> Function() test15() => DB2.new; // Ok.
B<Y> Function<Y extends num>() test16() => DB2.new; // Ok.
B<Y> Function<Y>() test17() => DB2.new; // Error.

B<num> Function() test18() => DB3<num, String>.new; // Ok.
B<num> Function() test19() => DB3<num, String>.foo; // Ok.
B<num> Function() test20() => DB3<num, String>.bar; // Ok.
B<num> Function() test21() => DB3.new; // Ok.
B<Y> Function<Y extends num, Z extends String>() test22() => DB3.new; // Ok.
B<Y> Function<Y, Z>() test23() => DB3.new; // Error.

B<String> Function() test24() => DB2.new; // Ok.

main() {}

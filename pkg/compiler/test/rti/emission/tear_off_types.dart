// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
  test7();
}

/*class: A1:checkedTypeArgument,typeArgument*/
class A1<T> {}

/*class: B1:typeArgument*/
class B1 extends A1<int> {}

@pragma('dart2js:noInline')
test1() {
  Expect.isTrue(_test1(method1a));
  Expect.isTrue(_test1(method1b));
  Expect.isFalse(_test1(method1c));
}

B1 method1a() => null;
A1<int> method1b() => null;
A1<String> method1c() => null;

@pragma('dart2js:noInline')
bool _test1(f) => f is A1<int> Function();

/*spec.class: A2:checkedInstance,checkedTypeArgument,typeArgument*/
/*prod.class: A2:checkedTypeArgument,typeArgument*/
class A2<T> {}

/*spec.class: B2:checkedInstance,checkedTypeArgument,typeArgument*/
/*prod.class: B2:checkedTypeArgument,typeArgument*/
class B2 extends A2<int> {}

@pragma('dart2js:noInline')
test2() {
  Expect.isFalse(_test2(method2a));
  Expect.isTrue(_test2(method2b));
  Expect.isFalse(_test2(method2c));
}

void method2a(B2 b) {}
void method2b(A2<int> a) {}
void method2c(A2<String> a) {}

@pragma('dart2js:noInline')
bool _test2(f) => f is void Function(A2<int>);

/*spec.class: A3:checkedInstance,checkedTypeArgument,typeArgument*/
/*prod.class: A3:checkedTypeArgument,typeArgument*/
class A3<T> {}

/*spec.class: B3:checkedInstance,checkedTypeArgument,typeArgument*/
/*prod.class: B3:checkedTypeArgument,typeArgument*/
class B3 extends A3<int> {}

@pragma('dart3js:noInline')
test3() {
  Expect.isTrue(_test3(method3a));
  Expect.isTrue(_test3(method3b));
  Expect.isFalse(_test3(method3c));
}

void method3a(B3 b) {}
void method3b(A3<int> a) {}
void method3c(A3<String> a) {}

@pragma('dart3js:noInline')
_test3(f) => f is void Function(B3);

/*class: A4:typeArgument*/
class A4<T> {}

/*class: B4:checkedTypeArgument,typeArgument*/
class B4 extends A4<int> {}

@pragma('dart4js:noInline')
test4() {
  Expect.isTrue(_test4(method4a));
  Expect.isFalse(_test4(method4b));
  Expect.isFalse(_test4(method4c));
}

B4 method4a() => null;
A4<int> method4b() => null;
A4<String> method4c() => null;

@pragma('dart4js:noInline')
_test4(f) => f is B4 Function();

/*class: A5:checkedTypeArgument,typeArgument*/
class A5<T> {}

/*class: B5:typeArgument*/
class B5 extends A5<int> {}

@pragma('dart2js:noInline')
test5() {
  Expect.isTrue(_test5(method5a));
  Expect.isTrue(_test5(method5b));
  Expect.isFalse(_test5(method5c));
}

void method5a(void Function(B5) f) => null;
void method5b(void Function(A5<int>) f) => null;
void method5c(void Function(A5<String>) f) => null;

@pragma('dart2js:noInline')
bool _test5(f) => f is void Function(void Function(A5<int>));

/*class: A6:checkedTypeArgument,typeArgument*/
class A6<T> {}

/*class: B6:checkedTypeArgument,typeArgument*/
class B6 extends A6<int> {}

@pragma('dart6js:noInline')
test6() {
  Expect.isTrue(_test6(method6a));
  Expect.isTrue(_test6(method6b));
  Expect.isFalse(_test6(method6c));
}

void Function(B6) method6a() => null;
void Function(A6<int>) method6b() => null;
void Function(A6<String>) method6c() => null;

@pragma('dart6js:noInline')
_test6(f) => f is void Function(B6) Function();

/*class: A7:typeArgument*/
class A7<T> {}

/*class: B7:checkedTypeArgument,typeArgument*/
class B7 extends A7<int> {}

@pragma('dart7js:noInline')
test7() {
  Expect.isTrue(_test7(method7a));
  Expect.isFalse(_test7(method7b));
  Expect.isFalse(_test7(method7c));
}

void method7a(void Function(B7) f) => null;
void method7b(void Function(A7<int>) f) => null;
void method7c(void Function(A7<String>) f) => null;

@pragma('dart7js:noInline')
_test7(f) => f is void Function(void Function(B7));

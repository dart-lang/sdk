// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart=2.6

/*class: A:A,Object*/
abstract class A {
  /*member: A.method:void Function(dynamic)**/
  void method(dynamic a);
}

/*class: B:B,Object*/
abstract class B {
  /*member: B.method:void Function(num*)**/
  void method(covariant num a);
}

/*class: C:C,Object*/
abstract class C {
  /*member: C.method:void Function(int*)**/
  void method(covariant int a);
}

/*class: D1:A,B,C,D1,Object*/
abstract class D1 implements A, B, C {
  /*cfe|cfe:builder.member: D1.method:void Function(dynamic)**/
  /*analyzer.member: D1.method:void Function(int*)**/
}

/*class: D2:A,B,D2,Object*/
abstract class D2 implements A, B {
  /*cfe|cfe:builder.member: D2.method:void Function(dynamic)**/
  /*analyzer.member: D2.method:void Function(num*)**/
}

/*class: D3:B,C,D3,Object*/
abstract class D3 implements B, C {
  /*cfe|cfe:builder.member: D3.method:void Function(num*)**/
  /*analyzer.member: D3.method:void Function(int*)**/
}

/*class: D4:B,C,D4,Object*/
abstract class D4 implements C, B {
  /*member: D4.method:void Function(num*)**/
}

/*class: D5:A,C,D5,Object*/
abstract class D5 implements A, C {
  /*cfe|cfe:builder.member: D5.method:void Function(dynamic)**/
  /*analyzer.member: D5.method:void Function(int*)**/
}

/*class: E:E,Object*/
abstract class E {
  /*member: E.method:void Function(num*)**/
  void method(num a);
}

/*class: F:F,Object*/
abstract class F {
  /*member: F.method:void Function(int*)**/
  void method(covariant int a);
}

/*class: G1:E,F,G1,Object*/
abstract class G1 implements E, F {
  /*cfe|cfe:builder.member: G1.method:void Function(num*)**/
  /*analyzer.member: G1.method:void Function(int*)**/
}

/*class: G2:E,F,G2,Object*/
abstract class G2 implements F, E {
  /*member: G2.method:void Function(num*)**/
}

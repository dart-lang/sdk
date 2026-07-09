// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  C();
  factory C.fact() => D();
  factory C.fact2() = D;
  C.nonFact();
  C.nonFact2() : this.nonFact();
  static void staticFunction(int i) {}
}

class D extends C {}

void topLevelFunction(int i) {}

test() {
  void localFunction(int i) {}
  List<int> a = <Object>[];
  //            ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //                    ^
  // [cfe] A value of type 'List<Object>' can't be assigned to a variable of type 'List<int>'.
  Map<int, String> b = <Object, String>{};
  //                   ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //                                   ^
  // [cfe] A value of type 'Map<Object, String>' can't be assigned to a variable of type 'Map<int, String>'.
  Map<int, String> c = <int, Object>{};
  //                   ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //                                ^
  // [cfe] A value of type 'Map<int, Object>' can't be assigned to a variable of type 'Map<int, String>'.
  int Function(Object) d = (int i) => i;
  //                       ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'int Function(int)' can't be assigned to a variable of type 'int Function(Object)'.
  D e = new C.fact() as D;
  D f = new C.fact2() as D;
  D g = new C.nonFact();
  //    ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //        ^
  // [cfe] A value of type 'C' can't be assigned to a variable of type 'D'.
  D h = new C.nonFact2();
  //    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //        ^
  // [cfe] A value of type 'C' can't be assigned to a variable of type 'D'.
  void Function(Object) i = C.staticFunction;
  //                        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //                          ^
  // [cfe] A value of type 'void Function(int)' can't be assigned to a variable of type 'void Function(Object)'.
  void Function(Object) j = topLevelFunction;
  //                        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'void Function(int)' can't be assigned to a variable of type 'void Function(Object)'.
  void Function(Object) k = localFunction;
  //                        ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'void Function(int)' can't be assigned to a variable of type 'void Function(Object)'.
}

main() {}

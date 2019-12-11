// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  C();
  factory C.fact() => null;
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
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CAST_LITERAL_LIST
  //                    ^
  // [cfe] The list literal type 'List<Object>' isn't of expected type 'List<int>'.
  Map<int, String> b = <Object, String>{};
  //                   ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CAST_LITERAL_MAP
  //                                   ^
  // [cfe] The map literal type 'Map<Object, String>' isn't of expected type 'Map<int, String>'.
  Map<int, String> c = <int, Object>{};
  //                   ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CAST_LITERAL_MAP
  //                                ^
  // [cfe] The map literal type 'Map<int, Object>' isn't of expected type 'Map<int, String>'.
  int Function(Object) d = (int i) => i;
  //                       ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CAST_FUNCTION_EXPR
  // [cfe] The function expression type 'int Function(int)' isn't of expected type 'int Function(Object)'.
  D e = new C.fact();
  D f = new C.fact2();
  D g = new C.nonFact();
  //    ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CAST_NEW_EXPR
  //        ^
  // [cfe] The constructor returns type 'C' that isn't of expected type 'D'.
  D h = new C.nonFact2();
  //    ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CAST_NEW_EXPR
  //        ^
  // [cfe] The constructor returns type 'C' that isn't of expected type 'D'.
  void Function(Object) i = C.staticFunction;
  //                        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CAST_METHOD
  //                          ^
  // [cfe] The static method has type 'void Function(int)' that isn't of expected type 'void Function(Object)'.
  void Function(Object) j = topLevelFunction;
  //                        ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CAST_FUNCTION
  // [cfe] The top level function has type 'void Function(int)' that isn't of expected type 'void Function(Object)'.
  void Function(Object) k = localFunction;
  //                        ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CAST_FUNCTION
  // [cfe] The local function has type 'void Function(int)' that isn't of expected type 'void Function(Object)'.
}

main() {}

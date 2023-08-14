// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that the use of a constant expression denoting an object that does
// not have primitive equality in a constant set or as a key of a constant map
// gives rise to a compile-time error.
//
// An enum cannot override `==` or `hashCode`, hence there are no cases with
// enums. Similarly, implicitly induced noSuchMethod forwarders cannot
// eliminate primitive equality from a given class: Such forwarders cannot
// override an explicitly declared inherited method implementation, in this
// case `Object.hashCode` and `Object.[]`.

class A {
  const A();
  int get hashCode => super.hashCode + 1;
}

class B {
  const B();
  bool operator ==(Object other) => super == other;
}

class C {
  const C();
  int get hashCode => super.hashCode + 1;
  bool operator ==(Object other) => super == other;
}

const aSet1 = <Object?>{
//                     ^
// [cfe] Constant evaluation error:
  0.5,
//^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY
};

const aSet2 = <Object?>{
//                     ^
// [cfe] Constant evaluation error:
  Duration(days: 2),
//^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY
};

const aSet3 = <Object?>{
//                     ^
// [cfe] Constant evaluation error:
  A(),
//^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY
};

const aSet4 = <Object?>{
//                     ^
// [cfe] Constant evaluation error:
  B(),
//^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY
};

const aSet5 = <Object?>{
//                     ^
// [cfe] Constant evaluation error:
  C(),
//^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY
};

const aSet6 = <Object?>{
//                     ^
// [cfe] Constant evaluation error:
  (A(), false, 1),
//^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY
};

const aMap1 = <Object?, Null>{
//                           ^
// [cfe] Constant evaluation error:
  0.5: null,
//^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY
};

const aMap2 = <Object?, Null>{
//                           ^
// [cfe] Constant evaluation error:
  Duration(days: 2): null,
//^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY
};

const aMap3 = <Object?, Null>{
//                           ^
// [cfe] Constant evaluation error:
  A(): null,
//^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY
};

const aMap4 = <Object?, Null>{
//                           ^
// [cfe] Constant evaluation error:
  B(): null,
//^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY
};

const aMap5 = <Object?, Null>{
//                           ^
// [cfe] Constant evaluation error:
  C(): null,
//^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY
};

const aMap6 = <Object?, Null>{
//                           ^
// [cfe] Constant evaluation error:
  (A(), false, 1): null,
//^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY
};

void main() {}

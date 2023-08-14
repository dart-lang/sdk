// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that the use of a constant expression denoting an object that has
// primitive equality in a constant set or as a key of a constant map is
// accepted.

enum E { one }

class A {
  const A(Object? o);
  static void staticMethod() {}
}

// Abstract methods (e.g., for DartDoc) do not eliminate primitive equality.

class B1 {
  const B1();
  bool operator ==(Object other);
}

class B2 {
  const B2();
  int get hashCode;
}

class B3 {
  const B3();
  bool operator ==(Object other);
  int get hashCode;
}

const aSet = <Object?>{
  null,
  true,
  false,
  0,
  -100000,
  'Hello!',
  #symbol,
  #+,
  Symbol(' '),
  int,
  Map<Object?, Null>,
  <int>[],
  <bool>{},
  <Object?, Null>{null: null},
  print,
  main,
  A.staticMethod,
  A(true),
  B1(),
  B2(),
  B3(),
  Object(),
  E.one,
  (1, true, Object()),
};

const aMap = <Object?, Null>{
  null: null,
  true: null,
  false: null,
  0: null,
  -100000: null,
  'Hello!': null,
  #symbol: null,
  #+: null,
  Symbol(' '): null,
  int: null,
  Map<Object?, Null>: null,
  <int>[]: null,
  <bool>{}: null,
  <Object?, Null>{0: null}: null,
  print: null,
  main: null,
  A.staticMethod: null,
  A(true): null,
  B1(): null,
  B2(): null,
  B3(): null,
  Object(): null,
  E.one: null,
  (1, true, Object()): null,
};

void main() {
  // Do not tree-shake the constant collections away.
  print('$aSet, $aMap');
}

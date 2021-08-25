// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Introduce an aliased type.

typedef T = Object;

// Use the aliased type.

abstract class C {
  T? v10;
  final T v12;
  C(): v12 = T();
  C.name1(this.v10, this.v12);
  factory C.name2(T arg1, T arg2) = C1.name1;
}

class C1 implements C {
  C1.name1(T arg1, T arg2);
  noSuchMethod(Invocation invocation) => throw 0;
}

abstract class D2 extends C with T {}
//             ^
// [analyzer] unspecified
// [cfe] Can't use 'Object' as a mixin because it has constructors.

abstract class D3 implements T {}
//             ^
// [analyzer] unspecified
// [cfe] 'Object' can't be used in both 'extends' and 'implements' clauses.

abstract class D4 = C with T;
//             ^
// [analyzer] unspecified
// [cfe] Can't use 'Object' as a mixin because it has constructors.

main() {
  T.named();
//  ^^^^^
// [analyzer] unspecified
// [cfe] Member not found: 'Object.named'.

  T.staticMethod<T>();
//  ^^^^^^^^^^^^
// [analyzer] unspecified
// [cfe] A constructor invocation can't have type arguments after the constructor name.
// [cfe] Member not found: 'Object.staticMethod'.
}

// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Shared code for tests that private names exported publicly via a typedef work
// as expected.

library private;

class _PrivateClass {
  int x;
  _PrivateClass(this.x);
  _PrivateClass.named(this.x);
  static int staticMethod() => 3;
  static int _privateStaticMethod() => 3;
  int instanceMethod() => 3;
  int _privateInstanceMethod() => 3;
}

typedef PublicClass = _PrivateClass;
PublicClass mkPublicClass() => PublicClass(0);

typedef _PrivateTypeDef = _PrivateClass;
typedef AlsoPublicClass = _PrivateTypeDef;
AlsoPublicClass mkAlsoPublicClass() => AlsoPublicClass(0);

class _PrivateGenericClass<T> {
  static int staticMethod() => 3;
}
typedef PublicGenericClass<T> = _PrivateGenericClass<T>;
PublicGenericClass<T> mkPublicGenericClass<T>() => PublicGenericClass();
typedef PublicGenericClassOfInt = _PrivateGenericClass<int>;

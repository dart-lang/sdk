// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Mixins cannot have declaring header/body constructors.

// SharedOptions=--enable-experiment=declaring-constructors

class C1;

mixin M1(var int x) implements C1;
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M2(final int x) on C1;
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M3(int x);
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M4.named(int x);
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M5();
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M6.named();
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M7 {
  this(var int x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified)
}

mixin M8 {
  this(final int x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified)
}

mixin M9 {
  this(int x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified)
}

mixin M10 {
  this.named(int x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified)
}

mixin M11 {
  this();
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified)
}

mixin M12 {
  this.named();
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified)
}

class C2<T>;

mixin M13<T>(var T x) implements C2<T>;
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M14<T>(final T x) on C2<T>;
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M15<T>(T x);
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M16<T>.named(T x);
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M17<T>();
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M18<T>.named();
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M19<T> {
  this(var T x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified)
}

mixin M20<T> {
  this(final T x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified)
}

mixin M21<T> {
  this(T x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified)
}

mixin M22<T> {
  this.named(T x);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified)
}

mixin M23<T> {
  this();
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified)
}

mixin M24<T> {
  this.named();
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified)
}

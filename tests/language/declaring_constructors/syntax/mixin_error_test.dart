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

class C2<T>;

mixin M7<T>(var T x) implements C2<T>;
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M8<T>(final T x) on C2<T>;
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M9<T>(T x);
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M10<T>.named(T x);
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M11<T>();
//    ^
// [analyzer] unspecified
// [cfe] unspecified

mixin M12<T>.named();
//    ^
// [analyzer] unspecified
// [cfe] unspecified

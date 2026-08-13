// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Mixins cannot have declaring header/body constructors.

class C1;

mixin M1(var int x) implements C1;
//      ^
// [analyzer] SYNTACTIC_ERROR.MIXIN_PRIMARY_CONSTRUCTOR
// [cfe] Mixins can't have primary constructors.

mixin M2(final int x) on C1;
//      ^
// [analyzer] SYNTACTIC_ERROR.MIXIN_PRIMARY_CONSTRUCTOR
// [cfe] Mixins can't have primary constructors.

mixin M3(int x);
//      ^
// [analyzer] SYNTACTIC_ERROR.MIXIN_PRIMARY_CONSTRUCTOR
// [cfe] Mixins can't have primary constructors.

mixin M4.named(int x);
//      ^
// [analyzer] SYNTACTIC_ERROR.MIXIN_PRIMARY_CONSTRUCTOR
// [cfe] Mixins can't have primary constructors.

mixin M5();
//      ^
// [analyzer] SYNTACTIC_ERROR.MIXIN_PRIMARY_CONSTRUCTOR
// [cfe] Mixins can't have primary constructors.

mixin M6.named();
//      ^
// [analyzer] SYNTACTIC_ERROR.MIXIN_PRIMARY_CONSTRUCTOR
// [cfe] Mixins can't have primary constructors.

class C2<T>;

mixin M7<T>(var T x) implements C2<T>;
//         ^
// [analyzer] SYNTACTIC_ERROR.MIXIN_PRIMARY_CONSTRUCTOR
// [cfe] Mixins can't have primary constructors.

mixin M8<T>(final T x) on C2<T>;
//         ^
// [analyzer] SYNTACTIC_ERROR.MIXIN_PRIMARY_CONSTRUCTOR
// [cfe] Mixins can't have primary constructors.

mixin M9<T>(T x);
//         ^
// [analyzer] SYNTACTIC_ERROR.MIXIN_PRIMARY_CONSTRUCTOR
// [cfe] Mixins can't have primary constructors.

mixin M10<T>.named(T x);
//          ^
// [analyzer] SYNTACTIC_ERROR.MIXIN_PRIMARY_CONSTRUCTOR
// [cfe] Mixins can't have primary constructors.

mixin M11<T>();
//          ^
// [analyzer] SYNTACTIC_ERROR.MIXIN_PRIMARY_CONSTRUCTOR
// [cfe] Mixins can't have primary constructors.

mixin M12<T>.named();
//          ^
// [analyzer] SYNTACTIC_ERROR.MIXIN_PRIMARY_CONSTRUCTOR
// [cfe] Mixins can't have primary constructors.

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X extends B> {}
//                ^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND

class B<X extends C> {}
//    ^
// [cfe] Generic type 'B' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through 'C'.
//                ^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND

class C<X extends A<B>> {}
//                  ^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND

main() {}

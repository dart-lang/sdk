// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X extends C> {}
//                ^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND

class C<X extends C> {}
//      ^
// [cfe] Generic type 'C' can't be used without type arguments in the bounds of its own type variables.
//                ^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND

main() {}

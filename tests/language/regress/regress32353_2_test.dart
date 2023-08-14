// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The following compile-time error is expected:
//
// Error: 'D' can't implement both '#lib1::B<#lib1::D::X, #lib1::D::Y>' and
// '#lib1::B<#lib1::D::X, #lib1::A>'
// class D<X, Y> extends B<X, Y> with C<X> {}
//       ~

class A {}

class B<X, Y> {}

mixin C<X> on B<X, A> {}

class D<X, Y> extends B<X, Y> with C {}
//    ^
// [cfe] 'B with C' can't implement both 'B<X, Y>' and 'B<dynamic, A>'
// [cfe] 'B<X, Y>' doesn't implement 'B<dynamic, A>' so it can't be used with 'C<dynamic>'.
//                                 ^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

main() {}

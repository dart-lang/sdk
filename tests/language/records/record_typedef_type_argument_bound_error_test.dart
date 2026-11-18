// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that a record type can't be passed as a type argument whose bound is
// another type argument that's instantiated with a typedef for a record type,
// if the record type isn't a subtype of that typedef.
//
// See also record_typedef_type_argument_bound_test.dart.

typedef R = (num, String);
typedef RNullable = (num,)?;

class C<X, Y extends X> {}

typedef Alias<X, Y extends X> = C<X, Y>;

extension type E<X, Y extends X>(int i) {}

C<R, (Object, String)>? c1;
// [error column 1]
// [cfe] Type argument '(Object, String)' doesn't conform to the bound 'X' of the type variable 'Y' on 'C'.
//   ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
C<R, (int, String)?>? c2;
// [error column 1]
// [cfe] Type argument '(int, String)?' doesn't conform to the bound 'X' of the type variable 'Y' on 'C'.
//   ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
C<RNullable, (Object,)>? c3;
// [error column 1]
// [cfe] Type argument '(Object)' doesn't conform to the bound 'X' of the type variable 'Y' on 'C'.
//           ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
Alias<R, (Object, String)>? a;
// [error column 1]
// [cfe] Type argument '(Object, String)' doesn't conform to the bound 'X' of the type variable 'Y' on 'Alias'.
//       ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
E<R, (Object, String)>? e;
// [error column 1]
// [cfe] Type argument '(Object, String)' doesn't conform to the bound 'X' of the type variable 'Y' on 'ExtensionType(E<R, (Object, String)>?)'.
//   ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

void main() {}

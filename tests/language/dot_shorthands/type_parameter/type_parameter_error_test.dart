// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Errors when having the wrong type parameters and using type parameters in
// `.new` or `.new()`.

// SharedOptions=--enable-experiment=dot-shorthands

import '../dot_shorthand_helper.dart';

void main() {
  StaticMember<int> s = .memberType<String, String>('s');
  //                    ^
  // [analyzer] unspecified
  // [cfe] A value of type 'StaticMember<String>' can't be assigned to a variable of type 'StaticMember<int>'.

  // Constructors doesn't have type parameters.
  StaticMember<int> constructorTypeParameter = .constNamed<int>(1);
  //                                            ^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] A dot shorthand constructor invocation can't have type arguments.

  // `.new<type-args>()` and `.new<type-args>` are a compile-time error.
  UnnamedConstructorTypeParameters typeParameters = .new<int>();
  //                                                 ^^^
  // [analyzer] unspecified
  // [cfe] A dot shorthand constructor invocation can't have type arguments.

  UnnamedConstructorTypeParameters Function() tearOff = .new<int>;
  //                                                     ^^^
  // [analyzer] unspecified
  // [cfe] The static getter or field 'new' isn't defined for the type 'UnnamedConstructorTypeParameters<dynamic> Function()'.
  //                                                        ^
  // [cfe] The static type of the explicit instantiation operand must be a generic function type but is 'dynamic'.
}

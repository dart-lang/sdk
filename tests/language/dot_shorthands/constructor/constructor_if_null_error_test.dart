// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Errors with `??` and dot shorthands with constructors.

import '../dot_shorthand_helper.dart';

extension type IfNullConstructorExt(int x) implements num {
  IfNullConstructorExt.regular(this.x);
  IfNullConstructorExt.named({this.x = 1});
  IfNullConstructorExt.optional([this.x = 1]);
}

void constructorClassTest() {
  ConstructorClass ctor = ConstructorClass(1);

  // Warning when LHS is not able to be `null`.
  ConstructorClass notNullable = .new(1) ?? ctor;
  //                                        ^^^^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION

  ConstructorClass notNullableRegular = .regular(1) ?? ctor;
  //                                                   ^^^^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION

  ConstructorClass notNullableNamed = .named(x: 1) ?? ctor;
  //                                                  ^^^^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION

  ConstructorClass notNullableOptional = .optional(1) ?? ctor;
  //                                                     ^^^^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
}

void constructorExtTest() {
  IfNullConstructorExt ctorExt = IfNullConstructorExt(1);

  // Warning when LHS is not able to be `null`.
  IfNullConstructorExt notNullableExt = .new(1) ?? ctorExt;
  //                                               ^^^^^^^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
  IfNullConstructorExt notNullableRegularExt = .regular(1) ?? ctorExt;
  //                                                          ^^^^^^^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
  IfNullConstructorExt notNullableNamedExt = .named(x: 1) ?? ctorExt;
  //                                                         ^^^^^^^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
  IfNullConstructorExt notNullableOptionalExt = .optional(1) ?? ctorExt;
  //                                                            ^^^^^^^
  // [analyzer] STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION
}

void main() {
  constructorClassTest();
  constructorExtTest();
}

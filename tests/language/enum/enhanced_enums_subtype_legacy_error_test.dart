// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests using a class as mixin.
// @dart=2.19

// Test errors required by new enhanced enum syntax, when used as a mixin.
// Not usable a mixin, even in language version that allows mixing in a class.

class MixesInEnum with Enum {
  //  ^
  // [cfe] Non-abstract class 'MixesInEnum' has 'Enum' as a superinterface.
  // [cfe] The non-abstract class 'MixesInEnum' is missing implementations for these members:
  //                   ^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_HAS_ENUM_SUPERINTERFACE
}

// Currently no error, it's a simple class with no constructors that extends
// `Object`. (No reason to allow, will not be allowed in Dart 3.0.)
abstract class AbstractMixesInEnum with Enum {}

abstract class MixesInMyEnum with MyEnum {
  //           ^
  // [cfe] 'MyEnum' is an enum and can't be extended or implemented.
  // [cfe] Can't use 'MyEnum' as a mixin because it has constructors.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
  // [cfe] The class 'MyEnum' can't be used as a mixin because it extends a class other than 'Object'.
}

enum EnumMixesInEnum with MyEnum {
  // ^
  // [cfe] 'MyEnum' is an enum and can't be extended or implemented.
  // [cfe] Can't use 'MyEnum' as a mixin because it has constructors.
  //                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
  // [cfe] The class 'MyEnum' can't be used as a mixin because it extends a class other than 'Object'.
  e1;
}

void main() {}

enum MyEnum {
  e1;
}

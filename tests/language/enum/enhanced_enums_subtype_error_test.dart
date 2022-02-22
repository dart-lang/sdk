// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-enums

// Test errors required by new enhanced enum syntax.

// Classes which implement `Enum`, but are not `enum` declarations,
// have extra requirements.
// Such a class is assumed to be either an interface intended to be
// implemented by an `enum` declaration,
// or a mixin intended to be mixed into an `enum` declaration.
// As such, we enforce restrictions which would definitely make
// that `enum` declaration invalid.
//
// * Such a class cannot be non-abstract.
// * It cannot implement `index`, `hashCode`, `==` or `values`.

class NonAbstract implements Enum {
  //  ^
  // [cfe] Non-abstract class 'NonAbstract' has 'Enum' as a superinterface.
  //                         ^^^^
  // [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

  int get index => 42;
}

// Cannot contain a `values` member
abstract class AbstractImplementsWithValues implements Enum {
  int get values => 42;
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_ENUM_VALUES_DECLARATION
  // [cfe] 'AbstractImplementsWithValues' has 'Enum' as a superinterface and can't contain non-static member with name 'values'.
}

abstract class AbstractExtendsWithValues extends Enum {
  int get values => 42;
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_ENUM_VALUES_DECLARATION
  // [cfe] 'AbstractExtendsWithValues' has 'Enum' as a superinterface and can't contain non-static member with name 'values'.
}

abstract class AbstractImplementsWithIndex implements Enum {
  int get index => 42;
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION
  // [cfe] unspecified
}

abstract class AbstractExtendsWithIndex extends Enum {
  int get index => 42;
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION
  // [cfe] unspecified
}

mixin MixinWithIndex on Enum {
  int get index => 42;
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION
  // [cfe] unspecified
}

mixin MixinWithIndex2 implements Enum {
  int get index => 42;
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION
  // [cfe] unspecified
}

mixin MixinWithValues on Enum {
  int get values => 42;
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_ENUM_VALUES_DECLARATION
  // [cfe] 'MixinWithValues' has 'Enum' as a superinterface and can't contain non-static member with name 'values'.
}

mixin MixinWithValues2 implements Enum {
  int get values => 42;
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_ENUM_VALUES_DECLARATION
  // [cfe] 'MixinWithValues2' has 'Enum' as a superinterface and can't contain non-static member with name 'values'.
}

// Can't implement Enum and declare hashCode/==.
abstract class ClassWithEquals implements Enum {
  bool operator ==(Object other) => true;
  //            ^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION
  //      ^^^^^^^^
  // [cfe] unspecified
}

mixin MixinWithEquals implements Enum {
  bool operator ==(Object other) => true;
  //            ^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION
  //      ^^^^^^^^
  // [cfe] unspecified
}

abstract class ClassWithHashCode implements Enum {
  int get hashCode => 0;
  //      ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION
  // [cfe] unspecified
}

mixin MixinWithHashCode implements Enum {
  int get hashCode => 0;
  //      ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION
  // [cfe] unspecified
}

abstract class SuperclassWithEquals {
  bool operator ==(Object other) => true;
}

abstract class SuperclassWithHashCode {
  int get hashCode => 0;
}

// Can't implement `Enum` and inherit concrete hashCode/==.
abstract class ClassSuperEquals extends SuperclassWithEquals implements Enum {
  //           ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER_INHERITANCE
  // [cfe] unspecified
}

abstract class ClassSuperHash extends SuperclassWithHashCode implements Enum {
  //           ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER_INHERITANCE
  // [cfe] unspecified
}

// No class can implement an actual enum.

abstract class ExtendsEnum extends MyEnum {
  //           ^
  // [cfe] 'MyEnum' is an enum and can't be extended or implemented.
  // [cfe] The superclass, 'MyEnum', has no unnamed constructor that takes no arguments.
  //                               ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENDS_NON_CLASS
}

abstract class ImplementsEnum implements MyEnum {
  //           ^
  // [cfe] 'MyEnum' is an enum and can't be extended or implemented.
  //                                     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_NON_CLASS
}

abstract class MixesInEnum with MyEnum { // It's not a mixin!
  //           ^
  // [cfe] 'MyEnum' is an enum and can't be extended or implemented.
  // [cfe] Can't use 'MyEnum' as a mixin because it has constructors.
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
}

mixin MixinImplementsEnum implements MyEnum {
  //  ^
  // [cfe] 'MyEnum' is an enum and can't be extended or implemented.
  //                                 ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_NON_CLASS
}

mixin MixinOnEnum on MyEnum {
  //  ^
  // [cfe] 'MyEnum' is an enum and can't be extended or implemented.
  //                 ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE
}

enum EnumImplementsEnum implements MyEnum {
  // ^
  // [cfe] 'MyEnum' is an enum and can't be extended or implemented.
  //                               ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_NON_CLASS
  e1;
}

enum EnumMixesInEnum with MyEnum {
  // ^
  // [cfe] 'MyEnum' is an enum and can't be extended or implemented.
  // [cfe] Can't use 'MyEnum' as a mixin because it has constructors.
  //                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
  e1;
}

void main() {}

enum MyEnum {
  e1;
}

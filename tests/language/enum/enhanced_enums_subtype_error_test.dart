// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  // [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_HAS_ENUM_SUPERINTERFACE

  int get index => 42;
  //      ^
  // [cfe] 'NonAbstract' has 'Enum' as a superinterface and can't contain non-static members with name 'index'.
}

// Cannot contain a `values` member
abstract class AbstractImplementsWithValues implements Enum {
  int get values => 42;
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_ENUM_VALUES
  // [cfe] 'AbstractImplementsWithValues' has 'Enum' as a superinterface and can't contain non-static member with name 'values'.
}

abstract class AbstractExtendsWithValues extends Enum {
//                                               ^
// [cfe] The class 'Enum' can't be extended outside of its library because it's an interface class.
  int get values => 42;
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_ENUM_VALUES
  // [cfe] 'AbstractExtendsWithValues' has 'Enum' as a superinterface and can't contain non-static member with name 'values'.
}

abstract class AbstractImplementsWithIndex implements Enum {
  int get index => 42;
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER
  // [cfe] 'AbstractImplementsWithIndex' has 'Enum' as a superinterface and can't contain non-static members with name 'index'.
}

abstract class AbstractExtendsWithIndex extends Enum {
//                                              ^
// [cfe] The class 'Enum' can't be extended outside of its library because it's an interface class.
  int get index => 42;
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER
  // [cfe] 'AbstractExtendsWithIndex' has 'Enum' as a superinterface and can't contain non-static members with name 'index'.
}

mixin MixinWithIndex on Enum {
  int get index => 42;
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER
  // [cfe] 'MixinWithIndex' has 'Enum' as a superinterface and can't contain non-static members with name 'index'.
}

mixin MixinWithIndex2 implements Enum {
  int get index => 42;
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER
  // [cfe] 'MixinWithIndex2' has 'Enum' as a superinterface and can't contain non-static members with name 'index'.
}

mixin MixinWithValues on Enum {
  int get values => 42;
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_ENUM_VALUES
  // [cfe] 'MixinWithValues' has 'Enum' as a superinterface and can't contain non-static member with name 'values'.
}

mixin MixinWithValues2 implements Enum {
  int get values => 42;
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_ENUM_VALUES
  // [cfe] 'MixinWithValues2' has 'Enum' as a superinterface and can't contain non-static member with name 'values'.
}

// Can't implement Enum and declare hashCode/==.
abstract class ClassWithEquals implements Enum {
  bool operator ==(Object other) => true;
  //            ^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER
  // [cfe] 'ClassWithEquals' has 'Enum' as a superinterface and can't contain non-static members with name '=='.
}

mixin MixinWithEquals implements Enum {
  bool operator ==(Object other) => true;
  //            ^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER
  // [cfe] 'MixinWithEquals' has 'Enum' as a superinterface and can't contain non-static members with name '=='.
}

abstract class ClassWithHashCode implements Enum {
  int get hashCode => 0;
  //      ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER
  // [cfe] 'ClassWithHashCode' has 'Enum' as a superinterface and can't contain non-static members with name 'hashCode'.
}

mixin MixinWithHashCode implements Enum {
  int get hashCode => 0;
  //      ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER
  // [cfe] 'MixinWithHashCode' has 'Enum' as a superinterface and can't contain non-static members with name 'hashCode'.
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
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER
  // [cfe] A concrete instance member named '==' can't be inherited from 'SuperclassWithEquals' in a class that implements 'Enum'.
}

abstract class ClassSuperHash extends SuperclassWithHashCode implements Enum {
  //           ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER
  // [cfe] A concrete instance member named 'hashCode' can't be inherited from 'SuperclassWithHashCode' in a class that implements 'Enum'.
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

// It's not a mixin!
abstract class MixesInEnum with MyEnum {
  //           ^
  // [cfe] 'MyEnum' is an enum and can't be extended or implemented.
  // [cfe] Can't use 'MyEnum' as a mixin because it has constructors.
  //                            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
  // [cfe] The class 'MyEnum' can't be used as a mixin because it extends a class other than 'Object'.
  // [cfe] The class 'MyEnum' can't be used as a mixin because it isn't a mixin class nor a mixin.
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
  // [cfe] The class 'MyEnum' can't be used as a mixin because it extends a class other than 'Object'.
  // [cfe] The class 'MyEnum' can't be used as a mixin because it isn't a mixin class nor a mixin.
  e1;
}

void main() {}

enum MyEnum {
  e1;
}

// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-enums

// Test errors required by new enhanced enum syntax.

// Enums must satisfy the same requirements as their induced class.
// That means no name conflicts, no static/instance member conflicts,
// and no type errors.
// Enum classes must implement their interface.
// They cannot override `Enum.index` or have any instance member named
// `values` or declare any name which will conflicts with a static
// constant getter named `values`.
//
// An enum declaration's generative constructors can never be referenced
// other than implicitly in creating the values and as target of redirecting
// generative constructors. All generative constructors must be const.
//
// An enum class cannot override `index` or implement anything named `values`.

// Helper mixins and also used as interfaces.
mixin GetFoo {
  int get foo => 42;
}

mixin SetFoo {
  void set foo(int _) {}
}

mixin MethodFoo {
  int foo() => 42;
}

mixin ValuesGetter {
  int get values => 42;
}

mixin IndexGetter {
  int get index => 42;
}

mixin NeverIndexGetter {
  Never get index => throw "Never!";
}

// "You cannot have two members with the same name in the same class---be
// they declared or inherited"

// Enums inherit members of `Object` and `index`.
// Enums implicitly declare `values` and their enum values (as static const
// getters.)

enum ConflictInstanceMembers {
  e1;
  int get foo => 42;
  int foo() => 37;
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'foo' is already declared in this scope.
}

// "It is an error if you have a static member named $m$ in your class
// and an instance member of the same basename"
enum ConflictStaticGetterInstanceMembers {
  e1;
  static int get foo => 42;
  //             ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
  int foo() => 37;
  //  ^
  // [cfe] 'foo' is already declared in this scope.
}

enum ConflictStaticSetterInstanceMembers {
  e1;
  static void set foo(int _) {}
  //              ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] This static member conflicts with an instance member.
  int foo() => 37;
  //  ^^^
  // [cfe] unspecified
}

enum ConflictStaticInstanceProperty2 {
  e1;
  int get foo => 42;
  //      ^^^
  // [cfe] unspecified
  static void set foo(int _) {}
  //              ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] This static member conflicts with an instance member.
}

// "It is an error if you have a static getter $v$
// and an instance setter \code{$v$=}"
enum ConflictStaticInstanceProperty {
  e1;
  static int get foo => 42;
  //             ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] This static member conflicts with an instance member.
  void set foo(int _) {}
  //       ^^^
  // [cfe] unspecified
}


enum ConflictStaticInheritedFoo with MethodFoo {
  e1;
  static int get foo => 42;
  //             ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] Can't declare a member that conflicts with an inherited one.
}

enum ConflictInheritedEnumValue with MethodFoo {
  foo;
//^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
// [cfe] Can't declare a member that conflicts with an inherited one.
}

enum ConflictStaticEnumValues {
  e1,
//^^
// [cfe] unspecified
  e1,
//^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] 'e1' is already declared in this scope.
  ;
}

enum ConflictStaticEnumValuesLooksDifferent {
  e1(),
//^^
// [cfe] unspecified
  e1.value(42),
//^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] 'e1' is already declared in this scope.
  ;
  const ConflictStaticEnumValuesLooksDifferent();
  const ConflictStaticEnumValuesLooksDifferent.value( dynamic_);
}

enum ConflictInstanceGetterInheritedFooMethod with MethodFoo {
  e1;
  int get foo => 42;
  //      ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_FIELD_AND_METHOD
  // [cfe] Can't declare a member that conflicts with an inherited one.
}

enum ConflictStaticInstanceImplicitValues {
  e1;
  int get values => 42;
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.VALUES_DECLARATION_IN_ENUM
  // [cfe] Enums can't contain declarations of members with the name 'values'.
}

enum ConflictStaticInstanceEnumValue {
  e1;
//^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
  int get e1 => 42;
  //      ^
  // [cfe] 'e1' is already declared in this scope.
}

enum ConflictEnumValueInheritedIndex {
  index;
//^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
// [cfe] Can't declare a member that conflicts with an inherited one.
}

enum ConflictEnumValueInheritedToString {
  toString;
//^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
// [cfe] 'toString' is already declared in this scope.
}

enum ConflictEnumValueImplicitValues {
  values;
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.VALUES_DECLARATION_IN_ENUM
// [cfe] unspecified
}

enum ConflictEnumValueInheritedFoo with MethodFoo {
  foo;
//^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
// [cfe] Can't declare a member that conflicts with an inherited one.
}

enum ConflictClassGetterSetterTypeInstance {
  e1;
  num get foo => 42;
  //      ^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
  // [cfe] The type 'num' of the getter 'ConflictClassGetterSetterTypeInstance.foo' is not a subtype of the type 'int' of the setter 'ConflictClassGetterSetterTypeInstance.foo'.

  // Type of setter parameter must be subtype of type of getter.
  void set foo(int _) {}
}

enum ConflictClassGetterSetterTypeStatic {
  e1;
  static num get foo => 42;
  //             ^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
  // [cfe] The type 'num' of the getter 'ConflictClassGetterSetterTypeStatic.foo' is not a subtype of the type 'int' of the setter 'ConflictClassGetterSetterTypeStatic.foo'.

  // Type of setter parameter must be subtype of type of getter.
  static void set foo(int _) {}
}

enum NoConflictClassEnumValueStaticSetter {
  e1;

  static void set e1(NoConflictClassEnumValueStaticSetter _) {}
}

enum ConflictClassEnumValueStaticSetterType {
  e1;
//^^
// [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
// [cfe] The type 'ConflictClassEnumValueStaticSetterType' of the getter 'ConflictClassEnumValueStaticSetterType.e1' is not a subtype of the type 'int' of the setter 'ConflictClassEnumValueStaticSetterType.e1'.

  // Type of setter parameter must be subtype of type of getter.
  static void set e1(int _) {}
}

enum ConflictTypeParameterMember<foo> {
  //                             ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_TYPE_VARIABLE_AND_MEMBER
  e1;
  int get foo => 42;
  //      ^
  // [cfe] Conflicts with type variable 'foo'.
}

enum ConflictTypeParameterValues<values> {
  //                             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_TYPE_VARIABLE_AND_MEMBER
  // [cfe] unspecified
  e1;
}

enum ConflictTypeParameterEnumValue<e1> {
  //                                ^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_TYPE_VARIABLE_AND_MEMBER
  // [cfe] unspecified
  e1;
//^^
// [cfe] unspecified
}

enum ConflictTypeParameters<T, T> {
  //                           ^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] A type variable can't have the same name as another.
  e1;
}

enum ConflictClassTypeParameter<ConflictClassTypeParameter> {
  //                            ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_TYPE_VARIABLE_AND_CONTAINER
  // [cfe] A type variable can't have the same name as its enclosing declaration.
  e1;
}

// "If you define an instance member named $m$,
//  and your superclass has an instance member of the same name,
//  they override each other."

enum OverrideInheritedMemberOverride with MethodFoo {
  e1;
  int foo(int x) => x; // super.foo is nullary.
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  // [cfe] The method 'OverrideInheritedMemberOverride.foo' has more required arguments than those of overridden method '_Enum with MethodFoo.foo'.
}

enum OverrideInheritedMemberDifferentType with GetFoo {
  e1;
  int foo(int x) => x;
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_METHOD_AND_FIELD
  // [cfe] Can't declare a member that conflicts with an inherited one.
}

enum ImplementInheritedMemberDifferentType implements GetFoo {
  e1;
  int foo(int x) => x;
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_METHOD_AND_FIELD
  // [cfe] unspecified
}

enum OverrideInheritedParameterTypeOverride with SetFoo {
  e1;
  void set foo(Never n) {} // Invalid parameter override.
  //       ^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  //                 ^
  // [cfe] The parameter 'n' of the method 'OverrideInheritedParameterTypeOverride.foo' has type 'Never', which does not match the corresponding type, 'int', in the overridden method, '_Enum with SetFoo.foo'.
}

// "Setters, getters and operators never have
//  optional parameters of any kind"

enum DeclareOperatorOptional {
  e1;
  int operator+([int? x]) => x ?? 0;
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.OPTIONAL_PARAMETER_IN_OPERATOR
  //                  ^
  // [cfe] An operator can't have optional parameters.
}

enum DeclareSetterOptional {
  e1;
  void set foo([int? x]) {}
  //       ^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER
  //          ^
  // [cfe] A setter should have exactly one formal parameter.
}

// "The identifier of a named constructor cannot be the same as
//  the basename of a static member declared in the same class"

enum ConflictConstructorNameStatic {
  e1.foo();
  const ConflictConstructorNameStatic.foo();
  //    ^
  // [cfe] Conflicts with member 'foo'.
  //                                  ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER
  static int get foo => 42;
  //             ^^^
  // [cfe] Conflicts with constructor 'ConflictConstructorNameStatic.foo'.
}

enum ConflictConstructorNameStaticEnumValue {
  e1.e1();
//^^
// [cfe] Conflicts with constructor 'ConflictConstructorNameStaticEnumValue.e1'.
  const ConflictConstructorNameStaticEnumValue.e1();
  //    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [cfe] Conflicts with member 'e1'.
  //                                           ^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER
}

// "It is an error if a member has the same name as its enclosing class"

enum ConflictClassStatic {
  e1;
//^
// [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  static int ConflictClassStatic() => 37;
//^^^^^^
// [analyzer] SYNTACTIC_ERROR.STATIC_CONSTRUCTOR
// [cfe] Constructors can't be static.
//       ^^^
// [analyzer] SYNTACTIC_ERROR.CONSTRUCTOR_WITH_RETURN_TYPE
// [cfe] Constructors can't have a return type.
//           ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR
// [cfe] Generative enum constructors must be marked as 'const'.
//                                 ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_IN_GENERATIVE_CONSTRUCTOR
//                                    ^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
// [cfe] Constructors can't have a return type.
}

enum ConflictClassInstance {
  e1;
//^
// [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  int ConflictClassInstance() => 37;
//^^^
// [analyzer] SYNTACTIC_ERROR.CONSTRUCTOR_WITH_RETURN_TYPE
// [cfe] Constructors can't have a return type.
//    ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR
// [cfe] Generative enum constructors must be marked as 'const'.
//                            ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_IN_GENERATIVE_CONSTRUCTOR
//                               ^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
// [cfe] Constructors can't have a return type.
}

enum ConflictClassEnumValue {
  ConflictClassEnumValue;
//^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING
// [cfe] Name of enum constant 'ConflictClassEnumValue' can't be the same as the enum's own name.
}

// Has conflict with implicitly inserted `values` member.
enum values {
  // ^^^^^^
  // [analyzer] unspecified
  // [cfe] unspecified
  e1;
}

// "It is an error if a concrete class does not implement some member
//  of its interface, and there is no non-trivial \code{noSuchMethod}"

enum UnimplementedInterface {
  // ^^^^^^^^^^^^^^^^^^^^^^
  // [cfe] The non-abstract class 'UnimplementedInterface' is missing implementations for these members:
  e1;
  int foo();
//^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ENUM_WITH_ABSTRACT_MEMBER
}

enum UnimplementedInterfaceInherited implements MethodFoo {
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER
  // [cfe] The non-abstract class 'UnimplementedInterfaceInherited' is missing implementations for these members:
  e1;
}

enum ImplementedInterface with MethodFoo {
  e1;
  int foo(); // Abstract members are allowed.
}

enum ImplementedInterfaceNSM {
  e1;
  int foo(); // Abstract members are allowed.
  dynamic noSuchMethod(i) => 42;
}

// Primitive Equality/HashCode.
// Enums must not override `==` or `hashCode`.

enum OverridesEquals {
  e1;

  bool operator==(Object other) => identical(e1, other);
  //   ^^^^^^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}

enum OverridesHashCode {
  e1;

  int get hashCode => 42;
  //      ^^^^^^^^
  // [cfe] unspecified
  // [analyzer] unspecified
}

// Invalid syntax that the compiled *should* recover from.
abstract enum CannotBeAbstract {
// [error column 1, length 8]
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'abstract' here.
  e1;
}

// Cannot reference generative constructors of enum classes.
// Never allowed to reference by ClassName[.name],
// only implicitly in value declarations and `this`[.name] in
// redirecting generative constructors.
// All ClassName[.name] references are errors.
enum NoConstructorCalls {
  e1(42),
  e2.ignore(NoConstructorCalls(1)),
  //        ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR
  // [cfe] Enums can't be instantiated.
  ;

  final int x;

  const NoConstructorCalls(this.x);
  const NoConstructorCalls.ignore(dynamic _) : x = 0;

  // Only valid use, as target of redirecting generative constructor.
  const NoConstructorCalls.redirect() : this(1);
  const NoConstructorCalls.redirectNamed() : this.ignore(0);

  const NoConstructorCalls.invalidRedirect()
       : this.ignore(NoConstructorCalls(1));
  //                 ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR
  //                 ^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  // [cfe] Enums can't be instantiated.

  // Generative constructors must be const.
  NoConstructorCalls.notConst(this.x);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR
// [cfe] Generative enum constructors must be marked as 'const'.

  // As usual, redirecting generative constructors must redirect to
  // generative constructors.
  const NoConstructorCalls.badRedirect() : this.factory();
  //    ^
  // [cfe] Final field 'x' is not initialized by this constructor.
  //                                       ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR
  // [cfe] Couldn't find constructor 'NoConstructorCalls.factory'.
  //                                            ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_NON_CONST_CONSTRUCTOR

  factory NoConstructorCalls.factory() => e1; // Valid.

  // Cannot reference generative constructors from factory constructors.
  factory NoConstructorCalls.badFactory() => NoConstructorCalls(2);
  //                                         ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR
  // [cfe] Enums can't be instantiated.

  factory NoConstructorCalls.badFactoryRedirect(int x) = NoConstructorCalls;
  //                                                     ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR
  // [cfe] Enum factory constructors can't redirect to generative constructors.

  static const NoConstructorCalls e3 = NoConstructorCalls(3);
  //                                   ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR
  // [cfe] Enums can't be instantiated.

  static void uses() {
    Function f = NoConstructorCalls.new; // No tearoffs.
    //           ^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR
    //                              ^
    // [cfe] Enum constructors can't be torn off.

    Function g = NoConstructorCalls.ignore; // No tearoffs.
    //           ^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR
    //                              ^
    // [cfe] Enum constructors can't be torn off.

    const c1 = NoConstructorCalls(0);
    //         ^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR
    // [cfe] Enums can't be instantiated.

    var v1 = new NoConstructorCalls(0);
    //           ^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR
    // [cfe] Enums can't be instantiated.
  }
}

enum DeclaresInstanceValues {
  e1;
  int get values => 42;
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.VALUES_DECLARATION_IN_ENUM
  // [cfe] Enums can't contain declarations of members with the name 'values'.
}

enum DeclaresStaticValues {
  e1;
  static int get values => 42;
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.VALUES_DECLARATION_IN_ENUM
  // [cfe] Enums can't contain declarations of members with the name 'values'.
}

enum InheritsValues with ValuesGetter {
  // ^^^^^^^^^^^^^^
  // [cfe] Can't declare a member that conflicts with an inherited one.
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_ENUM_VALUES
  e1;
}

enum ImplementsValues implements ValuesGetter {
  // ^^^^^^^^^^^^^^^^
  // [cfe] Can't declare a member that conflicts with an inherited one.
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_ENUM_VALUES
  e1;

  noSuchMethod(i) => 42;
}

enum DeclaresInstanceIndex {
  e1;
  int get index => 42;
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER
  // [cfe] unspecified
}

enum DeclaresStaticIndex {
  e1;
  static int get index => 42; // Conflicts with inherited instance member.
  //             ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] Can't declare a member that conflicts with an inherited one.
}

enum InheritsIndex with IndexGetter {
  // ^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] unspecified
  e1;
}

// No problem, implementation is not overridden.
enum ImplementsIndex implements IndexGetter {
  e1;
}

enum DeclaresNeverIndex {
  // ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_IMPLEMENTATION_OVERRIDE
  // [cfe] The implementation of 'index' in the non-abstract class 'DeclaresNeverIndex' does not conform to its interface.
  e1;

  Never get index;
}

enum ImplementsNeverIndex {
  e1;

  Never get index => throw "Never!";
  //        ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ILLEGAL_CONCRETE_ENUM_MEMBER
  // [cfe] unspecified
}

enum NSMImplementsNeverIndex implements NeverIndexGetter {
  // ^^^^^^
  // [analyzer] unspecified
  // [cfe] The implementation of 'index' in the non-abstract class 'NSMImplementsNeverIndex' does not conform to its interface.
  e1;

  noSuchMethod(i) => throw "Never!";
}

// Cannot have cyclic references between constants.
enum CyclicReference {
//   ^
// [cfe] Constant evaluation error:
  e1(e2),
//^
// [cfe] Constant evaluation error:
//   ^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
  e2(e1);
  // ^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
  final CyclicReference other;
  const CyclicReference(this.other);
}

// Since `values` contains `e1`,
// we can't have a reference in the other direction.
enum CyclicReferenceValues {
//   ^
// [cfe] Constant evaluation error:
  e1(values);
  // ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
  final List<CyclicReferenceValues> list;
  const CyclicReferenceValues(this.list);
}

void main() {}

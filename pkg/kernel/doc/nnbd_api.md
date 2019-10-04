# Nullability in CFE

Author: The Dart CFE team.

Status: Draft



## CHANGELOG

2019.09.26:
- Initial version uploaded.



## Summary

The sections below describe the encoding of the nullability property on types in the Kernel ASTs produced by the CFE.  Details are discussed, such as the use of `Nullability.neither`, and computation of the nullability property for the results of type substitution and type intersection is described.  The encoding for late fields and variables and required named parameters is described.  Finally, the list of the updates to the public interface of the CFE is given along with some recommendations on updating the client code.

This is a living document describing the changes in the output and in the public interface of the CFE related to the NNBD Dart language feature.  It is being updated as more changes are made.



## Objective

The document describes the updates in the output and in the API of the CFE related to the NNBD Dart language feature.  The document attempts to suggest the related updates in the client code for some simple cases.

*TODO: Describe non-goals.*



## Background

[The NNBD Dart language feature](https://github.com/dart-lang/language/blob/master/accepted/future-releases/nnbd/feature-specification.md) allows programmers to define types as nullable using the `?` suffix.  By default, the types are treated as non-nullable.  In addition to that, a [weak mode](https://github.com/dart-lang/language/blob/d4850d8fecaf2547c89f799a1d49a90cc9f935f4/accepted/future-releases/nnbd/roadmap.md#weak-null-checking) is defined that allows programmers to have some of their libraries to be opted out of the NNBD feature.  The types in the opted-out libraries are called legacy types and should be accounted for when they meet with nullable or non-nullable types on the library borders, for example in subtype checks.  Finally, there are types in the opted-in libraries that can't be classified as either nullable or non-nullable at compile time.

The presence of the nullability property on types affects some of the existing algorithms, such as type checks or type inference.  It also introduces additional notions and algorithms that are convenient and sometimes necessary to work with nullable types.

NNBD adds a number of features to the language that are not purely syntactic and should be communicated from the CFE to the back ends.  This document describes the related changes in the CFE output as well as the related changes in the API of the CFE libraries.



## Overview

The nullability property on types is represented by an `enum` with four possible values: for nullable types, non-nullable types, legacy types, and the types the nullability of which can't be fully determined at compile type.

It is required to compute the nullability of types and their parts when performing type substitution and creating an intersection of two types (also known as type-parameter types with promoted bounds).  There are tables that describe those two functions for combining nullabilities.

In addition to the nullability property on types there are new flags on the relevant nodes that mark the use of `late` and `required` keywords.  There's also a new Kernel AST node for the null check operator.

There's a number of changes in the API of the CFE.  The most notable changes are the removal of the `Class.rawType` getter and the related getters on `TypeEnvironment`.  There's a number of nullability-aware getters and methods that are added on `CoreTypes` that should be used instead of the removed getters.

To help avoid the explicit use of legacy types, there are getters on the `Library` AST node that help with choosing the appropriate nullability for the library depending on its opt-in status for the NNBD feature.  Some recommendations are given for using those getters.



## Detailed Design


### Terminology

In the document the term _type parameter_ is used to describe a formal type parameter of a class, a type alias, or a generic function.  For example,`X` and `Y` are type parameters in the declaration `class A<X, Y> {}`.  The term _type argument_ is used to describe an actual type parameter in an instance of a generic class or a type alias or an invocation of a generic function or a constructor of a generic class.  For example, `int` and `List<String>` are type arguments in the expression `new Map<int, List<String>>()`.


### Encoding for Nullability

The CFE combines various bits of information available at compile time, such as the nullability markers `?` used by the programmer and the NNBD opted-in status of the libraries, to mark every `DartType` in its output as belonging to one of the following four mutually disjoint sets:

- **Nullable** types.  Mainly, these are the types that are marked with `?` by the programmer.  They can also be inferred from other nullable types or synthesized according to the language specification.  For example, if the programmer omits the type bound on a type variable in an opted-in library, the CFE should synthesize `Object?` for the bound.
- **Non-nullable** types.  This is the default category of types.  If a type is declared without any modifiers in an opted-in library, in most cases it would be non-nullable.
- Types in opted-in libraries that are potentially nullable or potentially non-nullable, but **neither** can be said about them at compile time.  An example of such type is a type-parameter type with the nullable bound.  At run time both nullable and non-nullable types can be passed for that type parameter, so it's impossible to say anything about the nullability of such type at compile time.
- **Legacy** types.  These are the types originating from the opted-out libraries.

Every `DartType` subclass implements the `nullability` getter.  The return value of the getter is described by the following [`enum`](https://github.com/dart-lang/sdk/blob/0a4d47de3cb8cd398c5a2c669953129cdb11ec9a/pkg/kernel/lib/ast.dart#L4803):

```dart
enum Nullability {
  nullable,
  nonNullable,
  neither,
  legacy
}
```

In the textual representation of Kernel that is commonly used in `.expect` files `Nullability.nullable` is printed out as `?`, `Nullability.nonNullable` is printed as an empty sequence of characters, `Nullability.neither` is printed as `%`, and `Nullability.legacy` is printed as `*`.

*TODO: Add an example of a .expect file.*


####The 'neither' Nullability

`Nullability.neither` marks all types that can't be put into any other three categories at compile time and that should be categorized at run time.  The primary use case for `Nullability.neither` are type-parameter types with nullable bounds.  Consider the following Dart program:

```dart
// The enclosing library is opted in.

class A<T extends Object?> {
  foo(T x) {
    x = null;         // Compile-time error.
    Object y = x;     // Compile-time error.

    bar(T z) {}
    dynamic f = bar;
    f?.call(null);    // Runtime error?
  }
}
```

At compile time nothing can be said about the nullability of `T` because it is possible that at run time either a nullable or non-nullable type will be passed for it.  We have to be restrictive and prohibit both assignments of `null` to variables of type `T` and assignments of expression values of type `T` to variables of non-nullable types.  However, there are cases when the error can be caught only at run time when the nullability of the type passed for `T` is known.  An example of that is an invocation of a function stored in a variable of type `dynamic`.

A type-parameter type also has `Nullability.neither` if its bound have `Nullability.neither`.  In the following example types `T`, `S`, and `V` are of `neither` nullability:

```dart
class B<T extends S, S extends V, V extends Object?> {
  foo(T t, S s, V v) {
    // ...
  }
}
```

Additionally, if the nullability of a type depends on the nullability of an `InvalidType`, the former is set to `Nullability.neither` for recovery purposes.  An example of such dependency is the nullability of a type-parameter type with an `InvalidType` as the bound of its type parameter.  Note that the `.nullability` getter of `InvalidType` throws when accessed in order to make sure all such dependencies are treated explicitly.


#### Type Substitution and Nullability

Substitution of type arguments for occurrences of type parameters, when both the former and the latter have nullability attributes, requires computing the nullability of the substitution result.

In the following table the rows correspond to the possible nullability attributes of the type argument, the columns correspond to the possible nullability attributes of the type parameters, and the table elements contain the nullability for the result of the substitution of a type argument for a type parameter with the corresponding nullabilities.

| arg \ var | ! | ? | * | % |
|---|---|---|---|---|
| ! | ! | ? | * | ! |
| ? | N/A | ? | ? | ? |
| * | * | ? | * | * |
| % | N/A | ? | * | % |

In the table `!` denotes `Nullability.nonNullable`, `?` denotes `Nullability.nullable`, `*` denotes `Nullability.legacy`, and `%` denotes `Nullability.neither`.

Type-parameter types are assigned their nullabilities as follows:

- If a type parameter has a non-nullable bound, and a type-parameter type referring to that type parameter isn't marked with `?`, then that type-parameter type is non-nullable.  In the following example both `X` and `Y` are non-nullable when used as types:

```dart
class A<X extends Object> { X foo() => null; }
typedef F<Y extends int> = Y Function();
```

- If a type-parameter type is marked with `?`, the resulting type is nullable regardless of the nullability of the bound.  In the following example, types of all positional parameters of `foo` are nullable:

```dart
class A<X extends Object, Y extends Object?, Z extends Y> {
  foo(X? x, Y? y, Z? z) {}
}
```

- If a type-parameter type is used in an opted-out library, it's nullability is `Nullability.legacy` regardless of the nullability of the bound.  Note that in the following example both `X` and `Y` are legacy types despite `Y` having the nullable type `dynamic` as the bound.

```dart
// Assume the library is opted out.
class A<X extends int, Y extends dynamic> { foo(X x, Y y) {} }
```

- If a type parameter has a nullable bound or a bound that has `Nullability.neither`, and a type-parameter type referring that type parameter isn't marked with `?`, then that type-parameter type has `Nullability.neither`.  In the following example `X`, `Y`, and `Z` have `Nullability.neither` when used as types:

```dart
// Note that 'Object?' is provided for the omitted bounds in opted-in libraries.
class A<X extends Y, Y extends Z, Z> { foo(X x, Y y, Z z) {} }
```

All four cases above describe not promoted type-parameter types. Promoted type-parameter types are discussed in section **Nullability of Intersection Types**.

Type substitution happens both at compile time and at run time.  Unaliasing a `TypedefType`, such as the return type of `foo` in `typedef F<X, Y> = X Function(Y?); F<int?, String> foo() => null;`, is an example of type substitution happening at compile time.  The corresponding CFE output for the example looks as follows:

```kernel
library;
import self as self;
import "dart:core" as core;

typedef F<X extends core::Object? = dynamic, contravariant Y extends core::Object? = dynamic> = (Y?) → X%;
static method foo() → (core::String?) → core::int?
  return null;
```

Note that `X` has `Nullability.neither` when used as a type in the right-hand side of the `typedef` declaration.  The return type of `foo` is `int? Function(String?)`, which is the result of substituting `X` with `int?` and `Y` with `String` in `X% Function(Y?)`.

Obtaining the type for a type check, such as the is-check in the body of `foo` in the program fragment below, is an example where type substitution is needed at run time. 

```dart
class A<X> {
  foo(dynamic bar) => bar is List<X>;
}
```

The elements of the table that are marked with N/A correspond to cases that should be rejected by a type check.  The case for type argument having `Nullability.nullable` and the type parameter having `Nullability.nonNullable` should result in a type error because a nullable type can't be a subtype of a non-nullable type.  Similar is true for the argument that have `Nullability.neither` and the type parameter that have `Nullability.nonNullable` because at run time `Nullability.neither` can be replaced with `Nullability.nullable`.

The substitution routines in `pkg/kernel/lib/type_algebra.dart` follow the nullability computation rules described above.


#### Nullability of Intersection Types

In Kernel `TypeParameterType` represents types of two kinds.  The primary purpose of the node is to denote an occurrence of a type parameter in another type, which can be the entire type in the simplest case.  The secondary purpose of `TypeParameterType` is to represent a limited intersection type that arises from type promotion of variables declared with a `TypeParameterType`.  In the latter case the overall nullability of the intersection type is computed from the nullabilities of the left-hand side of the intersection (referred to as LHS below) and the right-hand side of the intersection (referred to as RHS below).

In the following table the rows correspond to the possible nullability attributes of the LHS, the columns correspond to the possible nullability attributes of the RHS, and the table elements contain the nullability of the intersection type of two types with the corresponding nullabilities.

| LHS \ RHS | ! | ? | * | % |
|---|---|---|---|---|
| ! | ! | N/A | N/A | ! |
| ? | N/A | N/A | N/A | N/A |
| * | N/A | N/A | * | N/A |
| % | ! | % | N/A | % |

In the table `!` denotes `Nullability.nonNullable`, `?` denotes `Nullability.nullable`, `*` denotes `Nullability.legacy`, and `%` denotes `Nullability.neither`.

The table elements marked with N/A represent combinations that can't be a part of a well-formed CFE output.  Some of them are due to the restriction on the intersection type that the RHS of the intersection should be a subtype of the bound of the type variable, and some others are due to the restriction that a nullable type is never promoted to an intersection type.

The intersection is induced by some of the type promotions, such as the one in the example below.

```dart
class A<T extends num?> {
  foo(T t) {
    if (t is int?) {
      var bar = t;
    }
  }
}
```

The type of the variable `t` in the example is promoted from `T` to `T & int?` because the RHS of the intersection, namely `int?`, is a subtype of the bound of `T`, which is `num?`.  In Kernel `T` has `Nullability.neither` because the bound of `T` is nullable, and the intersection type with the nullabilities of all its parts looks like `T% & int?`.  The following is the textual representation of the program from the example above compiled by the CFE.

```kernel
library;
import self as self;
import "dart:core" as core;

class A<T extends core::num? = core::num?> extends core::Object {
  synthetic constructor •() → self::A<self::A::T*>*
    : super core::Object::•()
    ;
  method foo(generic-covariant-impl self::A::T% t) → dynamic {
    if(t is core::int?) {
      self::A::T% & core::int? /* '%' & '?' = '%' */ bar = t{self::A::T% & core::int? /* '%' & '?' = '%' */};
    }
  }
}
```

Note that the type of `t`, which is written in the curly braces right after the getter, inside of the promoting if-statement is an intersection type with `self::A::T%` as the LHS and `core::int?` as the RHS.  The comments generated by the textual serializer show the computation of the overall nullability of the intersection type from the nullabilities of its components.

Instead of having the overall nullability on the `TypeParameterType` object, only the nullability of the LHS is serialized as the field `TypeParameterType.typeParameterTypeNullability`, and the overall nullability is computed in the `TypeParameterType.nullability` getter.  The back ends that perform their own deserialization may want to implement the computation of the overall nullability following that in the `TypeParameterType.nullability` getter.


### The 'required' Flag

Named parameters can be declared using the `required` keyword.  To reflect the use of the keyword the CFE sets the `isRequired` flag on `VariableDeclaration` and `NamedType` nodes.

The `isRequired` flag on `VariableDeclaration` is set if the node encodes a named formal parameter and the `required` keyword was used.

The use of the `required` keyword affects the override rules and the subtyping relationship for function types.  To reflect the use of the keyword in a function type, the `isRequired` flag is set on the corresponding `NamedType` representing the type of the named parameter.


### The 'late' Flag on Variables and Fields

Fields and variables can be declared using the `late` keyword.  To reflect the use of the keyword the CFE sets the `isLate` flag on `Field` and `VariableDeclaration` nodes.

The plan is to provide an optional desugaring of `late` fields and variables to aid the initial implementation of the feature.  The desugaring could be turned on by back ends via a compilation-target flag.

*TODO: Expand the section on desugaring.*


### The Null Check Operator

*TODO: Update the section.*


### Updates to the API

*TODO: Update the section as API changes.*

#### Nullability attribute on types

- `DartType.nullability` is added to `DartType` and the implementations are added to subclasses to subclasses (fields for InterfaceType, FunctionType, TypedefType, and TypeParameterType, concrete getter for `TypeParameterType`).
- Nullability parameter is added to constructors of InterfaceType, FunctionType, TypedefType, and TypeParameterType.
- `TypeParameterType.typeParameterTypeNullability is added.  For details see section **Nullability of Intersection Types** of this document.
- `TypeParameterType.computeNullabilityFromBound is added.

#### isRequired and isLate flags

- `VariableDeclaration.isRequired` setter and getter are added.
- `NamedType.isRequired` final field is added.
- `VariableDeclaration.isLate` setter and getter are added.
- `Field.isLate` setter and getter are added.

#### Null Check

- `NullCheck` AST node is added.

#### Changes in caching of raw types
- `Class.rawType` is removed.
- `TypeEnvironment.*Type` where `*` expands to `object`, `bool`, `int`, `num`, `double`, `string`, `symbol`, `type`, `rawFunction` are removed.
- `CoreTypes.*NonNullableRawType`, `CoreTypes.*NullableRawType`, `CoreTypes.*LegacyRawType`, and `CoreTypes.*RawType(Nullability)` where `*` expands into `object`, `bool`, `int`, `num`, `double`, `string`, `list`, `set`, `map`, `iterable`, `iterator`, `symbol`, `type`, `function`, `invocation`, `invocationMirror`, `future`, `stackTrace`, `stream`, `asyncAwaitCompleter`, `futureOr`, and `pragma` are added.
- `CoreTypes.nullType` is added.
- `CoreTypes.nonNullableRawType(Class)`, `CoreTypes.nullableRawType(Class)`, `CoreTypes.legacyRawType(Class)`, and `CoreTypes.rawType(Class, Nullability)` are added.

The reason for the changes is to avoid having type objects of undefined nullability and have nullability-aware getters and methods for retrieving the types instead.  The changes that landed the update ([commit 515a5977](https://github.com/dart-lang/sdk/commit/515a597710ace5b089d92c4bf3ebbfd0c61d7186), [commit e034104f](https://github.com/dart-lang/sdk/commit/e034104f04948ab9d5dc38a603841a70d0090812)) also change the client code so that a legacy type is retrieved from `CoreTypes` whenever there was an invocation of `Class.rawType`.  All of those places should be updated to retrieve a type with the desired nullability (see section **Updating the Client Code**).

#### Library status and library-specific nullability treatment
- `Library.isNonNullableByDefault` is added.
- `Library.nullable`, `Library.nonNullable`, and `Library.nullableIfTrue(bool)` are added.

The `Library.isNonNullableByDefault` getter is added to distinguish between opted-in and opted-out libraries.  Right now it returns `true` if the `non-nullable` experiment is enabled, and `false` otherwise.

The `Library.nullable` and `Library.nonNullable` getters are added to simplify the reasoning about types in the CFE and in the client code.  They return `Nullability.nullable` and `Nullability.nonNullable` respectively if the library is opted in, and both return `Nullability.legacy` otherwise.  Thus, one may only consider what nullability would be desirable in an opted-in library and have the case of opted-out library covered by the getters.

Similarly, `Library.nullableIfTrue(bool)` converts a boolean into a `Nullability` value: `true` is converted into `Nullability.nullable` and `false` is converted into `Nullability.nonNullable` if the library is opted in.  If the library is opted out, `Library.nullableIfTrue(bool)` returns `Nullability.legacy`.

This set of members makes it possible to avoid the explicit use of `Nullability.legacy` in the CFE and the client code.


### Updating the Client Code ###

#### Avoiding explicit legacy

As described in section **Changes in caching of raw types**, all previously existing invocations of `Class.rawType` and of the related getters of `TypeEnvironment` were replaced with invocations of nullability-aware members of `CoreTypes`.  To keep the observable behavior of the client code, legacy types were used wherever before a raw type was used.  For example, `intClass.rawType` was replaced with `coreTypes.intLegacyRawType` and `cls.rawType` was replaced with `coreTypes.legacyRawType(cls)`.  All of those call sites should be updated as a part of the NNBD feature implementation because they are the source of legacy types regardless of the opted-in status of the library they are generated for.  Section **Library status and library-specific nullability treatment** describes the changes in the CFE public interface that are supposed to help with the process.

The easiest way to avoid using explicitly legacy types is to do the following:

1.  Decide which nullability would be desirable for the type in an opted-in library.
2.  Specify the desired nullability for the type with `.nullable` or `.nonNullable` getter on the library node of the library that the type is used in.  In some cases, when a boolean condition tells if a type should be nullable, `.nullableIfTrue(bool)` method on the library node may be useful.

Quick recommendations for updating the described code are listed below.  The examples use `Nullability.nonNullable` as the desired nullability.

- Replace `coreTypes.intLegacyRawType` with `coreTypes.intRawType(library.nonNullable)`.  Similarly for other built-in types.
- Replace `coreTypes.legacyRawType(cls)` with `coreTypes.rawType(cls, library.nonNullable)`.
- Replace `coreTypes.rawType(cls, Nullability.legacy)` with `coreTypes.rawType(cls, library.nonNullable)`.
- Replace `new InterfaceType(cls, typeArgs)` with `new InterfaceType(cls, typeArgs, library.nonNullable)`.
- Replace `new InterfaceType(cls)` with `new InterfaceType(cls, const <DartType>[], library.nonNullable)`.
- Replace `new InterfaceType.byReference(clsRef, typeArgs)` with `new InterfaceType.byReference(clsRef, typeArgs, library.nonNullable)`.
- Replace `new FunctionType(positional, retType, <NAMED>)` with `new FunctionType(positional, retType, nullability: library.nonNullable, <NAMED>)` where `<NAMED>` are the named arguments passed in.
- Replace `new TypedefType(tdef, typeArgs)` with `new TypedefType(tdef, typeArgs, library.nonNullable)`.
- Replace `new TypedefType(tdef)` with `new TypedefType(tdef, const <DartType>[], library.nonNullable)`.
- Replace `new TypedefType.byReference(tdefRef, typeArgs)` with `new TypedefType.byReference(tdefRef, typeArgs, library.nonNullable)`.

The code updated this way will generate nullable and non-nullable types as desired for the opted-in libraries and will generate legacy types for the opted-out libraries.  It should also be easy to deprecate the weak-NNBD mode for such code: `Library.nonNullable` and `Library.nullable` will start returning the corresponding nullability constants.

#### Computing TypeParameterType.nullability

As described in section **Nullability of Intersection Types**, objects of `TypeParameterType` implement `.nullability` as a getter, not a field, and the overall nullability value for the type is not serialized in the binary format.  The back ends that implement their own deserialization may need to compute the nullability for `TypeParameterType`s.

#### Type equality

*TODO: Update the section.*

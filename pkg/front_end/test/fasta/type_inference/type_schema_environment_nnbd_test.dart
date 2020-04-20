// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/testing/type_parser_environment.dart';
import 'package:kernel/testing/mock_sdk.dart';
import 'package:kernel/type_environment.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeSchemaEnvironmentTest);
  });
}

@reflectiveTest
class TypeSchemaEnvironmentTest {
  Component component;

  CoreTypes coreTypes;

  TypeSchemaEnvironment env;

  TypeParserEnvironment typeParserEnvironment;

  Library get testLib => component.libraries.single;

  Class get iterableClass => coreTypes.iterableClass;

  Class get listClass => coreTypes.listClass;

  Class get mapClass => coreTypes.mapClass;

  Class get objectClass => coreTypes.objectClass;

  DartType get bottomType => const NeverType(Nullability.nonNullable);

  /// Converts the [text] representation of a type into a type.
  ///
  /// If [environment] is passed it's used to resolve the type terms in [text].
  /// If [typeParameters] are passed, they are used to extend
  /// [typeParserEnvironment] to resolve the type terms in [text].  Not more
  /// than one of [environment] or [typeParameters] should be passed in.
  DartType toType(String text,
      {TypeParserEnvironment environment, String typeParameters}) {
    assert(environment == null || typeParameters == null);
    environment ??= extend(typeParameters);
    return environment.parseType(text);
  }

  TypeParserEnvironment extend(String typeParameters) {
    return typeParserEnvironment.extendWithTypeParameters(typeParameters);
  }

  void test_addLowerBound() {
    const String testSdk = """
      class A;
      class B extends A;
      class C extends A;
    """;
    _initialize(testSdk);

    // TODO(dmitryas): Test for various nullabilities.
    TypeConstraint typeConstraint = new TypeConstraint();

    // typeConstraint: EMPTY <: TYPE <: EMPTY
    expect(typeConstraint.lower, new UnknownType());

    // typeConstraint: B* <: TYPE <: EMPTY
    env.addLowerBound(typeConstraint, toType("B*"), testLib);
    testConstraint(typeConstraint, lowerExpected: toType("B*"));

    // typeConstraint: UP(B*, C*) <: TYPE <: EMPTY,
    //     where UP(B*, C*) = A*
    env.addLowerBound(typeConstraint, toType("C*"), testLib);
    testConstraint(typeConstraint, lowerExpected: toType("A*"));
  }

  void test_addUpperBound() {
    const String testSdk = """
      class A;
      class B extends A;
      class C extends A;
    """;
    _initialize(testSdk);

    // TODO(dmitryas): Test for various nullabilities.
    TypeConstraint typeConstraint = new TypeConstraint();

    // typeConstraint: EMPTY <: TYPE <: EMPTY
    expect(typeConstraint.upper, new UnknownType());

    // typeConstraint: EMPTY <: TYPE <: A*
    env.addUpperBound(typeConstraint, toType("A*"), testLib);
    testConstraint(typeConstraint, upperExpected: toType("A*"));

    // typeConstraint: EMPTY <: TYPE <: DOWN(A*, B*),
    //     where DOWN(A*, B*) = B*
    env.addUpperBound(typeConstraint, toType("B*"), testLib);
    testConstraint(typeConstraint, upperExpected: toType("B*"));

    // typeConstraint: EMPTY <: TYPE <: DOWN(B*, C*),
    //     where DOWN(B*, C*) = Never*
    env.addUpperBound(typeConstraint, toType("C*"), testLib);
    testConstraint(typeConstraint,
        upperExpected: new NeverType(Nullability.legacy));
  }

  /// Some of the types satisfying the TOP predicate.
  ///
  /// There's an infinite amount of such types, and the list contains some
  /// practical base cases.  For the definition of TOP see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  static const Map<String, String> topPredicateEnumeration = <String, String>{
    // dynamic and void.
    "dynamic": null,
    "void": null,

    // T? where OBJECT(T).
    "Object?": null,
    "FutureOr<Object>?": null,
    "FutureOr<FutureOr<Object>>?": null,

    // T* where OBJECT(t).
    "Object*": null,
    "FutureOr<Object>*": null,
    "FutureOr<FutureOr<Object>>*": null,

    // FutureOr<T> where TOP(T).
    "FutureOr<dynamic>": null,
    "FutureOr<void>": null,
    "FutureOr<Object?>": null,
    "FutureOr<FutureOr<Object>?>": null,
    "FutureOr<FutureOr<FutureOr<Object>>?>": null,
    "FutureOr<Object*>": null,
    "FutureOr<FutureOr<Object>*>": null,
    "FutureOr<FutureOr<FutureOr<Object>>*>": null,
    "FutureOr<FutureOr<dynamic>?>": null,
    "FutureOr<FutureOr<void>?>": null,
    "FutureOr<FutureOr<Object?>?>": null,
    "FutureOr<FutureOr<FutureOr<Object>?>?>": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>?>?>": null,
    "FutureOr<FutureOr<Object*>?>": null,
    "FutureOr<FutureOr<FutureOr<Object>*>?>": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>*>?>": null,
    "FutureOr<FutureOr<dynamic>*>": null,
    "FutureOr<FutureOr<void>*>": null,
    "FutureOr<FutureOr<Object?>*>": null,
    "FutureOr<FutureOr<FutureOr<Object>?>*>": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>?>*>": null,
    "FutureOr<FutureOr<Object*>*>": null,
    "FutureOr<FutureOr<FutureOr<Object>*>*>": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>*>*>": null,

    // T? where TOP(T).
    "FutureOr<dynamic>?": null,
    "FutureOr<void>?": null,
    "FutureOr<Object?>?": null,
    "FutureOr<FutureOr<Object>?>?": null,
    "FutureOr<FutureOr<FutureOr<Object>>?>?": null,
    "FutureOr<Object*>?": null,
    "FutureOr<FutureOr<Object>*>?": null,
    "FutureOr<FutureOr<FutureOr<Object>>*>?": null,
    "FutureOr<FutureOr<dynamic>?>?": null,
    "FutureOr<FutureOr<void>?>?": null,
    "FutureOr<FutureOr<Object?>?>?": null,
    "FutureOr<FutureOr<FutureOr<Object>?>?>?": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>?>?>?": null,
    "FutureOr<FutureOr<Object*>?>?": null,
    "FutureOr<FutureOr<FutureOr<Object>*>?>?": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>*>?>?": null,
    "FutureOr<FutureOr<dynamic>*>?": null,
    "FutureOr<FutureOr<void>*>?": null,
    "FutureOr<FutureOr<Object?>*>?": null,
    "FutureOr<FutureOr<FutureOr<Object>?>*>?": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>?>*>?": null,
    "FutureOr<FutureOr<Object*>*>?": null,
    "FutureOr<FutureOr<FutureOr<Object>*>*>?": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>*>*>?": null,

    // T* where TOP(T).
    "FutureOr<dynamic>*": null,
    "FutureOr<void>*": null,
    "FutureOr<Object?>*": null,
    "FutureOr<FutureOr<Object>?>*": null,
    "FutureOr<FutureOr<FutureOr<Object>>?>*": null,
    "FutureOr<Object*>*": null,
    "FutureOr<FutureOr<Object>*>*": null,
    "FutureOr<FutureOr<FutureOr<Object>>*>*": null,
    "FutureOr<FutureOr<dynamic>?>*": null,
    "FutureOr<FutureOr<void>?>*": null,
    "FutureOr<FutureOr<Object?>?>*": null,
    "FutureOr<FutureOr<FutureOr<Object>?>?>*": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>?>?>*": null,
    "FutureOr<FutureOr<Object*>?>*": null,
    "FutureOr<FutureOr<FutureOr<Object>*>?>*": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>*>?>*": null,
    "FutureOr<FutureOr<dynamic>*>*": null,
    "FutureOr<FutureOr<void>*>*": null,
    "FutureOr<FutureOr<Object?>*>*": null,
    "FutureOr<FutureOr<FutureOr<Object>?>*>*": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>?>*>*": null,
    "FutureOr<FutureOr<Object*>*>*": null,
    "FutureOr<FutureOr<FutureOr<Object>*>*>*": null,
    "FutureOr<FutureOr<FutureOr<FutureOr<Object>>*>*>*": null,
  };

  /// Some of the types satisfying the OBJECT predicate.
  ///
  /// There's an infinite amount of such types, and the list contains some
  /// practical base cases.  For the definition of OBJECT see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  static const Map<String, String> objectPredicateEnumeration = {
    "Object": null,
    "FutureOr<Object>": null,
    "FutureOr<FutureOr<Object>>": null,
  };

  /// Some of the types satisfying the BOTTOM predicate.
  ///
  /// There's an infinite amount of such types, and the list contains some
  /// practical base cases.  For the definition of BOTTOM see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  ///
  /// The names of the variables here and in [nullPredicateEnumeration] should
  /// be distinct to avoid collisions.
  static const Map<String, String> bottomPredicateEnumeration = {
    "Never": null,
    "Xb & Never": "Xb extends Object?",
    "Yb & Zb & Never": "Yb extends Object?, Zb extends Object?",
    "Vb": "Vb extends Never",
    "Wb": "Wb extends Tb, Tb extends Never",
    "Sb & Rb": "Sb extends Object?, Rb extends Never",
  };

  /// Some of the types satisfying the NULL predicate.
  ///
  /// There's an infinite amount of such types, and the list contains some
  /// practical base cases.  For the definition of NULL see the following:
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/upper-lower-bounds.md#helper-predicates
  ///
  /// The names of the variables here and in [bottomPredicateEnumeration] should
  /// be distinct to avoid collisions.
  static const Map<String, String> nullPredicateEnumeration = {
    // T? where BOTTOM(T).
    "Never?": null,
    "Xn?": "Xn extends Never",
    "Yn?": "Yn extends Zn, Zn extends Never",

    // T* where BOTTOM(T).
    "Never*": null,
    "Vn*": "Vn extends Never",
    "Wn*": "Wn extends Tn, Tn extends Never",

    // Null.
    "Null": null,
  };

  static String joinTypeParameters(
      String typeParameters1, String typeParameters2) {
    if (typeParameters1 == null) return typeParameters2;
    if (typeParameters2 == null) return typeParameters1;
    if (typeParameters1 == typeParameters2) return typeParameters1;
    return "$typeParameters1, $typeParameters2";
  }

  void testLower(String first, String second, String expected,
      {String typeParameters}) {
    TypeParserEnvironment environment = extend(typeParameters);
    DartType firstType = toType(first, environment: environment);
    DartType secondType = toType(second, environment: environment);
    DartType expectedType = toType(expected, environment: environment);
    DartType producedType =
        env.getStandardLowerBound(firstType, secondType, testLib);
    expect(producedType, expectedType,
        reason: "DOWN(${firstType}, ${secondType}) produced '${producedType}', "
            "but expected '${expectedType}'.");
  }

  void testUpper(String first, String second, String expected,
      {String typeParameters}) {
    TypeParserEnvironment environment = extend(typeParameters);
    DartType firstType = toType(first, environment: environment);
    DartType secondType = toType(second, environment: environment);
    DartType expectedType = toType(expected, environment: environment);
    DartType producedType =
        env.getStandardUpperBound(firstType, secondType, testLib);
    expect(producedType, expectedType,
        reason: "UP(${firstType}, ${secondType}) produced '${producedType}', "
            "but expected '${expectedType}'.");
  }

  void testConstraint(TypeConstraint typeConstraint,
      {DartType lowerExpected, DartType upperExpected}) {
    assert(lowerExpected != null || upperExpected != null);
    if (lowerExpected != null) {
      expect(typeConstraint.lower, lowerExpected,
          reason: "Expected the lower bound to be '${lowerExpected}' "
              "for the following type constraint: ${typeConstraint}");
    }
    if (upperExpected != null) {
      expect(typeConstraint.upper, upperExpected,
          reason: "Expected the upper bound to be '${upperExpected}' "
              "for the following type constraint: ${typeConstraint}");
    }
  }

  void test_lower_bound_bottom() {
    _initialize("class A;");

    for (String type in ["A*", "A?", "A"]) {
      testLower("bottom", type, "bottom");
      testLower(type, "bottom", "bottom");
    }

    // DOWN(T1, T2) where BOTTOM(T1) and BOTTOM(T2) =
    //   T1 if MOREBOTTOM(T1, T2)
    //   T2 otherwise
    for (String t1 in bottomPredicateEnumeration.keys) {
      for (String t2 in bottomPredicateEnumeration.keys) {
        String typeParameters = joinTypeParameters(
            bottomPredicateEnumeration[t1], bottomPredicateEnumeration[t2]);
        String expected = env.morebottom(
                toType(t1, typeParameters: typeParameters),
                toType(t2, typeParameters: typeParameters))
            ? t1
            : t2;
        testLower(t1, t2, expected, typeParameters: typeParameters);
      }
    }

    // DOWN(T1, T2) = T2 if BOTTOM(T2)
    for (String type in ["A*", "A?", "A"]) {
      for (String t2 in bottomPredicateEnumeration.keys) {
        testLower(type, t2, t2, typeParameters: bottomPredicateEnumeration[t2]);
      }
    }

    // DOWN(T1, T2) = T1 if BOTTOM(T1)
    for (String t1 in bottomPredicateEnumeration.keys) {
      for (String type in ["A*", "A?", "A"]) {
        testLower(t1, type, t1, typeParameters: bottomPredicateEnumeration[t1]);
      }
    }

    // DOWN(T1, T2) where NULL(T1) and NULL(T2) =
    //   T1 if MOREBOTTOM(T1, T2)
    //   T2 otherwise
    for (String t1 in nullPredicateEnumeration.keys) {
      for (String t2 in nullPredicateEnumeration.keys) {
        String typeParameters = joinTypeParameters(
            nullPredicateEnumeration[t1], nullPredicateEnumeration[t2]);
        String expected = env.morebottom(
                toType(t1, typeParameters: typeParameters),
                toType(t2, typeParameters: typeParameters))
            ? t1
            : t2;
        testLower(t1, t2, expected, typeParameters: typeParameters);
      }
    }

    // DOWN(Null, T2) =
    //   Null if Null <: T2
    //   Never otherwise
    for (String t1 in nullPredicateEnumeration.keys) {
      testLower(t1, "A*", t1, typeParameters: nullPredicateEnumeration[t1]);
      testLower(t1, "A?", t1, typeParameters: nullPredicateEnumeration[t1]);
      testLower(t1, "A", "Never", typeParameters: nullPredicateEnumeration[t1]);
    }

    // DOWN(T1, Null) =
    //   Null if Null <: T1
    //   Never otherwise
    for (String t2 in nullPredicateEnumeration.keys) {
      testLower("A*", t2, t2, typeParameters: nullPredicateEnumeration[t2]);
      testLower("A?", t2, t2, typeParameters: nullPredicateEnumeration[t2]);
      testLower("A", t2, "Never", typeParameters: nullPredicateEnumeration[t2]);
    }
  }

  void test_lower_bound_function() {
    const String testSdk = """
      class A;
      class B extends A;
    """;
    _initialize(testSdk);

    // TODO(dmitryas): Test for various nullabilities.
    testLower("() ->* A*", "() ->* B*", "() ->* B*");
    testLower("() ->* void", "(A*, B*) ->* void", "([A*, B*]) ->* void");
    testLower("(A*, B*) ->* void", "() ->* void", "([A*, B*]) ->* void");
    testLower("(A*) ->* void", "(B*) ->* void", "(A*) ->* void");
    testLower("(B*) ->* void", "(A*) ->* void", "(A*) ->* void");
    testLower(
        "({A* a}) ->* void", "({B* b}) ->* void", "({A* a, B* b}) ->* void");
    testLower(
        "({B* b}) ->* void", "({A* a}) ->* void", "({A* a, B* b}) ->* void");
    testLower("({A* a, A* c}) ->* void", "({B* b, B* d}) ->* void",
        "({A* a, B* b, A* c, B* d}) ->* void");
    testLower("({A* a, B* b}) ->* void", "({B* a, A* b}) ->* void",
        "({A* a, A* b}) ->* void");
    testLower("({B* a, A* b}) ->* void", "({A* a, B* b}) ->* void",
        "({A* a, A* b}) ->* void");
    testLower(
        "(B*, {A* a}) ->* void", "(B*) ->* void", "(B*, {A* a}) ->* void");
    testLower("({A* a}) -> void", "(B*) -> void", "Never");
    testLower("({A* a}) -> void", "([B*]) ->* void", "Never");
    testLower("<X>() -> void", "<Y>() -> void", "<Z>() -> void");
    testLower("<X>(X) -> List<X>", "<Y>(Y) -> List<Y>", "<Z>(Z) -> List<Z>");
    testLower(
        "<X1, X2 extends List<X1>>(X1) -> X2",
        "<Y1, Y2 extends List<Y1>>(Y1) -> Y2",
        "<Z1, Z2 extends List<Z1>>(Z1) -> Z2");
    testLower(
        "<X extends int>(X) -> void", "<Y extends double>(Y) -> void", "Never");

    testLower(
        "({required A a, A b, required A c, A d, required A e}) -> A",
        "({required B a, required B b, B c, B f, required B g}) -> B",
        "({required A a, A b, A c, A d, A e, B f, B g}) -> B");

    testLower("<X extends dynamic>() -> void", "<Y extends Object?>() -> void",
        "<Z extends dynamic>() -> void");
    testLower("<X extends Null>() -> void", "<Y extends Never?>() -> void",
        "<Z extends Null>() -> void");
    testLower(
        "<X extends FutureOr<dynamic>?>() -> void",
        "<Y extends FutureOr<Object?>>() -> void",
        "<Z extends FutureOr<dynamic>?>() -> void");
  }

  void test_lower_bound_identical() {
    _initialize("class A;");

    testLower("A*", "A*", "A*");
    testLower("A?", "A?", "A?");
    testLower("A", "A", "A");
  }

  void test_lower_bound_subtype() {
    const String testSdk = """
      class A;
      class B extends A;
    """;
    _initialize(testSdk);

    testLower("A*", "B*", "B*");
    testLower("A*", "B?", "B*");
    testLower("A*", "B", "B");

    testLower("A?", "B*", "B*");
    testLower("A?", "B?", "B?");
    testLower("A?", "B", "B");

    testLower("A", "B*", "B");
    testLower("A", "B?", "B");
    testLower("A", "B", "B");

    testLower("B*", "A*", "B*");
    testLower("B?", "A*", "B*");
    testLower("B", "A*", "B");

    testLower("B*", "A?", "B*");
    testLower("B?", "A?", "B?");
    testLower("B", "A?", "B");

    testLower("B*", "A", "B");
    testLower("B?", "A", "B");
    testLower("B", "A", "B");

    testLower("Iterable<A>*", "List<B>*", "List<B>*");
    testLower("Iterable<A>*", "List<B>?", "List<B>*");
    testLower("Iterable<A>*", "List<B>", "List<B>");

    testLower("Iterable<A>?", "List<B>*", "List<B>*");
    testLower("Iterable<A>?", "List<B>?", "List<B>?");
    testLower("Iterable<A>?", "List<B>", "List<B>");

    testLower("Iterable<A>", "List<B>*", "List<B>");
    testLower("Iterable<A>", "List<B>?", "List<B>");
    testLower("Iterable<A>", "List<B>", "List<B>");

    testLower("List<B>*", "Iterable<A>*", "List<B>*");
    testLower("List<B>?", "Iterable<A>*", "List<B>*");
    testLower("List<B>", "Iterable<A>*", "List<B>");

    testLower("List<B>*", "Iterable<A>?", "List<B>*");
    testLower("List<B>?", "Iterable<A>?", "List<B>?");
    testLower("List<B>", "Iterable<A>?", "List<B>");

    testLower("List<B>*", "Iterable<A>", "List<B>");
    testLower("List<B>?", "Iterable<A>", "List<B>");
    testLower("List<B>", "Iterable<A>", "List<B>");
  }

  void test_lower_bound_top() {
    _initialize("class A;");

    // TODO(dmitryas): Test for various nullabilities.
    testLower("dynamic", "A*", "A*");
    testLower("A*", "dynamic", "A*");
    testLower("Object?", "A*", "A*");
    testLower("A*", "Object?", "A*");
    testLower("void", "A*", "A*");
    testLower("A*", "void", "A*");

    // DOWN(T1, T2) where TOP(T1) and TOP(T2) =
    //   T1 if MORETOP(T2, T1)
    //   T2 otherwise
    for (String t1 in topPredicateEnumeration.keys) {
      for (String t2 in topPredicateEnumeration.keys) {
        String typeParameters = joinTypeParameters(
            topPredicateEnumeration[t1], topPredicateEnumeration[t2]);
        String expected = env.moretop(
                toType(t2, typeParameters: typeParameters),
                toType(t1, typeParameters: typeParameters))
            ? t1
            : t2;
        testLower(t1, t2, expected, typeParameters: typeParameters);
      }
    }

    // DOWN(T1, T2) = T2 if TOP(T1)
    for (String t1 in topPredicateEnumeration.keys) {
      testLower(t1, "A*", "A*", typeParameters: topPredicateEnumeration[t1]);
    }

    // DOWN(T1, T2) = T1 if TOP(T2)
    for (String t2 in topPredicateEnumeration.keys) {
      testLower("A*", t2, "A*", typeParameters: topPredicateEnumeration[t2]);
    }
  }

  void test_lower_bound_unknown() {
    _initialize("class A;");

    testLower("A*", "unknown", "A*");
    testLower("A?", "unknown", "A?");
    testLower("A", "unknown", "A");

    testLower("unknown", "A*", "A*");
    testLower("unknown", "A?", "A?");
    testLower("unknown", "A", "A");
  }

  void test_lower_bound_unrelated() {
    const String testSdk = """
      class A;
      class B;
    """;
    _initialize(testSdk);

    testLower("A*", "B*", "Never*");
    testLower("A*", "B?", "Never*");
    testLower("A*", "B", "Never");

    testLower("A?", "B*", "Never*");
    testLower("A?", "B?", "Never?");
    testLower("A?", "B", "Never");

    testLower("A", "B*", "Never");
    testLower("A", "B?", "Never");
    testLower("A", "B", "Never");
  }

  void test_inferGenericFunctionOrType() {
    _initialize("");

    // TODO(dmitryas): Test for various nullabilities.
    InterfaceType listClassThisType =
        coreTypes.thisInterfaceType(listClass, testLib.nonNullable);
    {
      // Test an instantiation of [1, 2.0] with no context.  This should infer
      // as List<?> during downwards inference.
      List<DartType> inferredTypes = <DartType>[new UnknownType()];
      TypeParameterType T = listClassThisType.typeArguments[0];
      env.inferGenericFunctionOrType(listClassThisType, [T.parameter], null,
          null, null, inferredTypes, testLib);
      expect(inferredTypes[0], new UnknownType());
      // And upwards inference should refine it to List<num>.
      env.inferGenericFunctionOrType(
          listClassThisType,
          [T.parameter],
          [T, T],
          [coreTypes.intNonNullableRawType, coreTypes.doubleNonNullableRawType],
          null,
          inferredTypes,
          testLib);
      expect(inferredTypes[0], coreTypes.numNonNullableRawType);
    }
    {
      // Test an instantiation of [1, 2.0] with a context of List<Object>.  This
      // should infer as List<Object> during downwards inference.
      List<DartType> inferredTypes = <DartType>[new UnknownType()];
      TypeParameterType T = listClassThisType.typeArguments[0];
      env.inferGenericFunctionOrType(
          listClassThisType,
          [T.parameter],
          null,
          null,
          _list(coreTypes.objectNonNullableRawType),
          inferredTypes,
          testLib);
      expect(inferredTypes[0], coreTypes.objectNonNullableRawType);
      // And upwards inference should preserve the type.
      env.inferGenericFunctionOrType(
          listClassThisType,
          [T.parameter],
          [T, T],
          [coreTypes.intNonNullableRawType, coreTypes.doubleNonNullableRawType],
          _list(coreTypes.objectNonNullableRawType),
          inferredTypes,
          testLib);
      expect(inferredTypes[0], coreTypes.objectNonNullableRawType);
    }
    {
      // Test an instantiation of [1, 2.0, null] with no context.  This should
      // infer as List<?> during downwards inference.
      List<DartType> inferredTypes = <DartType>[new UnknownType()];
      TypeParameterType T = listClassThisType.typeArguments[0];
      env.inferGenericFunctionOrType(listClassThisType, [T.parameter], null,
          null, null, inferredTypes, testLib);
      expect(inferredTypes[0], new UnknownType());
      // And upwards inference should refine it to List<num?>.
      env.inferGenericFunctionOrType(
          listClassThisType,
          [T.parameter],
          [T, T, T],
          [
            coreTypes.intNonNullableRawType,
            coreTypes.doubleNonNullableRawType,
            coreTypes.nullType
          ],
          null,
          inferredTypes,
          testLib);
      expect(inferredTypes[0], coreTypes.numNullableRawType);
    }
    {
      // Test an instantiation of legacy [1, 2.0] with no context.
      // This should infer as List<?> during downwards inference.
      List<DartType> inferredTypes = <DartType>[new UnknownType()];
      TypeParameterType T = listClassThisType.typeArguments[0];
      env.inferGenericFunctionOrType(listClassThisType, [T.parameter], null,
          null, null, inferredTypes, testLib);
      expect(inferredTypes[0], new UnknownType());
      // And upwards inference should refine it to List<num!>.
      env.inferGenericFunctionOrType(
          listClassThisType,
          [T.parameter],
          [T, T],
          [coreTypes.intLegacyRawType, coreTypes.doubleLegacyRawType],
          null,
          inferredTypes,
          testLib);
      expect(inferredTypes[0], coreTypes.numNonNullableRawType);
    }
  }

  void test_inferTypeFromConstraints_applyBound() {
    _initialize("");

    // class A<T extends num*> {}
    TypeParameter T = new TypeParameter("T", coreTypes.numLegacyRawType);

    // TODO(dmitryas): Test for various nullabilities.
    {
      // With no constraints:
      Map<TypeParameter, TypeConstraint> constraints = {
        T: new TypeConstraint()
      };

      // Downward inference should infer A<?>
      List<DartType> inferredTypes = <DartType>[new UnknownType()];
      env.inferTypeFromConstraints(constraints, [T], inferredTypes, testLib,
          downwardsInferPhase: true);
      expect(inferredTypes[0], new UnknownType());

      // Upward inference should infer A<num*>
      env.inferTypeFromConstraints(constraints, [T], inferredTypes, testLib);
      expect(inferredTypes[0], coreTypes.numLegacyRawType);
    }
    {
      // With an upper bound of Object*:
      Map<TypeParameter, TypeConstraint> constraints = {
        T: _makeConstraint(upper: coreTypes.objectLegacyRawType)
      };

      // Downward inference should infer A<num*>
      List<DartType> inferredTypes = <DartType>[new UnknownType()];
      env.inferTypeFromConstraints(constraints, [T], inferredTypes, testLib,
          downwardsInferPhase: true);
      expect(inferredTypes[0], coreTypes.numLegacyRawType);

      // Upward inference should infer A<num*>
      env.inferTypeFromConstraints(constraints, [T], inferredTypes, testLib);
      expect(inferredTypes[0], coreTypes.numLegacyRawType);

      // Upward inference should still infer A<num*> even if there are more
      // constraints now, because num was finalized during downward inference.
      constraints = {
        T: _makeConstraint(
            lower: coreTypes.intLegacyRawType,
            upper: coreTypes.intLegacyRawType)
      };
      env.inferTypeFromConstraints(constraints, [T], inferredTypes, testLib);
      expect(inferredTypes[0], coreTypes.numLegacyRawType);
    }
  }

  void test_inferTypeFromConstraints_simple() {
    _initialize("");

    TypeParameter T = listClass.typeParameters[0];

    // TODO(dmitryas): Test for various nullabilities.

    // With an upper bound of List<?>*:
    Map<TypeParameter, TypeConstraint> constraints = {
      T: _makeConstraint(upper: _list(new UnknownType()))
    };

    // Downwards inference should infer List<List<?>*>*
    List<DartType> inferredTypes = <DartType>[new UnknownType()];
    env.inferTypeFromConstraints(constraints, [T], inferredTypes, testLib,
        downwardsInferPhase: true);
    expect(inferredTypes[0], _list(new UnknownType()));

    // Upwards inference should refine that to List<List<dynamic>*>*
    env.inferTypeFromConstraints(constraints, [T], inferredTypes, testLib);
    expect(inferredTypes[0], _list(new DynamicType()));
  }

  void test_upper_bound_classic() {
    // Make the class hierarchy:
    //
    // Object
    //   |
    //   A
    //  /|\
    // B C K
    // |X| |
    // D E L
    const String testSdk = """
      class A;
      class B implements A;
      class C implements A;
      class K implements A;
      class D implements B, C;
      class E implements B, C;
      class L implements K;
    """;
    _initialize(testSdk);

    // TODO(dmitryas): Test for various nullabilities.
    testUpper("B*", "E*", "B*");
    testUpper("D*", "C*", "C*");
    testUpper("D*", "E*", "A*");
    testUpper("D*", "A*", "A*");
    testUpper("B*", "K*", "A*");
    testUpper("B*", "L*", "A*");
  }

  void test_upper_bound_commonClass() {
    _initialize("");

    testUpper("List<int*>", "List<double*>", "List<num*>");
    testUpper("List<int?>", "List<double>", "List<num?>");
  }

  void test_upper_bound_function() {
    const String testSdk = """
      class A;
      class B extends A;
    """;
    _initialize(testSdk);

    testUpper("() ->? A", "() -> B?", "() ->? A?");
    testUpper("([A*]) ->* void", "(A*) ->* void", "Function*");
    testUpper("() ->* void", "(A*, B*) ->* void", "Function*");
    testUpper("(A*, B*) ->* void", "() ->* void", "Function*");
    testUpper("(A*) ->* void", "(B*) ->* void", "(B*) ->* void");
    testUpper("(B*) ->* void", "(A*) ->* void", "(B*) ->* void");
    testUpper("({A* a}) ->* void", "({B* b}) ->* void", "() ->* void");
    testUpper("({B* b}) ->* void", "({A* a}) ->* void", "() ->* void");
    testUpper(
        "({A* a, A* c}) ->* void", "({B* b, B* d}) ->* void", "() ->* void");
    testUpper("({A* a, B* b}) ->* void", "({B* a, A* b}) ->* void",
        "({B* a, B* b}) ->* void");
    testUpper("({B* a, A* b}) ->* void", "({A* a, B* b}) ->* void",
        "({B* a, B* b}) ->* void");
    testUpper("(B*, {A* a}) ->* void", "(B*) ->* void", "(B*) ->* void");
    testUpper("({A* a}) ->* void", "(B*) ->* void", "Function*");
    testUpper("() ->* void", "([B*]) ->* void", "() ->* void");
    testUpper("<X>() -> void", "<Y>() -> void", "<Z>() -> void");
    testUpper("<X>(X) -> List<X>", "<Y>(Y) -> List<Y>", "<Z>(Z) -> List<Z>");
    testUpper(
        "<X1, X2 extends List<X1>>(X1) -> X2",
        "<Y1, Y2 extends List<Y1>>(Y1) -> Y2",
        "<Z1, Z2 extends List<Z1>>(Z1) -> Z2");
    testUpper("<X extends int>() -> void", "<Y extends double>() -> void",
        "Function");

    testUpper("({required A a, B b}) -> A", "({B a, required A b}) -> B",
        "({required B a, required B b}) -> A");

    testUpper("<X extends dynamic>() -> void", "<Y extends Object?>() -> void",
        "<Z extends dynamic>() -> void");
    testUpper("<X extends Null>() -> void", "<Y extends Never?>() -> void",
        "<Z extends Null>() -> void");
    testUpper(
        "<X extends FutureOr<dynamic>?>() -> void",
        "<Y extends FutureOr<Object?>>() -> void",
        "<Z extends FutureOr<dynamic>?>() -> void");

    testUpper("([dynamic]) -> dynamic", "([dynamic]) -> dynamic",
        "([dynamic]) -> dynamic");
  }

  void test_upper_bound_identical() {
    _initialize("class A;");

    testUpper("A*", "A*", "A*");
    testUpper("A*", "A?", "A?");
    testUpper("A*", "A", "A*");

    testUpper("A?", "A*", "A?");
    testUpper("A?", "A?", "A?");
    testUpper("A?", "A", "A?");

    testUpper("A", "A*", "A*");
    testUpper("A", "A?", "A?");
    testUpper("A", "A", "A");
  }

  void test_upper_bound_sameClass() {
    const String testSdk = """
      class A;
      class B extends A;
      class Pair<X, Y>;
    """;
    _initialize(testSdk);

    testUpper("Pair<A*, B*>", "Pair<B*, A*>", "Pair<A*, A*>");
    testUpper("Pair<A*, B*>", "Pair<B?, A>", "Pair<A?, A*>");
    testUpper("Pair<A?, B?>", "Pair<B, A>", "Pair<A?, A?>");
  }

  void test_upper_bound_subtype() {
    const String testSdk = """
      class A;
      class B extends A;
    """;
    _initialize(testSdk);

    // UP(T1, T2) = T2 if T1 <: T2
    //   Note that both types must be class types at this point
    testUpper("List<B*>", "Iterable<A*>", "Iterable<A*>");
    testUpper("List<B*>", "Iterable<A?>", "Iterable<A?>");
    testUpper("List<B*>", "Iterable<A>", "Iterable<A>");
    testUpper("List<B>*", "Iterable<A>*", "Iterable<A>*");
    testUpper("List<B>*", "Iterable<A>?", "Iterable<A>?");
    testUpper("List<B>*", "Iterable<A>", "Iterable<A>*");
    testUpper("List<B>?", "Iterable<A>*", "Iterable<A>?");
    testUpper("List<B>?", "Iterable<A>?", "Iterable<A>?");
    testUpper("List<B>?", "Iterable<A>", "Iterable<A>?");

    // UP(T1, T2) = T2 if T1 <: T2
    //   Note that both types must be class types at this point
    testUpper("List<B?>", "Iterable<A*>", "Iterable<A*>");
    testUpper("List<B?>", "Iterable<A?>", "Iterable<A?>");
    testUpper("List<B>?", "Iterable<A>*", "Iterable<A>?");
    testUpper("List<B>?", "Iterable<A>?", "Iterable<A>?");
    testUpper("List<B>?", "Iterable<A>", "Iterable<A>?");
    // UP(C0<T0, ..., Tn>, C1<S0, ..., Sk>)
    //     = least upper bound of two interfaces as in Dart 1.
    testUpper("List<B?>", "Iterable<A>", "Object");

    // UP(T1, T2) = T2 if T1 <: T2
    //   Note that both types must be class types at this point
    testUpper("List<B>", "Iterable<A*>", "Iterable<A*>");
    testUpper("List<B>", "Iterable<A?>", "Iterable<A?>");
    testUpper("List<B>", "Iterable<A>", "Iterable<A>");
    testUpper("List<B>", "Iterable<A>*", "Iterable<A>*");
    testUpper("List<B>", "Iterable<A>?", "Iterable<A>?");

    // UP(T1, T2) = T1 if T2 <: T1
    //   Note that both types must be class types at this point
    testUpper("Iterable<A*>", "List<B*>", "Iterable<A*>");
    testUpper("Iterable<A*>", "List<B?>", "Iterable<A*>");
    testUpper("Iterable<A*>", "List<B>", "Iterable<A*>");
    testUpper("Iterable<A>*", "List<B>*", "Iterable<A>*");
    testUpper("Iterable<A>*", "List<B>?", "Iterable<A>?");
    testUpper("Iterable<A>*", "List<B>", "Iterable<A>*");

    // UP(T1, T2) = T1 if T2 <: T1
    //   Note that both types must be class types at this point
    testUpper("Iterable<A?>", "List<B*>", "Iterable<A?>");
    testUpper("Iterable<A?>", "List<B?>", "Iterable<A?>");
    testUpper("Iterable<A?>", "List<B>", "Iterable<A?>");
    testUpper("Iterable<A>?", "List<B>*", "Iterable<A>?");
    testUpper("Iterable<A>?", "List<B>?", "Iterable<A>?");
    testUpper("Iterable<A>?", "List<B>", "Iterable<A>?");

    // UP(T1, T2) = T1 if T2 <: T1
    //   Note that both types must be class types at this point
    testUpper("Iterable<A>", "List<B*>", "Iterable<A>");
    testUpper("Iterable<A>", "List<B>*", "Iterable<A>*");
    // UP(C0<T0, ..., Tn>, C1<S0, ..., Sk>)
    //     = least upper bound of two interfaces as in Dart 1.
    testUpper("Iterable<A>", "List<B?>", "Object");
    // UP(T1, T2) = T1 if T2 <: T1
    //   Note that both types must be class types at this point
    testUpper("Iterable<A>", "List<B>", "Iterable<A>");
  }

  void test_upper_bound_top() {
    _initialize("class A;");

    // UP(T1, T2) where TOP(T1) and TOP(T2) =
    //   T1 if MORETOP(T1, T2)
    //   T2 otherwise
    for (String t1 in topPredicateEnumeration.keys) {
      for (String t2 in topPredicateEnumeration.keys) {
        String typeParameters = joinTypeParameters(
            topPredicateEnumeration[t1], topPredicateEnumeration[t2]);
        String expected = env.moretop(
                toType(t1, typeParameters: typeParameters),
                toType(t2, typeParameters: typeParameters))
            ? t1
            : t2;
        testUpper(t1, t2, expected, typeParameters: typeParameters);
      }
    }

    // UP(T1, T2) = T1 if TOP(T1)
    for (String t1 in topPredicateEnumeration.keys) {
      for (String t2 in ["A*", "A?", "A"]) {
        testUpper(t1, t2, t1, typeParameters: topPredicateEnumeration[t1]);
      }
    }

    // UP(T1, T2) = T2 if TOP(T2)
    for (String t1 in ["A*", "A?", "A"]) {
      for (String t2 in topPredicateEnumeration.keys) {
        testUpper(t1, t2, t2, typeParameters: topPredicateEnumeration[t2]);
      }
    }

    // UP(T1, T2) where OBJECT(T1) and OBJECT(T2) =
    //   T1 if MORETOP(T1, T2)
    //   T2 otherwise
    for (String t1 in objectPredicateEnumeration.keys) {
      for (String t2 in objectPredicateEnumeration.keys) {
        String typeParameters = joinTypeParameters(
            objectPredicateEnumeration[t1], objectPredicateEnumeration[t2]);
        String expected = env.moretop(
                toType(t1, typeParameters: typeParameters),
                toType(t2, typeParameters: typeParameters))
            ? t1
            : t2;
        testUpper(t1, t2, expected, typeParameters: typeParameters);
      }
    }

    // UP(T1, T2) where OBJECT(T1) =
    //   T1 if T2 is non-nullable
    //   T1? otherwise
    for (String t1 in objectPredicateEnumeration.keys) {
      testUpper(t1, "A*", "${t1}?",
          typeParameters: objectPredicateEnumeration[t1]);
      testUpper(t1, "A?", "${t1}?",
          typeParameters: objectPredicateEnumeration[t1]);
      testUpper(t1, "A", t1);
    }

    // UP(T1, T2) where OBJECT(T2) =
    //   T2 if T1 is non-nullable
    //   T2? otherwise
    for (String t2 in objectPredicateEnumeration.keys) {
      testUpper("A*", t2, "${t2}?");
      testUpper("A?", t2, "${t2}?");
      testUpper("A", t2, t2);
    }
  }

  void test_upper_bound_bottom() {
    _initialize("class A;");

    // UP(T1, T2) where BOTTOM(T1) and BOTTOM(T2) =
    //   T2 if MOREBOTTOM(T1, T2)
    //   T1 otherwise
    for (String t1 in bottomPredicateEnumeration.keys) {
      for (String t2 in bottomPredicateEnumeration.keys) {
        String typeParameters = joinTypeParameters(
            bottomPredicateEnumeration[t1], bottomPredicateEnumeration[t2]);
        String expected = env.morebottom(
                toType(t1, typeParameters: typeParameters),
                toType(t2, typeParameters: typeParameters))
            ? t2
            : t1;
        testUpper(t1, t2, expected, typeParameters: typeParameters);
      }
    }

    // UP(T1, T2) = T2 if BOTTOM(T1)
    for (String t1 in bottomPredicateEnumeration.keys) {
      for (String t2 in ["A*", "A?", "A"]) {
        testUpper(t1, t2, t2, typeParameters: bottomPredicateEnumeration[t1]);
      }
    }

    // UP(T1, T2) = T1 if BOTTOM(T2)
    for (String t1 in ["A*", "A?", "A"]) {
      for (String t2 in bottomPredicateEnumeration.keys) {
        testUpper(t1, t2, t1, typeParameters: bottomPredicateEnumeration[t2]);
      }
    }

    // UP(T1, T2) where NULL(T1) and NULL(T2) =
    //   T2 if MOREBOTTOM(T1, T2)
    //   T1 otherwise
    for (String t1 in nullPredicateEnumeration.keys) {
      for (String t2 in nullPredicateEnumeration.keys) {
        String typeParameters = joinTypeParameters(
            nullPredicateEnumeration[t1], nullPredicateEnumeration[t2]);
        String expected = env.morebottom(
                toType(t1, typeParameters: typeParameters),
                toType(t2, typeParameters: typeParameters))
            ? t2
            : t1;
        testUpper(t1, t2, expected, typeParameters: typeParameters);
      }
    }

    // UP(T1, T2) where NULL(T1) =
    //   T2 if T2 is nullable
    //   T2? otherwise
    for (String t1 in nullPredicateEnumeration.keys) {
      testUpper(t1, "A*", "A?", typeParameters: nullPredicateEnumeration[t1]);
      testUpper(t1, "A?", "A?", typeParameters: nullPredicateEnumeration[t1]);
      testUpper(t1, "A", "A?", typeParameters: nullPredicateEnumeration[t1]);
    }

    // UP(T1, T2) where NULL(T2) =
    //   T1 if T1 is nullable
    //   T1? otherwise
    for (String t2 in nullPredicateEnumeration.keys) {
      testUpper("A*", t2, "A?", typeParameters: nullPredicateEnumeration[t2]);
      testUpper("A?", t2, "A?", typeParameters: nullPredicateEnumeration[t2]);
      testUpper("A", t2, "A?", typeParameters: nullPredicateEnumeration[t2]);
    }
  }

  void test_upper_bound_typeParameter() {
    _initialize("");

    // TODO(dmitryas): Test for various nullabilities.
    testUpper("T", "T", "T", typeParameters: "T extends Object");
    testUpper("T", "List<Never>", "List<Object>",
        typeParameters: "T extends List<T>");
    testUpper("List<Never>", "T", "List<Object>",
        typeParameters: "T extends List<T>");
    testUpper("T", "U", "List<Object>",
        typeParameters: "T extends List<T>, U extends List<Never>");
    testUpper("U", "T", "List<Object>",
        typeParameters: "T extends List<T>, U extends List<Never>");
  }

  void test_upper_bound_unknown() {
    _initialize("class A;");

    testLower("A*", "unknown", "A*");
    testLower("A?", "unknown", "A?");
    testLower("A", "unknown", "A");

    testLower("unknown", "A*", "A*");
    testLower("unknown", "A?", "A?");
    testLower("unknown", "A", "A");
  }

  void test_solveTypeConstraint() {
    const String testSdk = """
      class A<X>;
      class B<Y> extends A<Y>;
    """;
    _initialize(testSdk);

    // TODO(dmitryas): Test for various nullabilities.

    // Solve(? <: T <: ?) => ?
    expect(env.solveTypeConstraint(_makeConstraint(), bottomType),
        new UnknownType());

    // Solve(? <: T <: ?, grounded) => dynamic
    expect(
        env.solveTypeConstraint(_makeConstraint(), bottomType, grounded: true),
        new DynamicType());

    // Solve(A <: T <: ?) => A
    expect(
        env.solveTypeConstraint(
            _makeConstraint(lower: toType("A<dynamic>*")), bottomType),
        toType("A<dynamic>*"));

    // Solve(A <: T <: ?, grounded) => A
    expect(
        env.solveTypeConstraint(
            _makeConstraint(lower: toType("A<dynamic>*")), bottomType,
            grounded: true),
        toType("A<dynamic>*"));

    // Solve(A<?>* <: T <: ?) => A<?>*
    expect(
        env.solveTypeConstraint(
            _makeConstraint(lower: toType("A<unknown>*")), bottomType),
        toType("A<unknown>*"));

    // Solve(A<?>* <: T <: ?, grounded) => A<Never>*
    expect(
        env.solveTypeConstraint(
            _makeConstraint(lower: toType("A<unknown>*")), bottomType,
            grounded: true),
        toType("A<Never>*"));

    // Solve(? <: T <: A*) => A*
    expect(
        env.solveTypeConstraint(
            _makeConstraint(upper: toType("A<dynamic>*")), bottomType),
        toType("A<dynamic>*"));

    // Solve(? <: T <: A*, grounded) => A*
    expect(
        env.solveTypeConstraint(
            _makeConstraint(upper: toType("A<dynamic>*")), bottomType,
            grounded: true),
        toType("A<dynamic>*"));

    // Solve(? <: T <: A<?>*) => A<?>*
    expect(
        env.solveTypeConstraint(
            _makeConstraint(upper: toType("A<unknown>*")), bottomType),
        toType("A<unknown>*"));

    // Solve(? <: T <: A<?>*, grounded) => A<dynamic>*
    expect(
        env.solveTypeConstraint(
            _makeConstraint(upper: toType("A<unknown>*")), bottomType,
            grounded: true),
        toType("A<dynamic>*"));

    // Solve(B* <: T <: A*) => B*
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: toType("B<dynamic>*"), upper: toType("A<dynamic>*")),
            bottomType),
        toType("B<dynamic>*"));

    // Solve(B* <: T <: A*, grounded) => B*
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: toType("B<dynamic>*"), upper: toType("A<dynamic>*")),
            bottomType,
            grounded: true),
        toType("B<dynamic>*"));

    // Solve(B<?>* <: T <: A*) => A*
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: toType("B<unknown>*"), upper: toType("A<dynamic>*")),
            bottomType),
        toType("A<dynamic>*"));

    // Solve(B<?>* <: T <: A*, grounded) => A*
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: toType("B<unknown>*"), upper: toType("A<dynamic>*")),
            bottomType,
            grounded: true),
        toType("A<dynamic>*"));

    // Solve(B* <: T <: A<?>*) => B*
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: toType("B<dynamic>*"), upper: toType("A<unknown>*")),
            bottomType),
        toType("B<dynamic>*"));

    // Solve(B* <: T <: A<?>*, grounded) => B*
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: toType("B<dynamic>*"), upper: toType("A<unknown>*")),
            bottomType,
            grounded: true),
        toType("B<dynamic>*"));

    // Solve(B<?>* <: T <: A<?>*) => B<?>*
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: toType("B<unknown>*"), upper: toType("A<unknown>*")),
            bottomType),
        toType("B<unknown>*"));

    // Solve(B<?>* <: T <: A<?>*, grounded) => B<Never>*
    expect(
        env.solveTypeConstraint(
            _makeConstraint(
                lower: toType("B<unknown>*"), upper: toType("A<unknown>*")),
            bottomType,
            grounded: true),
        toType("B<Never>*"));
  }

  void test_typeConstraint_default() {
    TypeConstraint typeConstraint = new TypeConstraint();
    expect(typeConstraint.lower, new UnknownType());
    expect(typeConstraint.upper, new UnknownType());
  }

  void test_typeSatisfiesConstraint() {
    const String testSdk = """
      class A;
      class B extends A;
      class C extends B;
      class D extends C;
      class E extends D;
    """;
    _initialize(testSdk);

    // TODO(dmitryas): Test for various nullabilities.
    TypeConstraint typeConstraint =
        _makeConstraint(upper: toType("B*"), lower: toType("D*"));

    expect(env.typeSatisfiesConstraint(toType("A*"), typeConstraint), isFalse);
    expect(env.typeSatisfiesConstraint(toType("B*"), typeConstraint), isTrue);
    expect(env.typeSatisfiesConstraint(toType("C*"), typeConstraint), isTrue);
    expect(env.typeSatisfiesConstraint(toType("D*"), typeConstraint), isTrue);
    expect(env.typeSatisfiesConstraint(toType("E*"), typeConstraint), isFalse);
  }

  void test_unknown_at_bottom() {
    _initialize("class A;");

    // TODO(dmitryas): Test for various nullabilities.
    expect(
        env.isSubtypeOf(new UnknownType(), toType("A*"),
            SubtypeCheckMode.ignoringNullabilities),
        isTrue);
  }

  void test_unknown_at_top() {
    const String testSdk = """
      class A;
      class Pair<X, Y>;
    """;
    _initialize(testSdk);

    expect(
        env.isSubtypeOf(toType("A*"), new UnknownType(),
            SubtypeCheckMode.ignoringNullabilities),
        isTrue);
    expect(
        env.isSubtypeOf(
            toType("Pair<A*, Null>*"),
            toType("Pair<unknown, unknown>*"),
            SubtypeCheckMode.withNullabilities),
        isTrue);
  }

  DartType _list(DartType elementType) {
    return new InterfaceType(listClass, Nullability.nonNullable, [elementType]);
  }

  TypeConstraint _makeConstraint({DartType lower, DartType upper}) {
    lower ??= new UnknownType();
    upper ??= new UnknownType();
    return new TypeConstraint()
      ..lower = lower
      ..upper = upper;
  }

  void _initialize(String testSdk) {
    Uri uri = Uri.parse("dart:core");
    typeParserEnvironment = new TypeSchemaTypeParserEnvironment(uri);
    Library library =
        parseLibrary(uri, mockSdk + testSdk, environment: typeParserEnvironment)
          ..isNonNullableByDefault = true;
    component = new Component(libraries: <Library>[library]);
    coreTypes = new CoreTypes(component);
    env = new TypeSchemaEnvironment(
        coreTypes, new ClassHierarchy(component, coreTypes));
  }
}

class TypeSchemaTypeParserEnvironment extends TypeParserEnvironment {
  TypeSchemaTypeParserEnvironment(Uri uri) : super(uri, uri);

  DartType getPredefinedNamedType(String name) {
    if (name == "unknown") {
      // Don't return a const object to ensure we test implementations that use
      // identical.
      return new UnknownType();
    }
    return null;
  }
}

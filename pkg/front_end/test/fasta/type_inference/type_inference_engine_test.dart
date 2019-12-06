// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:kernel/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IncludesTypeParametersCovariantlyTest);
  });
}

@reflectiveTest
class IncludesTypeParametersCovariantlyTest {
  final TypeParameter T = new TypeParameter('T');
  final TypeParameter U = new TypeParameter('U');
  final TypeParameter V = new TypeParameter('V');

  bool check(DartType type, List<TypeParameter> typeParameters) {
    return type.accept(new IncludesTypeParametersNonCovariantly(typeParameters,
        initialVariance: Variance.contravariant));
  }

  bool checkContravariant(DartType type, List<TypeParameter> typeParameters) {
    return check(new FunctionType([type], const VoidType(), Nullability.legacy),
        typeParameters);
  }

  NamedType named(String name, DartType type) => new NamedType(name, type);

  void test_function_type() {
    expect(
        check(
            new FunctionType(
                [tpt(T), tpt(U)], const VoidType(), Nullability.legacy),
            [T]),
        isFalse);
    expect(
        check(
            new FunctionType(
                [tpt(T), tpt(U)], const VoidType(), Nullability.legacy),
            [U]),
        isFalse);
    expect(
        check(
            new FunctionType(
                [tpt(T), tpt(U)], const VoidType(), Nullability.legacy),
            []),
        isFalse);
    expect(
        check(
            new FunctionType([], const VoidType(), Nullability.legacy,
                namedParameters: [named('a', tpt(T)), named('b', tpt(U))]),
            [T]),
        isFalse);
    expect(
        check(
            new FunctionType([], const VoidType(), Nullability.legacy,
                namedParameters: [named('a', tpt(T)), named('b', tpt(U))]),
            [U]),
        isFalse);
    expect(
        check(
            new FunctionType([], const VoidType(), Nullability.legacy,
                namedParameters: [named('a', tpt(T)), named('b', tpt(U))]),
            []),
        isFalse);
    expect(
        check(new FunctionType([], tpt(T), Nullability.legacy), [T]), isTrue);
    expect(
        check(new FunctionType([], tpt(T), Nullability.legacy), [U]), isFalse);
    expect(
        checkContravariant(
            new FunctionType(
                [tpt(T), tpt(U)], const VoidType(), Nullability.legacy),
            [T]),
        isTrue);
    expect(
        checkContravariant(
            new FunctionType(
                [tpt(T), tpt(U)], const VoidType(), Nullability.legacy),
            [U]),
        isTrue);
    expect(
        checkContravariant(
            new FunctionType(
                [tpt(T), tpt(U)], const VoidType(), Nullability.legacy),
            []),
        isFalse);
    expect(
        checkContravariant(
            new FunctionType([], const VoidType(), Nullability.legacy,
                namedParameters: [named('a', tpt(T)), named('b', tpt(U))]),
            [T]),
        isTrue);
    expect(
        checkContravariant(
            new FunctionType([], const VoidType(), Nullability.legacy,
                namedParameters: [named('a', tpt(T)), named('b', tpt(U))]),
            [U]),
        isTrue);
    expect(
        checkContravariant(
            new FunctionType([], const VoidType(), Nullability.legacy,
                namedParameters: [named('a', tpt(T)), named('b', tpt(U))]),
            []),
        isFalse);
    expect(
        checkContravariant(
            new FunctionType([], tpt(T), Nullability.legacy), [T]),
        isFalse);
    expect(
        checkContravariant(
            new FunctionType([], tpt(T), Nullability.legacy), [U]),
        isFalse);
  }

  void test_interface_type() {
    Class cls = new Class(name: 'C', typeParameters: [T, U]);
    expect(
        check(
            new InterfaceType(cls, Nullability.legacy, [tpt(T), tpt(U)]), [T]),
        isTrue);
    expect(
        check(
            new InterfaceType(cls, Nullability.legacy, [tpt(T), tpt(U)]), [U]),
        isTrue);
    expect(
        check(new InterfaceType(cls, Nullability.legacy, [tpt(T), tpt(U)]), []),
        isFalse);
    expect(
        checkContravariant(
            new InterfaceType(cls, Nullability.legacy, [tpt(T), tpt(U)]), [T]),
        isFalse);
    expect(
        checkContravariant(
            new InterfaceType(cls, Nullability.legacy, [tpt(T), tpt(U)]), [U]),
        isFalse);
    expect(
        checkContravariant(
            new InterfaceType(cls, Nullability.legacy, [tpt(T), tpt(U)]), []),
        isFalse);
  }

  void test_other_type() {
    expect(check(new DynamicType(), [T, U]), isFalse);
    expect(checkContravariant(new DynamicType(), [T, U]), isFalse);
  }

  void test_type_parameter() {
    expect(check(tpt(T), [T, U]), isTrue);
    expect(check(tpt(U), [T, U]), isTrue);
    expect(check(tpt(V), [T, U]), isFalse);
    expect(checkContravariant(tpt(T), [T, U]), isFalse);
    expect(checkContravariant(tpt(U), [T, U]), isFalse);
    expect(checkContravariant(tpt(V), [T, U]), isFalse);

    // Type parameters with explicit variance do not need contravariant checks
    // if the variance position is greater or equal to the variance of the
    // parameter on the [Variance] lattice.
    expect(check(tpt(T, variance: Variance.covariant), [T, U]), isTrue);
    expect(check(tpt(T, variance: Variance.contravariant), [T, U]), isFalse);
    expect(check(tpt(T, variance: Variance.invariant), [T, U]), isFalse);
    expect(check(tpt(V, variance: Variance.covariant), [T, U]), isFalse);
    expect(check(tpt(V, variance: Variance.contravariant), [T, U]), isFalse);
    expect(check(tpt(V, variance: Variance.invariant), [T, U]), isFalse);
    expect(checkContravariant(tpt(T, variance: Variance.covariant), [T, U]),
        isFalse);
    expect(checkContravariant(tpt(T, variance: Variance.contravariant), [T, U]),
        isTrue);
    expect(checkContravariant(tpt(T, variance: Variance.invariant), [T, U]),
        isFalse);
    expect(checkContravariant(tpt(V, variance: Variance.covariant), [T, U]),
        isFalse);
    expect(checkContravariant(tpt(V, variance: Variance.contravariant), [T, U]),
        isFalse);
    expect(checkContravariant(tpt(V, variance: Variance.invariant), [T, U]),
        isFalse);
  }

  void test_typedef_type() {
    // typedef U F<T, U>(T x);
    var typedefNode = new Typedef(
        'F', new FunctionType([tpt(T)], tpt(U), Nullability.legacy),
        typeParameters: [T, U]);
    expect(
        check(
            new TypedefType(typedefNode, Nullability.legacy,
                [const DynamicType(), const DynamicType()]),
            [V]),
        isFalse);
    expect(
        check(
            new TypedefType(
                typedefNode, Nullability.legacy, [tpt(V), const DynamicType()]),
            [V]),
        isFalse);
    expect(
        check(
            new TypedefType(
                typedefNode, Nullability.legacy, [const DynamicType(), tpt(V)]),
            [V]),
        isTrue);
    expect(
        checkContravariant(
            new TypedefType(typedefNode, Nullability.legacy,
                [const DynamicType(), const DynamicType()]),
            [V]),
        isFalse);
    expect(
        checkContravariant(
            new TypedefType(
                typedefNode, Nullability.legacy, [tpt(V), const DynamicType()]),
            [V]),
        isTrue);
    expect(
        checkContravariant(
            new TypedefType(
                typedefNode, Nullability.legacy, [const DynamicType(), tpt(V)]),
            [V]),
        isFalse);
  }

  TypeParameterType tpt(TypeParameter param, {int variance = null}) {
    return new TypeParameterType(param, Nullability.legacy)
      ..parameter.variance = variance;
  }
}

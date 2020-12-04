// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:front_end/src/fasta/kernel/kernel_ast_api.dart';
import 'package:front_end/src/fasta/kernel/member_covariance.dart';

main() {
  void checkEquals(Covariance a, Covariance b) {
    Expect.equals(a, b);
    Expect.equals(a.hashCode, b.hashCode);
  }

  checkEquals(const Covariance.empty(), new Covariance.empty());

  Expect.isTrue(const Covariance.empty().isEmpty);
  Expect.isTrue(new Covariance.empty().isEmpty);
  Expect.isTrue(new Covariance.internal(null, null, null).isEmpty);

  checkEquals(
      const Covariance.empty(), new Covariance.internal(null, null, null));

  Expect.throws(() => new Covariance.internal([], null, null));
  Expect.throws(() => new Covariance.internal([0], null, null));

  checkEquals(
      new Covariance.internal([Covariance.GenericCovariantImpl], null, null),
      new Covariance.internal(
          [Covariance.GenericCovariantImpl, 0], null, null));

  checkEquals(new Covariance.internal([Covariance.Covariant], null, null),
      new Covariance.internal([Covariance.Covariant, 0], null, null));

  checkEquals(new Covariance.internal([0, Covariance.Covariant], null, null),
      new Covariance.internal([0, Covariance.Covariant, 0], null, null));

  Expect.throws(() => new Covariance.internal(null, {}, null));
  Expect.throws(() => new Covariance.internal(null, {'a': 0}, null));

  checkEquals(new Covariance.internal(null, {'a': Covariance.Covariant}, null),
      new Covariance.internal(null, {'a': Covariance.Covariant}, null));

  Expect.throws(() => new Covariance.internal(null, null, []));

  Expect.throws(() => new Covariance.internal(null, null, [false]));

  checkEquals(new Covariance.internal(null, null, [true]),
      new Covariance.internal(null, null, [true, false]));

  Covariance covariance = new Covariance.internal([
    Covariance.Covariant,
    Covariance.GenericCovariantImpl,
    0,
    Covariance.Covariant | Covariance.GenericCovariantImpl
  ], {
    'a': Covariance.Covariant,
    'b': Covariance.GenericCovariantImpl,
    'd': Covariance.Covariant | Covariance.GenericCovariantImpl
  }, [
    false,
    true
  ]);

  Expect.equals(Covariance.Covariant, covariance.getPositionalVariance(0));
  Expect.equals(
      Covariance.GenericCovariantImpl, covariance.getPositionalVariance(1));
  Expect.equals(0, covariance.getPositionalVariance(2));
  Expect.equals(Covariance.Covariant | Covariance.GenericCovariantImpl,
      covariance.getPositionalVariance(3));
  Expect.equals(0, covariance.getPositionalVariance(4));

  Expect.equals(Covariance.Covariant, covariance.getNamedVariance('a'));
  Expect.equals(
      Covariance.GenericCovariantImpl, covariance.getNamedVariance('b'));
  Expect.equals(0, covariance.getNamedVariance('c'));
  Expect.equals(Covariance.Covariant | Covariance.GenericCovariantImpl,
      covariance.getNamedVariance('d'));
  Expect.equals(0, covariance.getNamedVariance('e'));

  Expect.isFalse(covariance.isTypeParameterGenericCovariantImpl(0));
  Expect.isTrue(covariance.isTypeParameterGenericCovariantImpl(1));
  Expect.isFalse(covariance.isTypeParameterGenericCovariantImpl(0));

  Expect.stringEquals(
      'Covariance('
      '0:Covariant,1:GenericCovariantImpl,3:GenericCovariantImpl+Covariant,'
      'a:Covariant,b:GenericCovariantImpl,d:GenericCovariantImpl+Covariant,'
      'types:1)',
      covariance.toString());

  Procedure noParameterProcedure =
      new Procedure(null, ProcedureKind.Method, new FunctionNode(null));
  Covariance noParameterProcedureCovariance =
      new Covariance.fromMember(noParameterProcedure, forSetter: false);
  Expect.isTrue(noParameterProcedureCovariance.isEmpty);

  covariance.applyCovariance(noParameterProcedure);
  noParameterProcedureCovariance =
      new Covariance.fromMember(noParameterProcedure, forSetter: false);
  Expect.isTrue(noParameterProcedureCovariance.isEmpty);

  Procedure oneParameterProcedure = new Procedure(
      null,
      ProcedureKind.Method,
      new FunctionNode(null,
          positionalParameters: [new VariableDeclaration(null)]));
  Covariance oneParameterProcedureCovariance =
      new Covariance.fromMember(oneParameterProcedure, forSetter: false);
  Expect.isTrue(oneParameterProcedureCovariance.isEmpty);

  covariance.applyCovariance(oneParameterProcedure);
  oneParameterProcedureCovariance =
      new Covariance.fromMember(oneParameterProcedure, forSetter: false);
  Expect.isFalse(oneParameterProcedureCovariance.isEmpty);
  Expect.equals(new Covariance.internal([Covariance.Covariant], null, null),
      oneParameterProcedureCovariance);

  Procedure positionalParametersProcedure = new Procedure(
      null,
      ProcedureKind.Method,
      new FunctionNode(null, positionalParameters: [
        new VariableDeclaration(null),
        new VariableDeclaration(null),
        new VariableDeclaration(null),
        new VariableDeclaration(null),
        new VariableDeclaration(null)
      ]));
  Covariance positionalParametersProcedureCovariance =
      new Covariance.fromMember(positionalParametersProcedure,
          forSetter: false);
  Expect.isTrue(positionalParametersProcedureCovariance.isEmpty);

  covariance.applyCovariance(positionalParametersProcedure);
  positionalParametersProcedureCovariance = new Covariance.fromMember(
      positionalParametersProcedure,
      forSetter: false);
  Expect.isFalse(positionalParametersProcedureCovariance.isEmpty);
  checkEquals(
      new Covariance.internal([
        Covariance.Covariant,
        Covariance.GenericCovariantImpl,
        0,
        Covariance.Covariant | Covariance.GenericCovariantImpl
      ], null, null),
      positionalParametersProcedureCovariance);

  Procedure namedParametersProcedure = new Procedure(
      null,
      ProcedureKind.Method,
      new FunctionNode(null, namedParameters: [
        new VariableDeclaration('a'),
        new VariableDeclaration('b'),
        new VariableDeclaration('c'),
        new VariableDeclaration('d'),
        new VariableDeclaration('e')
      ]));
  Covariance namedParametersProcedureCovariance =
      new Covariance.fromMember(namedParametersProcedure, forSetter: false);
  Expect.isTrue(namedParametersProcedureCovariance.isEmpty);

  covariance.applyCovariance(namedParametersProcedure);
  namedParametersProcedureCovariance =
      new Covariance.fromMember(namedParametersProcedure, forSetter: false);
  Expect.isFalse(namedParametersProcedureCovariance.isEmpty);
  checkEquals(
      new Covariance.internal(
          null,
          {
            'a': Covariance.Covariant,
            'b': Covariance.GenericCovariantImpl,
            'd': Covariance.Covariant | Covariance.GenericCovariantImpl
          },
          null),
      namedParametersProcedureCovariance);

  Procedure typeParametersProcedure = new Procedure(
      null,
      ProcedureKind.Method,
      new FunctionNode(null, typeParameters: [
        new TypeParameter(null),
        new TypeParameter(null),
        new TypeParameter(null),
      ]));
  Covariance typeParametersProcedureCovariance =
      new Covariance.fromMember(typeParametersProcedure, forSetter: false);
  Expect.isTrue(typeParametersProcedureCovariance.isEmpty);

  covariance.applyCovariance(typeParametersProcedure);
  typeParametersProcedureCovariance =
      new Covariance.fromMember(typeParametersProcedure, forSetter: false);
  Expect.isFalse(typeParametersProcedureCovariance.isEmpty);
  checkEquals(new Covariance.internal(null, null, [false, true]),
      typeParametersProcedureCovariance);

  Covariance merged =
      const Covariance.empty().merge(positionalParametersProcedureCovariance);
  checkEquals(positionalParametersProcedureCovariance, merged);
  merged = merged.merge(namedParametersProcedureCovariance);
  checkEquals(
      new Covariance.internal([
        Covariance.Covariant,
        Covariance.GenericCovariantImpl,
        0,
        Covariance.GenericCovariantImpl | Covariance.Covariant
      ], {
        'a': Covariance.Covariant,
        'b': Covariance.GenericCovariantImpl,
        'd': Covariance.Covariant | Covariance.GenericCovariantImpl
      }, null),
      merged);
  merged = merged.merge(typeParametersProcedureCovariance);
  checkEquals(covariance, merged);
}

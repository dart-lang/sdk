// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

void testEquals(Constant a, Constant b) {
  if (a != b) {
    throw 'Expected $a and $b to be equal.';
  }
  if (a.hashCode != b.hashCode) {
    throw 'Expected $a and $b hash codes to be equal.';
  }
}

void testNotEquals(Constant a, Constant b) {
  if (a == b) {
    throw 'Expected $a and $b to be not equal.';
  }
}

void main() {
  Uri uri = Uri.parse('test:uri');
  Procedure procedure1 = new Procedure(
      new Name('foo'), ProcedureKind.Method, new FunctionNode(null),
      fileUri: uri, isStatic: true);
  Procedure procedure2 = new Procedure(
      new Name('foo'), ProcedureKind.Method, new FunctionNode(null),
      fileUri: uri, isStatic: true);
  Procedure procedure3 = new Procedure(
      new Name('foo'),
      ProcedureKind.Method,
      new FunctionNode(null, typeParameters: [
        new TypeParameter('X', const DynamicType(), const DynamicType())
      ]),
      fileUri: uri,
      isStatic: true);

  Class cls = new Class(name: 'Class', fileUri: uri);
  Procedure factory = new Procedure(
      new Name('foo'), ProcedureKind.Factory, new FunctionNode(null),
      fileUri: uri, isStatic: true);
  cls.addProcedure(factory);
  Constructor constructor = new Constructor(new FunctionNode(null),
      name: new Name('foo'), fileUri: uri);
  cls.addConstructor(constructor);
  Procedure redirectingFactory = new Procedure(
      new Name('foo'),
      ProcedureKind.Factory,
      new FunctionNode(null)
        ..redirectingFactoryTarget =
            new RedirectingFactoryTarget(constructor, []),
      fileUri: uri,
      isStatic: true);
  cls.addProcedure(redirectingFactory);

  TearOffConstant tearOffConstant1a = new StaticTearOffConstant(procedure1);
  TearOffConstant tearOffConstant1b = new StaticTearOffConstant(procedure1);
  TearOffConstant tearOffConstant2 = new StaticTearOffConstant(procedure2);
  TearOffConstant tearOffConstant3 = new StaticTearOffConstant(procedure3);
  TearOffConstant tearOffConstant4 =
      new ConstructorTearOffConstant(constructor);
  TearOffConstant tearOffConstant5 = new ConstructorTearOffConstant(factory);
  TearOffConstant tearOffConstant6 =
      new RedirectingFactoryTearOffConstant(redirectingFactory);

  // foo() {}
  // const a = foo;
  // const b = foo;
  // a == b
  testEquals(tearOffConstant1a, tearOffConstant1b);

  // foo() {} // from lib1;
  // foo() {} // from lib2;
  // lib1.foo != lib2.foo
  testNotEquals(tearOffConstant1a, tearOffConstant2);

  // foo() {}
  // typedef F = foo;
  // typedef G = foo;
  // F == G
  testEquals(new TypedefTearOffConstant([], tearOffConstant1a, []),
      new TypedefTearOffConstant([], tearOffConstant1b, []));

  // foo() {} // from lib1;
  // foo() {} // from lib2;
  // typedef F = lib1.foo;
  // typedef G = lib2.foo;
  // F != G
  testNotEquals(new TypedefTearOffConstant([], tearOffConstant1a, []),
      new TypedefTearOffConstant([], tearOffConstant2, []));

  // foo() {}
  // typedef F<T> = foo;
  // typedef G<S> = foo;
  // F == G
  testEquals(
      new TypedefTearOffConstant(
          [
            new StructuralParameter(
                'T', const DynamicType(), const DynamicType())
          ],
          tearOffConstant1a,
          []),
      new TypedefTearOffConstant(
          [
            new StructuralParameter(
                'S', const DynamicType(), const DynamicType())
          ],
          tearOffConstant1b,
          []));

  // foo() {}
  // typedef F<T1, T2> = foo;
  // typedef G<S> = foo;
  // F != G
  testNotEquals(
      new TypedefTearOffConstant(
          [
            new StructuralParameter(
                'T1', const DynamicType(), const DynamicType()),
            new StructuralParameter(
                'T2', const DynamicType(), const DynamicType())
          ],
          tearOffConstant1a,
          []),
      new TypedefTearOffConstant(
          [
            new StructuralParameter(
                'S', const DynamicType(), const DynamicType())
          ],
          tearOffConstant1b,
          []));

  // foo() {}
  // typedef F<T extends void> = foo;
  // typedef G<S> = foo;
  // F != G
  testNotEquals(
      new TypedefTearOffConstant(
          [new StructuralParameter('T', const VoidType(), const DynamicType())],
          tearOffConstant1a,
          []),
      new TypedefTearOffConstant(
          [
            new StructuralParameter(
                'S', const DynamicType(), const DynamicType())
          ],
          tearOffConstant1b,
          []));
  {
    StructuralParameter structuralParameter1 =
        new StructuralParameter('T', const DynamicType(), const DynamicType());
    StructuralParameter structuralParameter2 =
        new StructuralParameter('S', const DynamicType(), const DynamicType());

    // foo<X>() {}
    // typedef F<T> = foo<T>;
    // typedef G<S> = foo<S>;
    // F == G
    testEquals(
        new TypedefTearOffConstant(
            [structuralParameter1],
            tearOffConstant3,
            [
              new StructuralParameterType(
                  structuralParameter1, Nullability.nullable)
            ]),
        new TypedefTearOffConstant(
            [structuralParameter2],
            tearOffConstant3,
            [
              new StructuralParameterType(
                  structuralParameter2, Nullability.nullable)
            ]));
  }
  {
    StructuralParameter structuralParameter1a =
        new StructuralParameter('T1', const DynamicType(), const DynamicType());
    StructuralParameter structuralParameter1b =
        new StructuralParameter('T2', const DynamicType(), const DynamicType());
    StructuralParameter structuralParameter2a =
        new StructuralParameter('S1', const DynamicType(), const DynamicType());
    StructuralParameter structuralParameter2b =
        new StructuralParameter('S2', const DynamicType(), const DynamicType());

    // foo<X>() {}
    // typedef F<T1, T2> = foo<T1>;
    // typedef G<S1, S2> = foo<S1>;
    // F == G
    testEquals(
        new TypedefTearOffConstant(
            [structuralParameter1a, structuralParameter1b],
            tearOffConstant3,
            [
              new StructuralParameterType(
                  structuralParameter1a, Nullability.nullable)
            ]),
        new TypedefTearOffConstant(
            [structuralParameter2a, structuralParameter2b],
            tearOffConstant3,
            [
              new StructuralParameterType(
                  structuralParameter2a, Nullability.nullable)
            ]));

    // foo<X>() {}
    // typedef F<T1, T2> = foo<T1>;
    // typedef G<S1, S2> = foo<S2>;
    // F != G
    testNotEquals(
        new TypedefTearOffConstant(
            [structuralParameter1a, structuralParameter1b],
            tearOffConstant3,
            [
              new StructuralParameterType(
                  structuralParameter1a, Nullability.nullable)
            ]),
        new TypedefTearOffConstant(
            [structuralParameter2a, structuralParameter2b],
            tearOffConstant3,
            [
              new StructuralParameterType(
                  structuralParameter2b, Nullability.nullable)
            ]));

    testEquals(tearOffConstant4, tearOffConstant4);
    testEquals(tearOffConstant5, tearOffConstant5);
    testEquals(tearOffConstant6, tearOffConstant6);

    testNotEquals(tearOffConstant4, tearOffConstant5);
    testNotEquals(tearOffConstant4, tearOffConstant6);
    testNotEquals(tearOffConstant5, tearOffConstant6);
  }
}

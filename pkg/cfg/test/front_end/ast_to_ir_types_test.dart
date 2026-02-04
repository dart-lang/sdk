// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/front_end/ast_to_ir_types.dart';
import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:test/test.dart';
import '../test_helpers.dart';

void main() {
  final component = readVmPlatformKernelFile();
  final coreTypes = CoreTypes(component);
  final classHierarchy = ClassHierarchy(component, coreTypes);
  final astToIrTypes = AstToIrTypes(coreTypes, classHierarchy);

  test('int', () {
    expect(
      astToIrTypes.translate(coreTypes.intNonNullableRawType),
      equals(IntType(coreTypes.intNonNullableRawType)),
    );
    expect(
      astToIrTypes.translate(coreTypes.intNullableRawType),
      equals(StaticType(coreTypes.intNullableRawType)),
    );

    final smiClass = coreTypes.index.getClass('dart:core', '_Smi');
    final smiType = ast.InterfaceType(smiClass, ast.Nullability.nonNullable);
    expect(astToIrTypes.translate(smiType), equals(IntType(smiType)));

    final mintClass = coreTypes.index.getClass('dart:core', '_Mint');
    final mintType = ast.InterfaceType(mintClass, ast.Nullability.nonNullable);
    expect(astToIrTypes.translate(mintType), equals(IntType(mintType)));
  });

  test('double', () {
    expect(
      astToIrTypes.translate(coreTypes.doubleNonNullableRawType),
      equals(DoubleType(coreTypes.doubleNonNullableRawType)),
    );
    expect(
      astToIrTypes.translate(coreTypes.doubleNullableRawType),
      equals(StaticType(coreTypes.doubleNullableRawType)),
    );
  });

  test('bool', () {
    expect(
      astToIrTypes.translate(coreTypes.boolNonNullableRawType),
      equals(BoolType(coreTypes.boolNonNullableRawType)),
    );
    expect(
      astToIrTypes.translate(coreTypes.boolNullableRawType),
      equals(StaticType(coreTypes.boolNullableRawType)),
    );
  });

  test('string', () {
    expect(
      astToIrTypes.translate(coreTypes.stringNonNullableRawType),
      equals(StringType(coreTypes.stringNonNullableRawType)),
    );
    expect(
      astToIrTypes.translate(coreTypes.stringNullableRawType),
      equals(StaticType(coreTypes.stringNullableRawType)),
    );

    final oneByteStringClass = coreTypes.index.getClass(
      'dart:core',
      '_OneByteString',
    );
    final oneByteStringType = ast.InterfaceType(
      oneByteStringClass,
      ast.Nullability.nonNullable,
    );
    expect(
      astToIrTypes.translate(oneByteStringType),
      equals(StringType(oneByteStringType)),
    );

    final twoByteStringClass = coreTypes.index.getClass(
      'dart:core',
      '_TwoByteString',
    );
    final twoByteStringType = ast.InterfaceType(
      twoByteStringClass,
      ast.Nullability.nonNullable,
    );
    expect(
      astToIrTypes.translate(twoByteStringType),
      equals(StringType(twoByteStringType)),
    );
  });

  test('object', () {
    expect(
      astToIrTypes.translate(coreTypes.objectNonNullableRawType),
      equals(ObjectType(coreTypes.objectNonNullableRawType)),
    );
  });

  test('null', () {
    expect(
      astToIrTypes.translate(const ast.NullType()),
      equals(const NullType()),
    );
  });

  test('never', () {
    expect(
      astToIrTypes.translate(const ast.NeverType.nonNullable()),
      equals(const NeverType()),
    );
    expect(
      astToIrTypes.translate(const ast.NeverType.nullable()),
      equals(const NullType()),
    );
  });

  test('top', () {
    expect(
      astToIrTypes.translate(const ast.DynamicType()),
      equals(TopType(const ast.DynamicType())),
    );
    expect(
      astToIrTypes.translate(const ast.VoidType()),
      equals(TopType(const ast.VoidType())),
    );
    expect(
      astToIrTypes.translate(coreTypes.objectNullableRawType),
      equals(TopType(coreTypes.objectNullableRawType)),
    );
  });

  test('futureOr', () {
    final futureOrOfDynamic = ast.FutureOrType(
      const ast.DynamicType(),
      ast.Nullability.nonNullable,
    );
    expect(
      astToIrTypes.translate(futureOrOfDynamic),
      equals(TopType(futureOrOfDynamic)),
    );

    final futureOrOfVoid = ast.FutureOrType(
      const ast.VoidType(),
      ast.Nullability.nullable,
    );
    expect(
      astToIrTypes.translate(futureOrOfVoid),
      equals(TopType(futureOrOfVoid)),
    );

    final futureOrOfObject = ast.FutureOrType(
      coreTypes.objectNonNullableRawType,
      ast.Nullability.nonNullable,
    );
    expect(
      astToIrTypes.translate(futureOrOfObject),
      equals(ObjectType(futureOrOfObject)),
    );

    final futureOrOfNullableObject1 = ast.FutureOrType(
      coreTypes.objectNullableRawType,
      ast.Nullability.nonNullable,
    );
    expect(
      astToIrTypes.translate(futureOrOfNullableObject1),
      equals(TopType(futureOrOfNullableObject1)),
    );

    final futureOrOfNullableObject2 = ast.FutureOrType(
      coreTypes.objectNonNullableRawType,
      ast.Nullability.nullable,
    );
    expect(
      astToIrTypes.translate(futureOrOfNullableObject2),
      equals(TopType(futureOrOfNullableObject2)),
    );
  });
}

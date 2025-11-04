// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/type_environment.dart';
import 'package:test/test.dart';
import '../test_helpers.dart';

void main() {
  final component = readVmPlatformKernelFile();
  final coreTypes = CoreTypes(component);
  final classHierarchy = ClassHierarchy(component, coreTypes);
  final typeEnvironment = TypeEnvironment(coreTypes, classHierarchy);
  final globalContext = GlobalContext(typeEnvironment: typeEnvironment);

  setUp(() {
    GlobalContext.setCurrentContext(globalContext);
  });

  tearDown(() {
    GlobalContext.setCurrentContext(null);
  });

  test('int', () {
    final intDartType = coreTypes.intNonNullableRawType;
    expect(IntType(), equals(IntType(intDartType)));
    expect(IntType(), equals(CType.fromStaticType(intDartType)));

    expect(IntType().kind, equals(TypeKind.intType));
    expect(IntType().dartType, equals(intDartType));
    expect(IntType().hashCode, equals(IntType(intDartType).hashCode));

    expect(IntType(intDartType).kind, equals(TypeKind.intType));
    expect(IntType(intDartType).dartType, equals(intDartType));

    final smiClass = coreTypes.index.getClass('dart:core', '_Smi');
    final smiDartType = ast.InterfaceType(
      smiClass,
      ast.Nullability.nonNullable,
    );
    expect(IntType(smiDartType), equals(CType.fromStaticType(smiDartType)));
    expect(IntType(smiDartType).kind, equals(TypeKind.intType));
    expect(IntType(smiDartType).dartType, equals(smiDartType));

    expect(IntType(smiDartType).isSubtypeOf(const IntType()), isTrue);
    expect(IntType().isSubtypeOf(IntType(smiDartType)), isFalse);
    expect(IntType().isSubtypeOf(DoubleType()), isFalse);
    expect(IntType().isSubtypeOf(BoolType()), isFalse);
    expect(IntType().isSubtypeOf(StringType()), isFalse);
    expect(IntType().isSubtypeOf(ObjectType()), isTrue);
    expect(IntType().isSubtypeOf(TopType()), isTrue);
    expect(IntType().isSubtypeOf(NullType()), isFalse);
    expect(IntType().isSubtypeOf(NeverType()), isFalse);
    expect(
      IntType().isSubtypeOf(StaticType(coreTypes.listNonNullableRawType)),
      isFalse,
    );
  });

  test('double', () {
    final doubleDartType = coreTypes.doubleNonNullableRawType;
    expect(DoubleType(), equals(DoubleType(doubleDartType)));
    expect(DoubleType(), equals(CType.fromStaticType(doubleDartType)));

    expect(DoubleType().kind, equals(TypeKind.doubleType));
    expect(DoubleType().dartType, equals(doubleDartType));
    expect(DoubleType().hashCode, equals(DoubleType(doubleDartType).hashCode));

    expect(DoubleType(doubleDartType).kind, equals(TypeKind.doubleType));
    expect(DoubleType(doubleDartType).dartType, equals(doubleDartType));

    expect(DoubleType().isSubtypeOf(IntType()), isFalse);
    expect(DoubleType().isSubtypeOf(DoubleType()), isTrue);
    expect(DoubleType().isSubtypeOf(BoolType()), isFalse);
    expect(DoubleType().isSubtypeOf(StringType()), isFalse);
    expect(DoubleType().isSubtypeOf(ObjectType()), isTrue);
    expect(DoubleType().isSubtypeOf(TopType()), isTrue);
    expect(DoubleType().isSubtypeOf(NullType()), isFalse);
    expect(DoubleType().isSubtypeOf(NeverType()), isFalse);
    expect(
      DoubleType().isSubtypeOf(StaticType(coreTypes.listNonNullableRawType)),
      isFalse,
    );
  });

  test('bool', () {
    final boolDartType = coreTypes.boolNonNullableRawType;
    expect(BoolType(), equals(BoolType(boolDartType)));
    expect(BoolType(), equals(CType.fromStaticType(boolDartType)));

    expect(BoolType().kind, equals(TypeKind.boolType));
    expect(BoolType().dartType, equals(boolDartType));
    expect(BoolType().hashCode, equals(BoolType(boolDartType).hashCode));

    expect(BoolType(boolDartType).kind, equals(TypeKind.boolType));
    expect(BoolType(boolDartType).dartType, equals(boolDartType));

    expect(BoolType().isSubtypeOf(IntType()), isFalse);
    expect(BoolType().isSubtypeOf(DoubleType()), isFalse);
    expect(BoolType().isSubtypeOf(BoolType()), isTrue);
    expect(BoolType().isSubtypeOf(StringType()), isFalse);
    expect(BoolType().isSubtypeOf(ObjectType()), isTrue);
    expect(BoolType().isSubtypeOf(TopType()), isTrue);
    expect(BoolType().isSubtypeOf(NullType()), isFalse);
    expect(BoolType().isSubtypeOf(NeverType()), isFalse);
    expect(
      BoolType().isSubtypeOf(StaticType(coreTypes.listNonNullableRawType)),
      isFalse,
    );
  });

  test('string', () {
    final stringDartType = coreTypes.stringNonNullableRawType;
    expect(StringType(), equals(StringType(stringDartType)));
    expect(StringType(), equals(CType.fromStaticType(stringDartType)));

    expect(StringType().kind, equals(TypeKind.stringType));
    expect(StringType().dartType, equals(stringDartType));
    expect(StringType().hashCode, equals(StringType(stringDartType).hashCode));

    expect(StringType(stringDartType).kind, equals(TypeKind.stringType));
    expect(StringType(stringDartType).dartType, equals(stringDartType));

    expect(StringType().isSubtypeOf(IntType()), isFalse);
    expect(StringType().isSubtypeOf(DoubleType()), isFalse);
    expect(StringType().isSubtypeOf(BoolType()), isFalse);
    expect(StringType().isSubtypeOf(StringType()), isTrue);
    expect(StringType().isSubtypeOf(ObjectType()), isTrue);
    expect(StringType().isSubtypeOf(TopType()), isTrue);
    expect(StringType().isSubtypeOf(NullType()), isFalse);
    expect(StringType().isSubtypeOf(NeverType()), isFalse);
    expect(
      StringType().isSubtypeOf(StaticType(coreTypes.listNonNullableRawType)),
      isFalse,
    );
    final comparableClass = coreTypes.index.getClass('dart:core', 'Comparable');
    final comparableType = ast.InterfaceType(
      comparableClass,
      ast.Nullability.nonNullable,
      [const ast.DynamicType()],
    );
    expect(StringType().isSubtypeOf(StaticType(comparableType)), isTrue);
  });

  test('object', () {
    final objectDartType = coreTypes.objectNonNullableRawType;
    expect(ObjectType(), equals(ObjectType(objectDartType)));
    expect(ObjectType(), equals(CType.fromStaticType(objectDartType)));

    expect(ObjectType().kind, equals(TypeKind.objectType));
    expect(ObjectType().dartType, equals(objectDartType));
    expect(ObjectType().hashCode, equals(ObjectType(objectDartType).hashCode));

    expect(ObjectType(objectDartType).kind, equals(TypeKind.objectType));
    expect(ObjectType(objectDartType).dartType, equals(objectDartType));

    expect(ObjectType().isSubtypeOf(IntType()), isFalse);
    expect(ObjectType().isSubtypeOf(DoubleType()), isFalse);
    expect(ObjectType().isSubtypeOf(BoolType()), isFalse);
    expect(ObjectType().isSubtypeOf(StringType()), isFalse);
    expect(ObjectType().isSubtypeOf(ObjectType()), isTrue);
    expect(ObjectType().isSubtypeOf(TopType()), isTrue);
    expect(ObjectType().isSubtypeOf(NullType()), isFalse);
    expect(ObjectType().isSubtypeOf(NeverType()), isFalse);
    expect(
      ObjectType().isSubtypeOf(StaticType(coreTypes.listNonNullableRawType)),
      isFalse,
    );
  });

  test('null', () {
    final nullDartType = const ast.NullType();
    expect(NullType(), equals(CType.fromStaticType(nullDartType)));
    expect(NullType(), equals(CType.fromStaticType(ast.NeverType.nullable())));

    expect(NullType().kind, equals(TypeKind.nullType));
    expect(NullType().dartType, equals(nullDartType));

    expect(NullType().isSubtypeOf(IntType()), isFalse);
    expect(NullType().isSubtypeOf(DoubleType()), isFalse);
    expect(NullType().isSubtypeOf(BoolType()), isFalse);
    expect(NullType().isSubtypeOf(StringType()), isFalse);
    expect(NullType().isSubtypeOf(ObjectType()), isFalse);
    expect(NullType().isSubtypeOf(TopType()), isTrue);
    expect(NullType().isSubtypeOf(NullType()), isTrue);
    expect(NullType().isSubtypeOf(NeverType()), isFalse);
    expect(
      NullType().isSubtypeOf(StaticType(coreTypes.listNonNullableRawType)),
      isFalse,
    );
    expect(
      NullType().isSubtypeOf(StaticType(coreTypes.listNullableRawType)),
      isTrue,
    );
  });

  test('never', () {
    final neverDartType = const ast.NeverType.nonNullable();
    expect(NeverType(), equals(CType.fromStaticType(neverDartType)));

    expect(NeverType().kind, equals(TypeKind.neverType));
    expect(NeverType().dartType, equals(neverDartType));

    expect(NeverType().isSubtypeOf(IntType()), isTrue);
    expect(NeverType().isSubtypeOf(DoubleType()), isTrue);
    expect(NeverType().isSubtypeOf(BoolType()), isTrue);
    expect(NeverType().isSubtypeOf(StringType()), isTrue);
    expect(NeverType().isSubtypeOf(ObjectType()), isTrue);
    expect(NeverType().isSubtypeOf(TopType()), isTrue);
    expect(NeverType().isSubtypeOf(NullType()), isTrue);
    expect(NeverType().isSubtypeOf(NeverType()), isTrue);
    expect(
      NeverType().isSubtypeOf(StaticType(coreTypes.listNonNullableRawType)),
      isTrue,
    );
  });

  test('top', () {
    final dynamicDartType = const ast.DynamicType();
    final voidDartType = const ast.VoidType();
    final nullableObjDartType = coreTypes.objectNullableRawType;
    expect(TopType(), equals(TopType(dynamicDartType)));
    expect(TopType(), equals(CType.fromStaticType(dynamicDartType)));

    expect(TopType().kind, equals(TypeKind.top));
    expect(TopType().dartType, equals(dynamicDartType));
    expect(TopType().hashCode, equals(TopType(dynamicDartType).hashCode));

    expect(TopType(voidDartType).kind, equals(TypeKind.top));
    expect(TopType(voidDartType).dartType, equals(voidDartType));

    expect(TopType(nullableObjDartType).kind, equals(TypeKind.top));
    expect(TopType(nullableObjDartType).dartType, equals(nullableObjDartType));

    expect(TopType().isSubtypeOf(IntType()), isFalse);
    expect(TopType().isSubtypeOf(DoubleType()), isFalse);
    expect(TopType().isSubtypeOf(BoolType()), isFalse);
    expect(TopType().isSubtypeOf(StringType()), isFalse);
    expect(TopType().isSubtypeOf(ObjectType()), isFalse);
    expect(TopType().isSubtypeOf(TopType()), isTrue);
    expect(TopType().isSubtypeOf(NullType()), isFalse);
    expect(TopType().isSubtypeOf(NeverType()), isFalse);
    expect(
      TopType().isSubtypeOf(StaticType(coreTypes.listNonNullableRawType)),
      isFalse,
    );
  });

  test('other', () {
    final listDartType = coreTypes.listNonNullableRawType;
    final listType = StaticType(listDartType);
    expect(listType, equals(CType.fromStaticType(listDartType)));

    expect(listType.kind, equals(TypeKind.otherDartType));
    expect(listType.dartType, equals(listDartType));

    expect(listType.isSubtypeOf(IntType()), isFalse);
    expect(listType.isSubtypeOf(DoubleType()), isFalse);
    expect(listType.isSubtypeOf(BoolType()), isFalse);
    expect(listType.isSubtypeOf(StringType()), isFalse);
    expect(listType.isSubtypeOf(ObjectType()), isTrue);
    expect(listType.isSubtypeOf(TopType()), isTrue);
    expect(listType.isSubtypeOf(NullType()), isFalse);
    expect(listType.isSubtypeOf(NeverType()), isFalse);
    expect(
      listType.isSubtypeOf(StaticType(coreTypes.listNonNullableRawType)),
      isTrue,
    );
    expect(
      listType.isSubtypeOf(StaticType(coreTypes.listNullableRawType)),
      isTrue,
    );
    expect(
      listType.isSubtypeOf(StaticType(coreTypes.iterableNonNullableRawType)),
      isTrue,
    );
  });

  test('nothing', () {
    expect(NothingType().kind, equals(TypeKind.nothing));

    expect(NothingType().isSubtypeOf(IntType()), isFalse);
    expect(NothingType().isSubtypeOf(DoubleType()), isFalse);
    expect(NothingType().isSubtypeOf(BoolType()), isFalse);
    expect(NothingType().isSubtypeOf(StringType()), isFalse);
    expect(NothingType().isSubtypeOf(ObjectType()), isFalse);
    expect(NothingType().isSubtypeOf(TopType()), isFalse);
    expect(NothingType().isSubtypeOf(NullType()), isFalse);
    expect(NothingType().isSubtypeOf(NeverType()), isFalse);
    expect(
      NothingType().isSubtypeOf(StaticType(coreTypes.listNonNullableRawType)),
      isFalse,
    );
    expect(NothingType().isSubtypeOf(NothingType()), isTrue);
    expect(NothingType().isSubtypeOf(TypeParametersType()), isFalse);
    expect(NothingType().isSubtypeOf(TypeArgumentsType()), isFalse);
  });

  test('type parameters', () {
    expect(TypeParametersType().kind, equals(TypeKind.typeParameters));

    expect(TypeParametersType().isSubtypeOf(IntType()), isFalse);
    expect(TypeParametersType().isSubtypeOf(DoubleType()), isFalse);
    expect(TypeParametersType().isSubtypeOf(BoolType()), isFalse);
    expect(TypeParametersType().isSubtypeOf(StringType()), isFalse);
    expect(TypeParametersType().isSubtypeOf(ObjectType()), isFalse);
    expect(TypeParametersType().isSubtypeOf(TopType()), isFalse);
    expect(TypeParametersType().isSubtypeOf(NullType()), isFalse);
    expect(TypeParametersType().isSubtypeOf(NeverType()), isFalse);
    expect(
      TypeParametersType().isSubtypeOf(
        StaticType(coreTypes.listNonNullableRawType),
      ),
      isFalse,
    );
    expect(TypeParametersType().isSubtypeOf(NothingType()), isFalse);
    expect(TypeParametersType().isSubtypeOf(TypeParametersType()), isTrue);
    expect(TypeParametersType().isSubtypeOf(TypeArgumentsType()), isFalse);
  });

  test('type arguments', () {
    expect(TypeArgumentsType().kind, equals(TypeKind.typeArguments));

    expect(TypeArgumentsType().isSubtypeOf(IntType()), isFalse);
    expect(TypeArgumentsType().isSubtypeOf(DoubleType()), isFalse);
    expect(TypeArgumentsType().isSubtypeOf(BoolType()), isFalse);
    expect(TypeArgumentsType().isSubtypeOf(StringType()), isFalse);
    expect(TypeArgumentsType().isSubtypeOf(ObjectType()), isFalse);
    expect(TypeArgumentsType().isSubtypeOf(TopType()), isFalse);
    expect(TypeArgumentsType().isSubtypeOf(NullType()), isFalse);
    expect(TypeArgumentsType().isSubtypeOf(NeverType()), isFalse);
    expect(
      TypeArgumentsType().isSubtypeOf(
        StaticType(coreTypes.listNonNullableRawType),
      ),
      isFalse,
    );
    expect(TypeArgumentsType().isSubtypeOf(NothingType()), isFalse);
    expect(TypeArgumentsType().isSubtypeOf(TypeParametersType()), isFalse);
    expect(TypeArgumentsType().isSubtypeOf(TypeArgumentsType()), isTrue);
  });
}

// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/library_index.dart' show LibraryIndex;

/// Translates Dart static types to corresponding CFG IR types.
class AstToIrTypes
    with ast.DartTypeVisitorExperimentExclusionMixin<TypeKind>
    implements ast.DartTypeVisitor<TypeKind> {
  final CoreTypes coreTypes;
  final LibraryIndex coreLibraries;
  final ClassHierarchy classHierarchy;
  final Map<ast.DartType, CType> _builtinTypes = {};
  final Map<ast.Class, TypeKind> _classTypeKinds = {};

  late final ast.Class? float32x4Class = coreLibraries.tryGetClass(
    'dart:typed_data',
    'Float32x4',
  );
  late final ast.Class? float64x2Class = coreLibraries.tryGetClass(
    'dart:typed_data',
    'Float64x2',
  );
  late final ast.Class? int32x4Class = coreLibraries.tryGetClass(
    'dart:typed_data',
    'Int32x4',
  );

  AstToIrTypes(this.coreTypes, this.coreLibraries, this.classHierarchy);

  /// Translate [node] static type to [CType].
  CType translate(ast.DartType node) {
    CType? type = _builtinTypes[node];
    if (type != null) {
      return type;
    }
    final kind = node.accept(this);
    type = switch (kind) {
      .intType => IntType(node),
      .doubleType => DoubleType(node),
      .boolType => BoolType(node),
      .stringType => StringType(node),
      .float32x4Type => Float32x4Type(node),
      .float64x2Type => Float64x2Type(node),
      .int32x4Type => Int32x4Type(node),
      .recordType => RecordType(node as ast.RecordType),
      .objectType => ObjectType(node),
      .nullType => const NullType(),
      .neverType => const NeverType(),
      .top => TopType(node),
      .otherDartType => StaticType(node),
      .nothing || .lateValue || .typeParameters || .typeArguments || .context =>
        throw 'Unexpected $kind when translating ${node.runtimeType} $node',
    };
    if (kind != TypeKind.otherDartType) {
      _builtinTypes[node] = type;
    }
    return type;
  }

  TypeKind _getClassTypeKind(ast.Class cls) {
    if (cls == coreTypes.objectClass) {
      return TypeKind.objectType;
    }
    if (classHierarchy.isSubInterfaceOf(cls, coreTypes.intClass)) {
      return TypeKind.intType;
    }
    if (classHierarchy.isSubInterfaceOf(cls, coreTypes.doubleClass)) {
      return TypeKind.doubleType;
    }
    if (classHierarchy.isSubInterfaceOf(cls, coreTypes.boolClass)) {
      return TypeKind.boolType;
    }
    if (classHierarchy.isSubInterfaceOf(cls, coreTypes.stringClass)) {
      return TypeKind.stringType;
    }
    final float32x4Class = this.float32x4Class;
    if (float32x4Class != null &&
        classHierarchy.isSubInterfaceOf(cls, float32x4Class)) {
      return TypeKind.float32x4Type;
    }
    final float64x2Class = this.float64x2Class;
    if (float64x2Class != null &&
        classHierarchy.isSubInterfaceOf(cls, float64x2Class)) {
      return TypeKind.float64x2Type;
    }
    final int32x4Class = this.int32x4Class;
    if (int32x4Class != null &&
        classHierarchy.isSubInterfaceOf(cls, int32x4Class)) {
      return TypeKind.int32x4Type;
    }
    return TypeKind.otherDartType;
  }

  @override
  TypeKind visitFunctionType(ast.FunctionType node) => TypeKind.otherDartType;

  @override
  TypeKind visitInterfaceType(ast.InterfaceType node) {
    if (node.typeArguments.isNotEmpty) {
      return TypeKind.otherDartType;
    }
    final cls = node.classNode;
    if (!cls.enclosingLibrary.importUri.isScheme('dart')) {
      return TypeKind.otherDartType;
    }
    if (node.nullability == ast.Nullability.nullable) {
      if (cls == coreTypes.objectClass) {
        return TypeKind.top;
      }
      return TypeKind.otherDartType;
    }
    return _classTypeKinds[cls] ??= _getClassTypeKind(cls);
  }

  @override
  TypeKind visitTypedefType(ast.TypedefType node) => node.unalias.accept(this);

  @override
  TypeKind visitTypeParameterType(ast.TypeParameterType node) =>
      TypeKind.otherDartType;

  @override
  TypeKind visitStructuralParameterType(ast.StructuralParameterType node) =>
      TypeKind.otherDartType;

  @override
  TypeKind visitIntersectionType(ast.IntersectionType node) {
    final kind = node.left.accept(this);
    if (kind != TypeKind.otherDartType) return kind;
    return node.right.accept(this);
  }

  @override
  TypeKind visitExtensionType(ast.ExtensionType node) =>
      node.extensionTypeErasure.accept(this);

  @override
  TypeKind visitRecordType(ast.RecordType node) =>
      node.nullability == .nonNullable
      ? TypeKind.recordType
      : TypeKind.otherDartType;

  @override
  TypeKind visitFutureOrType(ast.FutureOrType node) {
    final kind = node.typeArgument.accept(this);
    if (kind == TypeKind.top) {
      return TypeKind.top;
    }
    if (kind == TypeKind.objectType) {
      return (node.nullability == ast.Nullability.nullable)
          ? TypeKind.top
          : TypeKind.objectType;
    }
    return TypeKind.otherDartType;
  }

  @override
  TypeKind visitNeverType(ast.NeverType node) =>
      (node.nullability == ast.Nullability.nullable)
      ? TypeKind.nullType
      : TypeKind.neverType;

  @override
  TypeKind visitNullType(ast.NullType node) => TypeKind.nullType;

  @override
  TypeKind visitVoidType(ast.VoidType node) => TypeKind.top;

  @override
  TypeKind visitDynamicType(ast.DynamicType node) => TypeKind.top;

  @override
  TypeKind visitInvalidType(ast.InvalidType node) =>
      throw 'Unsupported type ${node.runtimeType} $node';

  @override
  TypeKind visitAuxiliaryType(ast.AuxiliaryType node) =>
      throw 'Unsupported type ${node.runtimeType} $node';
}

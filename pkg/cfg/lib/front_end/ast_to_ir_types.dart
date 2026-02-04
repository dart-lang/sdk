// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;

/// Translates Dart static types to corresponding CFG IR types.
class AstToIrTypes
    with ast.DartTypeVisitorExperimentExclusionMixin<TypeKind>
    implements ast.DartTypeVisitor<TypeKind> {
  final CoreTypes coreTypes;
  final ClassHierarchy classHierarchy;
  final Map<ast.DartType, CType> _builtinTypes = {};
  final Map<ast.Class, TypeKind> _classTypeKinds = {};

  AstToIrTypes(this.coreTypes, this.classHierarchy);

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
      .objectType => ObjectType(node),
      .nullType => const NullType(),
      .neverType => const NeverType(),
      .top => TopType(node),
      .otherDartType => StaticType(node),
      .nothing || .typeParameters || .typeArguments =>
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
  TypeKind visitRecordType(ast.RecordType node) => TypeKind.otherDartType;

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

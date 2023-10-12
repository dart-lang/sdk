// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart'
    as macro;
import 'package:kernel/ast.dart';

import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/library_builder.dart';
import '../../builder/member_builder.dart';
import '../../builder/nullability_builder.dart';
import '../../builder/type_builder.dart';
import '../../uris.dart';
import 'macro.dart';

abstract class IdentifierImpl extends macro.IdentifierImpl {
  IdentifierImpl({
    required int id,
    required String name,
  }) : super(id: id, name: name);

  macro.ResolvedIdentifier resolveIdentifier();

  Future<macro.TypeDeclaration> resolveTypeDeclaration(
      MacroApplications macroApplications);

  DartType buildType(
      NullabilityBuilder nullabilityBuilder, List<DartType> typeArguments);

  macro.ResolvedIdentifier _resolveTypeDeclarationIdentifier(
      TypeDeclarationBuilder? typeDeclarationBuilder) {
    if (typeDeclarationBuilder != null) {
      Uri? uri;
      switch (typeDeclarationBuilder) {
        case ClassBuilder():
          uri = typeDeclarationBuilder.libraryBuilder.importUri;
        case TypeAliasBuilder():
          uri = typeDeclarationBuilder.libraryBuilder.importUri;
        case NominalVariableBuilder():
        // TODO(johnniwinther): Handle this case.
        case StructuralVariableBuilder():
        // TODO(johnniwinther): Handle this case.
        case ExtensionBuilder():
        // TODO(johnniwinther): Handle this case.
        case ExtensionTypeDeclarationBuilder():
        // TODO(johnniwinther): Handle this case.
        case InvalidTypeDeclarationBuilder():
        case BuiltinTypeDeclarationBuilder():
          if (name == 'dynamic') {
            uri = dartCore;
          }
        // TODO(johnniwinther): How should we handle this case?
        case OmittedTypeDeclarationBuilder():
      }

      return new macro.ResolvedIdentifier(
          kind: macro.IdentifierKind.topLevelMember,
          name: name,
          staticScope: null,
          uri: uri);
    } else {
      throw new StateError('Unable to resolve identifier $this');
    }
  }

  Future<macro.TypeDeclaration> _resolveTypeDeclaration(
      MacroApplications macroApplications,
      TypeDeclarationBuilder? typeDeclarationBuilder) {
    switch (typeDeclarationBuilder) {
      case ClassBuilder():
        return new Future.value(
            macroApplications.getClassDeclaration(typeDeclarationBuilder));
      case TypeAliasBuilder():
        return new Future.value(
            macroApplications.getTypeAliasDeclaration(typeDeclarationBuilder));
      case NominalVariableBuilder():
      case StructuralVariableBuilder():
      case ExtensionBuilder():
      case ExtensionTypeDeclarationBuilder():
      case InvalidTypeDeclarationBuilder():
      case BuiltinTypeDeclarationBuilder():
      // TODO(johnniwinther): How should we handle this case?
      case OmittedTypeDeclarationBuilder():
      case null:
        // TODO(johnniwinther): Handle these cases.
        return new Future.error(
            new ArgumentError('Unable to resolve identifier $this'));
    }
  }
}

class TypeBuilderIdentifier extends IdentifierImpl {
  final TypeBuilder typeBuilder;
  final LibraryBuilder libraryBuilder;

  TypeBuilderIdentifier({
    required this.typeBuilder,
    required this.libraryBuilder,
    required int id,
    required String name,
  }) : super(id: id, name: name);

  @override
  macro.ResolvedIdentifier resolveIdentifier() {
    return _resolveTypeDeclarationIdentifier(typeBuilder.declaration);
  }

  @override
  DartType buildType(
      NullabilityBuilder nullabilityBuilder, List<DartType> typeArguments) {
    return typeBuilder.declaration!.buildAliasedTypeWithBuiltArguments(
        libraryBuilder,
        nullabilityBuilder.build(libraryBuilder),
        typeArguments,
        TypeUse.macroTypeArgument,
        // TODO(johnniwinther): How should handle malbounded types here? Should
        // we report an error on the annotation?
        missingUri,
        TreeNode.noOffset,
        hasExplicitTypeArguments: true);
  }

  @override
  Future<macro.TypeDeclaration> resolveTypeDeclaration(
      MacroApplications macroApplications) {
    return _resolveTypeDeclaration(macroApplications, typeBuilder.declaration);
  }
}

class TypeDeclarationBuilderIdentifier extends IdentifierImpl {
  final TypeDeclarationBuilder typeDeclarationBuilder;
  final LibraryBuilder libraryBuilder;

  TypeDeclarationBuilderIdentifier({
    required this.typeDeclarationBuilder,
    required this.libraryBuilder,
    required int id,
    required String name,
  }) : super(id: id, name: name);

  @override
  macro.ResolvedIdentifier resolveIdentifier() {
    return _resolveTypeDeclarationIdentifier(typeDeclarationBuilder);
  }

  @override
  Future<macro.TypeDeclaration> resolveTypeDeclaration(
      MacroApplications macroApplications) {
    return _resolveTypeDeclaration(macroApplications, typeDeclarationBuilder);
  }

  @override
  DartType buildType(
      NullabilityBuilder nullabilityBuilder, List<DartType> typeArguments) {
    return typeDeclarationBuilder.buildAliasedTypeWithBuiltArguments(
        libraryBuilder,
        nullabilityBuilder.build(libraryBuilder),
        typeArguments,
        TypeUse.macroTypeArgument,
        // TODO(johnniwinther): How should handle malbounded types here? Should
        // we report an error on the annotation?
        missingUri,
        TreeNode.noOffset,
        hasExplicitTypeArguments: true);
  }
}

class MemberBuilderIdentifier extends IdentifierImpl {
  final MemberBuilder memberBuilder;

  MemberBuilderIdentifier(
      {required this.memberBuilder, required int id, required String name})
      : super(id: id, name: name);

  @override
  macro.ResolvedIdentifier resolveIdentifier() {
    Uri? uri;
    String? staticScope;
    macro.IdentifierKind kind;
    if (memberBuilder.isTopLevel) {
      uri = memberBuilder.libraryBuilder.importUri;
      kind = macro.IdentifierKind.topLevelMember;
    } else if (memberBuilder.isStatic || memberBuilder.isConstructor) {
      ClassBuilder classBuilder = memberBuilder.classBuilder!;
      staticScope = classBuilder.name;
      uri = classBuilder.libraryBuilder.importUri;
      kind = macro.IdentifierKind.staticInstanceMember;
    } else {
      kind = macro.IdentifierKind.instanceMember;
    }
    return new macro.ResolvedIdentifier(
        kind: kind, name: name, staticScope: staticScope, uri: uri);
  }

  @override
  DartType buildType(
      NullabilityBuilder nullabilityBuilder, List<DartType> typeArguments) {
    throw new UnsupportedError('Cannot build type from member.');
  }

  @override
  Future<macro.TypeDeclaration> resolveTypeDeclaration(
      MacroApplications macroApplications) {
    return new Future.error(
        new ArgumentError('Cannot resolve type declaration from member.'));
  }
}

class FormalParameterBuilderIdentifier extends IdentifierImpl {
  final LibraryBuilder libraryBuilder;
  final FormalParameterBuilder parameterBuilder;

  FormalParameterBuilderIdentifier({
    required this.parameterBuilder,
    required this.libraryBuilder,
    required int id,
    required String name,
  }) : super(id: id, name: name);

  @override
  macro.ResolvedIdentifier resolveIdentifier() {
    return new macro.ResolvedIdentifier(
        kind: macro.IdentifierKind.local,
        name: name,
        staticScope: null,
        uri: null);
  }

  @override
  DartType buildType(
      NullabilityBuilder nullabilityBuilder, List<DartType> typeArguments) {
    throw new UnsupportedError('Cannot build type from formal parameter.');
  }

  @override
  Future<macro.TypeDeclaration> resolveTypeDeclaration(
      MacroApplications macroApplications) {
    throw new ArgumentError(
        'Cannot resolve type declaration from formal parameter.');
  }
}

class OmittedTypeIdentifier extends IdentifierImpl {
  OmittedTypeIdentifier({required int id}) : super(id: id, name: 'dynamic');

  @override
  DartType buildType(
      NullabilityBuilder nullabilityBuilder, List<DartType> typeArguments) {
    return const DynamicType();
  }

  @override
  macro.ResolvedIdentifier resolveIdentifier() {
    return new macro.ResolvedIdentifier(
        kind: macro.IdentifierKind.topLevelMember,
        name: name,
        staticScope: null,
        uri: dartCore);
  }

  @override
  Future<macro.TypeDeclaration> resolveTypeDeclaration(
      MacroApplications macroApplications) {
    return new Future.error(new ArgumentError(
        'Cannot resolve type declaration from omitted type.'));
  }
}

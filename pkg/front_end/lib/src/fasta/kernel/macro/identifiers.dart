// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart'
    as macro;
import 'package:kernel/ast.dart';

import '../../builder/class_builder.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/library_builder.dart';
import '../../builder/member_builder.dart';
import '../../builder/nullability_builder.dart';
import '../../builder/type_alias_builder.dart';
import '../../builder/type_builder.dart';
import '../../builder/type_declaration_builder.dart';

abstract class IdentifierImpl implements macro.IdentifierImpl {
  macro.ResolvedIdentifier resolveIdentifier();
  DartType buildType(
      NullabilityBuilder nullabilityBuilder, List<DartType> typeArguments);
}

class TypeBuilderIdentifier extends macro.IdentifierImpl
    implements IdentifierImpl {
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
    TypeDeclarationBuilder? typeDeclarationBuilder = typeBuilder.declaration;
    if (typeDeclarationBuilder != null) {
      Uri? uri;
      if (typeDeclarationBuilder is ClassBuilder) {
        uri = typeDeclarationBuilder.library.importUri;
      } else if (typeDeclarationBuilder is TypeAliasBuilder) {
        uri = typeDeclarationBuilder.library.importUri;
      } else if (name == 'dynamic') {
        uri = Uri.parse('dart:core');
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

  @override
  DartType buildType(
      NullabilityBuilder nullabilityBuilder, List<DartType> typeArguments) {
    return typeBuilder.declaration!.buildTypeWithBuiltArguments(libraryBuilder,
        nullabilityBuilder.build(libraryBuilder), typeArguments);
  }
}

class TypeDeclarationBuilderIdentifier extends macro.IdentifierImpl
    implements IdentifierImpl {
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
    Uri? uri;
    if (typeDeclarationBuilder is ClassBuilder) {
      uri = (typeDeclarationBuilder as ClassBuilder).library.importUri;
    } else if (typeDeclarationBuilder is TypeAliasBuilder) {
      uri = (typeDeclarationBuilder as TypeAliasBuilder).library.importUri;
    } else if (name == 'dynamic') {
      uri = Uri.parse('dart:core');
    }
    return new macro.ResolvedIdentifier(
        kind: macro.IdentifierKind.topLevelMember,
        name: name,
        staticScope: null,
        uri: uri);
  }

  @override
  DartType buildType(
      NullabilityBuilder nullabilityBuilder, List<DartType> typeArguments) {
    return typeDeclarationBuilder.buildTypeWithBuiltArguments(libraryBuilder,
        nullabilityBuilder.build(libraryBuilder), typeArguments);
  }
}

class MemberBuilderIdentifier extends macro.IdentifierImpl
    implements IdentifierImpl {
  final MemberBuilder memberBuilder;

  MemberBuilderIdentifier(
      {required this.memberBuilder, required int id, required String name})
      : super(id: id, name: name);

  @override
  macro.ResolvedIdentifier resolveIdentifier() {
    Uri? uri;
    String? staticScope;
    macro.IdentifierKind kind;
    if (memberBuilder.isStatic || memberBuilder.isConstructor) {
      ClassBuilder classBuilder = memberBuilder.classBuilder!;
      staticScope = classBuilder.name;
      uri = classBuilder.library.importUri;
      kind = macro.IdentifierKind.staticInstanceMember;
    } else if (memberBuilder.isTopLevel) {
      uri = memberBuilder.library.importUri;
      kind = macro.IdentifierKind.topLevelMember;
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
}

class FormalParameterBuilderIdentifier extends macro.IdentifierImpl
    implements IdentifierImpl {
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
}

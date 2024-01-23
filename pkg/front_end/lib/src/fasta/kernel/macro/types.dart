// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart'
    as macro;
import 'package:kernel/ast.dart';
import 'package:kernel/src/types.dart';
import 'package:kernel/type_environment.dart' show SubtypeCheckMode;

import '../../builder/library_builder.dart';
import '../../builder/nullability_builder.dart';
import '../../builder/type_builder.dart';
import '../../source/source_loader.dart';
import '../hierarchy/hierarchy_builder.dart';
import 'identifiers.dart';

final IdentifierImpl omittedTypeIdentifier =
    new OmittedTypeIdentifier(id: macro.RemoteInstance.uniqueId);

class MacroTypes {
  final SourceLoader _sourceLoader;
  late Types _types;

  Map<TypeBuilder?, macro.TypeAnnotationImpl> _typeAnnotationCache = {};

  Map<DartType, _StaticTypeImpl> _staticTypeCache = {};

  MacroTypes(this._sourceLoader);

  void enterDeclarationsMacroPhase(ClassHierarchyBuilder classHierarchy) {
    _types = new Types(classHierarchy);
  }

  void clear() {
    _staticTypeCache.clear();
    _typeAnnotationCache.clear();
  }

  List<macro.TypeAnnotationImpl> computeTypeAnnotations(
      LibraryBuilder library, List<TypeBuilder>? typeBuilders) {
    if (typeBuilders == null) return const [];
    return new List.generate(typeBuilders.length,
        (int index) => computeTypeAnnotation(library, typeBuilders[index]));
  }

  macro.TypeAnnotationImpl _computeTypeAnnotation(
      LibraryBuilder libraryBuilder, TypeBuilder? typeBuilder) {
    switch (typeBuilder) {
      case NamedTypeBuilder():
        List<macro.TypeAnnotationImpl> typeArguments =
            computeTypeAnnotations(libraryBuilder, typeBuilder.typeArguments);
        bool isNullable = typeBuilder.nullabilityBuilder.isNullable;
        return new macro.NamedTypeAnnotationImpl(
            id: macro.RemoteInstance.uniqueId,
            identifier: new TypeBuilderIdentifier(
                typeBuilder: typeBuilder,
                libraryBuilder: libraryBuilder,
                id: macro.RemoteInstance.uniqueId,
                name: typeBuilder.typeName.name),
            typeArguments: typeArguments,
            isNullable: isNullable);
      case OmittedTypeBuilder():
        return new _OmittedTypeAnnotationImpl(typeBuilder,
            id: macro.RemoteInstance.uniqueId);
      case FunctionTypeBuilder():
      case InvalidTypeBuilder():
      case RecordTypeBuilder():
      case FixedTypeBuilder():
      case null:
        // TODO(johnniwinther): Should this only be for `null`? Can the other
        // type builders be observed here?
        return new macro.NamedTypeAnnotationImpl(
            id: macro.RemoteInstance.uniqueId,
            identifier: omittedTypeIdentifier,
            isNullable: false,
            typeArguments: const []);
    }
  }

  macro.TypeAnnotationImpl computeTypeAnnotation(
      LibraryBuilder libraryBuilder, TypeBuilder? typeBuilder) {
    return _typeAnnotationCache[typeBuilder] ??=
        _computeTypeAnnotation(libraryBuilder, typeBuilder);
  }

  DartType _typeForAnnotation(macro.TypeAnnotationCode typeAnnotation) {
    NullabilityBuilder nullabilityBuilder;
    if (typeAnnotation is macro.NullableTypeAnnotationCode) {
      nullabilityBuilder = const NullabilityBuilder.nullable();
      typeAnnotation = typeAnnotation.underlyingType;
    } else {
      nullabilityBuilder = const NullabilityBuilder.omitted();
    }

    if (typeAnnotation is macro.NamedTypeAnnotationCode) {
      macro.NamedTypeAnnotationCode namedTypeAnnotation = typeAnnotation;
      IdentifierImpl typeIdentifier = typeAnnotation.name as IdentifierImpl;
      List<DartType> arguments = new List<DartType>.generate(
          namedTypeAnnotation.typeArguments.length,
          (int index) =>
              _typeForAnnotation(namedTypeAnnotation.typeArguments[index]));
      return typeIdentifier.buildType(nullabilityBuilder, arguments);
    }
    // TODO: Implement support for function types.
    throw new UnimplementedError(
        'Unimplemented type annotation kind ${typeAnnotation.kind}');
  }

  macro.StaticType resolveTypeAnnotation(
      macro.TypeAnnotationCode typeAnnotation) {
    return createStaticType(_typeForAnnotation(typeAnnotation));
  }

  macro.StaticType createStaticType(DartType dartType) {
    return _staticTypeCache[dartType] ??= new _StaticTypeImpl(_types, dartType);
  }

  List<macro.NamedTypeAnnotationImpl> typeBuildersToAnnotations(
      LibraryBuilder libraryBuilder, List<TypeBuilder>? typeBuilders) {
    return typeBuilders == null
        ? []
        : typeBuilders
            .map((TypeBuilder typeBuilder) =>
                computeTypeAnnotation(libraryBuilder, typeBuilder)
                    as macro.NamedTypeAnnotationImpl)
            .toList();
  }

  macro.TypeAnnotation? inferOmittedType(
      macro.OmittedTypeAnnotation omittedType) {
    if (omittedType is _OmittedTypeAnnotationImpl) {
      OmittedTypeBuilder typeBuilder = omittedType.typeBuilder;
      if (typeBuilder.hasType) {
        return computeTypeAnnotation(
            _sourceLoader.coreLibrary,
            _sourceLoader.target.dillTarget.loader
                .computeTypeBuilder(typeBuilder.type));
      }
    }
    return null;
  }

  Map<String, OmittedTypeBuilder>? computeOmittedTypeBuilders(
      Map<macro.OmittedTypeAnnotation, String> omittedTypes) {
    if (omittedTypes.isEmpty) {
      return null;
    }
    Map<String, OmittedTypeBuilder> omittedTypeBuilders = {};
    for (MapEntry<macro.OmittedTypeAnnotation, String> entry
        in omittedTypes.entries) {
      _OmittedTypeAnnotationImpl omittedType =
          entry.key as _OmittedTypeAnnotationImpl;
      omittedTypeBuilders[entry.value] = omittedType.typeBuilder;
    }
    return omittedTypeBuilders;
  }
}

class _StaticTypeImpl implements macro.StaticType {
  final Types types;
  final DartType type;

  _StaticTypeImpl(this.types, this.type);

  @override
  Future<bool> isExactly(covariant _StaticTypeImpl other) {
    return new Future.value(type == other.type);
  }

  @override
  Future<bool> isSubtypeOf(covariant _StaticTypeImpl other) {
    return new Future.value(types.isSubtypeOf(
        type, other.type, SubtypeCheckMode.withNullabilities));
  }
}

// ignore: missing_override_of_must_be_overridden
class _OmittedTypeAnnotationImpl extends macro.OmittedTypeAnnotationImpl {
  final OmittedTypeBuilder typeBuilder;

  _OmittedTypeAnnotationImpl(this.typeBuilder, {required int id})
      : super(id: id);
}

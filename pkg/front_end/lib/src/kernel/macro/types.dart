// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/src/types.dart';
import 'package:kernel/type_environment.dart' show SubtypeCheckMode;
import 'package:macros/macros.dart' as macro;
import 'package:macros/src/executor/introspection_impls.dart' as macro;
import 'package:macros/src/executor/remote_instance.dart' as macro;

import '../../base/uri_offset.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/library_builder.dart';
import '../../builder/nullability_builder.dart';
import '../../builder/record_type_builder.dart';
import '../../builder/type_builder.dart';
import '../../source/source_loader.dart';
import '../hierarchy/hierarchy_builder.dart';
import 'identifiers.dart';
import 'introspectors.dart';

// Coverage-ignore(suite): Not run.
final IdentifierImpl omittedTypeIdentifier =
    new OmittedTypeIdentifier(id: macro.RemoteInstance.uniqueId);

// Coverage-ignore(suite): Not run.
class MacroTypes {
  final MacroIntrospection _introspection;
  final SourceLoader _sourceLoader;
  late Types _types;

  Map<TypeBuilder?, macro.TypeAnnotationImpl> _typeAnnotationCache = {};
  Map<macro.TypeAnnotation, UriOffset> _typeAnnotationOffsets = {};

  Map<DartType, _StaticTypeImpl> _staticTypeCache = {};

  MacroTypes(this._introspection, this._sourceLoader);

  void enterDeclarationsMacroPhase(ClassHierarchyBuilder classHierarchy) {
    _types = new Types(classHierarchy);
  }

  void clear() {
    _staticTypeCache.clear();
    _typeAnnotationCache.clear();
    _typeAnnotationOffsets.clear();
  }

  /// Returns the [UriOffset] for [typeAnnotation], if any.
  UriOffset? getLocationFromTypeAnnotation(
          macro.TypeAnnotation typeAnnotation) =>
      _typeAnnotationOffsets[typeAnnotation];

  /// Returns the list of [macro.TypeAnnotationImpl]s corresponding to
  /// [typeBuilders] occurring in [libraryBuilder].
  List<macro.TypeAnnotationImpl> getTypeAnnotations(
      LibraryBuilder library, List<TypeBuilder>? typeBuilders) {
    if (typeBuilders == null) return const [];
    return new List.generate(typeBuilders.length,
        (int index) => getTypeAnnotation(library, typeBuilders[index]));
  }

  /// Returns the list of [macro.NamedTypeAnnotationImpl]s corresponding to
  /// [typeBuilders] occurring in [libraryBuilder].
  List<macro.NamedTypeAnnotationImpl> getNamedTypeAnnotations(
      LibraryBuilder library, List<TypeBuilder>? typeBuilders) {
    if (typeBuilders == null) return const [];
    return new List.generate(
        typeBuilders.length,
        (int index) => getTypeAnnotation(library, typeBuilders[index])
            as macro.NamedTypeAnnotationImpl);
  }

  /// Creates the [macro.FormalParameterImpl]s corresponding to [formals]
  /// occurring in [libraryBuilder].
  (List<macro.FormalParameterImpl>, List<macro.FormalParameterImpl>)
      _createParameters(
          LibraryBuilder libraryBuilder, List<ParameterBuilder>? formals) {
    if (formals == null) {
      return const ([], []);
    } else {
      List<macro.FormalParameterImpl> positionalParameters = [];
      List<macro.FormalParameterImpl> namedParameters = [];
      for (ParameterBuilder formal in formals) {
        macro.TypeAnnotationImpl type =
            getTypeAnnotation(libraryBuilder, formal.type);
        if (formal.isNamed) {
          macro.FormalParameterImpl declaration = new macro.FormalParameterImpl(
            id: macro.RemoteInstance.uniqueId,
            name: formal.name,
            // TODO(johnniwinther): Provide metadata annotations.
            metadata: const [],
            isRequired: formal.isRequiredNamed,
            isNamed: true,
            type: type,
          );
          namedParameters.add(declaration);
        } else {
          macro.FormalParameterImpl declaration = new macro.FormalParameterImpl(
            id: macro.RemoteInstance.uniqueId,
            name: formal.name,
            // TODO(johnniwinther): Provide metadata annotations.
            metadata: const [],
            isRequired: formal.isRequiredPositional,
            isNamed: false,
            type: type,
          );
          positionalParameters.add(declaration);
        }
      }
      return (positionalParameters, namedParameters);
    }
  }

  /// Creates the [macro.RecordFieldImpl]s corresponding to [fields]
  /// occurring in [libraryBuilder].
  List<macro.RecordFieldImpl> _createRecordFields(
      LibraryBuilder libraryBuilder, List<RecordTypeFieldBuilder>? fields) {
    if (fields == null) {
      return const [];
    }
    List<macro.RecordFieldImpl> list = [];
    for (RecordTypeFieldBuilder field in fields) {
      list.add(new macro.RecordFieldImpl(
          id: macro.RemoteInstance.uniqueId,
          name: field.name,
          type: getTypeAnnotation(libraryBuilder, field.type)));
    }
    return list;
  }

  /// Creates the [macro.TypeAnnotationImpl] corresponding to [typeBuilder]
  /// occurring in [libraryBuilder].
  macro.TypeAnnotationImpl _createTypeAnnotation(
      LibraryBuilder libraryBuilder, TypeBuilder? typeBuilder) {
    macro.TypeAnnotationImpl typeAnnotation;
    UriOffset? uriOffset = typeBuilder?.fileUri != null
        ? new UriOffset(typeBuilder!.fileUri!, typeBuilder.charOffset!)
        : null;
    // TODO(johnniwinther): Implement this directly on [TypeBuilder].
    switch (typeBuilder) {
      case NamedTypeBuilder():
        List<macro.TypeAnnotationImpl> typeArguments =
            getTypeAnnotations(libraryBuilder, typeBuilder.typeArguments);
        bool isNullable = typeBuilder.nullabilityBuilder.isNullable;
        typeAnnotation = new macro.NamedTypeAnnotationImpl(
            id: macro.RemoteInstance.uniqueId,
            identifier: new TypeBuilderIdentifier(
                typeBuilder: typeBuilder,
                libraryBuilder: libraryBuilder,
                id: macro.RemoteInstance.uniqueId,
                name: typeBuilder.typeName.name),
            typeArguments: typeArguments,
            isNullable: isNullable);
      case OmittedTypeBuilder():
        typeAnnotation = new _OmittedTypeAnnotationImpl(typeBuilder,
            id: macro.RemoteInstance.uniqueId);
      case FunctionTypeBuilder(
          :TypeBuilder returnType,
          :List<ParameterBuilder>? formals,
          :List<StructuralVariableBuilder>? typeVariables
        ):
        bool isNullable = typeBuilder.nullabilityBuilder.isNullable;
        var (
          List<macro.FormalParameterImpl> positionalParameters,
          List<macro.FormalParameterImpl> namedParameters
        ) = _createParameters(libraryBuilder, formals);
        List<macro.TypeParameterImpl> typeParameters = [];
        if (typeVariables != null) {
          for (StructuralVariableBuilder typeVariable in typeVariables) {
            typeParameters.add(new macro.TypeParameterImpl(
                id: macro.RemoteInstance.uniqueId,
                bound: typeVariable.bound != null
                    ? _createTypeAnnotation(libraryBuilder, typeVariable.bound)
                    : null,
                metadata: const [],
                name: typeVariable.name));
          }
        }
        typeAnnotation = new macro.FunctionTypeAnnotationImpl(
            id: macro.RemoteInstance.uniqueId,
            isNullable: isNullable,
            namedParameters: namedParameters,
            positionalParameters: positionalParameters,
            returnType: getTypeAnnotation(libraryBuilder, returnType),
            typeParameters: typeParameters);
      case RecordTypeBuilder(
          :List<RecordTypeFieldBuilder>? positionalFields,
          :List<RecordTypeFieldBuilder>? namedFields
        ):
        bool isNullable = typeBuilder.nullabilityBuilder.isNullable;
        typeAnnotation = new macro.RecordTypeAnnotationImpl(
            id: macro.RemoteInstance.uniqueId,
            isNullable: isNullable,
            positionalFields:
                _createRecordFields(libraryBuilder, positionalFields),
            namedFields: _createRecordFields(libraryBuilder, namedFields));
      case null:
        // TODO(johnniwinther): Is this an error case?
        return new macro.NamedTypeAnnotationImpl(
            id: macro.RemoteInstance.uniqueId,
            identifier: omittedTypeIdentifier,
            isNullable: false,
            typeArguments: const []);
      case InvalidTypeBuilder():
      case FixedTypeBuilder():
        throw new UnsupportedError("Unexpected type builder $typeBuilder");
    }
    if (uriOffset != null) {
      _typeAnnotationOffsets[typeAnnotation] = uriOffset;
    }
    return typeAnnotation;
  }

  /// Returns the [macro.TypeAnnotationImpl] corresponding to [typeBuilder]
  /// occurring in [libraryBuilder].
  macro.TypeAnnotationImpl getTypeAnnotation(
      LibraryBuilder libraryBuilder, TypeBuilder? typeBuilder) {
    return _typeAnnotationCache[typeBuilder] ??=
        _createTypeAnnotation(libraryBuilder, typeBuilder);
  }

  /// Returns the [DartType] corresponding to [typeAnnotation].
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

  /// Returns the resolved [macro.StaticType] for [typeAnnotation].
  macro.StaticType resolveTypeAnnotation(
      macro.TypeAnnotationCode typeAnnotation) {
    return _createStaticType(_typeForAnnotation(typeAnnotation));
  }

  macro.StaticType _createStaticType(DartType dartType) {
    return _staticTypeCache[dartType] ??= switch (dartType) {
      TypeDeclarationType() => new _NamedStaticTypeImpl(
          macro.RemoteInstance.uniqueId,
          types: this,
          type: dartType,
          declaration: _introspection.resolveDeclarationFromKernel(
              dartType.typeDeclaration) as macro.ParameterizedTypeDeclaration,
          typeArguments: [
            for (DartType argument in dartType.typeArguments)
              _createStaticType(argument),
          ],
        ),
      _ => new _StaticTypeImpl(macro.RemoteInstance.uniqueId,
          types: this, type: dartType),
    };
  }

  macro.NamedStaticType _createNamedStaticType(TypeDeclarationType dartType) {
    return _createStaticType(dartType) as macro.NamedStaticType;
  }

  /// Returns the [macro.TypeAnnotation] for the inferred type of [omittedType],
  /// or `null` if the type has not yet been inferred.
  macro.TypeAnnotation? inferOmittedType(
      macro.OmittedTypeAnnotation omittedType) {
    if (omittedType is _OmittedTypeAnnotationImpl) {
      OmittedTypeBuilder typeBuilder = omittedType.typeBuilder;
      if (typeBuilder.hasType) {
        return getTypeAnnotation(
            _sourceLoader.coreLibrary,
            _sourceLoader.target.dillTarget.loader
                .computeTypeBuilder(typeBuilder.type));
      }
      return null;
    }
    throw new UnsupportedError(
        "Unexpected OmittedTypeAnnotation implementation "
        "${omittedType.runtimeType}.");
  }

  /// Computes a map of the [OmittedTypeBuilder]s corresponding to the
  /// [macro.OmittedTypeAnnotation]s in [omittedTypes]. The synthesized names
  /// in [omittedTypes] are used as the keys in the returned map.
  ///
  /// If [omittedTypes] is empty, `null` is returned.
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

// Coverage-ignore(suite): Not run.
class _StaticTypeImpl extends macro.StaticTypeImpl {
  final MacroTypes types;
  final DartType type;

  _StaticTypeImpl(
    super.id, {
    required this.types,
    required this.type,
  });

  @override
  Future<bool> isExactly(covariant _StaticTypeImpl other) {
    return new Future.value(type == other.type);
  }

  @override
  Future<bool> isSubtypeOf(covariant _StaticTypeImpl other) {
    return new Future.value(types._types
        .isSubtypeOf(type, other.type, SubtypeCheckMode.withNullabilities));
  }

  @override
  Future<macro.NamedStaticType?> asInstanceOf(
      macro.TypeDeclaration declaration) {
    TypeDeclarationType? result;
    DartType type = this.type;
    macro.Identifier identifier = declaration.identifier;

    if (type is TypeDeclarationType &&
        identifier is TypeDeclarationBuilderIdentifier) {
      TypeDeclarationBuilder declarationBuilder =
          identifier.typeDeclarationBuilder;
      switch (declarationBuilder) {
        case ClassBuilder():
          result = types._sourceLoader.hierarchyBuilder
              .getTypeAsInstanceOf(type, declarationBuilder.cls);
        case ExtensionTypeDeclarationBuilder():
          result = types._sourceLoader.hierarchyBuilder.getTypeAsInstanceOf(
              type, declarationBuilder.extensionTypeDeclaration);
        case BuiltinTypeDeclarationBuilder():
        case InvalidTypeDeclarationBuilder():
        case OmittedTypeDeclarationBuilder():
        case TypeAliasBuilder():
        case ExtensionBuilder():
        case NominalVariableBuilder():
        case StructuralVariableBuilder():
        // There is no instance of [declaration].
      }
    }

    if (result != null) {
      return new Future.value(types._createNamedStaticType(result));
    } else {
      return new Future.value(null);
    }
  }
}

// Coverage-ignore(suite): Not run.
class _NamedStaticTypeImpl extends _StaticTypeImpl
    implements macro.NamedStaticType {
  @override
  final macro.ParameterizedTypeDeclaration declaration;

  @override
  final List<macro.StaticType> typeArguments;

  _NamedStaticTypeImpl(
    super.id, {
    required this.declaration,
    required this.typeArguments,
    required super.types,
    required super.type,
  });
}

// Coverage-ignore(suite): Not run.
// ignore: missing_override_of_must_be_overridden
class _OmittedTypeAnnotationImpl extends macro.OmittedTypeAnnotationImpl {
  final OmittedTypeBuilder typeBuilder;

  _OmittedTypeAnnotationImpl(this.typeBuilder, {required int id})
      : super(id: id);
}

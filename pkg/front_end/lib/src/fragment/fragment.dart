// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:kernel/ast.dart';

import '../base/modifiers.dart';
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/mixin_application_builder.dart';
import '../builder/type_builder.dart';
import '../source/name_scheme.dart';
import '../source/source_class_builder.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_enum_builder.dart';
import '../source/source_extension_builder.dart';
import '../source/source_extension_type_declaration_builder.dart';
import '../source/source_factory_builder.dart';
import '../source/source_field_builder.dart';
import '../source/source_procedure_builder.dart';
import '../source/source_type_alias_builder.dart';
import '../source/type_parameter_scope_builder.dart';

sealed class Fragment {
  Builder get builder;
}

class TypedefFragment implements Fragment {
  final List<MetadataBuilder>? metadata;
  final String name;
  final List<NominalVariableBuilder>? typeVariables;
  final TypeBuilder type;
  final Uri fileUri;
  final int fileOffset;

  SourceTypeAliasBuilder? _builder;

  TypedefFragment(
      {required this.metadata,
      required this.name,
      required this.typeVariables,
      required this.type,
      required this.fileUri,
      required this.fileOffset});

  @override
  // Coverage-ignore(suite): Not run.
  SourceTypeAliasBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceTypeAliasBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => "$runtimeType($name,$fileUri,$fileOffset)";
}

class ClassFragment extends DeclarationFragment implements Fragment {
  @override
  final String name;

  final int nameOffset;

  SourceClassBuilder? _builder;

  late final LookupScope compilationUnitScope;
  late final List<MetadataBuilder>? metadata;
  late final Modifiers modifiers;
  late final TypeBuilder? supertype;
  late final MixinApplicationBuilder? mixins;
  late final List<TypeBuilder>? interfaces;
  late final List<ConstructorReferenceBuilder> constructorReferences;
  late final int startOffset;
  late final int charOffset;
  late final int endOffset;

  ClassFragment(this.name, super.fileUri, this.nameOffset, super.typeParameters,
      super.typeParameterScope, super._nominalParameterNameSpace);

  @override
  int get fileOffset => nameOffset;

  @override
  SourceClassBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceClassBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  DeclarationFragmentKind get kind => DeclarationFragmentKind.classDeclaration;

  @override
  String toString() => '$runtimeType($name,$fileUri,$fileOffset)';
}

class MixinFragment extends DeclarationFragment implements Fragment {
  @override
  final String name;

  final int nameOffset;

  SourceClassBuilder? _builder;

  late final LookupScope compilationUnitScope;
  late final List<MetadataBuilder>? metadata;
  late final Modifiers modifiers;
  late final TypeBuilder? supertype;
  late final MixinApplicationBuilder? mixins;
  late final List<TypeBuilder>? interfaces;
  late final List<ConstructorReferenceBuilder> constructorReferences;
  late final int startOffset;
  late final int charOffset;
  late final int endOffset;

  MixinFragment(this.name, super.fileUri, this.nameOffset, super.typeParameters,
      super.typeParameterScope, super._nominalParameterNameSpace);

  @override
  int get fileOffset => nameOffset;

  @override
  SourceClassBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceClassBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  DeclarationFragmentKind get kind => DeclarationFragmentKind.mixinDeclaration;

  @override
  String toString() => '$runtimeType($name,$fileUri,$fileOffset)';
}

class NamedMixinApplicationFragment implements Fragment {
  final String name;
  final Uri fileUri;
  final int startCharOffset;
  final int charOffset;
  final int charEndOffset;
  final Modifiers modifiers;
  final List<MetadataBuilder>? metadata;
  final List<NominalVariableBuilder>? typeParameters;
  final TypeBuilder? supertype;
  final MixinApplicationBuilder mixins;
  final List<TypeBuilder>? interfaces;
  final LookupScope compilationUnitScope;

  SourceClassBuilder? _builder;

  NamedMixinApplicationFragment(
      {required this.name,
      required this.fileUri,
      required this.startCharOffset,
      required this.charOffset,
      required this.charEndOffset,
      required this.modifiers,
      required this.metadata,
      required this.typeParameters,
      required this.supertype,
      required this.mixins,
      required this.interfaces,
      required this.compilationUnitScope});

  @override
  // Coverage-ignore(suite): Not run.
  SourceClassBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  // Coverage-ignore(suite): Not run.
  void set builder(SourceClassBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$charOffset)';
}

class EnumFragment extends DeclarationFragment implements Fragment {
  @override
  final String name;

  final int nameOffset;

  SourceEnumBuilder? _builder;

  late final LookupScope compilationUnitScope;
  late final List<MetadataBuilder>? metadata;
  late final MixinApplicationBuilder? supertypeBuilder;
  late final List<TypeBuilder>? interfaces;
  late final List<EnumConstantInfo?>? enumConstantInfos;
  late final List<ConstructorReferenceBuilder> constructorReferences;
  late final int startCharOffset;
  late final int charOffset;
  late final int charEndOffset;

  EnumFragment(this.name, super.fileUri, this.nameOffset, super.typeParameters,
      super.typeParameterScope, super._nominalParameterNameSpace);

  @override
  int get fileOffset => nameOffset;

  @override
  SourceEnumBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceEnumBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  DeclarationFragmentKind get kind => DeclarationFragmentKind.enumDeclaration;

  @override
  String toString() => '$runtimeType($name,$fileUri,$fileOffset)';
}

class ExtensionFragment extends DeclarationFragment implements Fragment {
  final ExtensionName extensionName;

  @override
  final int fileOffset;

  /// The type of `this` in instance methods declared in extension declarations.
  ///
  /// Instance methods declared in extension declarations methods are extended
  /// with a synthesized parameter of this type.
  TypeBuilder? _extensionThisType;

  SourceExtensionBuilder? _builder;

  late final List<MetadataBuilder>? metadata;
  late final Modifiers modifiers;
  late final TypeBuilder onType;
  late final int startOffset;
  late final int nameOffset;
  late final int endOffset;

  ExtensionFragment(
      String? name,
      super.fileUri,
      this.fileOffset,
      super.typeParameters,
      super.typeParameterScope,
      super._nominalParameterNameSpace)
      : extensionName = name != null
            ? new FixedExtensionName(name)
            : new UnnamedExtensionName();

  @override
  SourceExtensionBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceExtensionBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String get name => extensionName.name;

  @override
  DeclarationFragmentKind get kind =>
      DeclarationFragmentKind.extensionDeclaration;

  /// Registers the 'extension this type' of the extension declaration prepared
  /// for by this builder.
  ///
  /// See [extensionThisType] for terminology.
  void registerExtensionThisType(TypeBuilder type) {
    assert(_extensionThisType == null,
        "Extension this type has already been set.");
    _extensionThisType = type;
  }

  /// Returns the 'extension this type' of the extension declaration prepared
  /// for by this builder.
  ///
  /// The 'extension this type' is the type mentioned in the on-clause of the
  /// extension declaration. For instance `B` in this extension declaration:
  ///
  ///     extension A on B {
  ///       B method() => this;
  ///     }
  ///
  /// The 'extension this type' is the type if `this` expression in instance
  /// methods declared in extension declarations.
  TypeBuilder get extensionThisType {
    assert(_extensionThisType != null,
        "DeclarationBuilder.extensionThisType has not been set on $this.");
    return _extensionThisType!;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$fileOffset)';
}

class ExtensionTypeFragment extends DeclarationFragment implements Fragment {
  @override
  final String name;

  final int nameOffset;

  late final List<MetadataBuilder>? metadata;
  late final Modifiers modifiers;
  late final List<TypeBuilder>? interfaces;
  late final List<ConstructorReferenceBuilder> constructorReferences;
  late final int startOffset;
  late final int endOffset;

  SourceExtensionTypeDeclarationBuilder? _builder;

  ExtensionTypeFragment(
      this.name,
      super.fileUri,
      this.nameOffset,
      super.typeParameters,
      super.typeParameterScope,
      super._nominalParameterNameSpace);

  @override
  int get fileOffset => nameOffset;

  @override
  SourceExtensionTypeDeclarationBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceExtensionTypeDeclarationBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  DeclarationFragmentKind get kind =>
      DeclarationFragmentKind.extensionTypeDeclaration;

  @override
  String toString() => '$runtimeType($name,$fileUri,$fileOffset)';
}

class FieldFragment implements Fragment {
  final String name;
  final Uri fileUri;
  final int charOffset;
  final int charEndOffset;
  Token? _initializerToken;
  Token? _constInitializerToken;
  final List<MetadataBuilder>? metadata;
  final TypeBuilder type;
  final bool isTopLevel;
  final Modifiers modifiers;

  SourceFieldBuilder? _builder;

  FieldFragment(
      {required this.name,
      required this.fileUri,
      required this.charOffset,
      required this.charEndOffset,
      required Token? initializerToken,
      required Token? constInitializerToken,
      required this.metadata,
      required this.type,
      required this.isTopLevel,
      required this.modifiers})
      : _initializerToken = initializerToken,
        _constInitializerToken = constInitializerToken;

  Token? get initializerToken {
    Token? result = _initializerToken;
    // Ensure that we don't hold onto the token.
    _initializerToken = null;
    return result;
  }

  Token? get constInitializerToken {
    Token? result = _constInitializerToken;
    // Ensure that we don't hold onto the token.
    _constInitializerToken = null;
    return result;
  }

  @override
  SourceFieldBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceFieldBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$charOffset)';
}

class GetterFragment implements Fragment {
  final String name;
  final Uri fileUri;
  final int startCharOffset;
  final int charOffset;
  final int charOpenParenOffset;
  final int charEndOffset;
  final List<MetadataBuilder>? metadata;
  final Modifiers modifiers;
  final TypeBuilder returnType;
  final List<NominalVariableBuilder>? typeParameters;
  final List<FormalParameterBuilder>? formals;
  final AsyncMarker asyncModifier;
  final String? nativeMethodName;

  SourceProcedureBuilder? _builder;

  GetterFragment(
      {required this.name,
      required this.fileUri,
      required this.startCharOffset,
      required this.charOffset,
      required this.charOpenParenOffset,
      required this.charEndOffset,
      required this.metadata,
      required this.modifiers,
      required this.returnType,
      required this.typeParameters,
      required this.formals,
      required this.asyncModifier,
      required this.nativeMethodName});

  @override
  SourceProcedureBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceProcedureBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$charOffset)';
}

class SetterFragment implements Fragment {
  final String name;
  final Uri fileUri;
  final int startCharOffset;
  final int charOffset;
  final int charOpenParenOffset;
  final int charEndOffset;
  final List<MetadataBuilder>? metadata;
  final Modifiers modifiers;
  final TypeBuilder returnType;
  final List<NominalVariableBuilder>? typeParameters;
  final List<FormalParameterBuilder>? formals;
  final AsyncMarker asyncModifier;
  final String? nativeMethodName;

  SourceProcedureBuilder? _builder;

  SetterFragment(
      {required this.name,
      required this.fileUri,
      required this.startCharOffset,
      required this.charOffset,
      required this.charOpenParenOffset,
      required this.charEndOffset,
      required this.metadata,
      required this.modifiers,
      required this.returnType,
      required this.typeParameters,
      required this.formals,
      required this.asyncModifier,
      required this.nativeMethodName});

  @override
  SourceProcedureBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceProcedureBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$charOffset)';
}

class MethodFragment implements Fragment {
  final String name;
  final Uri fileUri;
  final int startCharOffset;
  final int charOffset;
  final int charOpenParenOffset;
  final int charEndOffset;
  final List<MetadataBuilder>? metadata;
  final Modifiers modifiers;
  final TypeBuilder returnType;
  final List<NominalVariableBuilder>? typeParameters;
  final List<FormalParameterBuilder>? formals;
  final ProcedureKind kind;
  final AsyncMarker asyncModifier;
  final String? nativeMethodName;

  SourceProcedureBuilder? _builder;

  MethodFragment(
      {required this.name,
      required this.fileUri,
      required this.startCharOffset,
      required this.charOffset,
      required this.charOpenParenOffset,
      required this.charEndOffset,
      required this.metadata,
      required this.modifiers,
      required this.returnType,
      required this.typeParameters,
      required this.formals,
      required this.kind,
      required this.asyncModifier,
      required this.nativeMethodName});

  @override
  SourceProcedureBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceProcedureBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$charOffset)';
}

class ConstructorFragment implements Fragment {
  final String name;
  final Uri fileUri;
  final int startCharOffset;
  final int charOffset;
  final int charOpenParenOffset;
  final int charEndOffset;
  final Modifiers modifiers;
  final List<MetadataBuilder>? metadata;
  final OmittedTypeBuilder returnType;
  final List<NominalVariableBuilder>? typeParameters;
  final List<FormalParameterBuilder>? formals;
  final String? nativeMethodName;
  final bool forAbstractClassOrMixin;
  Token? _beginInitializers;

  AbstractSourceConstructorBuilder? _builder;

  ConstructorFragment(
      {required this.name,
      required this.fileUri,
      required this.startCharOffset,
      required this.charOffset,
      required this.charOpenParenOffset,
      required this.charEndOffset,
      required this.modifiers,
      required this.metadata,
      required this.returnType,
      required this.typeParameters,
      required this.formals,
      required this.nativeMethodName,
      required this.forAbstractClassOrMixin,
      required Token? beginInitializers})
      : _beginInitializers = beginInitializers;

  Token? get beginInitializers {
    Token? result = _beginInitializers;
    // Ensure that we don't hold onto the token.
    _beginInitializers = null;
    return result;
  }

  @override
  AbstractSourceConstructorBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(AbstractSourceConstructorBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$charOffset)';
}

class FactoryFragment implements Fragment {
  final String name;
  final Uri fileUri;
  final int startCharOffset;
  final int charOffset;
  final int charOpenParenOffset;
  final int charEndOffset;
  final Modifiers modifiers;
  final List<MetadataBuilder>? metadata;
  final TypeBuilder returnType;
  final List<NominalVariableBuilder>? typeParameters;
  final List<FormalParameterBuilder>? formals;
  final AsyncMarker asyncModifier;
  final String? nativeMethodName;
  final ConstructorReferenceBuilder? redirectionTarget;

  SourceFactoryBuilder? _builder;

  FactoryFragment(
      {required this.name,
      required this.fileUri,
      required this.startCharOffset,
      required this.charOffset,
      required this.charOpenParenOffset,
      required this.charEndOffset,
      required this.modifiers,
      required this.metadata,
      required this.returnType,
      required this.typeParameters,
      required this.formals,
      required this.asyncModifier,
      required this.nativeMethodName,
      required this.redirectionTarget});

  @override
  SourceFactoryBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceFactoryBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$charOffset)';
}

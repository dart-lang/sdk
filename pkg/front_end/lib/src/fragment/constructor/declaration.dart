// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';

import '../../base/identifiers.dart';
import '../../base/local_scope.dart';
import '../../base/scope.dart';
import '../../builder/builder.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/metadata_builder.dart';
import '../../builder/type_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/internal_ast.dart';
import '../../kernel/kernel_helper.dart';
import '../../source/name_scheme.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_constructor_builder.dart';
import '../../source/source_extension_type_declaration_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_member_builder.dart';
import '../fragment.dart';
import 'encoding.dart';

abstract class ConstructorDeclaration {
  List<MetadataBuilder>? get metadata;

  OmittedTypeBuilder get returnType;

  List<NominalParameterBuilder>? get typeParameters;

  List<FormalParameterBuilder>? get formals;

  LookupScope get typeParameterScope;

  Member get constructor;

  Procedure? get tearOff;

  FunctionNode get function;

  Member get readTarget;

  Reference get readTargetReference;

  Member get invokeTarget;

  Reference get invokeTargetReference;

  void registerFunctionBody(Statement value);

  void registerNoBodyConstructor();

  VariableDeclaration? get thisVariable;

  List<TypeParameter>? get thisTypeParameters;

  List<Initializer> get initializers;

  void createNode({
    required String name,
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required Reference? constructorReference,
    required Reference? tearOffReference,
  });

  void buildOutlineNodes(
    BuildNodesCallback f, {
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required Member declarationConstructor,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  });

  void buildOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required bool createFileUriExpression,
  });

  void prepareInitializers();

  void prependInitializer(Initializer initializer);

  void becomeNative();

  /// Returns the [VariableDeclaration] for the [index]th formal parameter
  /// declared in the constructor.
  ///
  /// The synthetic parameters of enum constructor are *not* included, so index
  /// 0 zero of an enum constructor is the first user defined parameter.
  VariableDeclaration getFormalParameter(int index);

  /// Returns the [VariableDeclaration] for the tear off, if any, of the
  /// [index]th formal parameter declared in the constructor.
  VariableDeclaration? getTearOffParameter(int index);

  FormalParameterBuilder? getFormal(Identifier identifier);

  LocalScope computeFormalParameterInitializerScope(LocalScope parent);

  void finishAugmentation(SourceConstructorBuilder origin);

  Substitution computeFieldTypeSubstitution(
      DeclarationBuilder declarationBuilder);

  void buildBody();

  bool get isConst;

  bool get isExternal;

  bool get isRedirecting;

  bool get hasSuperInitializingFormals;

  void addSuperParameterDefaultValueCloners(
      {required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required Member superTarget,
      required List<int?>? positionalSuperParameters,
      required List<String>? namedSuperParameters,
      required SourceLibraryBuilder libraryBuilder});
}

mixin ConstructorDeclarationMixin implements ConstructorDeclaration {
  @override
  FormalParameterBuilder? getFormal(Identifier identifier) {
    if (formals != null) {
      for (FormalParameterBuilder formal in formals!) {
        if (formal.isWildcard &&
            identifier.name == '_' &&
            formal.fileOffset == identifier.nameOffset) {
          return formal;
        }
        if (formal.name == identifier.name &&
            formal.fileOffset == identifier.nameOffset) {
          return formal;
        }
      }
      // Coverage-ignore(suite): Not run.
      // If we have any formals we should find the one we're looking for.
      assert(false, "$identifier not found in $formals");
    }
    return null;
  }

  @override
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    // From
    // [dartLangSpec.tex](../../../../../../docs/language/dartLangSpec.tex) at
    // revision 94b23d3b125e9d246e07a2b43b61740759a0dace:
    //
    // When the formal parameter list of a non-redirecting generative
    // constructor contains any initializing formals, a new scope is
    // introduced, the _formal parameter initializer scope_, which is the
    // current scope of the initializer list of the constructor, and which is
    // enclosed in the scope where the constructor is declared.  Each
    // initializing formal in the formal parameter list introduces a final
    // local variable into the formal parameter initializer scope, but not into
    // the formal parameter scope; every other formal parameter introduces a
    // local variable into both the formal parameter scope and the formal
    // parameter initializer scope.

    if (formals == null) return parent;
    Map<String, Builder> local = {};
    for (FormalParameterBuilder formal in formals!) {
      // Wildcard initializing formal parameters do not introduce a local
      // variable in the initializer list.
      if (formal.isWildcard) continue;

      local[formal.name] = formal.forFormalParameterInitializerScope();
    }
    return parent.createNestedFixedScope(
        debugName: "formal parameter initializer",
        kind: ScopeKind.initializers,
        local: local);
  }
}

mixin RegularConstructorDeclarationMixin implements ConstructorDeclaration {
  RegularConstructorEncoding get _encoding;

  @override
  // Coverage-ignore(suite): Not run.
  Member get constructor => _encoding.constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Procedure? get tearOff => _encoding.constructorTearOff;

  @override
  FunctionNode get function => _encoding.function;

  @override
  Member get readTarget => _encoding.readTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _encoding.readTargetReference;

  @override
  Member get invokeTarget => _encoding.invokeTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _encoding.invokeTargetReference;

  @override
  void registerFunctionBody(Statement value) {
    _encoding.registerFunctionBody(value);
  }

  @override
  void registerNoBodyConstructor() {
    _encoding.registerNoBodyConstructor();
  }

  @override
  VariableDeclaration? get thisVariable => null;

  @override
  List<TypeParameter>? get thisTypeParameters => null;

  @override
  List<Initializer> get initializers => _encoding.initializers;

  @override
  void prepareInitializers() {
    _encoding.prepareInitializers();
  }

  @override
  void prependInitializer(Initializer initializer) {
    _encoding.prependInitializer(initializer);
  }

  @override
  void becomeNative() {
    _encoding.becomeNative();
  }

  @override
  VariableDeclaration getFormalParameter(int index) {
    return _encoding.getFormalParameter(index);
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _encoding.getTearOffParameter(index);
  }

  @override
  void finishAugmentation(SourceConstructorBuilder origin) {
    _encoding.finishAugmentation(origin);
  }

  @override
  Substitution computeFieldTypeSubstitution(
      DeclarationBuilder declarationBuilder) {
    // Nothing to substitute. Regular generative constructors don't have their
    // own type parameters.
    return Substitution.empty;
  }

  @override
  void buildBody() {}

  @override
  bool get isRedirecting {
    for (Initializer initializer in initializers) {
      if (initializer is RedirectingInitializer) {
        return true;
      }
    }
    return false;
  }

  @override
  late final bool hasSuperInitializingFormals =
      formals?.any((formal) => formal.isSuperInitializingFormal) ?? false;

  @override
  void addSuperParameterDefaultValueCloners(
      {required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required Member superTarget,
      required List<int?>? positionalSuperParameters,
      required List<String>? namedSuperParameters,
      required SourceLibraryBuilder libraryBuilder}) {
    _encoding.addSuperParameterDefaultValueCloners(
        delayedDefaultValueCloners: delayedDefaultValueCloners,
        superTarget: superTarget,
        positionalSuperParameters: positionalSuperParameters,
        namedSuperParameters: namedSuperParameters,
        libraryBuilder: libraryBuilder);
  }

  void _buildTypeParametersAndFormals({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required LookupScope typeParameterScope,
  }) {
    if (typeParameters != null) {
      for (int i = 0; i < typeParameters!.length; i++) {
        typeParameters![i].buildOutlineExpressions(libraryBuilder,
            bodyBuilderContext, classHierarchy, typeParameterScope);
      }
    }

    if (formals != null) {
      // For const constructors we need to include default parameter values
      // into the outline. For all other formals we need to call
      // buildOutlineExpressions to clear initializerToken to prevent
      // consuming too much memory.
      for (FormalParameterBuilder formal in formals!) {
        formal.buildOutlineExpressions(libraryBuilder, declarationBuilder,
            scope: typeParameterScope, buildDefaultValue: true);
      }
    }
  }
}

class RegularConstructorDeclaration
    with ConstructorDeclarationMixin, RegularConstructorDeclarationMixin
    implements ConstructorDeclaration {
  final ConstructorFragment _fragment;
  final List<FormalParameterBuilder>? _syntheticFormals;

  @override
  final RegularConstructorEncoding _encoding;

  @override
  final List<NominalParameterBuilder>? typeParameters;

  RegularConstructorDeclaration(this._fragment,
      {required List<FormalParameterBuilder>? syntheticFormals,
      required this.typeParameters,
      // TODO(johnniwinther): Create a separate [ConstructorDeclaration] for
      // enum constructors.
      required bool isEnumConstructor})
      : _syntheticFormals = syntheticFormals,
        _encoding = new RegularConstructorEncoding(
            isExternal: _fragment.modifiers.isExternal,
            isEnumConstructor: isEnumConstructor);

  @override
  LookupScope get typeParameterScope => _fragment.typeParameterScope;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  OmittedTypeBuilder get returnType => _fragment.returnType;

  @override
  late final List<FormalParameterBuilder>? formals = _syntheticFormals != null
      ? [..._syntheticFormals, ...?_fragment.formals]
      : _fragment.formals;

  @override
  bool get isConst => _fragment.modifiers.isConst;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  void createNode(
      {required String name,
      required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required Reference? constructorReference,
      required Reference? tearOffReference}) {
    _encoding.createNode(
        name: name,
        libraryBuilder: libraryBuilder,
        nameScheme: nameScheme,
        constructorReference: constructorReference,
        tearOffReference: tearOffReference,
        fileUri: _fragment.fileUri,
        startOffset: _fragment.startOffset,
        fileOffset: _fragment.fullNameOffset,
        endOffset: _fragment.endOffset,
        isSynthetic: false,
        forAbstractClassOrEnumOrMixin: _fragment.forAbstractClassOrMixin);
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f,
      {required SourceConstructorBuilder constructorBuilder,
      required SourceLibraryBuilder libraryBuilder,
      required Member declarationConstructor,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    _encoding.buildOutlineNodes(f,
        constructorBuilder: constructorBuilder,
        libraryBuilder: libraryBuilder,
        declarationBuilder:
            constructorBuilder.declarationBuilder as SourceClassBuilder,
        declarationConstructor: declarationConstructor,
        formalsOffset: _fragment.formalsOffset,
        isConst: _fragment.modifiers.isConst,
        returnType: returnType,
        typeParameters: typeParameters,
        formals: formals,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  void buildOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required bool createFileUriExpression,
  }) {
    for (Annotatable annotatable in annotatables) {
      MetadataBuilder.buildAnnotations(
          annotatable,
          _fragment.metadata,
          bodyBuilderContext,
          libraryBuilder,
          _fragment.fileUri,
          _fragment.enclosingScope,
          createFileUriExpression: createFileUriExpression);
    }
    _buildTypeParametersAndFormals(
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        typeParameterScope: _fragment.typeParameterScope);
  }
}

// Coverage-ignore(suite): Not run.
class PrimaryConstructorDeclaration
    with ConstructorDeclarationMixin, RegularConstructorDeclarationMixin
    implements ConstructorDeclaration {
  final PrimaryConstructorFragment _fragment;

  @override
  final RegularConstructorEncoding _encoding;

  PrimaryConstructorDeclaration(this._fragment)
      : _encoding = new RegularConstructorEncoding(
            isExternal: _fragment.modifiers.isExternal,
            isEnumConstructor: false);

  @override
  LookupScope get typeParameterScope => _fragment.typeParameterScope;

  @override
  OmittedTypeBuilder get returnType => _fragment.returnType;

  @override
  List<MetadataBuilder>? get metadata => null;

  @override
  List<FormalParameterBuilder>? get formals => _fragment.formals;

  @override
  List<NominalParameterBuilder>? get typeParameters => null;

  @override
  bool get isConst => _fragment.modifiers.isConst;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  void createNode(
      {required String name,
      required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required Reference? constructorReference,
      required Reference? tearOffReference}) {
    _encoding.createNode(
        name: name,
        libraryBuilder: libraryBuilder,
        nameScheme: nameScheme,
        constructorReference: constructorReference,
        tearOffReference: tearOffReference,
        fileUri: _fragment.fileUri,
        startOffset: _fragment.startOffset,
        fileOffset: _fragment.fileOffset,
        // TODO(johnniwinther): Provide `endOffset`.
        endOffset: _fragment.formalsOffset,
        isSynthetic: false,
        forAbstractClassOrEnumOrMixin: _fragment.forAbstractClassOrMixin);
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f,
      {required SourceConstructorBuilder constructorBuilder,
      required SourceLibraryBuilder libraryBuilder,
      required Member declarationConstructor,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    _encoding.buildOutlineNodes(f,
        constructorBuilder: constructorBuilder,
        libraryBuilder: libraryBuilder,
        declarationBuilder:
            constructorBuilder.declarationBuilder as SourceClassBuilder,
        declarationConstructor: declarationConstructor,
        formalsOffset: _fragment.formalsOffset,
        isConst: _fragment.modifiers.isConst,
        returnType: returnType,
        typeParameters: typeParameters,
        formals: formals,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  void buildOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required bool createFileUriExpression,
  }) {
    // There is no metadata on a primary constructor.
    _buildTypeParametersAndFormals(
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        typeParameterScope: _fragment.typeParameterScope);
  }
}

class DefaultEnumConstructorDeclaration
    with ConstructorDeclarationMixin, RegularConstructorDeclarationMixin
    implements ConstructorDeclaration {
  final Uri _fileUri;
  final int _fileOffset;

  @override
  final OmittedTypeBuilder returnType;

  @override
  final List<FormalParameterBuilder> formals;

  @override
  final RegularConstructorEncoding _encoding = new RegularConstructorEncoding(
      isExternal: false, isEnumConstructor: true);

  /// The scope in which to build the formal parameters.
  final LookupScope _lookupScope;

  DefaultEnumConstructorDeclaration(
      {required this.returnType,
      required this.formals,
      required Uri fileUri,
      required int fileOffset,
      required LookupScope lookupScope})
      : _fileUri = fileUri,
        _fileOffset = fileOffset,
        _lookupScope = lookupScope;

  @override
  LookupScope get typeParameterScope => _lookupScope;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => null;

  @override
  List<NominalParameterBuilder>? get typeParameters => null;

  @override
  bool get isConst => true;

  @override
  bool get isExternal => false;

  @override
  void createNode(
      {required String name,
      required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required Reference? constructorReference,
      required Reference? tearOffReference}) {
    _encoding.createNode(
        name: name,
        libraryBuilder: libraryBuilder,
        nameScheme: nameScheme,
        constructorReference: constructorReference,
        tearOffReference: tearOffReference,
        fileUri: _fileUri,
        startOffset: _fileOffset,
        fileOffset: _fileOffset,
        endOffset: _fileOffset,
        isSynthetic: true,
        forAbstractClassOrEnumOrMixin: true);
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f,
      {required SourceConstructorBuilder constructorBuilder,
      required SourceLibraryBuilder libraryBuilder,
      required Member declarationConstructor,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    _encoding.buildOutlineNodes(f,
        constructorBuilder: constructorBuilder,
        libraryBuilder: libraryBuilder,
        declarationBuilder:
            constructorBuilder.declarationBuilder as SourceClassBuilder,
        declarationConstructor: declarationConstructor,
        formalsOffset: _fileOffset,
        isConst: true,
        returnType: returnType,
        typeParameters: typeParameters,
        formals: formals,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  void buildOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required bool createFileUriExpression,
  }) {
    // There is no metadata on a default enum constructor.
    _buildTypeParametersAndFormals(
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        typeParameterScope: _lookupScope);
  }
}

mixin ExtensionTypeConstructorDeclarationMixin
    implements ConstructorDeclaration {
  ExtensionTypeConstructorEncoding get _encoding;

  @override
  // Coverage-ignore(suite): Not run.
  Member get constructor => _encoding.constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Procedure? get tearOff => _encoding.constructorTearOff;

  @override
  FunctionNode get function => _encoding.function;

  @override
  Member get readTarget => _encoding.readTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _encoding.readTargetReference;

  @override
  Member get invokeTarget => _encoding.invokeTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _encoding.invokeTargetReference;

  @override
  void registerFunctionBody(Statement value) {
    _encoding.registerFunctionBody(value);
  }

  @override
  void registerNoBodyConstructor() {
    _encoding.registerNoBodyConstructor();
  }

  @override
  VariableDeclaration? get thisVariable => _encoding.thisVariable;

  @override
  List<TypeParameter>? get thisTypeParameters => _encoding.thisTypeParameters;

  @override
  List<Initializer> get initializers => _encoding.initializers;

  @override
  void prepareInitializers() {
    _encoding.prepareInitializers();
  }

  @override
  void prependInitializer(Initializer initializer) {
    _encoding.prependInitializer(initializer);
  }

  @override
  void becomeNative() {
    throw new UnsupportedError("$runtimeType.becomeNative()");
  }

  @override
  VariableDeclaration getFormalParameter(int index) {
    return _encoding.getFormalParameter(index);
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _encoding.getTearOffParameter(index);
  }

  @override
  void finishAugmentation(SourceConstructorBuilder origin) {
    throw new UnsupportedError('$runtimeType.finishAugmentation');
  }

  @override
  Substitution computeFieldTypeSubstitution(
      DeclarationBuilder declarationBuilder) {
    if (typeParameters != null) {
      assert(
          declarationBuilder.typeParameters!.length == typeParameters?.length);
      return Substitution.fromPairs(
          (declarationBuilder as SourceExtensionTypeDeclarationBuilder)
              .extensionTypeDeclaration
              .typeParameters,
          new List<DartType>.generate(
              declarationBuilder.typeParameters!.length,
              (int index) => new TypeParameterType.withDefaultNullability(
                  function.typeParameters[index])));
    } else {
      return Substitution.empty;
    }
  }

  @override
  void buildBody() {
    _encoding.buildBody();
  }

  @override
  bool get isRedirecting {
    for (Initializer initializer in initializers) {
      if (initializer is ExtensionTypeRedirectingInitializer) {
        return true;
      }
    }
    return false;
  }

  @override
  late final bool hasSuperInitializingFormals =
      formals?.any((formal) => formal.isSuperInitializingFormal) ?? false;

  @override
  void addSuperParameterDefaultValueCloners(
      {required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required Member superTarget,
      required List<int?>? positionalSuperParameters,
      required List<String>? namedSuperParameters,
      required SourceLibraryBuilder libraryBuilder}) {
    throw new UnsupportedError(
        '$runtimeType.addSuperParameterDefaultValueCloners');
  }

  void _buildTypeParametersAndFormals({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required LookupScope typeParameterScope,
  }) {
    if (typeParameters != null) {
      for (int i = 0; i < typeParameters!.length; i++) {
        typeParameters![i].buildOutlineExpressions(libraryBuilder,
            bodyBuilderContext, classHierarchy, typeParameterScope);
      }
    }

    if (formals != null) {
      // For const constructors we need to include default parameter values
      // into the outline. For all other formals we need to call
      // buildOutlineExpressions to clear initializerToken to prevent
      // consuming too much memory.
      for (FormalParameterBuilder formal in formals!) {
        formal.buildOutlineExpressions(libraryBuilder, declarationBuilder,
            scope: typeParameterScope, buildDefaultValue: true);
      }
    }
  }
}

class ExtensionTypeConstructorDeclaration
    with ConstructorDeclarationMixin, ExtensionTypeConstructorDeclarationMixin
    implements ConstructorDeclaration {
  final ConstructorFragment _fragment;

  @override
  final List<NominalParameterBuilder>? typeParameters;

  @override
  final ExtensionTypeConstructorEncoding _encoding;

  ExtensionTypeConstructorDeclaration(this._fragment,
      {required this.typeParameters})
      : _encoding = new ExtensionTypeConstructorEncoding(
            isExternal: _fragment.modifiers.isExternal);

  @override
  LookupScope get typeParameterScope => _fragment.typeParameterScope;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  OmittedTypeBuilder get returnType => _fragment.returnType;

  @override
  List<FormalParameterBuilder>? get formals => _fragment.formals;

  @override
  bool get isConst => _fragment.modifiers.isConst;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  void createNode(
      {required String name,
      required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required Reference? constructorReference,
      required Reference? tearOffReference}) {
    _encoding.createNode(
        name: name,
        libraryBuilder: libraryBuilder,
        nameScheme: nameScheme,
        constructorReference: constructorReference,
        tearOffReference: tearOffReference,
        fileUri: _fragment.fileUri,
        fileOffset: _fragment.fullNameOffset,
        endOffset: _fragment.endOffset,
        forAbstractClassOrEnumOrMixin: _fragment.forAbstractClassOrMixin);
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f,
      {required SourceConstructorBuilder constructorBuilder,
      required SourceLibraryBuilder libraryBuilder,
      required Member declarationConstructor,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    _encoding.buildOutlineNodes(f,
        constructorBuilder: constructorBuilder,
        libraryBuilder: libraryBuilder,
        declarationBuilder: constructorBuilder.declarationBuilder
            as SourceExtensionTypeDeclarationBuilder,
        declarationConstructor: declarationConstructor,
        fileOffset: _fragment.fullNameOffset,
        formalsOffset: _fragment.formalsOffset,
        isConst: _fragment.modifiers.isConst,
        returnType: returnType,
        typeParameters: typeParameters,
        formals: formals,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  void buildOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required bool createFileUriExpression,
  }) {
    for (Annotatable annotatable in annotatables) {
      MetadataBuilder.buildAnnotations(
          annotatable,
          _fragment.metadata,
          bodyBuilderContext,
          libraryBuilder,
          _fragment.fileUri,
          _fragment.enclosingScope,
          createFileUriExpression: createFileUriExpression);
    }
    _buildTypeParametersAndFormals(
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        typeParameterScope: _fragment.typeParameterScope);
  }
}

class ExtensionTypePrimaryConstructorDeclaration
    with ConstructorDeclarationMixin, ExtensionTypeConstructorDeclarationMixin
    implements ConstructorDeclaration {
  final PrimaryConstructorFragment _fragment;

  @override
  final List<NominalParameterBuilder>? typeParameters;

  @override
  final ExtensionTypeConstructorEncoding _encoding;

  ExtensionTypePrimaryConstructorDeclaration(this._fragment,
      {required this.typeParameters})
      : _encoding = new ExtensionTypeConstructorEncoding(
            isExternal: _fragment.modifiers.isExternal);

  @override
  LookupScope get typeParameterScope => _fragment.typeParameterScope;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => null;

  @override
  OmittedTypeBuilder get returnType => _fragment.returnType;

  @override
  List<FormalParameterBuilder>? get formals => _fragment.formals;

  @override
  bool get isConst => _fragment.modifiers.isConst;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  void createNode(
      {required String name,
      required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required Reference? constructorReference,
      required Reference? tearOffReference}) {
    _encoding.createNode(
        name: name,
        libraryBuilder: libraryBuilder,
        nameScheme: nameScheme,
        constructorReference: constructorReference,
        tearOffReference: tearOffReference,
        fileUri: _fragment.fileUri,
        fileOffset: _fragment.fileOffset,
        // TODO(johnniwinther): Provide `endOffset`.
        endOffset: _fragment.formalsOffset,
        forAbstractClassOrEnumOrMixin: _fragment.forAbstractClassOrMixin);
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f,
      {required SourceConstructorBuilder constructorBuilder,
      required SourceLibraryBuilder libraryBuilder,
      required Member declarationConstructor,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    _encoding.buildOutlineNodes(f,
        constructorBuilder: constructorBuilder,
        libraryBuilder: libraryBuilder,
        declarationBuilder: constructorBuilder.declarationBuilder
            as SourceExtensionTypeDeclarationBuilder,
        declarationConstructor: declarationConstructor,
        fileOffset: _fragment.fileOffset,
        formalsOffset: _fragment.formalsOffset,
        isConst: _fragment.modifiers.isConst,
        returnType: returnType,
        typeParameters: typeParameters,
        formals: formals,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  void buildOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required bool createFileUriExpression,
  }) {
    // There is no metadata on a primary constructor.
    _buildTypeParametersAndFormals(
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        typeParameterScope: _fragment.typeParameterScope);
  }
}

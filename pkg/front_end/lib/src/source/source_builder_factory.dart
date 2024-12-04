// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:_fe_analyzer_shared/src/util/resolve_relative_uri.dart'
    show resolveRelativeUri;
import 'package:kernel/ast.dart' hide Combinator, MapLiteralEntry;
import 'package:kernel/names.dart' show indexSetName;
import 'package:kernel/reference_from_index.dart'
    show IndexedClass, IndexedLibrary;
import 'package:kernel/src/bounds_checks.dart' show VarianceCalculationValue;

import '../api_prototype/experimental_flags.dart';
import '../api_prototype/lowering_predicates.dart';
import '../base/combinator.dart' show CombinatorBuilder;
import '../base/configuration.dart' show Configuration;
import '../base/export.dart' show Export;
import '../base/identifiers.dart' show Identifier, QualifiedNameIdentifier;
import '../base/import.dart' show Import;
import '../base/messages.dart';
import '../base/modifiers.dart' show Modifiers;
import '../base/problems.dart' show internalProblem, unhandled;
import '../base/scope.dart';
import '../base/uris.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/library_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/mixin_application_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/synthesized_type_builder.dart';
import '../builder/type_builder.dart';
import '../builder/void_type_builder.dart';
import '../fragment/fragment.dart';
import '../util/local_stack.dart';
import 'builder_factory.dart';
import 'offset_map.dart';
import 'source_class_builder.dart' show SourceClassBuilder;
import 'source_enum_builder.dart';
import 'source_library_builder.dart';
import 'source_loader.dart' show SourceLoader;
import 'type_parameter_scope_builder.dart';

class BuilderFactoryImpl implements BuilderFactory, BuilderFactoryResult {
  final SourceCompilationUnit _compilationUnit;

  final ProblemReporting _problemReporting;

  /// The object used as the root for creating augmentation libraries.
  // TODO(johnniwinther): Remove this once parts support augmentations.
  final SourceCompilationUnit _augmentationRoot;

  final LibraryNameSpaceBuilder _libraryNameSpaceBuilder;

  /// Index of the library we use references for.
  final IndexedLibrary? indexedLibrary;

  String? _name;

  Uri? _partOfUri;

  String? _partOfName;

  List<MetadataBuilder>? _metadata;

  /// The part directives in this compilation unit.
  final List<Part> _parts = [];

  final List<LibraryPart> _libraryParts = [];

  @override
  final List<Import> imports = <Import>[];

  @override
  final List<Export> exports = <Export>[];

  /// Map from synthesized names used for omitted types to their corresponding
  /// synthesized type declarations.
  ///
  /// This is used in macro generated code to create type annotations from
  /// inferred types in the original code.
  final Map<String, Builder>? _omittedTypeDeclarationBuilders;

  /// Map from mixin application classes to their mixin types.
  ///
  /// This is used to check that super access in mixin declarations have a
  /// concrete target.
  Map<SourceClassBuilder, TypeBuilder>? _mixinApplications = {};

  final List<NominalParameterBuilder> _unboundNominalParameters = [];

  final List<StructuralParameterBuilder> _unboundStructuralVariables = [];

  final List<FactoryFragment> _nativeFactoryFragments = [];

  final List<GetterFragment> _nativeGetterFragments = [];

  final List<SetterFragment> _nativeSetterFragments = [];

  final List<MethodFragment> _nativeMethodFragments = [];

  final List<ConstructorFragment> _nativeConstructorFragments = [];

  final LookupScope _compilationUnitScope;

  /// Index for building unique lowered names for wildcard variables.
  int wildcardVariableIndex = 0;

  final LocalStack<TypeScope> _typeScopes;

  final LocalStack<NominalParameterNameSpace> _nominalParameterNameSpaces =
      new LocalStack([]);

  final LocalStack<Map<String, StructuralParameterBuilder>>
      _structuralParameterScopes = new LocalStack([]);

  final LocalStack<DeclarationFragment> _declarationFragments =
      new LocalStack([]);

  BuilderFactoryImpl(
      {required SourceCompilationUnit compilationUnit,
      required SourceCompilationUnit augmentationRoot,
      required LibraryNameSpaceBuilder libraryNameSpaceBuilder,
      required ProblemReporting problemReporting,
      required LookupScope scope,
      required IndexedLibrary? indexedLibrary,
      required Map<String, Builder>? omittedTypeDeclarationBuilders})
      : _compilationUnit = compilationUnit,
        _augmentationRoot = augmentationRoot,
        _libraryNameSpaceBuilder = libraryNameSpaceBuilder,
        _problemReporting = problemReporting,
        _compilationUnitScope = scope,
        indexedLibrary = indexedLibrary,
        _omittedTypeDeclarationBuilders = omittedTypeDeclarationBuilders,
        _typeScopes =
            new LocalStack([new TypeScope(TypeScopeKind.library, scope)]);

  SourceLoader get loader => _compilationUnit.loader;

  LibraryFeatures get libraryFeatures => _compilationUnit.libraryFeatures;

  final List<ConstructorReferenceBuilder> _constructorReferences = [];

  @override
  void beginClassOrNamedMixinApplicationHeader() {
    NominalParameterNameSpace nominalParameterNameSpace =
        new NominalParameterNameSpace();
    _nominalParameterNameSpaces.push(nominalParameterNameSpace);
    _typeScopes.push(new TypeScope(
        TypeScopeKind.declarationTypeParameters,
        new NominalParameterScope(
            _typeScopes.current.lookupScope, nominalParameterNameSpace),
        _typeScopes.current));
  }

  @override
  void beginClassDeclaration(String name, int nameOffset,
      List<NominalParameterBuilder>? typeParameters) {
    _declarationFragments.push(new ClassFragment(
        name,
        _compilationUnit.fileUri,
        nameOffset,
        typeParameters,
        _typeScopes.current.lookupScope,
        _nominalParameterNameSpaces.current));
  }

  @override
  void beginClassBody() {
    _typeScopes.push(new TypeScope(TypeScopeKind.classDeclaration,
        _declarationFragments.current.bodyScope, _typeScopes.current));
  }

  @override
  void endClassDeclaration(String name) {
    TypeScope bodyScope = _typeScopes.pop();
    assert(bodyScope.kind == TypeScopeKind.classDeclaration,
        "Unexpected type scope: $bodyScope.");
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.declarationTypeParameters,
        "Unexpected type scope: $typeParameterScope.");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void endClassDeclarationForParserRecovery(
      List<NominalParameterBuilder>? typeParameters) {
    TypeScope bodyScope = _typeScopes.pop();
    assert(bodyScope.kind == TypeScopeKind.classDeclaration,
        "Unexpected type scope: $bodyScope.");
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.declarationTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    _declarationFragments.pop();
    _nominalParameterNameSpaces.pop().addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: null, allowNameConflict: true);
  }

  @override
  void beginMixinDeclaration(String name, int nameOffset,
      List<NominalParameterBuilder>? typeParameters) {
    _declarationFragments.push(new MixinFragment(
        name,
        _compilationUnit.fileUri,
        nameOffset,
        typeParameters,
        _typeScopes.current.lookupScope,
        _nominalParameterNameSpaces.current));
  }

  @override
  void beginMixinBody() {
    _typeScopes.push(new TypeScope(TypeScopeKind.mixinDeclaration,
        _declarationFragments.current.bodyScope, _typeScopes.current));
  }

  @override
  void endMixinDeclaration(String name) {
    TypeScope bodyScope = _typeScopes.pop();
    assert(bodyScope.kind == TypeScopeKind.mixinDeclaration,
        "Unexpected type scope: $bodyScope.");
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.declarationTypeParameters,
        "Unexpected type scope: $typeParameterScope.");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void endMixinDeclarationForParserRecovery(
      List<NominalParameterBuilder>? typeParameters) {
    TypeScope bodyScope = _typeScopes.pop();
    assert(bodyScope.kind == TypeScopeKind.mixinDeclaration,
        "Unexpected type scope: $bodyScope.");
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.declarationTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    _declarationFragments.pop();
    _nominalParameterNameSpaces.pop().addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: null, allowNameConflict: true);
  }

  @override
  void beginNamedMixinApplication(String name, int charOffset,
      List<NominalParameterBuilder>? typeParameters) {}

  @override
  void endNamedMixinApplication(String name) {
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.declarationTypeParameters,
        "Unexpected type scope: $typeParameterScope.");
  }

  @override
  void endNamedMixinApplicationForParserRecovery(
      List<NominalParameterBuilder>? typeParameters) {
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.declarationTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    _nominalParameterNameSpaces.pop().addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: null, allowNameConflict: true);
  }

  @override
  void beginEnumDeclarationHeader(String name) {
    NominalParameterNameSpace nominalParameterNameSpace =
        new NominalParameterNameSpace();
    _nominalParameterNameSpaces.push(nominalParameterNameSpace);
    _typeScopes.push(new TypeScope(
        TypeScopeKind.declarationTypeParameters,
        new NominalParameterScope(
            _typeScopes.current.lookupScope, nominalParameterNameSpace),
        _typeScopes.current));
  }

  @override
  void beginEnumDeclaration(String name, int nameOffset,
      List<NominalParameterBuilder>? typeParameters) {
    _declarationFragments.push(new EnumFragment(
        name,
        _compilationUnit.fileUri,
        nameOffset,
        typeParameters,
        _typeScopes.current.lookupScope,
        _nominalParameterNameSpaces.current));
  }

  @override
  void beginEnumBody() {
    _typeScopes.push(new TypeScope(TypeScopeKind.enumDeclaration,
        _declarationFragments.current.bodyScope, _typeScopes.current));
  }

  @override
  void endEnumDeclaration(String name) {
    TypeScope bodyScope = _typeScopes.pop();
    assert(bodyScope.kind == TypeScopeKind.enumDeclaration,
        "Unexpected type scope: $bodyScope.");
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.declarationTypeParameters,
        "Unexpected type scope: $typeParameterScope.");
  }

  @override
  void endEnumDeclarationForParserRecovery(
      List<NominalParameterBuilder>? typeParameters) {
    TypeScope bodyScope = _typeScopes.pop();
    assert(bodyScope.kind == TypeScopeKind.enumDeclaration,
        "Unexpected type scope: $bodyScope.");
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.declarationTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    _declarationFragments.pop();
    _nominalParameterNameSpaces.pop().addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: null, allowNameConflict: true);
  }

  @override
  void beginExtensionOrExtensionTypeHeader() {
    NominalParameterNameSpace nominalParameterNameSpace =
        new NominalParameterNameSpace();
    _nominalParameterNameSpaces.push(nominalParameterNameSpace);
    _typeScopes.push(new TypeScope(
        TypeScopeKind.declarationTypeParameters,
        new NominalParameterScope(
            _typeScopes.current.lookupScope, nominalParameterNameSpace),
        _typeScopes.current));
  }

  @override
  void beginExtensionDeclaration(String? name, int charOffset,
      List<NominalParameterBuilder>? typeParameters) {
    _declarationFragments.push(new ExtensionFragment(
        name,
        _compilationUnit.fileUri,
        charOffset,
        typeParameters,
        _typeScopes.current.lookupScope,
        _nominalParameterNameSpaces.current));
  }

  @override
  void beginExtensionBody() {
    ExtensionFragment declarationFragment =
        _declarationFragments.current as ExtensionFragment;
    _typeScopes.push(new TypeScope(TypeScopeKind.extensionDeclaration,
        declarationFragment.bodyScope, _typeScopes.current));
  }

  @override
  void endExtensionDeclaration(String? name) {
    TypeScope bodyScope = _typeScopes.pop();
    assert(bodyScope.kind == TypeScopeKind.extensionDeclaration,
        "Unexpected type scope: $bodyScope.");
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.declarationTypeParameters,
        "Unexpected type scope: $typeParameterScope.");
  }

  @override
  void beginExtensionTypeDeclaration(String name, int nameOffset,
      List<NominalParameterBuilder>? typeParameters) {
    _declarationFragments.push(new ExtensionTypeFragment(
        name,
        _compilationUnit.fileUri,
        nameOffset,
        typeParameters,
        _typeScopes.current.lookupScope,
        _nominalParameterNameSpaces.current));
  }

  @override
  void beginExtensionTypeBody() {
    _typeScopes.push(new TypeScope(TypeScopeKind.extensionTypeDeclaration,
        _declarationFragments.current.bodyScope, _typeScopes.current));
  }

  @override
  void endExtensionTypeDeclaration(String name) {
    TypeScope bodyScope = _typeScopes.pop();
    assert(bodyScope.kind == TypeScopeKind.extensionTypeDeclaration,
        "Unexpected type scope: $bodyScope.");
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.declarationTypeParameters,
        "Unexpected type scope: $typeParameterScope.");
  }

  @override
  void beginFactoryMethod() {
    NominalParameterNameSpace nominalParameterNameSpace =
        new NominalParameterNameSpace();
    _nominalParameterNameSpaces.push(nominalParameterNameSpace);
    _typeScopes.push(new TypeScope(
        TypeScopeKind.memberTypeParameters,
        new NominalParameterScope(
            _typeScopes.current.lookupScope, nominalParameterNameSpace),
        _typeScopes.current));
  }

  @override
  // Coverage-ignore(suite): Not run.
  void endFactoryMethodForParserRecovery() {
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.memberTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    _nominalParameterNameSpaces.pop().addTypeParameters(_problemReporting, null,
        ownerName: null, allowNameConflict: true);
  }

  @override
  void beginConstructor() {
    NominalParameterNameSpace nominalParameterNameSpace =
        new NominalParameterNameSpace();
    _nominalParameterNameSpaces.push(nominalParameterNameSpace);
    _typeScopes.push(new TypeScope(
        TypeScopeKind.memberTypeParameters,
        new NominalParameterScope(
            _typeScopes.current.lookupScope, nominalParameterNameSpace),
        _typeScopes.current));
  }

  @override
  void endConstructorForParserRecovery(
      List<NominalParameterBuilder>? typeParameters) {
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.memberTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    _nominalParameterNameSpaces.pop().addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: null, allowNameConflict: true);
  }

  @override
  void beginStaticMethod() {
    NominalParameterNameSpace nominalParameterNameSpace =
        new NominalParameterNameSpace();
    _nominalParameterNameSpaces.push(nominalParameterNameSpace);
    _typeScopes.push(new TypeScope(
        TypeScopeKind.memberTypeParameters,
        new NominalParameterScope(
            _typeScopes.current.lookupScope, nominalParameterNameSpace),
        _typeScopes.current));
  }

  @override
  // Coverage-ignore(suite): Not run.
  void endStaticMethodForParserRecovery(
      List<NominalParameterBuilder>? typeParameters) {
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.memberTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    _nominalParameterNameSpaces.pop().addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: null, allowNameConflict: true);
  }

  @override
  void beginInstanceMethod() {
    NominalParameterNameSpace nominalParameterNameSpace =
        new NominalParameterNameSpace();
    _nominalParameterNameSpaces.push(nominalParameterNameSpace);
    _typeScopes.push(new TypeScope(
        TypeScopeKind.memberTypeParameters,
        new NominalParameterScope(
            _typeScopes.current.lookupScope, nominalParameterNameSpace),
        _typeScopes.current));
  }

  @override
  void endInstanceMethodForParserRecovery(
      List<NominalParameterBuilder>? typeParameters) {
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.memberTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    _nominalParameterNameSpaces.pop().addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: null, allowNameConflict: true);
  }

  @override
  void beginTopLevelMethod() {
    NominalParameterNameSpace nominalParameterNameSpace =
        new NominalParameterNameSpace();
    _nominalParameterNameSpaces.push(nominalParameterNameSpace);
    _typeScopes.push(new TypeScope(
        TypeScopeKind.memberTypeParameters,
        new NominalParameterScope(
            _typeScopes.current.lookupScope, nominalParameterNameSpace),
        _typeScopes.current));
  }

  @override
  void endTopLevelMethodForParserRecovery(
      List<NominalParameterBuilder>? typeParameters) {
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.memberTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    _nominalParameterNameSpaces.pop().addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: null, allowNameConflict: true);
  }

  @override
  void beginTypedef() {
    NominalParameterNameSpace nominalParameterNameSpace =
        new NominalParameterNameSpace();
    _nominalParameterNameSpaces.push(nominalParameterNameSpace);
    _typeScopes.push(new TypeScope(
        TypeScopeKind.declarationTypeParameters,
        new NominalParameterScope(
            _typeScopes.current.lookupScope, nominalParameterNameSpace),
        _typeScopes.current));
  }

  @override
  void endTypedef() {
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.declarationTypeParameters,
        "Unexpected type scope: $typeParameterScope.");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void endTypedefForParserRecovery(
      List<NominalParameterBuilder>? typeParameters) {
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.declarationTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    _nominalParameterNameSpaces.pop().addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: null, allowNameConflict: true);
  }

  @override
  void beginFunctionType() {
    Map<String, StructuralParameterBuilder> structuralParameterScope = {};
    _structuralParameterScopes.push(structuralParameterScope);
    _typeScopes.push(new TypeScope(
        TypeScopeKind.functionTypeParameters,
        new TypeParameterScope(
            _typeScopes.current.lookupScope, structuralParameterScope),
        _typeScopes.current));
  }

  @override
  void endFunctionType() {
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.functionTypeParameters,
        "Unexpected type scope: $typeParameterScope.");
  }

  @override
  void checkStacks() {
    assert(
        _typeScopes.isSingular,
        "Unexpected type scope stack: "
        "$_typeScopes.");
    assert(
        _declarationFragments.isEmpty,
        "Unexpected declaration fragment stack: "
        "$_declarationFragments.");
    assert(
        _nominalParameterNameSpaces.isEmpty,
        "Unexpected nominal parameter name space stack : "
        "$_nominalParameterNameSpaces.");
    assert(
        _structuralParameterScopes.isEmpty,
        "Unexpected structural parameter scope stack : "
        "$_structuralParameterScopes.");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void registerUnboundStructuralParameters(
      List<StructuralParameterBuilder> variableBuilders) {
    _unboundStructuralVariables.addAll(variableBuilders);
  }

  Uri _resolve(Uri baseUri, String? uri, int uriOffset, {isPart = false}) {
    if (uri == null) {
      // Coverage-ignore-block(suite): Not run.
      _problemReporting.addProblem(
          messageExpectedUri, uriOffset, noLength, _compilationUnit.fileUri);
      return new Uri(scheme: MALFORMED_URI_SCHEME);
    }
    Uri parsedUri;
    try {
      parsedUri = Uri.parse(uri);
    } on FormatException catch (e) {
      // Point to position in string indicated by the exception,
      // or to the initial quote if no position is given.
      // (Assumes the directive is using a single-line string.)
      _problemReporting.addProblem(
          templateCouldNotParseUri.withArguments(uri, e.message),
          uriOffset +
              1 +
              (e.offset ?? // Coverage-ignore(suite): Not run.
                  -1),
          1,
          _compilationUnit.fileUri);
      return new Uri(
          scheme: MALFORMED_URI_SCHEME, query: Uri.encodeQueryComponent(uri));
    }
    if (isPart && baseUri.isScheme("dart")) {
      // Coverage-ignore-block(suite): Not run.
      // Resolve using special rules for dart: URIs
      return resolveRelativeUri(baseUri, parsedUri);
    } else {
      return baseUri.resolveUri(parsedUri);
    }
  }

  @override
  void addPart(OffsetMap offsetMap, Token partKeyword,
      List<MetadataBuilder>? metadata, String uri, int charOffset) {
    Uri resolvedUri =
        _resolve(_compilationUnit.importUri, uri, charOffset, isPart: true);
    // To support absolute paths from within packages in the part uri, we try to
    // translate the file uri from the resolved import uri before resolving
    // through the file uri of this library. See issue #52964.
    Uri newFileUri = loader.target.uriTranslator.translate(resolvedUri) ??
        _resolve(_compilationUnit.fileUri, uri, charOffset);
    CompilationUnit compilationUnit = loader.read(resolvedUri, charOffset,
        origin: _compilationUnit.isAugmenting ? _augmentationRoot : null,
        originImportUri: _compilationUnit.originImportUri,
        fileUri: newFileUri,
        accessor: _compilationUnit,
        isPatch: _compilationUnit.isAugmenting,
        referencesFromIndex: indexedLibrary,
        referenceIsPartOwner: indexedLibrary != null);
    _parts.add(new Part(charOffset, compilationUnit));

    // TODO(ahe): [metadata] should be stored, evaluated, and added to [part].
    LibraryPart part = new LibraryPart(<Expression>[], uri)
      ..fileOffset = charOffset;
    _libraryParts.add(part);
    offsetMap.registerPart(partKeyword, part);
  }

  @override
  void addPartOf(List<MetadataBuilder>? metadata, String? name, String? uri,
      int uriOffset) {
    _partOfName = name;
    if (uri != null) {
      Uri resolvedUri =
          _partOfUri = _resolve(_compilationUnit.importUri, uri, uriOffset);
      // To support absolute paths from within packages in the part of uri, we
      // try to translate the file uri from the resolved import uri before
      // resolving through the file uri of this library. See issue #52964.
      Uri newFileUri = loader.target.uriTranslator.translate(resolvedUri) ??
          _resolve(_compilationUnit.fileUri, uri, uriOffset);
      loader.read(partOfUri!, uriOffset,
          fileUri: newFileUri, accessor: _compilationUnit);
    }
    if (_scriptTokenOffset != null) {
      _problemReporting.addProblem(messageScriptTagInPartFile,
          _scriptTokenOffset!, noLength, _compilationUnit.fileUri);
    }
  }

  /// Offset of the first script tag (`#!...`) in this library or part.
  int? _scriptTokenOffset;

  @override
  void addScriptToken(int charOffset) {
    _scriptTokenOffset ??= charOffset;
  }

  @override
  void addImport(
      {OffsetMap? offsetMap,
      Token? importKeyword,
      required List<MetadataBuilder>? metadata,
      required bool isAugmentationImport,
      required String uri,
      required List<Configuration>? configurations,
      required String? prefix,
      required List<CombinatorBuilder>? combinators,
      required bool deferred,
      required int charOffset,
      required int prefixCharOffset,
      required int uriOffset}) {
    if (configurations != null) {
      for (Configuration config in configurations) {
        if (loader.getLibrarySupportValue(config.dottedName) ==
            config.condition) {
          uri = config.importUri;
          break;
        }
      }
    }

    CompilationUnit? compilationUnit = null;
    Uri? resolvedUri;
    String? nativePath;
    const String nativeExtensionScheme = "dart-ext:";
    if (uri.startsWith(nativeExtensionScheme)) {
      _problemReporting.addProblem(messageUnsupportedDartExt, charOffset,
          noLength, _compilationUnit.fileUri);
      String strippedUri = uri.substring(nativeExtensionScheme.length);
      if (strippedUri.startsWith("package")) {
        // Coverage-ignore-block(suite): Not run.
        resolvedUri = _resolve(_compilationUnit.importUri, strippedUri,
            uriOffset + nativeExtensionScheme.length);
        resolvedUri = loader.target.translateUri(resolvedUri);
        nativePath = resolvedUri.toString();
      } else {
        resolvedUri = new Uri(scheme: "dart-ext", pathSegments: [uri]);
        nativePath = uri;
      }
    } else {
      resolvedUri = _resolve(_compilationUnit.importUri, uri, uriOffset);
      compilationUnit = loader.read(resolvedUri, uriOffset,
          origin: isAugmentationImport ? _augmentationRoot : null,
          accessor: _compilationUnit,
          isAugmentation: isAugmentationImport,
          referencesFromIndex: isAugmentationImport ? indexedLibrary : null);
    }

    Import import = new Import(
        _compilationUnit,
        compilationUnit,
        isAugmentationImport,
        deferred,
        prefix,
        combinators,
        configurations,
        _compilationUnit.fileUri,
        charOffset,
        prefixCharOffset,
        nativeImportPath: nativePath);
    imports.add(import);
    offsetMap?.registerImport(importKeyword!, import);
  }

  @override
  void addExport(
      OffsetMap offsetMap,
      Token exportKeyword,
      List<MetadataBuilder>? metadata,
      String uri,
      List<Configuration>? configurations,
      List<CombinatorBuilder>? combinators,
      int charOffset,
      int uriOffset) {
    if (configurations != null) {
      // Coverage-ignore-block(suite): Not run.
      for (Configuration config in configurations) {
        if (loader.getLibrarySupportValue(config.dottedName) ==
            config.condition) {
          uri = config.importUri;
          break;
        }
      }
    }

    CompilationUnit exportedLibrary = loader.read(
        _resolve(_compilationUnit.importUri, uri, uriOffset), charOffset,
        accessor: _compilationUnit);
    exportedLibrary.addExporter(_compilationUnit, combinators, charOffset);
    Export export =
        new Export(_compilationUnit, exportedLibrary, combinators, charOffset);
    exports.add(export);
    offsetMap.registerExport(exportKeyword, export);
  }

  @override
  void addClass(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier identifier,
      required List<NominalParameterBuilder>? typeParameters,
      required TypeBuilder? supertype,
      required MixinApplicationBuilder? mixins,
      required List<TypeBuilder>? interfaces,
      required int startOffset,
      required int nameOffset,
      required int endOffset,
      required int supertypeOffset}) {
    String className = identifier.name;

    endClassDeclaration(className);

    ClassFragment declarationFragment =
        _declarationFragments.pop() as ClassFragment;

    NominalParameterNameSpace nominalParameterNameSpace =
        _nominalParameterNameSpaces.pop();
    nominalParameterNameSpace.addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: className, allowNameConflict: false);

    if (declarationFragment.declaresConstConstructor) {
      modifiers |= Modifiers.DeclaresConstConstructor;
    }

    declarationFragment.compilationUnitScope = _compilationUnitScope;
    declarationFragment.metadata = metadata;
    declarationFragment.modifiers = modifiers;
    declarationFragment.supertype = supertype;
    declarationFragment.mixins = mixins;
    declarationFragment.interfaces = interfaces;
    declarationFragment.constructorReferences =
        new List<ConstructorReferenceBuilder>.of(_constructorReferences);
    declarationFragment.startOffset = startOffset;
    declarationFragment.endOffset = endOffset;

    _constructorReferences.clear();

    _addFragment(declarationFragment);
    offsetMap.registerNamedDeclarationFragment(identifier, declarationFragment);
  }

  @override
  void addEnum(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Identifier identifier,
      required List<NominalParameterBuilder>? typeParameters,
      required MixinApplicationBuilder? supertypeBuilder,
      required List<TypeBuilder>? interfaceBuilders,
      required List<EnumConstantInfo?>? enumConstantInfos,
      required int startOffset,
      required int endOffset}) {
    String name = identifier.name;

    // Nested declaration began in `OutlineBuilder.beginEnum`.
    endEnumDeclaration(name);

    EnumFragment declarationFragment =
        _declarationFragments.pop() as EnumFragment;

    NominalParameterNameSpace nominalParameterNameSpace =
        _nominalParameterNameSpaces.pop();
    nominalParameterNameSpace.addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: name, allowNameConflict: false);

    declarationFragment.compilationUnitScope = _compilationUnitScope;
    declarationFragment.metadata = metadata;
    declarationFragment.supertypeBuilder = supertypeBuilder;
    declarationFragment.interfaces = interfaceBuilders;
    declarationFragment.enumConstantInfos = enumConstantInfos;
    declarationFragment.constructorReferences =
        new List<ConstructorReferenceBuilder>.of(_constructorReferences);
    declarationFragment.startOffset = startOffset;
    declarationFragment.endOffset = endOffset;

    _constructorReferences.clear();

    _addFragment(declarationFragment);

    offsetMap.registerNamedDeclarationFragment(identifier, declarationFragment);
  }

  @override
  void addMixinDeclaration(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier identifier,
      required List<NominalParameterBuilder>? typeParameters,
      required List<TypeBuilder>? supertypeConstraints,
      required List<TypeBuilder>? interfaces,
      required int startOffset,
      required int nameOffset,
      required int endOffset}) {
    TypeBuilder? supertype;
    MixinApplicationBuilder? mixinApplication;
    if (supertypeConstraints != null && supertypeConstraints.isNotEmpty) {
      supertype = supertypeConstraints.first;
      if (supertypeConstraints.length > 1) {
        mixinApplication = new MixinApplicationBuilder(
            supertypeConstraints.skip(1).toList(),
            supertype.fileUri!,
            supertype.charOffset!);
      }
    }

    String className = identifier.name;
    endMixinDeclaration(className);

    MixinFragment declarationFragment =
        _declarationFragments.pop() as MixinFragment;

    NominalParameterNameSpace nominalParameterNameSpace =
        _nominalParameterNameSpaces.pop();
    nominalParameterNameSpace.addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: className, allowNameConflict: false);

    modifiers |= Modifiers.Abstract;
    if (declarationFragment.declaresConstConstructor) {
      modifiers |= Modifiers.DeclaresConstConstructor;
    }

    declarationFragment.compilationUnitScope = _compilationUnitScope;
    declarationFragment.metadata = metadata;
    declarationFragment.modifiers = modifiers;
    declarationFragment.supertype = supertype;
    declarationFragment.mixins = mixinApplication;
    declarationFragment.interfaces = interfaces;
    declarationFragment.constructorReferences =
        new List<ConstructorReferenceBuilder>.of(_constructorReferences);
    declarationFragment.startOffset = startOffset;
    declarationFragment.endOffset = endOffset;

    _constructorReferences.clear();

    _addFragment(declarationFragment);

    offsetMap.registerNamedDeclarationFragment(identifier, declarationFragment);
  }

  @override
  MixinApplicationBuilder addMixinApplication(
      List<TypeBuilder> mixins, int charOffset) {
    return new MixinApplicationBuilder(
        mixins, _compilationUnit.fileUri, charOffset);
  }

  @override
  void addNamedMixinApplication(
      {required List<MetadataBuilder>? metadata,
      required String name,
      required List<NominalParameterBuilder>? typeParameters,
      required Modifiers modifiers,
      required TypeBuilder? supertype,
      required MixinApplicationBuilder mixinApplication,
      required List<TypeBuilder>? interfaces,
      required int startOffset,
      required int nameOffset,
      required int endOffset}) {
    // Nested declaration began in `OutlineBuilder.beginNamedMixinApplication`.
    endNamedMixinApplication(name);

    assert(
        _mixinApplications != null, "Late registration of mixin application.");

    _nominalParameterNameSpaces.pop().addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: name, allowNameConflict: false);

    _addFragment(new NamedMixinApplicationFragment(
        name: name,
        fileUri: _compilationUnit.fileUri,
        startOffset: startOffset,
        nameOffset: nameOffset,
        endOffset: endOffset,
        modifiers: modifiers,
        metadata: metadata,
        typeParameters: typeParameters,
        supertype: supertype,
        mixins: mixinApplication,
        interfaces: interfaces,
        compilationUnitScope: _compilationUnitScope));
  }

  static TypeBuilder? applyMixins(
      {required ProblemReporting problemReporting,
      required SourceLibraryBuilder enclosingLibraryBuilder,
      required List<NominalParameterBuilder> unboundNominalParameters,
      required TypeBuilder? supertype,
      required MixinApplicationBuilder? mixinApplicationBuilder,
      required int startOffset,
      required int nameOffset,
      required int endOffset,
      required String subclassName,
      required bool isMixinDeclaration,
      required IndexedLibrary? indexedLibrary,
      required LookupScope compilationUnitScope,
      required Map<SourceClassBuilder, TypeBuilder> mixinApplications,
      required Uri fileUri,
      List<MetadataBuilder>? metadata,
      String? name,
      List<NominalParameterBuilder>? typeParameters,
      required Modifiers modifiers,
      List<TypeBuilder>? interfaces,
      required TypeBuilder objectTypeBuilder,
      required void Function(String name, Builder declaration, int charOffset,
              {Reference? getterReference})
          addBuilder}) {
    if (name == null) {
      // The following parameters should only be used when building a named
      // mixin application.
      if (metadata != null) {
        unhandled("metadata", "unnamed mixin application", nameOffset, fileUri);
      } else if (interfaces != null) {
        unhandled(
            "interfaces", "unnamed mixin application", nameOffset, fileUri);
      }
    }
    if (mixinApplicationBuilder != null) {
      // Documentation below assumes the given mixin application is in one of
      // these forms:
      //
      //     class C extends S with M1, M2, M3;
      //     class Named = S with M1, M2, M3;
      //
      // When we refer to the subclass, we mean `C` or `Named`.

      /// The current supertype.
      ///
      /// Starts out having the value `S` and on each iteration of the loop
      /// below, it will take on the value corresponding to:
      ///
      /// 1. `S with M1`.
      /// 2. `(S with M1) with M2`.
      /// 3. `((S with M1) with M2) with M3`.
      supertype ??= objectTypeBuilder;

      /// The variable part of the mixin application's synthetic name. It
      /// starts out as the name of the superclass, but is only used after it
      /// has been combined with the name of the current mixin. In the examples
      /// from above, it will take these values:
      ///
      /// 1. `S&M1`
      /// 2. `S&M1&M2`
      /// 3. `S&M1&M2&M3`.
      ///
      /// The full name of the mixin application is obtained by prepending the
      /// name of the subclass (`C` or `Named` in the above examples) to the
      /// running name. For the example `C`, that leads to these full names:
      ///
      /// 1. `_C&S&M1`
      /// 2. `_C&S&M1&M2`
      /// 3. `_C&S&M1&M2&M3`.
      ///
      /// For a named mixin application, the last name has been given by the
      /// programmer, so for the example `Named` we see these full names:
      ///
      /// 1. `_Named&S&M1`
      /// 2. `_Named&S&M1&M2`
      /// 3. `Named`.
      String runningName;
      if (supertype.typeName == null) {
        assert(supertype is FunctionTypeBuilder);

        // Function types don't have names, and we can supply any string that
        // doesn't have to be unique. The actual supertype of the mixin will
        // not be built in that case.
        runningName = "";
      } else {
        runningName = supertype.typeName!.name;
      }

      /// True when we're building a named mixin application. Notice that for
      /// the `Named` example above, this is only true on the last
      /// iteration because only the full mixin application is named.
      bool isNamedMixinApplication;

      /// The names of the type parameters of the subclass.
      Set<String>? typeParameterNames;
      if (typeParameters != null) {
        typeParameterNames = new Set<String>();
        for (NominalParameterBuilder typeParameter in typeParameters) {
          typeParameterNames.add(typeParameter.name);
        }
      }

      /// Iterate over the mixins from left to right. At the end of each
      /// iteration, a new [supertype] is computed that is the mixin
      /// application of [supertype] with the current mixin.
      for (int i = 0; i < mixinApplicationBuilder.mixins.length; i++) {
        TypeBuilder mixin = mixinApplicationBuilder.mixins[i];
        isNamedMixinApplication =
            name != null && mixin == mixinApplicationBuilder.mixins.last;
        bool isGeneric = false;
        if (!isNamedMixinApplication) {
          if (typeParameterNames != null) {
            if (supertype != null) {
              isGeneric =
                  isGeneric || supertype.usesTypeParameters(typeParameterNames);
            }
            isGeneric =
                isGeneric || mixin.usesTypeParameters(typeParameterNames);
          }
          TypeName? typeName = mixin.typeName;
          if (typeName != null) {
            runningName += "&${typeName.name}";
          }
        }
        String fullname =
            isNamedMixinApplication ? name : "_$subclassName&$runningName";
        List<NominalParameterBuilder>? applicationTypeParameters;
        List<TypeBuilder>? applicationTypeArguments;
        if (isNamedMixinApplication) {
          // If this is a named mixin application, it must be given all the
          // declared type parameters.
          applicationTypeParameters = typeParameters;
        } else {
          // Otherwise, we pass the fresh type parameters to the mixin
          // application in the same order as they're declared on the subclass.
          if (isGeneric) {
            NominalParameterNameSpace nominalParameterNameSpace =
                new NominalParameterNameSpace();

            NominalParameterCopy nominalVariableCopy = copyTypeParameters(
                unboundNominalParameters, typeParameters,
                kind: TypeParameterKind.extensionSynthesized,
                instanceTypeParameterAccess:
                    InstanceTypeParameterAccessState.Allowed)!;

            applicationTypeParameters =
                nominalVariableCopy.newParameterBuilders;
            Map<NominalParameterBuilder, NominalParameterBuilder>
                newToOldVariableMap = nominalVariableCopy.newToOldParameterMap;

            Map<NominalParameterBuilder, TypeBuilder> substitutionMap =
                nominalVariableCopy.substitutionMap;

            applicationTypeArguments = [];
            for (NominalParameterBuilder typeParameter in typeParameters!) {
              TypeBuilder applicationTypeArgument =
                  new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
                      // The type parameter types passed as arguments to the
                      // generic class representing the anonymous mixin
                      // application should refer back to the type parameters of
                      // the class that extend the anonymous mixin application.
                      typeParameter,
                      const NullabilityBuilder.omitted(),
                      fileUri: fileUri,
                      charOffset: nameOffset,
                      instanceTypeParameterAccess:
                          InstanceTypeParameterAccessState.Allowed);
              applicationTypeArguments.add(applicationTypeArgument);
            }
            nominalParameterNameSpace.addTypeParameters(
                problemReporting, applicationTypeParameters,
                ownerName: fullname, allowNameConflict: true);
            if (supertype != null) {
              supertype = new SynthesizedTypeBuilder(
                  supertype, newToOldVariableMap, substitutionMap);
            }
            mixin = new SynthesizedTypeBuilder(
                mixin, newToOldVariableMap, substitutionMap);
          }
        }
        final int computedStartOffset =
            !isNamedMixinApplication || metadata == null
                ? startOffset
                : metadata.first.atOffset;

        IndexedClass? referencesFromIndexedClass;
        if (indexedLibrary != null) {
          referencesFromIndexedClass =
              indexedLibrary.lookupIndexedClass(fullname);
        }

        LookupScope typeParameterScope =
            TypeParameterScope.fromList(compilationUnitScope, typeParameters);
        DeclarationNameSpaceBuilder nameSpaceBuilder =
            new DeclarationNameSpaceBuilder.empty();
        SourceClassBuilder application = new SourceClassBuilder(
            metadata: isNamedMixinApplication ? metadata : null,
            modifiers: isNamedMixinApplication
                ? modifiers | Modifiers.NamedMixinApplication
                : Modifiers.Abstract,
            name: fullname,
            typeParameters: applicationTypeParameters,
            supertypeBuilder: isMixinDeclaration ? null : supertype,
            interfaceBuilders: isNamedMixinApplication
                ? interfaces
                : isMixinDeclaration
                    ? [supertype!, mixin]
                    : null,
            onTypes: null,
            typeParameterScope: typeParameterScope,
            nameSpaceBuilder: nameSpaceBuilder,
            libraryBuilder: enclosingLibraryBuilder,
            constructorReferences: <ConstructorReferenceBuilder>[],
            fileUri: fileUri,
            startOffset: computedStartOffset,
            nameOffset: nameOffset,
            endOffset: endOffset,
            indexedClass: referencesFromIndexedClass,
            mixedInTypeBuilder: isMixinDeclaration ? null : mixin);
        // TODO(ahe, kmillikin): Should always be true?
        // pkg/analyzer/test/src/summary/resynthesize_kernel_test.dart can't
        // handle that :(
        application.cls.isAnonymousMixin = !isNamedMixinApplication;
        addBuilder(fullname, application, nameOffset,
            getterReference: referencesFromIndexedClass?.reference);
        supertype = new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
            application, const NullabilityBuilder.omitted(),
            arguments: applicationTypeArguments,
            fileUri: fileUri,
            charOffset: nameOffset,
            instanceTypeParameterAccess:
                InstanceTypeParameterAccessState.Allowed);
        mixinApplications[application] = mixin;
      }
      return supertype;
    } else {
      return supertype;
    }
  }

  @override
  void addExtensionDeclaration(
      {required OffsetMap offsetMap,
      required Token beginToken,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier? identifier,
      required List<NominalParameterBuilder>? typeParameters,
      required TypeBuilder onType,
      required int startOffset,
      required int nameOrExtensionOffset,
      required int endOffset}) {
    String? name = identifier?.name;
    // Nested declaration began in
    // `OutlineBuilder.beginExtensionDeclarationPrelude`.
    endExtensionDeclaration(name);

    ExtensionFragment declarationFragment =
        _declarationFragments.pop() as ExtensionFragment;

    NominalParameterNameSpace nominalParameterNameSpace =
        _nominalParameterNameSpaces.pop();
    nominalParameterNameSpace.addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: name, allowNameConflict: false);

    declarationFragment.metadata = metadata;
    declarationFragment.modifiers = modifiers;
    declarationFragment.onType = onType;
    declarationFragment.startOffset = startOffset;
    declarationFragment.nameOrExtensionOffset = nameOrExtensionOffset;
    declarationFragment.endOffset = endOffset;

    _constructorReferences.clear();

    _addFragment(declarationFragment);

    if (identifier != null) {
      offsetMap.registerNamedDeclarationFragment(
          identifier, declarationFragment);
    } else {
      offsetMap.registerUnnamedDeclaration(beginToken, declarationFragment);
    }
  }

  @override
  void addExtensionTypeDeclaration(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier identifier,
      required List<NominalParameterBuilder>? typeParameters,
      required List<TypeBuilder>? interfaces,
      required int startOffset,
      required int endOffset}) {
    String name = identifier.name;
    // Nested declaration began in `OutlineBuilder.beginExtensionDeclaration`.
    endExtensionTypeDeclaration(name);

    ExtensionTypeFragment declarationFragment =
        _declarationFragments.pop() as ExtensionTypeFragment;

    NominalParameterNameSpace nominalParameterNameSpace =
        _nominalParameterNameSpaces.pop();
    nominalParameterNameSpace.addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: name, allowNameConflict: false);

    declarationFragment.metadata = metadata;
    declarationFragment.modifiers = modifiers;
    declarationFragment.interfaces = interfaces;
    declarationFragment.constructorReferences =
        new List<ConstructorReferenceBuilder>.of(_constructorReferences);
    declarationFragment.startOffset = startOffset;
    declarationFragment.endOffset = endOffset;

    _constructorReferences.clear();

    _addFragment(declarationFragment);
    offsetMap.registerNamedDeclarationFragment(identifier, declarationFragment);
  }

  @override
  void addFunctionTypeAlias(
      List<MetadataBuilder>? metadata,
      String name,
      List<NominalParameterBuilder>? typeParameters,
      TypeBuilder type,
      int nameOffset) {
    if (typeParameters != null) {
      for (NominalParameterBuilder typeParameter in typeParameters) {
        typeParameter.varianceCalculationValue =
            VarianceCalculationValue.pending;
      }
    }
    _nominalParameterNameSpaces.pop().addTypeParameters(
        _problemReporting, typeParameters,
        ownerName: name, allowNameConflict: true);
    // Nested declaration began in `OutlineBuilder.beginFunctionTypeAlias`.
    endTypedef();
    TypedefFragment fragment = new TypedefFragment(
        metadata: metadata,
        name: name,
        typeParameters: typeParameters,
        type: type,
        fileUri: _compilationUnit.fileUri,
        nameOffset: nameOffset);
    _addFragment(fragment);
  }

  @override
  void addClassMethod(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Identifier identifier,
      required String name,
      required TypeBuilder? returnType,
      required List<FormalParameterBuilder>? formals,
      required List<NominalParameterBuilder>? typeParameters,
      required Token? beginInitializers,
      required int startOffset,
      required int endOffset,
      required int nameOffset,
      required int formalsOffset,
      required Modifiers modifiers,
      required bool inConstructor,
      required bool isStatic,
      required bool isConstructor,
      required bool forAbstractClassOrMixin,
      required bool isExtensionMember,
      required bool isExtensionTypeMember,
      required AsyncMarker asyncModifier,
      required String? nativeMethodName,
      required ProcedureKind? kind}) {
    DeclarationFragment declarationFragment = _declarationFragments.current;
    // TODO(johnniwinther): Avoid discrepancy between [inConstructor] and
    // [isConstructor]. The former is based on the enclosing declaration name
    // and get/set keyword. The latter also takes initializers into account.

    if (isConstructor) {
      switch (declarationFragment) {
        case ExtensionFragment():
        case ExtensionTypeFragment():
          // Discard type parameters declared on the constructor. It's not
          // allowed, an error has already been issued and it will cause
          // crashes later if they are kept/added to the ones from the parent.
          // TODO(johnniwinther): This will cause us issuing errors about not
          // knowing the names of what we discard here. Is there a way to
          // preserve them?
          typeParameters = null;
        case ClassFragment():
        case MixinFragment():
        case EnumFragment():
      }
      ConstructorName constructorName =
          computeAndValidateConstructorName(declarationFragment, identifier);
      addConstructor(
          offsetMap: offsetMap,
          metadata: metadata,
          modifiers: modifiers,
          identifier: identifier,
          constructorName: constructorName,
          typeParameters: typeParameters,
          formals: formals,
          startOffset: startOffset,
          formalsOffset: formalsOffset,
          endOffset: endOffset,
          nativeMethodName: nativeMethodName,
          beginInitializers: beginInitializers,
          forAbstractClassOrMixin: forAbstractClassOrMixin);
    } else {
      switch (kind!) {
        case ProcedureKind.Method:
        case ProcedureKind.Operator:
          addMethod(
              offsetMap: offsetMap,
              metadata: metadata,
              modifiers: modifiers,
              returnType: returnType,
              identifier: identifier,
              name: name,
              typeParameters: typeParameters,
              formals: formals,
              kind: kind,
              startOffset: startOffset,
              nameOffset: nameOffset,
              formalsOffset: formalsOffset,
              endOffset: endOffset,
              nativeMethodName: nativeMethodName,
              asyncModifier: asyncModifier,
              isInstanceMember: !isStatic,
              isExtensionMember: isExtensionMember,
              isExtensionTypeMember: isExtensionTypeMember);
        case ProcedureKind.Getter:
          addGetter(
              offsetMap: offsetMap,
              metadata: metadata,
              modifiers: modifiers,
              returnType: returnType,
              identifier: identifier,
              name: name,
              typeParameters: typeParameters,
              formals: formals,
              startOffset: startOffset,
              nameOffset: nameOffset,
              formalsOffset: formalsOffset,
              endOffset: endOffset,
              nativeMethodName: nativeMethodName,
              asyncModifier: asyncModifier,
              isInstanceMember: !isStatic,
              isExtensionMember: isExtensionMember,
              isExtensionTypeMember: isExtensionTypeMember);
        case ProcedureKind.Setter:
          addSetter(
              offsetMap: offsetMap,
              metadata: metadata,
              modifiers: modifiers,
              returnType: returnType,
              identifier: identifier,
              name: name,
              typeParameters: typeParameters,
              formals: formals,
              startOffset: startOffset,
              nameOffset: nameOffset,
              formalsOffset: formalsOffset,
              endOffset: endOffset,
              nativeMethodName: nativeMethodName,
              asyncModifier: asyncModifier,
              isInstanceMember: !isStatic,
              isExtensionMember: isExtensionMember,
              isExtensionTypeMember: isExtensionTypeMember);
        // Coverage-ignore(suite): Not run.
        case ProcedureKind.Factory:
          throw new UnsupportedError("Unexpected procedure kind: $kind");
      }
    }
  }

  @override
  void addPrimaryConstructor(
      {required OffsetMap offsetMap,
      required Token beginToken,
      required String? name,
      required List<FormalParameterBuilder>? formals,
      required int startOffset,
      required int? nameOffset,
      required int formalsOffset,
      required bool isConst}) {
    NominalParameterNameSpace nominalParameterNameSpace =
        new NominalParameterNameSpace();
    _nominalParameterNameSpaces.push(nominalParameterNameSpace);
    _typeScopes.push(new TypeScope(
        TypeScopeKind.memberTypeParameters,
        new NominalParameterScope(
            _typeScopes.current.lookupScope, nominalParameterNameSpace),
        _typeScopes.current));
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.memberTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    ConstructorName constructorName;
    String declarationName = _declarationFragments.current.name;
    if (name == 'new') {
      constructorName = new ConstructorName(
          name: '',
          nameOffset: nameOffset!,
          fullName: declarationName,
          fullNameOffset: nameOffset,
          fullNameLength: noLength);
    } else if (name != null) {
      constructorName = new ConstructorName(
          name: name,
          nameOffset: nameOffset!,
          fullName: '$declarationName.$name',
          fullNameOffset: nameOffset,
          fullNameLength: noLength);
    } else {
      constructorName = new ConstructorName(
          name: '',
          nameOffset: null,
          fullName: declarationName,
          fullNameOffset: formalsOffset,
          fullNameLength: noLength);
    }
    NominalParameterNameSpace typeParameterNameSpace =
        _nominalParameterNameSpaces.pop();

    PrimaryConstructorFragment fragment = new PrimaryConstructorFragment(
        constructorName: constructorName,
        fileUri: _compilationUnit.fileUri,
        startOffset: startOffset,
        formalsOffset: formalsOffset,
        modifiers: isConst ? Modifiers.Const : Modifiers.empty,
        returnType: addInferableType(),
        typeParameterNameSpace: typeParameterNameSpace,
        typeParameterScope: typeParameterScope.lookupScope,
        formals: formals,
        forAbstractClassOrMixin: false,
        beginInitializers: isConst || libraryFeatures.superParameters.isEnabled
            // const constructors will have their initializers compiled and
            // written into the outline. In case of super-parameters language
            // feature, the super initializers are required to infer the types
            // of super parameters.
            // TODO(johnniwinther): Avoid using a dummy token to ensure building
            // of constant constructors in the outline phase.
            ? new Token.eof(-1)
            : null);

    _addFragment(fragment);
    if (isConst) {
      _declarationFragments.current.declaresConstConstructor = true;
    }

    offsetMap.registerPrimaryConstructor(beginToken, fragment);
  }

  @override
  void addConstructor(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier identifier,
      required ConstructorName constructorName,
      required List<NominalParameterBuilder>? typeParameters,
      required List<FormalParameterBuilder>? formals,
      required int startOffset,
      required int formalsOffset,
      required int endOffset,
      required String? nativeMethodName,
      required Token? beginInitializers,
      required bool forAbstractClassOrMixin}) {
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.memberTypeParameters,
        "Unexpected type scope: $typeParameterScope.");
    NominalParameterNameSpace typeParameterNameSpace =
        _nominalParameterNameSpaces.pop();

    ConstructorFragment fragment = new ConstructorFragment(
        constructorName: constructorName,
        fileUri: _compilationUnit.fileUri,
        startOffset: startOffset,
        formalsOffset: formalsOffset,
        endOffset: endOffset,
        modifiers: modifiers - Modifiers.Abstract,
        metadata: metadata,
        returnType: addInferableType(),
        typeParameters: typeParameters,
        typeParameterNameSpace: typeParameterNameSpace,
        typeParameterScope: typeParameterScope.lookupScope,
        formals: formals,
        nativeMethodName: nativeMethodName,
        forAbstractClassOrMixin: forAbstractClassOrMixin,
        beginInitializers: modifiers.isConst ||
                libraryFeatures.superParameters.isEnabled
            // const constructors will have their initializers compiled and
            // written into the outline. In case of super-parameters language
            // feature, the super initializers are required to infer the types
            // of super parameters.
            // TODO(johnniwinther): Avoid using a dummy token to ensure building
            // of constant constructors in the outline phase.
            ? (beginInitializers ?? new Token.eof(-1))
            : null);

    _addFragment(fragment);
    if (nativeMethodName != null) {
      _addNativeConstructorFragment(fragment);
    }
    if (modifiers.isConst) {
      _declarationFragments.current.declaresConstConstructor = true;
    }
    offsetMap.registerConstructorFragment(identifier, fragment);
  }

  @override
  void addPrimaryConstructorField(
      {required List<MetadataBuilder>? metadata,
      required TypeBuilder type,
      required String name,
      required int nameOffset}) {
    _declarationFragments.current.addPrimaryConstructorField(_addField(
        metadata: metadata,
        modifiers: Modifiers.Final,
        isTopLevel: false,
        type: type,
        name: name,
        nameOffset: nameOffset,
        endOffset: nameOffset,
        initializerToken: null,
        hasInitializer: false,
        isPrimaryConstructorField: true));
  }

  @override
  void addFactoryMethod(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier identifier,
      required List<FormalParameterBuilder>? formals,
      required ConstructorReferenceBuilder? redirectionTarget,
      required int startOffset,
      required int nameOffset,
      required int formalsOffset,
      required int endOffset,
      required String? nativeMethodName,
      required AsyncMarker asyncModifier}) {
    DeclarationFragment enclosingDeclaration = _declarationFragments.current;

    ConstructorName constructorName = computeAndValidateConstructorName(
        enclosingDeclaration, identifier,
        isFactory: true);

    NominalParameterNameSpace typeParameterNameSpace =
        _nominalParameterNameSpaces.pop();

    FactoryFragment fragment = new FactoryFragment(
        constructorName: constructorName,
        fileUri: _compilationUnit.fileUri,
        startOffset: startOffset,
        formalsOffset: formalsOffset,
        endOffset: endOffset,
        modifiers: modifiers | Modifiers.Static,
        metadata: metadata,
        typeParameterNameSpace: typeParameterNameSpace,
        typeParameterScope: _typeScopes.current.lookupScope,
        formals: formals,
        asyncModifier: asyncModifier,
        nativeMethodName: nativeMethodName,
        redirectionTarget: redirectionTarget);

    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.memberTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    _addFragment(fragment);
    if (nativeMethodName != null) {
      _addNativeFactoryFragment(fragment);
    }
    offsetMap.registerFactoryFragment(identifier, fragment);
  }

  @override
  ConstructorReferenceBuilder addConstructorReference(TypeName name,
      List<TypeBuilder>? typeArguments, String? suffix, int charOffset) {
    ConstructorReferenceBuilder ref = new ConstructorReferenceBuilder(
        name, typeArguments, suffix, _compilationUnit.fileUri, charOffset);
    _constructorReferences.add(ref);
    return ref;
  }

  @override
  ConstructorReferenceBuilder? addUnnamedConstructorReference(
      List<TypeBuilder>? typeArguments, Identifier? suffix, int charOffset) {
    // At the moment, the name of the type in a constructor reference can be
    // omitted only within an enum element declaration.
    DeclarationFragment enclosingDeclaration = _declarationFragments.current;
    if (enclosingDeclaration.kind == DeclarationFragmentKind.enumDeclaration) {
      if (libraryFeatures.enhancedEnums.isEnabled) {
        int constructorNameOffset = suffix?.nameOffset ?? charOffset;
        return addConstructorReference(
            new SyntheticTypeName(
                enclosingDeclaration.name, constructorNameOffset),
            typeArguments,
            suffix?.name,
            constructorNameOffset);
      } else {
        // Coverage-ignore-block(suite): Not run.
        // For entries that consist of their name only, all of the elements
        // of the constructor reference should be null.
        if (typeArguments != null || suffix != null) {
          _compilationUnit.reportFeatureNotEnabled(
              libraryFeatures.enhancedEnums,
              _compilationUnit.fileUri,
              charOffset,
              noLength);
        }
        return null;
      }
    } else {
      internalProblem(
          messageInternalProblemOmittedTypeNameInConstructorReference,
          charOffset,
          _compilationUnit.fileUri);
    }
  }

  @override
  ConstructorName computeAndValidateConstructorName(
      DeclarationFragment enclosingDeclaration, Identifier identifier,
      {isFactory = false}) {
    String className = enclosingDeclaration.name;
    String prefix;
    String? suffix;
    int? suffixOffset;
    String fullName;
    int fullNameOffset;
    int fullNameLength;
    int charOffset;
    if (identifier is QualifiedNameIdentifier) {
      Identifier qualifier = identifier.qualifier;
      prefix = qualifier.name;
      suffix = identifier.name;
      suffixOffset = identifier.nameOffset;
      charOffset = qualifier.nameOffset;
      String prefixAndSuffix = '${prefix}.${suffix}';
      fullNameOffset = qualifier.nameOffset;
      // If the there is no space between the prefix and suffix we use the full
      // length as the name length. Otherwise the full name has no length.
      fullNameLength = fullNameOffset + prefix.length + 1 == suffixOffset
          ? prefixAndSuffix.length
          : noLength;
      if (suffix == "new") {
        // Normalize `Class.new` to `Class`.
        suffix = '';
        fullName = className;
      } else {
        fullName = '$className.$suffix';
      }
    } else {
      prefix = identifier.name;
      suffix = null;
      suffixOffset = null;
      charOffset = identifier.nameOffset;
      fullName = prefix;
      fullNameOffset = identifier.nameOffset;
      fullNameLength = prefix.length;
    }

    if (prefix == className) {
      return new ConstructorName(
          name: suffix ?? '',
          nameOffset: suffixOffset,
          fullName: fullName,
          fullNameOffset: fullNameOffset,
          fullNameLength: fullNameLength);
    } else if (suffix == null) {
      // Normalize `foo` in `Class` to `Class.foo`.
      fullName = '$className.$prefix';
    }
    if (suffix == null && !isFactory) {
      // This method is called because the syntax indicated that this is a
      // constructor, either because it had qualified name or because the method
      // had an initializer list.
      //
      // In either case this is reported elsewhere, and since the name is a
      // legal name for a regular method, we don't remove an error on the name.
    } else {
      _problemReporting.addProblem(messageConstructorWithWrongName, charOffset,
          prefix.length, _compilationUnit.fileUri,
          context: [
            templateConstructorWithWrongNameContext
                .withArguments(enclosingDeclaration.name)
                .withLocation(
                    _compilationUnit.importUri,
                    enclosingDeclaration.fileOffset,
                    enclosingDeclaration.name.length)
          ]);
    }

    return new ConstructorName(
        name: suffix ?? prefix,
        nameOffset: suffixOffset,
        fullName: fullName,
        fullNameOffset: fullNameOffset,
        fullNameLength: fullNameLength);
  }

  void _addNativeGetterFragment(GetterFragment fragment) {
    _nativeGetterFragments.add(fragment);
  }

  void _addNativeSetterFragment(SetterFragment fragment) {
    _nativeSetterFragments.add(fragment);
  }

  void _addNativeMethodFragment(MethodFragment fragment) {
    _nativeMethodFragments.add(fragment);
  }

  void _addNativeConstructorFragment(ConstructorFragment fragment) {
    _nativeConstructorFragments.add(fragment);
  }

  void _addNativeFactoryFragment(FactoryFragment method) {
    _nativeFactoryFragments.add(method);
  }

  @override
  void addGetter(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required TypeBuilder? returnType,
      required Identifier identifier,
      required String name,
      required List<NominalParameterBuilder>? typeParameters,
      required List<FormalParameterBuilder>? formals,
      required int startOffset,
      required int nameOffset,
      required int formalsOffset,
      required int endOffset,
      required String? nativeMethodName,
      required AsyncMarker asyncModifier,
      required bool isInstanceMember,
      required bool isExtensionMember,
      required bool isExtensionTypeMember}) {
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.memberTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    DeclarationFragment? enclosingDeclaration =
        _declarationFragments.currentOrNull;
    assert(!isExtensionMember ||
        enclosingDeclaration?.kind ==
            DeclarationFragmentKind.extensionDeclaration);
    assert(!isExtensionTypeMember ||
        enclosingDeclaration?.kind ==
            DeclarationFragmentKind.extensionTypeDeclaration);

    NominalParameterNameSpace typeParameterNameSpace =
        _nominalParameterNameSpaces.pop();

    GetterFragment fragment = new GetterFragment(
        name: name,
        fileUri: _compilationUnit.fileUri,
        startOffset: startOffset,
        nameOffset: nameOffset,
        formalsOffset: formalsOffset,
        endOffset: endOffset,
        isTopLevel: enclosingDeclaration == null,
        metadata: metadata,
        modifiers: modifiers,
        returnType: returnType ?? addInferableType(),
        typeParameters: typeParameters,
        typeParameterNameSpace: typeParameterNameSpace,
        typeParameterScope: typeParameterScope.lookupScope,
        formals: formals,
        asyncModifier: asyncModifier,
        nativeMethodName: nativeMethodName);
    _addFragment(fragment);
    if (nativeMethodName != null) {
      _addNativeGetterFragment(fragment);
    }
    offsetMap.registerGetter(identifier, fragment);
  }

  @override
  void addSetter(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required TypeBuilder? returnType,
      required Identifier identifier,
      required String name,
      required List<NominalParameterBuilder>? typeParameters,
      required List<FormalParameterBuilder>? formals,
      required int startOffset,
      required int nameOffset,
      required int formalsOffset,
      required int endOffset,
      required String? nativeMethodName,
      required AsyncMarker asyncModifier,
      required bool isInstanceMember,
      required bool isExtensionMember,
      required bool isExtensionTypeMember}) {
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.memberTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    DeclarationFragment? enclosingDeclaration =
        _declarationFragments.currentOrNull;
    assert(!isExtensionMember ||
        enclosingDeclaration?.kind ==
            DeclarationFragmentKind.extensionDeclaration);
    assert(!isExtensionTypeMember ||
        enclosingDeclaration?.kind ==
            DeclarationFragmentKind.extensionTypeDeclaration);

    if (returnType == null) {
      returnType = addVoidType(nameOffset);
    }

    NominalParameterNameSpace typeParameterNameSpace =
        _nominalParameterNameSpaces.pop();

    SetterFragment fragment = new SetterFragment(
        name: name,
        fileUri: _compilationUnit.fileUri,
        startOffset: startOffset,
        nameOffset: nameOffset,
        formalsOffset: formalsOffset,
        endOffset: endOffset,
        isTopLevel: enclosingDeclaration == null,
        metadata: metadata,
        modifiers: modifiers,
        returnType: returnType,
        typeParameters: typeParameters,
        typeParameterNameSpace: typeParameterNameSpace,
        typeParameterScope: typeParameterScope.lookupScope,
        formals: formals,
        asyncModifier: asyncModifier,
        nativeMethodName: nativeMethodName);
    _addFragment(fragment);
    if (nativeMethodName != null) {
      _addNativeSetterFragment(fragment);
    }
    offsetMap.registerSetter(identifier, fragment);
  }

  @override
  void addMethod(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required TypeBuilder? returnType,
      required Identifier identifier,
      required String name,
      required List<NominalParameterBuilder>? typeParameters,
      required List<FormalParameterBuilder>? formals,
      required ProcedureKind kind,
      required int startOffset,
      required int nameOffset,
      required int formalsOffset,
      required int endOffset,
      required String? nativeMethodName,
      required AsyncMarker asyncModifier,
      required bool isInstanceMember,
      required bool isExtensionMember,
      required bool isExtensionTypeMember}) {
    TypeScope typeParameterScope = _typeScopes.pop();
    assert(typeParameterScope.kind == TypeScopeKind.memberTypeParameters,
        "Unexpected type scope: $typeParameterScope.");

    DeclarationFragment? enclosingDeclaration =
        _declarationFragments.currentOrNull;
    assert(!isExtensionMember ||
        enclosingDeclaration?.kind ==
            DeclarationFragmentKind.extensionDeclaration);
    assert(!isExtensionTypeMember ||
        enclosingDeclaration?.kind ==
            DeclarationFragmentKind.extensionTypeDeclaration);

    if (returnType == null) {
      if (kind == ProcedureKind.Operator &&
          identical(name, indexSetName.text)) {
        returnType = addVoidType(nameOffset);
      } else if (kind == ProcedureKind.Setter) {
        // Coverage-ignore-block(suite): Not run.
        returnType = addVoidType(nameOffset);
      }
    }

    NominalParameterNameSpace typeParameterNameSpace =
        _nominalParameterNameSpaces.pop();

    MethodFragment fragment = new MethodFragment(
        name: name,
        fileUri: _compilationUnit.fileUri,
        startOffset: startOffset,
        nameOffset: nameOffset,
        formalsOffset: formalsOffset,
        endOffset: endOffset,
        isTopLevel: enclosingDeclaration == null,
        metadata: metadata,
        modifiers: modifiers,
        returnType: returnType ?? addInferableType(),
        typeParameters: typeParameters,
        typeParameterNameSpace: typeParameterNameSpace,
        typeParameterScope: typeParameterScope.lookupScope,
        formals: formals,
        kind: kind,
        asyncModifier: asyncModifier,
        nativeMethodName: nativeMethodName);
    _addFragment(fragment);
    if (nativeMethodName != null) {
      _addNativeMethodFragment(fragment);
    }
    offsetMap.registerMethod(identifier, fragment);
  }

  @override
  void addFields(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      Modifiers modifiers,
      bool isTopLevel,
      TypeBuilder? type,
      List<FieldInfo> fieldInfos) {
    for (FieldInfo info in fieldInfos) {
      bool isConst = modifiers.isConst;
      bool isFinal = modifiers.isFinal;
      bool potentiallyNeedInitializerInOutline = isConst || isFinal;
      Token? startToken;
      if (potentiallyNeedInitializerInOutline || type == null) {
        startToken = info.initializerToken;
      }
      if (startToken != null) {
        // Extract only the tokens for the initializer expression from the
        // token stream.
        Token endToken = info.beforeLast!;
        endToken.setNext(new Token.eof(endToken.next!.offset));
        new Token.eof(startToken.previous!.offset).setNext(startToken);
      }
      bool hasInitializer = info.initializerToken != null;
      offsetMap.registerField(
          info.identifier,
          _addField(
              metadata: metadata,
              modifiers: modifiers,
              isTopLevel: isTopLevel,
              type: type ?? addInferableType(),
              name: info.identifier.name,
              nameOffset: info.identifier.nameOffset,
              endOffset: info.endOffset,
              initializerToken: startToken,
              hasInitializer: hasInitializer,
              constInitializerToken:
                  potentiallyNeedInitializerInOutline ? startToken : null,
              isPrimaryConstructorField: false));
    }
  }

  FieldFragment _addField(
      {required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required bool isTopLevel,
      required TypeBuilder type,
      required String name,
      required int nameOffset,
      required int endOffset,
      required Token? initializerToken,
      required bool hasInitializer,
      Token? constInitializerToken,
      required bool isPrimaryConstructorField}) {
    if (hasInitializer) {
      modifiers |= Modifiers.HasInitializer;
    }
    FieldFragment fragment = new FieldFragment(
        name: name,
        fileUri: _compilationUnit.fileUri,
        nameOffset: nameOffset,
        endOffset: endOffset,
        initializerToken: initializerToken,
        constInitializerToken: constInitializerToken,
        metadata: metadata,
        type: type,
        isTopLevel: isTopLevel,
        modifiers: modifiers,
        isPrimaryConstructorField: isPrimaryConstructorField);
    _addFragment(fragment);
    return fragment;
  }

  @override
  FormalParameterBuilder addFormalParameter(
      List<MetadataBuilder>? metadata,
      FormalParameterKind kind,
      Modifiers modifiers,
      TypeBuilder type,
      String name,
      bool hasThis,
      bool hasSuper,
      int charOffset,
      Token? initializerToken,
      {bool lowerWildcard = false}) {
    assert(!hasThis || !hasSuper,
        "Formal parameter '${name}' has both 'this' and 'super' prefixes.");
    if (hasThis) {
      modifiers |= Modifiers.InitializingFormal;
    }
    if (hasSuper) {
      modifiers |= Modifiers.SuperInitializingFormal;
    }
    String formalName = name;
    bool isWildcard =
        libraryFeatures.wildcardVariables.isEnabled && formalName == '_';
    if (isWildcard && lowerWildcard) {
      formalName = createWildcardFormalParameterName(wildcardVariableIndex);
      wildcardVariableIndex++;
    }
    FormalParameterBuilder formal = new FormalParameterBuilder(
        kind, modifiers, type, formalName, charOffset,
        fileUri: _compilationUnit.fileUri,
        hasImmediatelyDeclaredInitializer: initializerToken != null,
        isWildcard: isWildcard)
      ..initializerToken = initializerToken;
    return formal;
  }

  @override
  TypeBuilder addNamedType(
      TypeName typeName,
      NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder>? arguments,
      int charOffset,
      {required InstanceTypeParameterAccessState instanceTypeParameterAccess}) {
    if (_omittedTypeDeclarationBuilders != null) {
      // Coverage-ignore-block(suite): Not run.
      Builder? builder = _omittedTypeDeclarationBuilders[typeName.name];
      if (builder is OmittedTypeDeclarationBuilder) {
        return new DependentTypeBuilder(builder.omittedTypeBuilder);
      }
    }
    return _registerUnresolvedNamedType(new NamedTypeBuilderImpl(
        typeName, nullabilityBuilder,
        arguments: arguments,
        fileUri: _compilationUnit.fileUri,
        charOffset: charOffset,
        instanceTypeParameterAccess: instanceTypeParameterAccess));
  }

  NamedTypeBuilder _registerUnresolvedNamedType(NamedTypeBuilder type) {
    _typeScopes.current.registerUnresolvedNamedType(type);
    return type;
  }

  @override
  FunctionTypeBuilder addFunctionType(
      TypeBuilder returnType,
      List<StructuralParameterBuilder>? structuralVariableBuilders,
      List<FormalParameterBuilder>? formals,
      NullabilityBuilder nullabilityBuilder,
      Uri fileUri,
      int charOffset,
      {required bool hasFunctionFormalParameterSyntax}) {
    FunctionTypeBuilder builder = new FunctionTypeBuilderImpl(
        returnType,
        structuralVariableBuilders,
        formals,
        nullabilityBuilder,
        fileUri,
        charOffset,
        hasFunctionFormalParameterSyntax: hasFunctionFormalParameterSyntax);
    _checkStructuralParameters(structuralVariableBuilders);
    if (structuralVariableBuilders != null) {
      for (StructuralParameterBuilder builder in structuralVariableBuilders) {
        if (builder.metadata != null) {
          if (!libraryFeatures.genericMetadata.isEnabled) {
            _problemReporting.addProblem(
                messageAnnotationOnFunctionTypeTypeParameter,
                builder.fileOffset,
                builder.name.length,
                builder.fileUri);
          }
        }
      }
    }
    // Nested declaration began in `OutlineBuilder.beginFunctionType` or
    // `OutlineBuilder.beginFunctionTypedFormalParameter`.
    endFunctionType();
    return builder;
  }

  void _checkStructuralParameters(
      List<StructuralParameterBuilder>? typeParameters) {
    Map<String, StructuralParameterBuilder> typeParametersByName =
        _structuralParameterScopes.pop();
    if (typeParameters == null || typeParameters.isEmpty) return null;
    for (StructuralParameterBuilder tv in typeParameters) {
      if (tv.isWildcard) continue;
      StructuralParameterBuilder? existing = typeParametersByName[tv.name];
      if (existing != null) {
        // Coverage-ignore-block(suite): Not run.
        _problemReporting.addProblem(messageTypeParameterDuplicatedName,
            tv.fileOffset, tv.name.length, _compilationUnit.fileUri,
            context: [
              templateTypeParameterDuplicatedNameCause
                  .withArguments(tv.name)
                  .withLocation(_compilationUnit.fileUri, existing.fileOffset,
                      existing.name.length)
            ]);
      } else {
        typeParametersByName[tv.name] = tv;
      }
    }
  }

  @override
  TypeBuilder addVoidType(int charOffset) {
    return new VoidTypeBuilder(_compilationUnit.fileUri, charOffset);
  }

  @override
  NominalParameterBuilder addNominalParameter(List<MetadataBuilder>? metadata,
      String name, TypeBuilder? bound, int charOffset, Uri fileUri,
      {required TypeParameterKind kind}) {
    String variableName = name;
    bool isWildcard =
        libraryFeatures.wildcardVariables.isEnabled && variableName == '_';
    if (isWildcard) {
      variableName = createWildcardTypeParameterName(wildcardVariableIndex);
      wildcardVariableIndex++;
    }
    NominalParameterBuilder builder = new NominalParameterBuilder(
        variableName, charOffset, fileUri,
        bound: bound, metadata: metadata, kind: kind, isWildcard: isWildcard);

    _unboundNominalParameters.add(builder);
    return builder;
  }

  @override
  StructuralParameterBuilder addStructuralParameter(
      List<MetadataBuilder>? metadata,
      String name,
      TypeBuilder? bound,
      int charOffset,
      Uri fileUri) {
    String variableName = name;
    bool isWildcard =
        libraryFeatures.wildcardVariables.isEnabled && variableName == '_';
    if (isWildcard) {
      variableName = createWildcardTypeParameterName(wildcardVariableIndex);
      wildcardVariableIndex++;
    }
    StructuralParameterBuilder builder = new StructuralParameterBuilder(
        variableName, charOffset, fileUri,
        bound: bound, metadata: metadata, isWildcard: isWildcard);

    _unboundStructuralVariables.add(builder);
    return builder;
  }

  /// Creates a [NominalParameterCopy] object containing a copy of
  /// [oldVariableBuilders] into the scope of [declaration].
  ///
  /// This is used for adding copies of class type parameters to factory
  /// methods and unnamed mixin applications, and for adding copies of
  /// extension type parameters to extension instance methods.
  static NominalParameterCopy? copyTypeParameters(
      List<NominalParameterBuilder> _unboundNominalVariables,
      List<NominalParameterBuilder>? oldVariableBuilders,
      {required TypeParameterKind kind,
      required InstanceTypeParameterAccessState instanceTypeParameterAccess}) {
    if (oldVariableBuilders == null || oldVariableBuilders.isEmpty) {
      return null;
    }

    List<TypeBuilder> newTypeArguments = [];
    Map<NominalParameterBuilder, TypeBuilder> substitutionMap =
        new Map.identity();
    Map<NominalParameterBuilder, NominalParameterBuilder> newToOldVariableMap =
        new Map.identity();

    List<NominalParameterBuilder> newVariableBuilders =
        <NominalParameterBuilder>[];
    for (NominalParameterBuilder oldVariable in oldVariableBuilders) {
      NominalParameterBuilder newVariable = new NominalParameterBuilder(
          oldVariable.name, oldVariable.fileOffset, oldVariable.fileUri,
          kind: kind,
          variableVariance: oldVariable.parameter.isLegacyCovariant
              ? null
              :
              // Coverage-ignore(suite): Not run.
              oldVariable.variance,
          isWildcard: oldVariable.isWildcard);
      newVariableBuilders.add(newVariable);
      newToOldVariableMap[newVariable] = oldVariable;
      _unboundNominalVariables.add(newVariable);
    }
    for (int i = 0; i < newVariableBuilders.length; i++) {
      NominalParameterBuilder oldVariableBuilder = oldVariableBuilders[i];
      TypeBuilder newTypeArgument =
          new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
              newVariableBuilders[i], const NullabilityBuilder.omitted(),
              instanceTypeParameterAccess: instanceTypeParameterAccess);
      substitutionMap[oldVariableBuilder] = newTypeArgument;
      newTypeArguments.add(newTypeArgument);

      if (oldVariableBuilder.bound != null) {
        newVariableBuilders[i].bound = new SynthesizedTypeBuilder(
            oldVariableBuilder.bound!, newToOldVariableMap, substitutionMap);
      }
    }
    return new NominalParameterCopy(newVariableBuilders, newTypeArguments,
        substitutionMap, newToOldVariableMap);
  }

  @override
  void addLibraryDirective(
      {required String? libraryName,
      required List<MetadataBuilder>? metadata,
      required bool isAugment}) {
    _name = libraryName;
    _metadata = metadata;
  }

  @override
  InferableTypeBuilder addInferableType() {
    return _compilationUnit.loader.inferableTypes.addInferableType();
  }

  void _addFragment(Fragment fragment) {
    if (_declarationFragments.isEmpty) {
      _libraryNameSpaceBuilder.addFragment(fragment);
    } else {
      _declarationFragments.current.addFragment(fragment);
    }
  }

  @override
  void takeMixinApplications(
      Map<SourceClassBuilder, TypeBuilder> mixinApplications) {
    assert(_mixinApplications != null,
        "Mixin applications have already been processed.");
    mixinApplications.addAll(_mixinApplications!);
    _mixinApplications = null;
  }

  @override
  void collectUnboundTypeParameters(
      SourceLibraryBuilder libraryBuilder,
      Map<NominalParameterBuilder, SourceLibraryBuilder> nominalVariables,
      Map<StructuralParameterBuilder, SourceLibraryBuilder>
          structuralVariables) {
    for (NominalParameterBuilder builder in _unboundNominalParameters) {
      nominalVariables[builder] = libraryBuilder;
    }
    for (StructuralParameterBuilder builder in _unboundStructuralVariables) {
      structuralVariables[builder] = libraryBuilder;
    }
    _unboundStructuralVariables.clear();
    _unboundNominalParameters.clear();
  }

  @override
  TypeScope get typeScope => _typeScopes.current;

  @override
  String? get name => _name;

  @override
  List<MetadataBuilder>? get metadata => _metadata;

  @override
  bool get isPart => _partOfName != null || _partOfUri != null;

  @override
  String? get partOfName => _partOfName;

  @override
  Uri? get partOfUri => _partOfUri;

  @override
  List<Part> get parts => _parts;

  @override
  void registerUnresolvedStructuralParameters(
      List<StructuralParameterBuilder> unboundTypeParameters) {
    this._unboundStructuralVariables.addAll(unboundTypeParameters);
  }

  @override
  int finishNativeMethods() {
    for (FactoryFragment fragment in _nativeFactoryFragments) {
      fragment.builder.becomeNative(loader);
    }
    for (GetterFragment fragment in _nativeGetterFragments) {
      fragment.builder.becomeNative(loader);
    }
    for (SetterFragment fragment in _nativeSetterFragments) {
      fragment.builder.becomeNative(loader);
    }
    for (MethodFragment fragment in _nativeMethodFragments) {
      fragment.builder.becomeNative(loader);
    }
    for (ConstructorFragment fragment in _nativeConstructorFragments) {
      fragment.builder.becomeNative(loader);
    }
    return _nativeFactoryFragments.length;
  }

  @override
  List<LibraryPart> get libraryParts => _libraryParts;
}

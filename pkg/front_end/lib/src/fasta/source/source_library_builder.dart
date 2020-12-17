// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_library_builder;

import 'dart:convert' show jsonEncode;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:_fe_analyzer_shared/src/util/resolve_relative_uri.dart'
    show resolveRelativeUri;

import 'package:front_end/src/fasta/dill/dill_library_builder.dart'
    show DillLibraryBuilder;

import 'package:kernel/ast.dart'
    show
        Arguments,
        AsyncMarker,
        Class,
        Constructor,
        ConstructorInvocation,
        DartType,
        DynamicType,
        Expression,
        Extension,
        Field,
        FunctionNode,
        FunctionType,
        InterfaceType,
        InvalidType,
        Library,
        LibraryDependency,
        LibraryPart,
        ListLiteral,
        MapLiteral,
        Member,
        Name,
        NeverType,
        NonNullableByDefaultCompiledMode,
        NullType,
        Nullability,
        Procedure,
        ProcedureKind,
        Reference,
        SetLiteral,
        StaticInvocation,
        StringLiteral,
        Supertype,
        TypeParameter,
        TypeParameterType,
        Typedef,
        VariableDeclaration,
        Version,
        VoidType;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/clone.dart' show CloneVisitorNotMembers;

import 'package:kernel/reference_from_index.dart'
    show IndexedClass, IndexedLibrary;

import 'package:kernel/src/bounds_checks.dart'
    show
        TypeArgumentIssue,
        findTypeArgumentIssues,
        findTypeArgumentIssuesForInvocation,
        getGenericTypeName;

import 'package:kernel/type_algebra.dart' show Substitution, substitute;

import 'package:kernel/type_environment.dart'
    show SubtypeCheckMode, TypeEnvironment;

import '../../api_prototype/experimental_flags.dart';
import '../../base/nnbd_mode.dart';

import '../builder/builder.dart';
import '../builder/builtin_type_declaration_builder.dart';
import '../builder/class_builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/dynamic_type_declaration_builder.dart';
import '../builder/enum_builder.dart';
import '../builder/extension_builder.dart';
import '../builder/field_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/mixin_application_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/named_type_builder.dart';
import '../builder/never_type_declaration_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/type_variable_builder.dart';
import '../builder/unresolved_type.dart';
import '../builder/void_type_declaration_builder.dart';

import '../combinator.dart' show Combinator;

import '../configuration.dart' show Configuration;

import '../export.dart' show Export;

import '../fasta_codes.dart';

import '../identifiers.dart' show QualifiedName, flattenName;

import '../import.dart' show Import;

import '../kernel/internal_ast.dart';

import '../kernel/kernel_builder.dart'
    show
        ImplicitFieldType,
        LoadLibraryBuilder,
        compareProcedures,
        toKernelCombinators;

import '../kernel/metadata_collector.dart';

import '../kernel/type_algorithms.dart'
    show
        calculateBounds,
        computeTypeVariableBuilderVariance,
        findGenericFunctionTypes,
        getNonSimplicityIssuesForDeclaration,
        getNonSimplicityIssuesForTypeVariables,
        pendingVariance;

import '../loader.dart' show Loader;

import '../modifier.dart'
    show
        abstractMask,
        constMask,
        finalMask,
        declaresConstConstructorMask,
        hasInitializerMask,
        initializingFormalMask,
        lateMask,
        mixinDeclarationMask,
        namedMixinApplicationMask,
        staticMask;

import '../names.dart' show indexSetName;

import '../problems.dart' show unexpected, unhandled;

import '../scope.dart';

import '../type_inference/type_inferrer.dart' show TypeInferrerImpl;

import 'source_class_builder.dart' show SourceClassBuilder;

import 'source_extension_builder.dart' show SourceExtensionBuilder;

import 'source_loader.dart' show SourceLoader;

import 'source_type_alias_builder.dart';

class SourceLibraryBuilder extends LibraryBuilderImpl {
  static const String MALFORMED_URI_SCHEME = "org-dartlang-malformed-uri";

  final SourceLoader loader;

  final TypeParameterScopeBuilder libraryDeclaration;

  final List<ConstructorReferenceBuilder> constructorReferences =
      <ConstructorReferenceBuilder>[];

  final List<LibraryBuilder> parts = <LibraryBuilder>[];

  // Can I use library.parts instead? See SourceLibraryBuilder.addPart.
  final List<int> partOffsets = <int>[];

  final List<Import> imports = <Import>[];

  final List<Export> exports = <Export>[];

  final Scope importScope;

  final Uri fileUri;

  final Uri _packageUri;

  Uri get packageUriForTesting => _packageUri;

  final List<ImplementationInfo> implementationBuilders =
      <ImplementationInfo>[];

  final List<Object> accessors = <Object>[];

  String documentationComment;

  String name;

  String partOfName;

  Uri partOfUri;

  List<MetadataBuilder> metadata;

  /// The current declaration that is being built. When we start parsing a
  /// declaration (class, method, and so on), we don't have enough information
  /// to create a builder and this object records its members and types until,
  /// for example, [addClass] is called.
  TypeParameterScopeBuilder currentTypeParameterScopeBuilder;

  bool canAddImplementationBuilders = false;

  /// Non-null if this library causes an error upon access, that is, there was
  /// an error reading its source.
  Message accessProblem;

  @override
  final Library library;

  final SourceLibraryBuilder actualOrigin;

  final List<FunctionBuilder> nativeMethods = <FunctionBuilder>[];

  final List<TypeVariableBuilder> boundlessTypeVariables =
      <TypeVariableBuilder>[];

  // A list of alternating forwarders and the procedures they were generated
  // for.  Note that it may not include a forwarder-origin pair in cases when
  // the former does not need to be updated after the body of the latter was
  // built.
  final List<Procedure> forwardersOrigins = <Procedure>[];

  // List of types inferred in the outline.  Errors in these should be reported
  // differently than for specified types.
  // TODO(dmitryas):  Find a way to mark inferred types.
  final Set<DartType> inferredTypes = new Set<DartType>.identity();

  // While the bounds of type parameters aren't compiled yet, we can't tell the
  // default nullability of the corresponding type-parameter types.  This list
  // is used to collect such type-parameter types in order to set the
  // nullability after the bounds are built.
  final List<TypeParameterType> pendingNullabilities = <TypeParameterType>[];

  // A library to use for Names generated when compiling code in this library.
  // This allows code generated in one library to use the private namespace of
  // another, for example during expression compilation (debugging).
  Library get nameOrigin => _nameOrigin ?? library;
  final Library _nameOrigin;

  final Library referencesFrom;
  final IndexedLibrary referencesFromIndexed;
  IndexedClass _currentClassReferencesFromIndexed;

  /// Exports that can't be serialized.
  ///
  /// The key is the name of the exported member.
  ///
  /// If the name is `dynamic` or `void`, this library reexports the
  /// corresponding type from `dart:core`, and the value is null.
  ///
  /// Otherwise, this represents an error (an ambiguous export). In this case,
  /// the error message is the corresponding value in the map.
  Map<String, String> unserializableExports;

  List<FieldBuilder> _implicitlyTypedFields;

  LanguageVersion _languageVersion;

  bool postponedProblemsIssued = false;
  List<PostponedProblem> postponedProblems;

  /// List of [PrefixBuilder]s for imports with prefixes.
  List<PrefixBuilder> _prefixBuilders;

  /// Set of extension declarations in scope. This is computed lazily in
  /// [forEachExtensionInScope].
  Set<ExtensionBuilder> _extensionsInScope;

  SourceLibraryBuilder.internal(
      SourceLoader loader,
      Uri fileUri,
      Uri packageUri,
      Scope scope,
      SourceLibraryBuilder actualOrigin,
      Library library,
      Library nameOrigin,
      Library referencesFrom,
      bool referenceIsPartOwner)
      : this.fromScopes(
            loader,
            fileUri,
            packageUri,
            new TypeParameterScopeBuilder.library(),
            scope ?? new Scope.top(),
            actualOrigin,
            library,
            nameOrigin,
            referencesFrom);

  SourceLibraryBuilder.fromScopes(
      this.loader,
      this.fileUri,
      this._packageUri,
      this.libraryDeclaration,
      this.importScope,
      this.actualOrigin,
      this.library,
      this._nameOrigin,
      this.referencesFrom)
      : _languageVersion = new ImplicitLanguageVersion(library.languageVersion),
        currentTypeParameterScopeBuilder = libraryDeclaration,
        referencesFromIndexed =
            referencesFrom == null ? null : new IndexedLibrary(referencesFrom),
        super(
            fileUri, libraryDeclaration.toScope(importScope), new Scope.top()) {
    assert(
        _packageUri == null ||
            importUri.scheme != 'package' ||
            importUri.path.startsWith(_packageUri.path),
        "Foreign package uri '$_packageUri' set on library with import uri "
        "'${importUri}'.");
    assert(
        importUri.scheme != 'dart' || _packageUri == null,
        "Package uri '$_packageUri' set on dart: library with import uri "
        "'${importUri}'.");
  }

  bool _enableVarianceInLibrary;
  bool _enableNonfunctionTypeAliasesInLibrary;
  bool _enableNonNullableInLibrary;
  Version _enableNonNullableVersionInLibrary;
  bool _enableTripleShiftInLibrary;
  bool _enableExtensionMethodsInLibrary;

  bool get enableVarianceInLibrary =>
      _enableVarianceInLibrary ??= loader.target.isExperimentEnabledInLibrary(
          ExperimentalFlag.variance, _packageUri ?? importUri);

  bool get enableNonfunctionTypeAliasesInLibrary =>
      _enableNonfunctionTypeAliasesInLibrary ??= loader.target
          .isExperimentEnabledInLibrary(ExperimentalFlag.nonfunctionTypeAliases,
              _packageUri ?? importUri);

  /// Returns `true` if the 'non-nullable' experiment is enabled for this
  /// library.
  ///
  /// Note that the library might still opt out of the experiment by having
  /// a version that is too low for opting in to the experiment.
  bool get enableNonNullableInLibrary => _enableNonNullableInLibrary ??=
      loader.target.isExperimentEnabledInLibrary(
              ExperimentalFlag.nonNullable, _packageUri ?? importUri) &&
          !isOptOutTest(library.importUri);

  Version get enableNonNullableVersionInLibrary =>
      _enableNonNullableVersionInLibrary ??= loader.target
          .getExperimentEnabledVersionInLibrary(
              ExperimentalFlag.nonNullable, _packageUri ?? importUri);

  bool get enableTripleShiftInLibrary => _enableTripleShiftInLibrary ??=
      loader.target.isExperimentEnabledInLibrary(
          ExperimentalFlag.tripleShift, _packageUri ?? importUri);

  bool get enableExtensionMethodsInLibrary =>
      _enableExtensionMethodsInLibrary ??= loader.target
          .isExperimentEnabledInLibrary(
              ExperimentalFlag.extensionMethods, _packageUri ?? importUri);

  void updateLibraryNNBDSettings() {
    library.isNonNullableByDefault = isNonNullableByDefault;
    if (enableNonNullableInLibrary) {
      switch (loader.nnbdMode) {
        case NnbdMode.Weak:
          library.nonNullableByDefaultCompiledMode =
              NonNullableByDefaultCompiledMode.Weak;
          break;
        case NnbdMode.Strong:
          library.nonNullableByDefaultCompiledMode =
              NonNullableByDefaultCompiledMode.Strong;
          break;
        case NnbdMode.Agnostic:
          library.nonNullableByDefaultCompiledMode =
              NonNullableByDefaultCompiledMode.Agnostic;
          break;
      }
    } else {
      library.nonNullableByDefaultCompiledMode =
          NonNullableByDefaultCompiledMode.Weak;
    }
  }

  SourceLibraryBuilder(Uri uri, Uri fileUri, Uri packageUri, Loader loader,
      SourceLibraryBuilder actualOrigin,
      {Scope scope,
      Library target,
      Library nameOrigin,
      Library referencesFrom,
      bool referenceIsPartOwner})
      : this.internal(
            loader,
            fileUri,
            packageUri,
            scope,
            actualOrigin,
            target ??
                (actualOrigin?.library ??
                    new Library(uri,
                        fileUri: fileUri,
                        reference: referenceIsPartOwner == true
                            ? null
                            : referencesFrom?.reference)
                  ..setLanguageVersion(loader.target.currentSdkVersion)),
            nameOrigin,
            referencesFrom,
            referenceIsPartOwner);

  @override
  bool get isPart => partOfName != null || partOfUri != null;

  List<UnresolvedType> get types => libraryDeclaration.types;

  @override
  bool get isSynthetic => accessProblem != null;

  TypeBuilder addType(TypeBuilder type, int charOffset) {
    currentTypeParameterScopeBuilder
        .addType(new UnresolvedType(type, charOffset, fileUri));
    return type;
  }

  bool _isNonNullableByDefault;

  @override
  bool get isNonNullableByDefault {
    assert(
        _isNonNullableByDefault == null ||
            _isNonNullableByDefault == _computeIsNonNullableByDefault(),
        "Unstable isNonNullableByDefault property, changed "
        "from ${_isNonNullableByDefault} to "
        "${_computeIsNonNullableByDefault()}");
    return _ensureIsNonNullableByDefault();
  }

  bool _ensureIsNonNullableByDefault() {
    if (_isNonNullableByDefault == null) {
      _isNonNullableByDefault = _computeIsNonNullableByDefault();
      updateLibraryNNBDSettings();
    }
    return _isNonNullableByDefault;
  }

  bool _computeIsNonNullableByDefault() =>
      enableNonNullableInLibrary &&
      languageVersion.version >= enableNonNullableVersionInLibrary;

  static bool isOptOutTest(Uri uri) {
    String path = uri.path;
    for (String testDir in ['/tests/', '/generated_tests/']) {
      int start = path.indexOf(testDir);
      if (start == -1) continue;
      String rest = path.substring(start + testDir.length);
      return optOutTestPaths.any(rest.startsWith);
    }
    return false;
  }

  static const List<String> optOutTestPaths = [
    'co19_2/',
    'corelib_2/',
    'dart2js_2/',
    'ffi_2',
    'language_2/',
    'lib_2/',
    'samples_2/',
    'service_2/',
    'standalone_2/',
    'vm/dart_2/', // in runtime/tests
  ];

  LanguageVersion get languageVersion => _languageVersion;

  void markLanguageVersionFinal() {
    if (!isNonNullableByDefault &&
        (loader.nnbdMode == NnbdMode.Strong ||
            loader.nnbdMode == NnbdMode.Agnostic)) {
      // In strong and agnostic mode, the language version is not allowed to
      // opt a library out of nnbd.
      if (_languageVersion.isExplicit) {
        addPostponedProblem(messageStrongModeNNBDButOptOut,
            _languageVersion.charOffset, _languageVersion.charCount, fileUri);
      } else {
        loader.registerStrongOptOutLibrary(this);
      }
      library.nonNullableByDefaultCompiledMode =
          NonNullableByDefaultCompiledMode.Invalid;
      loader.hasInvalidNnbdModeLibrary = true;
    }
    _languageVersion.isFinal = true;
    _ensureIsNonNullableByDefault();
  }

  @override
  void setLanguageVersion(Version version,
      {int offset: 0, int length: noLength, bool explicit: false}) {
    assert(!_languageVersion.isFinal);
    if (languageVersion.isExplicit) return;

    if (version == null) {
      addPostponedProblem(
          messageLanguageVersionInvalidInDotPackages, offset, length, fileUri);
      if (_languageVersion is ImplicitLanguageVersion) {
        // If the package set an OK version, but the file set an invalid version
        // we want to use the package version.
        _languageVersion = new InvalidLanguageVersion(
            fileUri, offset, length, explicit, loader.target.currentSdkVersion);
        library.setLanguageVersion(_languageVersion.version);
      }
      return;
    }

    // If trying to set a language version that is higher than the current sdk
    // version it's an error.
    if (version > loader.target.currentSdkVersion) {
      addPostponedProblem(
          templateLanguageVersionTooHigh.withArguments(
              loader.target.currentSdkVersion.major,
              loader.target.currentSdkVersion.minor),
          offset,
          length,
          fileUri);
      if (_languageVersion is ImplicitLanguageVersion) {
        // If the package set an OK version, but the file set an invalid version
        // we want to use the package version.
        _languageVersion = new InvalidLanguageVersion(
            fileUri, offset, length, explicit, loader.target.currentSdkVersion);
        library.setLanguageVersion(_languageVersion.version);
      }
      return;
    }

    _languageVersion =
        new LanguageVersion(version, fileUri, offset, length, explicit);
    library.setLanguageVersion(version);
  }

  ConstructorReferenceBuilder addConstructorReference(Object name,
      List<TypeBuilder> typeArguments, String suffix, int charOffset) {
    ConstructorReferenceBuilder ref = new ConstructorReferenceBuilder(
        name, typeArguments, suffix, this, charOffset);
    constructorReferences.add(ref);
    return ref;
  }

  void beginNestedDeclaration(TypeParameterScopeKind kind, String name,
      {bool hasMembers: true}) {
    currentTypeParameterScopeBuilder =
        currentTypeParameterScopeBuilder.createNested(kind, name, hasMembers);
  }

  TypeParameterScopeBuilder endNestedDeclaration(
      TypeParameterScopeKind kind, String name) {
    assert(
        currentTypeParameterScopeBuilder.kind == kind,
        "Unexpected declaration. "
        "Trying to end a ${currentTypeParameterScopeBuilder.kind} as a $kind.");
    assert(
        (name?.startsWith(currentTypeParameterScopeBuilder.name) ??
                (name == currentTypeParameterScopeBuilder.name)) ||
            currentTypeParameterScopeBuilder.name == "operator" ||
            identical(name, "<syntax-error>"),
        "${name} != ${currentTypeParameterScopeBuilder.name}");
    TypeParameterScopeBuilder previous = currentTypeParameterScopeBuilder;
    currentTypeParameterScopeBuilder = currentTypeParameterScopeBuilder.parent;
    return previous;
  }

  bool uriIsValid(Uri uri) => uri.scheme != MALFORMED_URI_SCHEME;

  Uri resolve(Uri baseUri, String uri, int uriOffset, {isPart: false}) {
    if (uri == null) {
      addProblem(messageExpectedUri, uriOffset, noLength, fileUri);
      return new Uri(scheme: MALFORMED_URI_SCHEME);
    }
    Uri parsedUri;
    try {
      parsedUri = Uri.parse(uri);
    } on FormatException catch (e) {
      // Point to position in string indicated by the exception,
      // or to the initial quote if no position is given.
      // (Assumes the directive is using a single-line string.)
      addProblem(templateCouldNotParseUri.withArguments(uri, e.message),
          uriOffset + 1 + (e.offset ?? -1), 1, fileUri);
      return new Uri(
          scheme: MALFORMED_URI_SCHEME, query: Uri.encodeQueryComponent(uri));
    }
    if (isPart && baseUri.scheme == "dart") {
      // Resolve using special rules for dart: URIs
      return resolveRelativeUri(baseUri, parsedUri);
    } else {
      return baseUri.resolveUri(parsedUri);
    }
  }

  String computeAndValidateConstructorName(Object name, int charOffset,
      {isFactory: false}) {
    String className = currentTypeParameterScopeBuilder.name;
    String prefix;
    String suffix;
    if (name is QualifiedName) {
      prefix = name.qualifier;
      suffix = name.name;
    } else {
      prefix = name;
      suffix = null;
    }
    if (prefix == className) {
      return suffix ?? "";
    }
    if (suffix == null && !isFactory) {
      // A legal name for a regular method, but not for a constructor.
      return null;
    }

    addProblem(
        messageConstructorWithWrongName, charOffset, prefix.length, fileUri,
        context: [
          templateConstructorWithWrongNameContext
              .withArguments(currentTypeParameterScopeBuilder.name)
              .withLocation(
                  importUri,
                  currentTypeParameterScopeBuilder.charOffset,
                  currentTypeParameterScopeBuilder.name.length)
        ]);

    return suffix;
  }

  void addExport(
      List<MetadataBuilder> metadata,
      String uri,
      List<Configuration> configurations,
      List<Combinator> combinators,
      int charOffset,
      int uriOffset) {
    if (configurations != null) {
      for (Configuration config in configurations) {
        if (lookupImportCondition(config.dottedName) == config.condition) {
          uri = config.importUri;
          break;
        }
      }
    }

    LibraryBuilder exportedLibrary = loader.read(
        resolve(this.importUri, uri, uriOffset), charOffset,
        accessor: this);
    exportedLibrary.addExporter(this, combinators, charOffset);
    exports.add(new Export(this, exportedLibrary, combinators, charOffset));
  }

  String lookupImportCondition(String dottedName) {
    const String prefix = "dart.library.";
    if (!dottedName.startsWith(prefix)) return "";
    dottedName = dottedName.substring(prefix.length);
    if (!loader.target.uriTranslator.isLibrarySupported(dottedName)) return "";

    LibraryBuilder imported =
        loader.builders[new Uri(scheme: "dart", path: dottedName)];

    if (imported == null) {
      LibraryBuilder coreLibrary = loader.read(
          resolve(this.importUri,
              new Uri(scheme: "dart", path: "core").toString(), -1),
          -1,
          accessor: loader.first);
      imported = coreLibrary
          .loader.builders[new Uri(scheme: 'dart', path: dottedName)];
    }
    return imported != null && !imported.isSynthetic ? "true" : "";
  }

  void addImport(
      List<MetadataBuilder> metadata,
      String uri,
      List<Configuration> configurations,
      String prefix,
      List<Combinator> combinators,
      bool deferred,
      int charOffset,
      int prefixCharOffset,
      int uriOffset,
      int importIndex) {
    if (configurations != null) {
      for (Configuration config in configurations) {
        if (lookupImportCondition(config.dottedName) == config.condition) {
          uri = config.importUri;
          break;
        }
      }
    }

    LibraryBuilder builder = null;

    Uri resolvedUri;
    String nativePath;
    const String nativeExtensionScheme = "dart-ext:";
    if (uri.startsWith(nativeExtensionScheme)) {
      String strippedUri = uri.substring(nativeExtensionScheme.length);
      if (strippedUri.startsWith("package")) {
        resolvedUri = resolve(this.importUri, strippedUri,
            uriOffset + nativeExtensionScheme.length);
        resolvedUri = loader.target.translateUri(resolvedUri);
        nativePath = resolvedUri.toString();
      } else {
        resolvedUri = new Uri(scheme: "dart-ext", pathSegments: [uri]);
        nativePath = uri;
      }
    } else {
      resolvedUri = resolve(this.importUri, uri, uriOffset);
      builder = loader.read(resolvedUri, uriOffset, accessor: this);
    }

    imports.add(new Import(this, builder, deferred, prefix, combinators,
        configurations, charOffset, prefixCharOffset, importIndex,
        nativeImportPath: nativePath));
  }

  void addPart(List<MetadataBuilder> metadata, String uri, int charOffset) {
    Uri resolvedUri;
    Uri newFileUri;
    resolvedUri = resolve(this.importUri, uri, charOffset, isPart: true);
    newFileUri = resolve(fileUri, uri, charOffset);
    // TODO(johnniwinther): Add a LibraryPartBuilder instead of using
    // [LibraryBuilder] to represent both libraries and parts.
    parts.add(loader.read(resolvedUri, charOffset,
        fileUri: newFileUri, accessor: this));
    partOffsets.add(charOffset);

    // TODO(ahe): [metadata] should be stored, evaluated, and added to [part].
    LibraryPart part = new LibraryPart(<Expression>[], uri)
      ..fileOffset = charOffset;
    library.addPart(part);
  }

  void addPartOf(
      List<MetadataBuilder> metadata, String name, String uri, int uriOffset) {
    partOfName = name;
    if (uri != null) {
      partOfUri = resolve(this.importUri, uri, uriOffset);
      Uri newFileUri = resolve(fileUri, uri, uriOffset);
      LibraryBuilder library = loader.read(partOfUri, uriOffset,
          fileUri: newFileUri, accessor: this);
      if (loader.first == this) {
        // This is a part, and it was the first input. Let the loader know
        // about that.
        loader.first = library;
      }
    }
  }

  void addFields(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      bool isTopLevel,
      TypeBuilder type,
      List<FieldInfo> fieldInfos) {
    for (FieldInfo info in fieldInfos) {
      bool isConst = modifiers & constMask != 0;
      bool isFinal = modifiers & finalMask != 0;
      bool potentiallyNeedInitializerInOutline = isConst || isFinal;
      Token startToken;
      if (potentiallyNeedInitializerInOutline || type == null) {
        startToken = info.initializerToken;
      }
      if (startToken != null) {
        // Extract only the tokens for the initializer expression from the
        // token stream.
        Token endToken = info.beforeLast;
        endToken.setNext(new Token.eof(endToken.next.offset));
        new Token.eof(startToken.previous.offset).setNext(startToken);
      }
      bool hasInitializer = info.initializerToken != null;
      addField(
          documentationComment,
          metadata,
          modifiers,
          isTopLevel,
          type,
          info.name,
          info.charOffset,
          info.charEndOffset,
          startToken,
          hasInitializer,
          constInitializerToken:
              potentiallyNeedInitializerInOutline ? startToken : null);
    }
  }

  @override
  Builder addBuilder(String name, Builder declaration, int charOffset,
      {Reference getterReference, Reference setterReference}) {
    // TODO(ahe): Set the parent correctly here. Could then change the
    // implementation of MemberBuilder.isTopLevel to test explicitly for a
    // LibraryBuilder.
    if (name == null) {
      unhandled("null", "name", charOffset, fileUri);
    }
    if (getterReference != null) {
      loader.buildersCreatedWithReferences[getterReference] = declaration;
    }
    if (setterReference != null) {
      loader.buildersCreatedWithReferences[setterReference] = declaration;
    }
    if (currentTypeParameterScopeBuilder == libraryDeclaration) {
      if (declaration is MemberBuilder) {
        declaration.parent = this;
      } else if (declaration is TypeDeclarationBuilder) {
        declaration.parent = this;
      } else if (declaration is PrefixBuilder) {
        assert(declaration.parent == this);
      } else {
        return unhandled(
            "${declaration.runtimeType}", "addBuilder", charOffset, fileUri);
      }
    } else {
      assert(currentTypeParameterScopeBuilder.parent == libraryDeclaration);
    }
    bool isConstructor = declaration is FunctionBuilder &&
        (declaration.isConstructor || declaration.isFactory);
    if (!isConstructor && name == currentTypeParameterScopeBuilder.name) {
      addProblem(
          messageMemberWithSameNameAsClass, charOffset, noLength, fileUri);
    }
    Map<String, Builder> members = isConstructor
        ? currentTypeParameterScopeBuilder.constructors
        : (declaration.isSetter
            ? currentTypeParameterScopeBuilder.setters
            : currentTypeParameterScopeBuilder.members);
    Builder existing = members[name];

    if (existing == declaration) return existing;

    if (declaration.next != null && declaration.next != existing) {
      unexpected(
          "${declaration.next.fileUri}@${declaration.next.charOffset}",
          "${existing?.fileUri}@${existing?.charOffset}",
          declaration.charOffset,
          declaration.fileUri);
    }
    declaration.next = existing;
    if (declaration is PrefixBuilder && existing is PrefixBuilder) {
      assert(existing.next is! PrefixBuilder);
      Builder deferred;
      Builder other;
      if (declaration.deferred) {
        deferred = declaration;
        other = existing;
      } else if (existing.deferred) {
        deferred = existing;
        other = declaration;
      }
      if (deferred != null) {
        addProblem(templateDeferredPrefixDuplicated.withArguments(name),
            deferred.charOffset, noLength, fileUri,
            context: [
              templateDeferredPrefixDuplicatedCause
                  .withArguments(name)
                  .withLocation(fileUri, other.charOffset, noLength)
            ]);
      }
      return existing
        ..exportScope.merge(declaration.exportScope,
            (String name, Builder existing, Builder member) {
          return computeAmbiguousDeclaration(
              name, existing, member, charOffset);
        });
    } else if (isDuplicatedDeclaration(existing, declaration)) {
      String fullName = name;
      if (isConstructor) {
        if (name.isEmpty) {
          fullName = currentTypeParameterScopeBuilder.name;
        } else {
          fullName = "${currentTypeParameterScopeBuilder.name}.$name";
        }
      }
      addProblem(templateDuplicatedDeclaration.withArguments(fullName),
          charOffset, fullName.length, declaration.fileUri,
          context: <LocatedMessage>[
            templateDuplicatedDeclarationCause
                .withArguments(fullName)
                .withLocation(
                    existing.fileUri, existing.charOffset, fullName.length)
          ]);
    } else if (declaration.isExtension) {
      // We add the extension declaration to the extension scope only if its
      // name is unique. Only the first of duplicate extensions is accessible
      // by name or by resolution and the remaining are dropped for the output.
      currentTypeParameterScopeBuilder.extensions.add(declaration);
    }
    if (declaration is PrefixBuilder) {
      _prefixBuilders ??= <PrefixBuilder>[];
      _prefixBuilders.add(declaration);
    }
    return members[name] = declaration;
  }

  bool isDuplicatedDeclaration(Builder existing, Builder other) {
    if (existing == null) return false;
    Builder next = existing.next;
    if (next == null) {
      if (existing.isGetter && other.isSetter) return false;
      if (existing.isSetter && other.isGetter) return false;
    } else {
      if (next is ClassBuilder && !next.isMixinApplication) return true;
    }
    if (existing is ClassBuilder && other is ClassBuilder) {
      // We allow multiple mixin applications with the same name. An
      // alternative is to share these mixin applications. This situation can
      // happen if you have `class A extends Object with Mixin {}` and `class B
      // extends Object with Mixin {}` in the same library.
      return !existing.isMixinApplication || !other.isMixinApplication;
    }
    return true;
  }

  /// Builds the core AST structure of this library as needed for the outline.
  Library build(LibraryBuilder coreLibrary, {bool modifyTarget}) {
    assert(implementationBuilders.isEmpty);
    canAddImplementationBuilders = true;
    Iterator<Builder> iterator = this.iterator;
    while (iterator.moveNext()) {
      buildBuilder(iterator.current, coreLibrary);
    }
    for (ImplementationInfo info in implementationBuilders) {
      String name = info.name;
      Builder declaration = info.declaration;
      int charOffset = info.charOffset;
      addBuilder(name, declaration, charOffset);
      buildBuilder(declaration, coreLibrary);
    }
    canAddImplementationBuilders = false;

    scope.forEachLocalSetter((String name, Builder setter) {
      Builder member = scopeBuilder[name];
      if (member == null ||
          !member.isField ||
          member.isFinal ||
          member.isConst) {
        return;
      }
      addProblem(templateConflictsWithMember.withArguments(name),
          setter.charOffset, noLength, fileUri);
      // TODO(ahe): Context to previous message?
      addProblem(templateConflictsWithSetter.withArguments(name),
          member.charOffset, noLength, fileUri);
    });

    if (modifyTarget == false) return library;

    library.isSynthetic = isSynthetic;
    addDependencies(library, new Set<SourceLibraryBuilder>());

    loader.target.metadataCollector
        ?.setDocumentationComment(library, documentationComment);

    library.name = name;
    library.procedures.sort(compareProcedures);

    if (unserializableExports != null) {
      Field referenceFrom = referencesFromIndexed?.lookupField("_exports#");
      library.addField(new Field(new Name("_exports#", library),
          initializer: new StringLiteral(jsonEncode(unserializableExports)),
          isStatic: true,
          isConst: true,
          getterReference: referenceFrom?.getterReference,
          setterReference: referenceFrom?.setterReference));
    }

    return library;
  }

  /// Used to add implementation builder during the call to [build] above.
  /// Currently, only anonymous mixins are using implementation builders (see
  /// [MixinApplicationBuilder]
  /// (../kernel/kernel_mixin_application_builder.dart)).
  void addImplementationBuilder(
      String name, Builder declaration, int charOffset) {
    assert(canAddImplementationBuilders, "$importUri");
    implementationBuilders
        .add(new ImplementationInfo(name, declaration, charOffset));
  }

  void validatePart(SourceLibraryBuilder library, Set<Uri> usedParts) {
    if (library != null && parts.isNotEmpty) {
      // If [library] is null, we have already reported a problem that this
      // part is orphaned.
      List<LocatedMessage> context = <LocatedMessage>[
        messagePartInPartLibraryContext.withLocation(library.fileUri, -1, 1),
      ];
      for (int offset in partOffsets) {
        addProblem(messagePartInPart, offset, noLength, fileUri,
            context: context);
      }
      for (SourceLibraryBuilder part in parts) {
        // Mark this part as used so we don't report it as orphaned.
        usedParts.add(part.importUri);
      }
    }
    parts.clear();
    if (exporters.isNotEmpty) {
      List<LocatedMessage> context = <LocatedMessage>[
        messagePartExportContext.withLocation(fileUri, -1, 1),
      ];
      for (Export export in exporters) {
        export.exporter.addProblem(
            messagePartExport, export.charOffset, "export".length, null,
            context: context);
      }
    }
  }

  void includeParts(Set<Uri> usedParts) {
    Set<Uri> seenParts = new Set<Uri>();
    for (int i = 0; i < parts.length; i++) {
      LibraryBuilder part = parts[i];
      int partOffset = partOffsets[i];
      if (part == this) {
        addProblem(messagePartOfSelf, -1, noLength, fileUri);
      } else if (seenParts.add(part.fileUri)) {
        if (part.partOfLibrary != null) {
          addProblem(messagePartOfTwoLibraries, -1, noLength, part.fileUri,
              context: [
                messagePartOfTwoLibrariesContext.withLocation(
                    part.partOfLibrary.fileUri, -1, noLength),
                messagePartOfTwoLibrariesContext.withLocation(
                    this.fileUri, -1, noLength)
              ]);
        } else {
          if (isPatch) {
            usedParts.add(part.fileUri);
          } else {
            usedParts.add(part.importUri);
          }
          includePart(part, usedParts, partOffset);
        }
      } else {
        addProblem(templatePartTwice.withArguments(part.fileUri), -1, noLength,
            fileUri);
      }
    }
  }

  bool includePart(LibraryBuilder part, Set<Uri> usedParts, int partOffset) {
    if (part is SourceLibraryBuilder) {
      if (part.partOfUri != null) {
        if (uriIsValid(part.partOfUri) && part.partOfUri != importUri) {
          // This is an error, but the part is not removed from the list of
          // parts, so that metadata annotations can be associated with it.
          addProblem(
              templatePartOfUriMismatch.withArguments(
                  part.fileUri, importUri, part.partOfUri),
              partOffset,
              noLength,
              fileUri);
          return false;
        }
      } else if (part.partOfName != null) {
        if (name != null) {
          if (part.partOfName != name) {
            // This is an error, but the part is not removed from the list of
            // parts, so that metadata annotations can be associated with it.
            addProblem(
                templatePartOfLibraryNameMismatch.withArguments(
                    part.fileUri, name, part.partOfName),
                partOffset,
                noLength,
                fileUri);
            return false;
          }
        } else {
          // This is an error, but the part is not removed from the list of
          // parts, so that metadata annotations can be associated with it.
          addProblem(
              templatePartOfUseUri.withArguments(
                  part.fileUri, fileUri, part.partOfName),
              partOffset,
              noLength,
              fileUri);
          return false;
        }
      } else {
        // This is an error, but the part is not removed from the list of parts,
        // so that metadata annotations can be associated with it.
        assert(!part.isPart);
        if (uriIsValid(part.fileUri)) {
          addProblem(templateMissingPartOf.withArguments(part.fileUri),
              partOffset, noLength, fileUri);
        }
        return false;
      }

      // Language versions have to match. Except if (at least) one of them is
      // invalid in which case we've already gotten an error about this.
      if (languageVersion != part.languageVersion &&
          languageVersion.valid &&
          part.languageVersion.valid) {
        // This is an error, but the part is not removed from the list of
        // parts, so that metadata annotations can be associated with it.
        List<LocatedMessage> context = <LocatedMessage>[];
        if (languageVersion.isExplicit) {
          context.add(messageLanguageVersionLibraryContext.withLocation(
              languageVersion.fileUri,
              languageVersion.charOffset,
              languageVersion.charCount));
        }
        if (part.languageVersion.isExplicit) {
          context.add(messageLanguageVersionPartContext.withLocation(
              part.languageVersion.fileUri,
              part.languageVersion.charOffset,
              part.languageVersion.charCount));
        }
        addProblem(
            messageLanguageVersionMismatchInPart, partOffset, noLength, fileUri,
            context: context);
      }

      part.validatePart(this, usedParts);
      NameIterator partDeclarations = part.nameIterator;
      while (partDeclarations.moveNext()) {
        String name = partDeclarations.name;
        Builder declaration = partDeclarations.current;

        if (declaration.next != null) {
          List<Builder> duplicated = <Builder>[];
          while (declaration.next != null) {
            duplicated.add(declaration);
            partDeclarations.moveNext();
            declaration = partDeclarations.current;
          }
          duplicated.add(declaration);
          // Handle duplicated declarations in the part.
          //
          // Duplicated declarations are handled by creating a linked list using
          // the `next` field. This is preferred over making all scope entries
          // be a `List<Declaration>`.
          //
          // We maintain the linked list so that the last entry is easy to
          // recognize (it's `next` field is null). This means that it is
          // reversed with respect to source code order. Since kernel doesn't
          // allow duplicated declarations, we ensure that we only add the first
          // declaration to the kernel tree.
          //
          // Since the duplicated declarations are stored in reverse order, we
          // iterate over them in reverse order as this is simpler and normally
          // not a problem. However, in this case we need to call [addBuilder]
          // in source order as it would otherwise create cycles.
          //
          // We also need to be careful preserving the order of the links. The
          // part library still keeps these declarations in its scope so that
          // DietListener can find them.
          for (int i = duplicated.length; i > 0; i--) {
            Builder declaration = duplicated[i - 1];
            // No reference: There should be no duplicates when using
            // references.
            addBuilder(name, declaration, declaration.charOffset);
          }
        } else {
          // No reference: The part is in the same loader so the reference
          // - if needed - was already added.
          addBuilder(name, declaration, declaration.charOffset);
        }
      }
      types.addAll(part.types);
      constructorReferences.addAll(part.constructorReferences);
      part.partOfLibrary = this;
      part.scope.becomePartOf(scope);
      // TODO(ahe): Include metadata from part?

      nativeMethods.addAll(part.nativeMethods);
      boundlessTypeVariables.addAll(part.boundlessTypeVariables);
      // Check that the targets are different. This is not normally a problem
      // but is for patch files.
      if (library != part.library && part.library.problemsAsJson != null) {
        library.problemsAsJson ??= <String>[];
        library.problemsAsJson.addAll(part.library.problemsAsJson);
      }
      List<FieldBuilder> partImplicitlyTypedFields =
          part.takeImplicitlyTypedFields();
      if (partImplicitlyTypedFields != null) {
        if (_implicitlyTypedFields == null) {
          _implicitlyTypedFields = partImplicitlyTypedFields;
        } else {
          _implicitlyTypedFields.addAll(partImplicitlyTypedFields);
        }
      }
      return true;
    } else {
      assert(part is DillLibraryBuilder);
      // Trying to add a dill library builder as a part means that it exists
      // as a stand-alone library in the dill file.
      // This means, that it's not a part (if it had been it would be been
      // "merged in" to the real library and thus not been a library on its own)
      // so we behave like if it's a library with a missing "part of"
      // declaration (i.e. as it was a SourceLibraryBuilder without a "part of"
      // declaration).
      if (uriIsValid(part.fileUri)) {
        addProblem(templateMissingPartOf.withArguments(part.fileUri),
            partOffset, noLength, fileUri);
      }
      return false;
    }
  }

  void buildInitialScopes() {
    NameIterator iterator = nameIterator;
    while (iterator.moveNext()) {
      addToExportScope(iterator.name, iterator.current);
    }
  }

  void addImportsToScope() {
    bool explicitCoreImport = this == loader.coreLibrary;
    for (Import import in imports) {
      if (import.imported == loader.coreLibrary) {
        explicitCoreImport = true;
      }
      if (import.imported?.isPart ?? false) {
        addProblem(
            templatePartOfInLibrary.withArguments(import.imported.fileUri),
            import.charOffset,
            noLength,
            fileUri);
      }
      import.finalizeImports(this);
    }
    if (!explicitCoreImport) {
      loader.coreLibrary.exportScope.forEach((String name, Builder member) {
        addToScope(name, member, -1, true);
      });
    }

    exportScope.forEach((String name, Builder member) {
      if (member.parent != this) {
        switch (name) {
          case "dynamic":
          case "void":
          case "Never":
            unserializableExports ??= <String, String>{};
            unserializableExports[name] = null;
            break;

          default:
            if (member is InvalidTypeDeclarationBuilder) {
              unserializableExports ??= <String, String>{};
              unserializableExports[name] = member.message.message;
            } else {
              // Eventually (in #buildBuilder) members aren't added to the
              // library if the have 'next' pointers, so don't add them as
              // additionalExports either. Add the last one only (the one that
              // will eventually be added to the library).
              Builder memberLast = member;
              while (memberLast.next != null) {
                memberLast = memberLast.next;
              }
              if (memberLast is ClassBuilder) {
                library.additionalExports.add(memberLast.cls.reference);
              } else if (memberLast is TypeAliasBuilder) {
                library.additionalExports.add(memberLast.typedef.reference);
              } else if (memberLast is ExtensionBuilder) {
                library.additionalExports.add(memberLast.extension.reference);
              } else if (memberLast is MemberBuilder) {
                for (Member member in memberLast.exportedMembers) {
                  if (member is Field) {
                    // For fields add both getter and setter references
                    // so replacing a field with a getter/setter pair still
                    // exports correctly.
                    library.additionalExports.add(member.getterReference);
                    library.additionalExports.add(member.setterReference);
                  } else {
                    library.additionalExports.add(member.reference);
                  }
                }
              } else {
                unhandled('member', 'exportScope', memberLast.charOffset,
                    memberLast.fileUri);
              }
            }
        }
      }
    });
  }

  @override
  void addToScope(String name, Builder member, int charOffset, bool isImport) {
    Builder existing =
        importScope.lookupLocalMember(name, setter: member.isSetter);
    if (existing != null) {
      if (existing != member) {
        importScope.addLocalMember(
            name,
            computeAmbiguousDeclaration(name, existing, member, charOffset,
                isImport: isImport),
            setter: member.isSetter);
      }
    } else {
      importScope.addLocalMember(name, member, setter: member.isSetter);
    }
    if (member.isExtension) {
      importScope.addExtension(member);
    }
  }

  /// Resolves all unresolved types in [types]. The list of types is cleared
  /// when done.
  int resolveTypes() {
    int typeCount = types.length;
    for (UnresolvedType t in types) {
      t.resolveIn(scope, this);
      t.checkType(this);
    }
    types.clear();
    return typeCount;
  }

  @override
  int resolveConstructors(_) {
    int count = 0;
    Iterator<Builder> iterator = this.iterator;
    while (iterator.moveNext()) {
      count += iterator.current.resolveConstructors(this);
    }
    return count;
  }

  @override
  String get fullNameForErrors {
    // TODO(ahe): Consider if we should use relativizeUri here. The downside to
    // doing that is that this URI may be used in an error message. Ideally, we
    // should create a class that represents qualified names that we can
    // relativize when printing a message, but still store the full URI in
    // .dill files.
    return name ?? "<library '$fileUri'>";
  }

  @override
  void recordAccess(int charOffset, int length, Uri fileUri) {
    accessors.add(fileUri);
    accessors.add(charOffset);
    accessors.add(length);
    if (accessProblem != null) {
      addProblem(accessProblem, charOffset, length, fileUri);
    }
  }

  void addProblemAtAccessors(Message message) {
    if (accessProblem == null) {
      if (accessors.isEmpty && this == loader.first) {
        // This is the entry point library, and nobody access it directly. So
        // we need to report a problem.
        loader.addProblem(message, -1, 1, null);
      }
      for (int i = 0; i < accessors.length; i += 3) {
        Uri accessor = accessors[i];
        int charOffset = accessors[i + 1];
        int length = accessors[i + 2];
        addProblem(message, charOffset, length, accessor);
      }
      accessProblem = message;
    }
  }

  @override
  SourceLibraryBuilder get origin => actualOrigin ?? this;

  Uri get importUri => library.importUri;

  void addSyntheticDeclarationOfDynamic() {
    addBuilder("dynamic",
        new DynamicTypeDeclarationBuilder(const DynamicType(), this, -1), -1);
  }

  void addSyntheticDeclarationOfNever() {
    addBuilder(
        "Never",
        new NeverTypeDeclarationBuilder(
            const NeverType(Nullability.nonNullable), this, -1),
        -1);
  }

  void addSyntheticDeclarationOfNull() {
    // TODO(dmitryas): Uncomment the following when the Null class is removed
    // from the SDK.
    //addBuilder("Null", new NullTypeBuilder(const NullType(), this, -1), -1);
  }

  TypeBuilder addNamedType(Object name, NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder> arguments, int charOffset) {
    return addType(
        new NamedTypeBuilder(
            name, nullabilityBuilder, arguments, fileUri, charOffset),
        charOffset);
  }

  TypeBuilder addMixinApplication(
      TypeBuilder supertype, List<TypeBuilder> mixins, int charOffset) {
    return addType(
        new MixinApplicationBuilder(supertype, mixins, fileUri, charOffset),
        charOffset);
  }

  TypeBuilder addVoidType(int charOffset) {
    // 'void' is always nullable.
    return addNamedType(
        "void", const NullabilityBuilder.nullable(), null, charOffset)
      ..bind(
          new VoidTypeDeclarationBuilder(const VoidType(), this, charOffset));
  }

  /// Add a problem that might not be reported immediately.
  ///
  /// Problems will be issued after source information has been added.
  /// Once the problems has been issued, adding a new "postponed" problem will
  /// be issued immediately.
  void addPostponedProblem(
      Message message, int charOffset, int length, Uri fileUri) {
    if (postponedProblemsIssued) {
      addProblem(message, charOffset, length, fileUri);
    } else {
      postponedProblems ??= <PostponedProblem>[];
      postponedProblems
          .add(new PostponedProblem(message, charOffset, length, fileUri));
    }
  }

  void issuePostponedProblems() {
    postponedProblemsIssued = true;
    if (postponedProblems == null) return;
    for (int i = 0; i < postponedProblems.length; ++i) {
      PostponedProblem postponedProblem = postponedProblems[i];
      addProblem(postponedProblem.message, postponedProblem.charOffset,
          postponedProblem.length, postponedProblem.fileUri);
    }
    postponedProblems = null;
  }

  @override
  FormattedMessage addProblem(
      Message message, int charOffset, int length, Uri fileUri,
      {bool wasHandled: false,
      List<LocatedMessage> context,
      Severity severity,
      bool problemOnLibrary: false}) {
    FormattedMessage formattedMessage = super.addProblem(
        message, charOffset, length, fileUri,
        wasHandled: wasHandled,
        context: context,
        severity: severity,
        problemOnLibrary: true);
    if (formattedMessage != null) {
      library.problemsAsJson ??= <String>[];
      library.problemsAsJson.add(formattedMessage.toJsonString());
    }
    return formattedMessage;
  }

  void addClass(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      String className,
      List<TypeVariableBuilder> typeVariables,
      TypeBuilder supertype,
      List<TypeBuilder> interfaces,
      int startOffset,
      int nameOffset,
      int endOffset,
      int supertypeOffset) {
    _addClass(
        TypeParameterScopeKind.classDeclaration,
        documentationComment,
        metadata,
        modifiers,
        className,
        typeVariables,
        supertype,
        interfaces,
        startOffset,
        nameOffset,
        endOffset,
        supertypeOffset);
  }

  void addMixinDeclaration(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      String className,
      List<TypeVariableBuilder> typeVariables,
      TypeBuilder supertype,
      List<TypeBuilder> interfaces,
      int startOffset,
      int nameOffset,
      int endOffset,
      int supertypeOffset) {
    _addClass(
        TypeParameterScopeKind.mixinDeclaration,
        documentationComment,
        metadata,
        modifiers,
        className,
        typeVariables,
        supertype,
        interfaces,
        startOffset,
        nameOffset,
        endOffset,
        supertypeOffset);
  }

  void _addClass(
      TypeParameterScopeKind kind,
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      String className,
      List<TypeVariableBuilder> typeVariables,
      TypeBuilder supertype,
      List<TypeBuilder> interfaces,
      int startOffset,
      int nameOffset,
      int endOffset,
      int supertypeOffset) {
    // Nested declaration began in `OutlineBuilder.beginClassDeclaration`.
    TypeParameterScopeBuilder declaration =
        endNestedDeclaration(kind, className)
          ..resolveTypes(typeVariables, this);
    assert(declaration.parent == libraryDeclaration);
    Map<String, MemberBuilder> members = declaration.members;
    Map<String, MemberBuilder> constructors = declaration.constructors;
    Map<String, MemberBuilder> setters = declaration.setters;

    Scope classScope = new Scope(
        local: members,
        setters: setters,
        parent: scope.withTypeVariables(typeVariables),
        debugName: "class $className",
        isModifiable: false);

    // When looking up a constructor, we don't consider type variables or the
    // library scope.
    ConstructorScope constructorScope =
        new ConstructorScope(className, constructors);
    bool isMixinDeclaration = false;
    if (modifiers & mixinDeclarationMask != 0) {
      isMixinDeclaration = true;
      modifiers = (modifiers & ~mixinDeclarationMask) | abstractMask;
    }
    if (declaration.declaresConstConstructor) {
      modifiers |= declaresConstConstructorMask;
    }
    Class referencesFromClass;
    if (referencesFrom != null) {
      referencesFromClass = referencesFromIndexed.lookupClass(className);
      assert(referencesFromClass == null ||
          _currentClassReferencesFromIndexed != null);
    }
    ClassBuilder classBuilder = new SourceClassBuilder(
        metadata,
        modifiers,
        className,
        typeVariables,
        applyMixins(supertype, startOffset, nameOffset, endOffset, className,
            isMixinDeclaration,
            typeVariables: typeVariables),
        interfaces,
        // TODO(johnniwinther): Add the `on` clause types of a mixin declaration
        // here.
        null,
        classScope,
        constructorScope,
        this,
        new List<ConstructorReferenceBuilder>.from(constructorReferences),
        startOffset,
        nameOffset,
        endOffset,
        referencesFromClass,
        _currentClassReferencesFromIndexed,
        isMixinDeclaration: isMixinDeclaration);
    loader.target.metadataCollector
        ?.setDocumentationComment(classBuilder.cls, documentationComment);

    constructorReferences.clear();
    Map<String, TypeVariableBuilder> typeVariablesByName =
        checkTypeVariables(typeVariables, classBuilder);
    void setParent(String name, MemberBuilder member) {
      while (member != null) {
        member.parent = classBuilder;
        member = member.next;
      }
    }

    void setParentAndCheckConflicts(String name, MemberBuilder member) {
      if (typeVariablesByName != null) {
        TypeVariableBuilder tv = typeVariablesByName[name];
        if (tv != null) {
          classBuilder.addProblem(
              templateConflictsWithTypeVariable.withArguments(name),
              member.charOffset,
              name.length,
              context: [
                messageConflictsWithTypeVariableCause.withLocation(
                    tv.fileUri, tv.charOffset, name.length)
              ]);
        }
      }
      setParent(name, member);
    }

    members.forEach(setParentAndCheckConflicts);
    constructors.forEach(setParentAndCheckConflicts);
    setters.forEach(setParentAndCheckConflicts);
    addBuilder(className, classBuilder, nameOffset,
        getterReference: referencesFromClass?.reference);
  }

  Map<String, TypeVariableBuilder> checkTypeVariables(
      List<TypeVariableBuilder> typeVariables, Builder owner) {
    if (typeVariables?.isEmpty ?? true) return null;
    Map<String, TypeVariableBuilder> typeVariablesByName =
        <String, TypeVariableBuilder>{};
    for (TypeVariableBuilder tv in typeVariables) {
      TypeVariableBuilder existing = typeVariablesByName[tv.name];
      if (existing != null) {
        if (existing.isExtensionTypeParameter) {
          // The type parameter from the extension is shadowed by the type
          // parameter from the member. Rename the shadowed type parameter.
          existing.parameter.name = '#${existing.name}';
          typeVariablesByName[tv.name] = tv;
        } else {
          addProblem(messageTypeVariableDuplicatedName, tv.charOffset,
              tv.name.length, fileUri,
              context: [
                templateTypeVariableDuplicatedNameCause
                    .withArguments(tv.name)
                    .withLocation(
                        fileUri, existing.charOffset, existing.name.length)
              ]);
        }
      } else {
        typeVariablesByName[tv.name] = tv;
        if (owner is ClassBuilder) {
          // Only classes and type variables can't have the same name. See
          // [#29555](https://github.com/dart-lang/sdk/issues/29555).
          if (tv.name == owner.name) {
            addProblem(messageTypeVariableSameNameAsEnclosing, tv.charOffset,
                tv.name.length, fileUri);
          }
        }
      }
    }
    return typeVariablesByName;
  }

  void checkGetterSetterTypes(ProcedureBuilder getterBuilder,
      ProcedureBuilder setterBuilder, TypeEnvironment typeEnvironment) {
    DartType getterType;
    List<TypeParameter> getterExtensionTypeParameters;
    if (getterBuilder.isExtensionInstanceMember) {
      // An extension instance getter
      //
      //     extension E<T> on A {
      //       T get property => ...
      //     }
      //
      // is encoded as a top level method
      //
      //   T# E#get#property<T#>(A #this) => ...
      //
      Procedure procedure = getterBuilder.procedure;
      getterType = procedure.function.returnType;
      getterExtensionTypeParameters = procedure.function.typeParameters;
    } else {
      getterType = getterBuilder.procedure.getterType;
    }
    DartType setterType;
    if (setterBuilder.isExtensionInstanceMember) {
      // An extension instance setter
      //
      //     extension E<T> on A {
      //       void set property(T value) { ... }
      //     }
      //
      // is encoded as a top level method
      //
      //   void E#set#property<T#>(A #this, T# value) { ... }
      //
      Procedure procedure = setterBuilder.procedure;
      setterType = procedure.function.positionalParameters[1].type;
      if (getterExtensionTypeParameters != null &&
          getterExtensionTypeParameters.isNotEmpty) {
        // We substitute the setter type parameters for the getter type
        // parameters to check them below in a shared context.
        List<TypeParameter> setterExtensionTypeParameters =
            procedure.function.typeParameters;
        assert(getterExtensionTypeParameters.length ==
            setterExtensionTypeParameters.length);
        setterType = Substitution.fromPairs(
                setterExtensionTypeParameters,
                new List<DartType>.generate(
                    getterExtensionTypeParameters.length,
                    (int index) => new TypeParameterType.forAlphaRenaming(
                        setterExtensionTypeParameters[index],
                        getterExtensionTypeParameters[index])))
            .substituteType(setterType);
      }
    } else {
      setterType = setterBuilder.procedure.setterType;
    }

    if (getterType is InvalidType || setterType is InvalidType) {
      // Don't report a problem as something else is wrong that has already
      // been reported.
    } else {
      bool isValid = typeEnvironment.isSubtypeOf(
          getterType,
          setterType,
          library.isNonNullableByDefault
              ? SubtypeCheckMode.withNullabilities
              : SubtypeCheckMode.ignoringNullabilities);
      if (!isValid && !library.isNonNullableByDefault) {
        // Allow assignability in legacy libraries.
        isValid = typeEnvironment.isSubtypeOf(
            setterType, getterType, SubtypeCheckMode.ignoringNullabilities);
      }
      if (!isValid) {
        String getterMemberName = getterBuilder.fullNameForErrors;
        String setterMemberName = setterBuilder.fullNameForErrors;
        Template<Message Function(DartType, String, DartType, String, bool)>
            template = library.isNonNullableByDefault
                ? templateInvalidGetterSetterType
                : templateInvalidGetterSetterTypeLegacy;
        addProblem(
            template.withArguments(getterType, getterMemberName, setterType,
                setterMemberName, library.isNonNullableByDefault),
            getterBuilder.charOffset,
            getterBuilder.name.length,
            getterBuilder.fileUri,
            context: [
              templateInvalidGetterSetterTypeSetterContext
                  .withArguments(setterMemberName)
                  .withLocation(setterBuilder.fileUri, setterBuilder.charOffset,
                      setterBuilder.name.length)
            ]);
      }
    }
  }

  void addExtensionDeclaration(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      String extensionName,
      List<TypeVariableBuilder> typeVariables,
      TypeBuilder type,
      int startOffset,
      int nameOffset,
      int endOffset) {
    // Nested declaration began in `OutlineBuilder.beginExtensionDeclaration`.
    TypeParameterScopeBuilder declaration = endNestedDeclaration(
        TypeParameterScopeKind.extensionDeclaration, extensionName)
      ..resolveTypes(typeVariables, this);
    assert(declaration.parent == libraryDeclaration);
    Map<String, MemberBuilder> members = declaration.members;
    Map<String, MemberBuilder> constructors = declaration.constructors;
    Map<String, MemberBuilder> setters = declaration.setters;

    Scope classScope = new Scope(
        local: members,
        setters: setters,
        parent: scope.withTypeVariables(typeVariables),
        debugName: "extension $extensionName",
        isModifiable: false);

    Extension referenceFrom =
        referencesFromIndexed?.lookupExtension(extensionName);

    ExtensionBuilder extensionBuilder = new SourceExtensionBuilder(
        metadata,
        modifiers,
        extensionName,
        typeVariables,
        type,
        classScope,
        this,
        startOffset,
        nameOffset,
        endOffset,
        referenceFrom);
    loader.target.metadataCollector?.setDocumentationComment(
        extensionBuilder.extension, documentationComment);

    constructorReferences.clear();
    Map<String, TypeVariableBuilder> typeVariablesByName =
        checkTypeVariables(typeVariables, extensionBuilder);
    void setParent(String name, MemberBuilder member) {
      while (member != null) {
        member.parent = extensionBuilder;
        member = member.next;
      }
    }

    void setParentAndCheckConflicts(String name, MemberBuilder member) {
      if (typeVariablesByName != null) {
        TypeVariableBuilder tv = typeVariablesByName[name];
        if (tv != null) {
          extensionBuilder.addProblem(
              templateConflictsWithTypeVariable.withArguments(name),
              member.charOffset,
              name.length,
              context: [
                messageConflictsWithTypeVariableCause.withLocation(
                    tv.fileUri, tv.charOffset, name.length)
              ]);
        }
      }
      setParent(name, member);
    }

    members.forEach(setParentAndCheckConflicts);
    constructors.forEach(setParentAndCheckConflicts);
    setters.forEach(setParentAndCheckConflicts);
    addBuilder(extensionName, extensionBuilder, nameOffset,
        getterReference: referenceFrom?.reference);
  }

  TypeBuilder applyMixins(TypeBuilder type, int startCharOffset, int charOffset,
      int charEndOffset, String subclassName, bool isMixinDeclaration,
      {String documentationComment,
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      int modifiers,
      List<TypeBuilder> interfaces}) {
    if (name == null) {
      // The following parameters should only be used when building a named
      // mixin application.
      if (documentationComment != null) {
        unhandled("documentationComment", "unnamed mixin application",
            charOffset, fileUri);
      } else if (metadata != null) {
        unhandled("metadata", "unnamed mixin application", charOffset, fileUri);
      } else if (interfaces != null) {
        unhandled(
            "interfaces", "unnamed mixin application", charOffset, fileUri);
      }
    }
    if (type is MixinApplicationBuilder) {
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
      TypeBuilder supertype = type.supertype ?? loader.target.objectType;

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
      String runningName = extractName(supertype.name);

      /// True when we're building a named mixin application. Notice that for
      /// the `Named` example above, this is only true on the last
      /// iteration because only the full mixin application is named.
      bool isNamedMixinApplication;

      /// The names of the type variables of the subclass.
      Set<String> typeVariableNames;
      if (typeVariables != null) {
        typeVariableNames = new Set<String>();
        for (TypeVariableBuilder typeVariable in typeVariables) {
          typeVariableNames.add(typeVariable.name);
        }
      }

      /// Helper function that returns `true` if a type variable with a name
      /// from [typeVariableNames] is referenced in [type].
      bool usesTypeVariables(TypeBuilder type) {
        if (type is NamedTypeBuilder) {
          if (type.declaration is TypeVariableBuilder) {
            return typeVariableNames.contains(type.declaration.name);
          }

          List<TypeBuilder> typeArguments = type.arguments;
          if (typeArguments != null && typeVariables != null) {
            for (TypeBuilder argument in typeArguments) {
              if (usesTypeVariables(argument)) {
                return true;
              }
            }
          }
        } else if (type is FunctionTypeBuilder) {
          if (type.formals != null) {
            for (FormalParameterBuilder formal in type.formals) {
              if (usesTypeVariables(formal.type)) {
                return true;
              }
            }
          }
          List<TypeVariableBuilder> typeVariables = type.typeVariables;
          if (typeVariables != null) {
            for (TypeVariableBuilder variable in typeVariables) {
              if (usesTypeVariables(variable.bound)) {
                return true;
              }
            }
          }
          return usesTypeVariables(type.returnType);
        }
        return false;
      }

      /// Iterate over the mixins from left to right. At the end of each
      /// iteration, a new [supertype] is computed that is the mixin
      /// application of [supertype] with the current mixin.
      for (int i = 0; i < type.mixins.length; i++) {
        TypeBuilder mixin = type.mixins[i];
        isNamedMixinApplication = name != null && mixin == type.mixins.last;
        bool isGeneric = false;
        if (!isNamedMixinApplication) {
          if (supertype is NamedTypeBuilder) {
            isGeneric = isGeneric || usesTypeVariables(supertype);
          }
          if (mixin is NamedTypeBuilder) {
            runningName += "&${extractName(mixin.name)}";
            isGeneric = isGeneric || usesTypeVariables(mixin);
          }
        }
        String fullname =
            isNamedMixinApplication ? name : "_$subclassName&$runningName";
        List<TypeVariableBuilder> applicationTypeVariables;
        List<TypeBuilder> applicationTypeArguments;
        if (isNamedMixinApplication) {
          // If this is a named mixin application, it must be given all the
          // declarated type variables.
          applicationTypeVariables = typeVariables;
        } else {
          // Otherwise, we pass the fresh type variables to the mixin
          // application in the same order as they're declared on the subclass.
          if (isGeneric) {
            this.beginNestedDeclaration(
                TypeParameterScopeKind.unnamedMixinApplication,
                "mixin application");

            applicationTypeVariables = copyTypeVariables(
                typeVariables, currentTypeParameterScopeBuilder);

            List<TypeBuilder> newTypes = <TypeBuilder>[];
            if (supertype is NamedTypeBuilder && supertype.arguments != null) {
              for (int i = 0; i < supertype.arguments.length; ++i) {
                supertype.arguments[i] = supertype.arguments[i].clone(newTypes);
              }
            }
            if (mixin is NamedTypeBuilder && mixin.arguments != null) {
              for (int i = 0; i < mixin.arguments.length; ++i) {
                mixin.arguments[i] = mixin.arguments[i].clone(newTypes);
              }
            }
            for (TypeBuilder newType in newTypes) {
              currentTypeParameterScopeBuilder
                  .addType(new UnresolvedType(newType, -1, null));
            }

            TypeParameterScopeBuilder mixinDeclaration = this
                .endNestedDeclaration(
                    TypeParameterScopeKind.unnamedMixinApplication,
                    "mixin application");
            mixinDeclaration.resolveTypes(applicationTypeVariables, this);

            applicationTypeArguments = <TypeBuilder>[];
            for (TypeVariableBuilder typeVariable in typeVariables) {
              applicationTypeArguments.add(addNamedType(typeVariable.name,
                  const NullabilityBuilder.omitted(), null, charOffset)
                ..bind(
                    // The type variable types passed as arguments to the
                    // generic class representing the anonymous mixin
                    // application should refer back to the type variables of
                    // the class that extend the anonymous mixin application.
                    typeVariable));
            }
          }
        }
        final int computedStartCharOffset =
            (isNamedMixinApplication ? metadata : null) == null
                ? startCharOffset
                : metadata.first.charOffset;

        Class referencesFromClass;
        IndexedClass referencesFromIndexedClass;
        if (referencesFrom != null) {
          referencesFromClass = referencesFromIndexed.lookupClass(fullname);
          referencesFromIndexedClass =
              referencesFromIndexed.lookupIndexedClass(fullname);
        }

        SourceClassBuilder application = new SourceClassBuilder(
          isNamedMixinApplication ? metadata : null,
          isNamedMixinApplication
              ? modifiers | namedMixinApplicationMask
              : abstractMask,
          fullname,
          applicationTypeVariables,
          isMixinDeclaration ? null : supertype,
          isNamedMixinApplication
              ? interfaces
              : isMixinDeclaration
                  ? [supertype, mixin]
                  : null,
          null, // No `on` clause types.
          new Scope(
              local: <String, MemberBuilder>{},
              setters: <String, MemberBuilder>{},
              parent: scope.withTypeVariables(typeVariables),
              debugName: "mixin $fullname ",
              isModifiable: false),
          new ConstructorScope(fullname, <String, MemberBuilder>{}),
          this,
          <ConstructorReferenceBuilder>[],
          computedStartCharOffset,
          charOffset,
          charEndOffset,
          referencesFromClass,
          referencesFromIndexedClass,
          mixedInTypeBuilder: isMixinDeclaration ? null : mixin,
        );
        if (isNamedMixinApplication) {
          loader.target.metadataCollector
              ?.setDocumentationComment(application.cls, documentationComment);
        }
        // TODO(ahe, kmillikin): Should always be true?
        // pkg/analyzer/test/src/summary/resynthesize_kernel_test.dart can't
        // handle that :(
        application.cls.isAnonymousMixin = !isNamedMixinApplication;
        addBuilder(fullname, application, charOffset,
            getterReference: referencesFromClass?.reference);
        supertype = addNamedType(fullname, const NullabilityBuilder.omitted(),
            applicationTypeArguments, charOffset);
      }
      return supertype;
    } else {
      return type;
    }
  }

  void addNamedMixinApplication(
      String documentationComment,
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      int modifiers,
      TypeBuilder mixinApplication,
      List<TypeBuilder> interfaces,
      int startCharOffset,
      int charOffset,
      int charEndOffset) {
    // Nested declaration began in `OutlineBuilder.beginNamedMixinApplication`.
    endNestedDeclaration(TypeParameterScopeKind.namedMixinApplication, name)
        .resolveTypes(typeVariables, this);
    NamedTypeBuilder supertype = applyMixins(mixinApplication, startCharOffset,
        charOffset, charEndOffset, name, false,
        documentationComment: documentationComment,
        metadata: metadata,
        name: name,
        typeVariables: typeVariables,
        modifiers: modifiers,
        interfaces: interfaces);
    checkTypeVariables(typeVariables, supertype.declaration);
  }

  void addField(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      bool isTopLevel,
      TypeBuilder type,
      String name,
      int charOffset,
      int charEndOffset,
      Token initializerToken,
      bool hasInitializer,
      {Token constInitializerToken}) {
    if (hasInitializer) {
      modifiers |= hasInitializerMask;
    }
    Field referenceFrom;
    Field lateIsSetReferenceFrom;
    Procedure getterReferenceFrom;
    Procedure setterReferenceFrom;
    final bool fieldIsLateWithLowering = (modifiers & lateMask) != 0 &&
        loader.target.backendTarget.isLateFieldLoweringEnabled(
            hasInitializer: hasInitializer,
            isFinal: (modifiers & finalMask) != 0,
            isStatic: isTopLevel || (modifiers & staticMask) != 0);
    final bool isInstanceMember = currentTypeParameterScopeBuilder.kind ==
            TypeParameterScopeKind.classDeclaration &&
        (modifiers & staticMask) == 0;
    String className;
    if (isInstanceMember) {
      className = currentTypeParameterScopeBuilder.name;
    }
    final bool isExtension = currentTypeParameterScopeBuilder.kind ==
        TypeParameterScopeKind.extensionDeclaration;
    String extensionName;
    if (isExtension) {
      extensionName = currentTypeParameterScopeBuilder.name;
    }
    if (referencesFrom != null) {
      String nameToLookup = SourceFieldBuilder.createFieldName(
          FieldNameType.Field, name,
          isInstanceMember: isInstanceMember,
          className: className,
          isExtensionMethod: isExtension,
          extensionName: extensionName,
          isSynthesized: fieldIsLateWithLowering);

      if (_currentClassReferencesFromIndexed != null) {
        referenceFrom =
            _currentClassReferencesFromIndexed.lookupField(nameToLookup);
        if (fieldIsLateWithLowering) {
          lateIsSetReferenceFrom = _currentClassReferencesFromIndexed
              .lookupField(SourceFieldBuilder.createFieldName(
                  FieldNameType.IsSetField, name,
                  isInstanceMember: isInstanceMember,
                  className: className,
                  isExtensionMethod: isExtension,
                  extensionName: extensionName,
                  isSynthesized: fieldIsLateWithLowering));
          getterReferenceFrom =
              _currentClassReferencesFromIndexed.lookupProcedureNotSetter(
                  SourceFieldBuilder.createFieldName(FieldNameType.Getter, name,
                      isInstanceMember: isInstanceMember,
                      className: className,
                      isExtensionMethod: isExtension,
                      extensionName: extensionName,
                      isSynthesized: fieldIsLateWithLowering));
          setterReferenceFrom =
              _currentClassReferencesFromIndexed.lookupProcedureSetter(
                  SourceFieldBuilder.createFieldName(FieldNameType.Setter, name,
                      isInstanceMember: isInstanceMember,
                      className: className,
                      isExtensionMethod: isExtension,
                      extensionName: extensionName,
                      isSynthesized: fieldIsLateWithLowering));
        }
      } else {
        referenceFrom = referencesFromIndexed.lookupField(nameToLookup);
        if (fieldIsLateWithLowering) {
          lateIsSetReferenceFrom = referencesFromIndexed.lookupField(
              SourceFieldBuilder.createFieldName(FieldNameType.IsSetField, name,
                  isInstanceMember: isInstanceMember,
                  className: className,
                  isExtensionMethod: isExtension,
                  extensionName: extensionName,
                  isSynthesized: fieldIsLateWithLowering));
          getterReferenceFrom = referencesFromIndexed.lookupProcedureNotSetter(
              SourceFieldBuilder.createFieldName(FieldNameType.Getter, name,
                  isInstanceMember: isInstanceMember,
                  className: className,
                  isExtensionMethod: isExtension,
                  extensionName: extensionName,
                  isSynthesized: fieldIsLateWithLowering));
          setterReferenceFrom = referencesFromIndexed.lookupProcedureSetter(
              SourceFieldBuilder.createFieldName(FieldNameType.Setter, name,
                  isInstanceMember: isInstanceMember,
                  className: className,
                  isExtensionMethod: isExtension,
                  extensionName: extensionName,
                  isSynthesized: fieldIsLateWithLowering));
        }
      }
    }
    SourceFieldBuilder fieldBuilder = new SourceFieldBuilder(
        metadata,
        type,
        name,
        modifiers,
        isTopLevel,
        this,
        charOffset,
        charEndOffset,
        referenceFrom,
        lateIsSetReferenceFrom,
        getterReferenceFrom,
        setterReferenceFrom);
    fieldBuilder.constInitializerToken = constInitializerToken;
    addBuilder(name, fieldBuilder, charOffset,
        getterReference: referenceFrom?.getterReference,
        setterReference: referenceFrom?.setterReference);
    if (type == null && fieldBuilder.next == null) {
      // Only the first one (the last one in the linked list of next pointers)
      // are added to the tree, had parent pointers and can infer correctly.
      if (initializerToken == null && fieldBuilder.isStatic) {
        // A static field without type and initializer will always be inferred
        // to have type `dynamic`.
        fieldBuilder.fieldType = const DynamicType();
      } else {
        // A field with no type and initializer or an instance field without
        // type and initializer need to have the type inferred.
        fieldBuilder.fieldType =
            new ImplicitFieldType(fieldBuilder, initializerToken);
        registerImplicitlyTypedField(fieldBuilder);
      }
    }
    loader.target.metadataCollector
        ?.setDocumentationComment(fieldBuilder.field, documentationComment);
  }

  void addConstructor(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      TypeBuilder returnType,
      final Object name,
      String constructorName,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName,
      {Token beginInitializers}) {
    MetadataCollector metadataCollector = loader.target.metadataCollector;
    Constructor referenceFrom;
    if (_currentClassReferencesFromIndexed != null) {
      referenceFrom =
          _currentClassReferencesFromIndexed.lookupConstructor(constructorName);
    }
    ConstructorBuilder constructorBuilder = new ConstructorBuilderImpl(
        metadata,
        modifiers & ~abstractMask,
        returnType,
        constructorName,
        typeVariables,
        formals,
        this,
        startCharOffset,
        charOffset,
        charOpenParenOffset,
        charEndOffset,
        referenceFrom,
        nativeMethodName);
    metadataCollector?.setDocumentationComment(
        constructorBuilder.constructor, documentationComment);
    metadataCollector?.setConstructorNameOffset(
        constructorBuilder.constructor, name);
    checkTypeVariables(typeVariables, constructorBuilder);
    addBuilder(constructorName, constructorBuilder, charOffset,
        getterReference: referenceFrom?.reference);
    if (nativeMethodName != null) {
      addNativeMethod(constructorBuilder);
    }
    if (constructorBuilder.isConst) {
      currentTypeParameterScopeBuilder?.declaresConstConstructor = true;
      // const constructors will have their initializers compiled and written
      // into the outline.
      constructorBuilder.beginInitializers =
          beginInitializers ?? new Token.eof(-1);
    }
  }

  void addProcedure(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      TypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      ProcedureKind kind,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName,
      AsyncMarker asyncModifier,
      {bool isTopLevel,
      bool isExtensionInstanceMember}) {
    assert(isTopLevel != null);
    assert(isExtensionInstanceMember != null);

    MetadataCollector metadataCollector = loader.target.metadataCollector;
    if (returnType == null) {
      if (kind == ProcedureKind.Operator &&
          identical(name, indexSetName.text)) {
        returnType = addVoidType(charOffset);
      } else if (kind == ProcedureKind.Setter) {
        returnType = addVoidType(charOffset);
      }
    }
    Procedure referenceFrom;
    Procedure tearOffReferenceFrom;
    if (referencesFrom != null) {
      if (_currentClassReferencesFromIndexed != null) {
        if (kind == ProcedureKind.Setter) {
          referenceFrom =
              _currentClassReferencesFromIndexed.lookupProcedureSetter(name);
        } else {
          referenceFrom =
              _currentClassReferencesFromIndexed.lookupProcedureNotSetter(name);
        }
      } else {
        if (currentTypeParameterScopeBuilder.kind ==
            TypeParameterScopeKind.extensionDeclaration) {
          bool extensionIsStatic = (modifiers & staticMask) != 0;
          String nameToLookup = SourceProcedureBuilder.createProcedureName(
              true,
              extensionIsStatic,
              kind,
              currentTypeParameterScopeBuilder.name,
              name);
          if (extensionIsStatic && kind == ProcedureKind.Setter) {
            referenceFrom =
                referencesFromIndexed.lookupProcedureSetter(nameToLookup);
          } else {
            referenceFrom =
                referencesFromIndexed.lookupProcedureNotSetter(nameToLookup);
          }
          if (kind == ProcedureKind.Method) {
            String tearOffNameToLookup =
                SourceProcedureBuilder.createProcedureName(
                    true,
                    false,
                    ProcedureKind.Getter,
                    currentTypeParameterScopeBuilder.name,
                    name);
            tearOffReferenceFrom = referencesFromIndexed
                .lookupProcedureNotSetter(tearOffNameToLookup);
          }
        } else {
          if (kind == ProcedureKind.Setter) {
            referenceFrom = referencesFromIndexed.lookupProcedureSetter(name);
          } else {
            referenceFrom =
                referencesFromIndexed.lookupProcedureNotSetter(name);
          }
        }
      }
    }
    ProcedureBuilder procedureBuilder = new SourceProcedureBuilder(
        metadata,
        modifiers,
        returnType,
        name,
        typeVariables,
        formals,
        kind,
        this,
        startCharOffset,
        charOffset,
        charOpenParenOffset,
        charEndOffset,
        referenceFrom,
        tearOffReferenceFrom,
        asyncModifier,
        isExtensionInstanceMember,
        nativeMethodName);
    metadataCollector?.setDocumentationComment(
        procedureBuilder.procedure, documentationComment);
    checkTypeVariables(typeVariables, procedureBuilder);
    addBuilder(name, procedureBuilder, charOffset,
        getterReference: referenceFrom?.reference);
    if (nativeMethodName != null) {
      addNativeMethod(procedureBuilder);
    }
  }

  void addFactoryMethod(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      Object name,
      List<FormalParameterBuilder> formals,
      ConstructorReferenceBuilder redirectionTarget,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName,
      AsyncMarker asyncModifier) {
    TypeBuilder returnType = addNamedType(
        currentTypeParameterScopeBuilder.parent.name,
        const NullabilityBuilder.omitted(),
        <TypeBuilder>[],
        charOffset);
    // Nested declaration began in `OutlineBuilder.beginFactoryMethod`.
    TypeParameterScopeBuilder factoryDeclaration = endNestedDeclaration(
        TypeParameterScopeKind.factoryMethod, "#factory_method");

    // Prepare the simple procedure name.
    String procedureName;
    String constructorName =
        computeAndValidateConstructorName(name, charOffset, isFactory: true);
    if (constructorName != null) {
      procedureName = constructorName;
    } else {
      procedureName = name;
    }

    Procedure referenceFrom = _currentClassReferencesFromIndexed
        ?.lookupProcedureNotSetter(procedureName);

    ProcedureBuilder procedureBuilder;
    if (redirectionTarget != null) {
      procedureBuilder = new RedirectingFactoryBuilder(
          metadata,
          staticMask | modifiers,
          returnType,
          procedureName,
          copyTypeVariables(
              currentTypeParameterScopeBuilder.typeVariables ??
                  const <TypeVariableBuilder>[],
              factoryDeclaration),
          formals,
          this,
          startCharOffset,
          charOffset,
          charOpenParenOffset,
          charEndOffset,
          referenceFrom,
          nativeMethodName,
          redirectionTarget);
    } else {
      procedureBuilder = new SourceProcedureBuilder(
          metadata,
          staticMask | modifiers,
          returnType,
          procedureName,
          copyTypeVariables(
              currentTypeParameterScopeBuilder.typeVariables ??
                  const <TypeVariableBuilder>[],
              factoryDeclaration),
          formals,
          ProcedureKind.Factory,
          this,
          startCharOffset,
          charOffset,
          charOpenParenOffset,
          charEndOffset,
          referenceFrom,
          null,
          asyncModifier,
          /* isExtensionInstanceMember = */ false,
          nativeMethodName);
    }

    MetadataCollector metadataCollector = loader.target.metadataCollector;
    metadataCollector?.setDocumentationComment(
        procedureBuilder.procedure, documentationComment);
    metadataCollector?.setConstructorNameOffset(
        procedureBuilder.procedure, name);

    TypeParameterScopeBuilder savedDeclaration =
        currentTypeParameterScopeBuilder;
    currentTypeParameterScopeBuilder = factoryDeclaration;
    for (TypeVariableBuilder tv in procedureBuilder.typeVariables) {
      NamedTypeBuilder t = procedureBuilder.returnType;
      t.arguments.add(addNamedType(tv.name, const NullabilityBuilder.omitted(),
          null, procedureBuilder.charOffset));
    }
    currentTypeParameterScopeBuilder = savedDeclaration;

    factoryDeclaration.resolveTypes(procedureBuilder.typeVariables, this);
    addBuilder(procedureName, procedureBuilder, charOffset,
        getterReference: referenceFrom?.reference);
    if (nativeMethodName != null) {
      addNativeMethod(procedureBuilder);
    }
  }

  void addEnum(
      String documentationComment,
      List<MetadataBuilder> metadata,
      String name,
      List<EnumConstantInfo> enumConstantInfos,
      int startCharOffset,
      int charOffset,
      int charEndOffset) {
    MetadataCollector metadataCollector = loader.target.metadataCollector;
    Class referencesFromClass;
    IndexedClass referencesFromIndexedClass;
    if (referencesFrom != null) {
      referencesFromClass = referencesFromIndexed.lookupClass(name);
      referencesFromIndexedClass =
          referencesFromIndexed.lookupIndexedClass(name);
    }
    EnumBuilder builder = new EnumBuilder(
        metadataCollector,
        metadata,
        name,
        enumConstantInfos,
        this,
        startCharOffset,
        charOffset,
        charEndOffset,
        referencesFromClass,
        referencesFromIndexedClass);
    addBuilder(name, builder, charOffset,
        getterReference: referencesFromClass?.reference);
    metadataCollector?.setDocumentationComment(
        builder.cls, documentationComment);
  }

  void addFunctionTypeAlias(
      String documentationComment,
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      TypeBuilder type,
      int charOffset) {
    if (typeVariables != null) {
      for (TypeVariableBuilder typeVariable in typeVariables) {
        typeVariable.variance = pendingVariance;
      }
    }
    Typedef referenceFrom = referencesFromIndexed?.lookupTypedef(name);
    TypeAliasBuilder typedefBuilder = new SourceTypeAliasBuilder(
        metadata, name, typeVariables, type, this, charOffset,
        referenceFrom: referenceFrom);
    loader.target.metadataCollector
        ?.setDocumentationComment(typedefBuilder.typedef, documentationComment);
    checkTypeVariables(typeVariables, typedefBuilder);
    // Nested declaration began in `OutlineBuilder.beginFunctionTypeAlias`.
    endNestedDeclaration(TypeParameterScopeKind.typedef, "#typedef")
        .resolveTypes(typeVariables, this);
    addBuilder(name, typedefBuilder, charOffset,
        getterReference: referenceFrom?.reference);
  }

  FunctionTypeBuilder addFunctionType(
      TypeBuilder returnType,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      NullabilityBuilder nullabilityBuilder,
      int charOffset) {
    FunctionTypeBuilder builder = new FunctionTypeBuilder(returnType,
        typeVariables, formals, nullabilityBuilder, fileUri, charOffset);
    checkTypeVariables(typeVariables, null);
    // Nested declaration began in `OutlineBuilder.beginFunctionType` or
    // `OutlineBuilder.beginFunctionTypedFormalParameter`.
    endNestedDeclaration(TypeParameterScopeKind.functionType, "#function_type")
        .resolveTypes(typeVariables, this);
    return addType(builder, charOffset);
  }

  FormalParameterBuilder addFormalParameter(
      List<MetadataBuilder> metadata,
      int modifiers,
      TypeBuilder type,
      String name,
      bool hasThis,
      int charOffset,
      Token initializerToken) {
    if (hasThis) {
      modifiers |= initializingFormalMask;
    }
    FormalParameterBuilder formal = new FormalParameterBuilder(
        metadata, modifiers, type, name, this, charOffset,
        fileUri: fileUri)
      ..initializerToken = initializerToken
      ..hasDeclaredInitializer = (initializerToken != null);
    return formal;
  }

  TypeVariableBuilder addTypeVariable(
      String name, TypeBuilder bound, int charOffset) {
    TypeVariableBuilder builder =
        new TypeVariableBuilder(name, this, charOffset, bound: bound);
    boundlessTypeVariables.add(builder);
    return builder;
  }

  @override
  void buildOutlineExpressions() {
    MetadataBuilder.buildAnnotations(library, metadata, this, null, null);
  }

  /// Builds the core AST structures for [declaration] needed for the outline.
  void buildBuilder(Builder declaration, LibraryBuilder coreLibrary) {
    String findDuplicateSuffix(Builder declaration) {
      if (declaration.next != null) {
        int count = 0;
        Builder current = declaration.next;
        while (current != null) {
          count++;
          current = current.next;
        }
        return "#$count";
      }
      return "";
    }

    if (declaration is SourceClassBuilder) {
      Class cls = declaration.build(this, coreLibrary);
      if (!declaration.isPatch) {
        cls.name += findDuplicateSuffix(declaration);
        library.addClass(cls);
      }
    } else if (declaration is SourceExtensionBuilder) {
      Extension extension = declaration.build(this, coreLibrary,
          addMembersToLibrary: !declaration.isDuplicate);
      if (!declaration.isPatch && !declaration.isDuplicate) {
        library.addExtension(extension);
      }
    } else if (declaration is MemberBuilderImpl) {
      declaration.buildMembers(this,
          (Member member, BuiltMemberKind memberKind) {
        if (member is Field) {
          member.isStatic = true;
          if (!declaration.isPatch && !declaration.isDuplicate) {
            library.addField(member);
          }
        } else if (member is Procedure) {
          member.isStatic = true;
          if (!declaration.isPatch && !declaration.isDuplicate) {
            library.addProcedure(member);
          }
        } else {
          unhandled("${member.runtimeType}:${memberKind}", "buildBuilder",
              declaration.charOffset, declaration.fileUri);
        }
      });
    } else if (declaration is SourceTypeAliasBuilder) {
      Typedef typedef = declaration.build(this);
      if (!declaration.isPatch && !declaration.isDuplicate) {
        library.addTypedef(typedef);
      }
    } else if (declaration is EnumBuilder) {
      Class cls = declaration.build(this, coreLibrary);
      if (!declaration.isPatch) {
        cls.name += findDuplicateSuffix(declaration);
        library.addClass(cls);
      }
    } else if (declaration is PrefixBuilder) {
      // Ignored. Kernel doesn't represent prefixes.
      return;
    } else if (declaration is BuiltinTypeDeclarationBuilder) {
      // Nothing needed.
      return;
    } else {
      unhandled("${declaration.runtimeType}", "buildBuilder",
          declaration.charOffset, declaration.fileUri);
      return;
    }
  }

  void addNativeDependency(String nativeImportPath) {
    MemberBuilder constructor = loader.getNativeAnnotation();
    Arguments arguments =
        new Arguments(<Expression>[new StringLiteral(nativeImportPath)]);
    Expression annotation;
    if (constructor.isConstructor) {
      annotation = new ConstructorInvocation(constructor.member, arguments)
        ..isConst = true;
    } else {
      annotation = new StaticInvocation(constructor.member, arguments)
        ..isConst = true;
    }
    library.addAnnotation(annotation);
  }

  void addDependencies(Library library, Set<SourceLibraryBuilder> seen) {
    if (!seen.add(this)) {
      return;
    }

    // Merge import and export lists to have the dependencies in source order.
    // This is required for the DietListener to correctly match up metadata.
    int importIndex = 0;
    int exportIndex = 0;
    while (importIndex < imports.length || exportIndex < exports.length) {
      if (exportIndex >= exports.length ||
          (importIndex < imports.length &&
              imports[importIndex].charOffset <
                  exports[exportIndex].charOffset)) {
        // Add import
        Import import = imports[importIndex++];

        // Rather than add a LibraryDependency, we attach an annotation.
        if (import.nativeImportPath != null) {
          addNativeDependency(import.nativeImportPath);
          continue;
        }

        if (import.deferred && import.prefixBuilder?.dependency != null) {
          library.addDependency(import.prefixBuilder.dependency);
        } else {
          library.addDependency(new LibraryDependency.import(
              import.imported.library,
              name: import.prefix,
              combinators: toKernelCombinators(import.combinators))
            ..fileOffset = import.charOffset);
        }
      } else {
        // Add export
        Export export = exports[exportIndex++];
        library.addDependency(new LibraryDependency.export(
            export.exported.library,
            combinators: toKernelCombinators(export.combinators))
          ..fileOffset = export.charOffset);
      }
    }

    for (LibraryBuilder part in parts) {
      if (part is SourceLibraryBuilder) {
        part.addDependencies(library, seen);
      }
    }
  }

  @override
  Builder computeAmbiguousDeclaration(
      String name, Builder declaration, Builder other, int charOffset,
      {bool isExport: false, bool isImport: false}) {
    // TODO(ahe): Can I move this to Scope or Prefix?
    if (declaration == other) return declaration;
    if (declaration is InvalidTypeDeclarationBuilder) return declaration;
    if (other is InvalidTypeDeclarationBuilder) return other;
    if (declaration is AccessErrorBuilder) {
      AccessErrorBuilder error = declaration;
      declaration = error.builder;
    }
    if (other is AccessErrorBuilder) {
      AccessErrorBuilder error = other;
      other = error.builder;
    }
    bool isLocal = false;
    bool isLoadLibrary = false;
    Builder preferred;
    Uri uri;
    Uri otherUri;
    Uri preferredUri;
    Uri hiddenUri;
    if (scope.lookupLocalMember(name, setter: false) == declaration) {
      isLocal = true;
      preferred = declaration;
      hiddenUri = computeLibraryUri(other);
    } else {
      uri = computeLibraryUri(declaration);
      otherUri = computeLibraryUri(other);
      if (declaration is LoadLibraryBuilder) {
        isLoadLibrary = true;
        preferred = declaration;
        preferredUri = otherUri;
      } else if (other is LoadLibraryBuilder) {
        isLoadLibrary = true;
        preferred = other;
        preferredUri = uri;
      } else if (otherUri?.scheme == "dart" && uri?.scheme != "dart") {
        preferred = declaration;
        preferredUri = uri;
        hiddenUri = otherUri;
      } else if (uri?.scheme == "dart" && otherUri?.scheme != "dart") {
        preferred = other;
        preferredUri = otherUri;
        hiddenUri = uri;
      }
    }
    if (preferred != null) {
      if (isLocal) {
        Template<Message Function(String name, Uri uri)> template = isExport
            ? templateLocalDefinitionHidesExport
            : templateLocalDefinitionHidesImport;
        addProblem(template.withArguments(name, hiddenUri), charOffset,
            noLength, fileUri);
      } else if (isLoadLibrary) {
        addProblem(templateLoadLibraryHidesMember.withArguments(preferredUri),
            charOffset, noLength, fileUri);
      } else {
        Template<Message Function(String name, Uri uri, Uri uri2)> template =
            isExport ? templateExportHidesExport : templateImportHidesImport;
        addProblem(template.withArguments(name, preferredUri, hiddenUri),
            charOffset, noLength, fileUri);
      }
      return preferred;
    }
    if (declaration.next == null && other.next == null) {
      if (isImport && declaration is PrefixBuilder && other is PrefixBuilder) {
        // Handles the case where the same prefix is used for different
        // imports.
        return declaration
          ..exportScope.merge(other.exportScope,
              (String name, Builder existing, Builder member) {
            return computeAmbiguousDeclaration(
                name, existing, member, charOffset,
                isExport: isExport, isImport: isImport);
          });
      }
    }
    Template<Message Function(String name, Uri uri, Uri uri2)> template =
        isExport ? templateDuplicatedExport : templateDuplicatedImport;
    Message message = template.withArguments(name, uri, otherUri);
    addProblem(message, charOffset, noLength, fileUri);
    Template<Message Function(String name, Uri uri, Uri uri2)> builderTemplate =
        isExport
            ? templateDuplicatedExportInType
            : templateDuplicatedImportInType;
    message = builderTemplate.withArguments(
        name,
        // TODO(ahe): We should probably use a context object here
        // instead of including URIs in this message.
        uri,
        otherUri);
    // We report the error lazily (setting suppressMessage to false) because the
    // spec 18.1 states that 'It is not an error if N is introduced by two or
    // more imports but never referred to.'
    return new InvalidTypeDeclarationBuilder(
        name, message.withLocation(fileUri, charOffset, name.length),
        suppressMessage: false);
  }

  int finishDeferredLoadTearoffs() {
    int total = 0;
    for (Import import in imports) {
      if (import.deferred) {
        Procedure tearoff = import.prefixBuilder.loadLibraryBuilder.tearoff;
        if (tearoff != null) library.addProcedure(tearoff);
        total++;
      }
    }
    return total;
  }

  int finishForwarders() {
    int count = 0;
    CloneVisitorNotMembers cloner = new CloneVisitorNotMembers();
    for (int i = 0; i < forwardersOrigins.length; i += 2) {
      Procedure forwarder = forwardersOrigins[i];
      Procedure origin = forwardersOrigins[i + 1];

      int positionalCount = origin.function.positionalParameters.length;
      if (forwarder.function.positionalParameters.length != positionalCount) {
        return unexpected(
            "$positionalCount",
            "${forwarder.function.positionalParameters.length}",
            origin.fileOffset,
            origin.fileUri);
      }
      for (int j = 0; j < positionalCount; ++j) {
        VariableDeclaration forwarderParameter =
            forwarder.function.positionalParameters[j];
        VariableDeclaration originParameter =
            origin.function.positionalParameters[j];
        if (originParameter.initializer != null) {
          forwarderParameter.initializer =
              cloner.clone(originParameter.initializer);
          forwarderParameter.initializer.parent = forwarderParameter;
        }
      }

      Map<String, VariableDeclaration> originNamedMap =
          <String, VariableDeclaration>{};
      for (VariableDeclaration originNamed in origin.function.namedParameters) {
        originNamedMap[originNamed.name] = originNamed;
      }
      for (VariableDeclaration forwarderNamed
          in forwarder.function.namedParameters) {
        VariableDeclaration originNamed = originNamedMap[forwarderNamed.name];
        if (originNamed == null) {
          return unhandled(
              "null", forwarder.name.text, origin.fileOffset, origin.fileUri);
        }
        if (originNamed.initializer == null) continue;
        forwarderNamed.initializer = cloner.clone(originNamed.initializer);
        forwarderNamed.initializer.parent = forwarderNamed;
      }

      ++count;
    }
    forwardersOrigins.clear();
    return count;
  }

  void addNativeMethod(FunctionBuilder method) {
    nativeMethods.add(method);
  }

  int finishNativeMethods() {
    for (FunctionBuilder method in nativeMethods) {
      method.becomeNative(loader);
    }
    return nativeMethods.length;
  }

  /// Creates a copy of [original] into the scope of [declaration].
  ///
  /// This is used for adding copies of class type parameters to factory
  /// methods and unnamed mixin applications, and for adding copies of
  /// extension type parameters to extension instance methods.
  ///
  /// If [synthesizeTypeParameterNames] is `true` the names of the
  /// [TypeParameter] are prefix with '#' to indicate that their synthesized.
  List<TypeVariableBuilder> copyTypeVariables(
      List<TypeVariableBuilder> original, TypeParameterScopeBuilder declaration,
      {bool isExtensionTypeParameter: false}) {
    List<TypeBuilder> newTypes = <TypeBuilder>[];
    List<TypeVariableBuilder> copy = <TypeVariableBuilder>[];
    for (TypeVariableBuilder variable in original) {
      TypeVariableBuilder newVariable = new TypeVariableBuilder(
          variable.name, this, variable.charOffset,
          bound: variable.bound?.clone(newTypes),
          isExtensionTypeParameter: isExtensionTypeParameter,
          variableVariance:
              variable.parameter.isLegacyCovariant ? null : variable.variance);
      copy.add(newVariable);
      boundlessTypeVariables.add(newVariable);
    }
    for (TypeBuilder newType in newTypes) {
      declaration.addType(new UnresolvedType(newType, -1, null));
    }
    return copy;
  }

  int finishTypeVariables(ClassBuilder object, TypeBuilder dynamicType) {
    int count = boundlessTypeVariables.length;
    for (TypeVariableBuilder builder in boundlessTypeVariables) {
      builder.finish(this, object, dynamicType);
    }
    boundlessTypeVariables.clear();

    TypeVariableBuilder.finishNullabilities(this, pendingNullabilities);
    pendingNullabilities.clear();

    return count;
  }

  int computeVariances() {
    int count = 0;
    for (Builder declaration in libraryDeclaration.members.values) {
      if (declaration is TypeAliasBuilder &&
          declaration.typeVariablesCount > 0) {
        for (TypeVariableBuilder typeParameter in declaration.typeVariables) {
          typeParameter.variance = computeTypeVariableBuilderVariance(
              typeParameter, declaration.type, this);
          ++count;
        }
      }
    }
    return count;
  }

  int computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder nullType,
      TypeBuilder bottomType, ClassBuilder objectClass) {
    int count = 0;

    int computeDefaultTypesForVariables(List<TypeVariableBuilder> variables,
        {bool inErrorRecovery}) {
      if (variables == null) return 0;

      bool haveErroneousBounds = false;
      if (!inErrorRecovery) {
        for (int i = 0; i < variables.length; ++i) {
          TypeVariableBuilder variable = variables[i];
          List<TypeBuilder> genericFunctionTypes = <TypeBuilder>[];
          findGenericFunctionTypes(variable.bound,
              result: genericFunctionTypes);
          if (genericFunctionTypes.length > 0) {
            haveErroneousBounds = true;
            addProblem(messageGenericFunctionTypeInBound, variable.charOffset,
                variable.name.length, variable.fileUri);
          }
        }

        if (!haveErroneousBounds) {
          List<TypeBuilder> calculatedBounds = calculateBounds(
              variables,
              dynamicType,
              isNonNullableByDefault ? bottomType : nullType,
              objectClass);
          for (int i = 0; i < variables.length; ++i) {
            variables[i].defaultType = calculatedBounds[i];
          }
        }
      }

      if (inErrorRecovery || haveErroneousBounds) {
        // Use dynamic in case of errors.
        for (int i = 0; i < variables.length; ++i) {
          variables[i].defaultType = dynamicType;
        }
      }

      return variables.length;
    }

    void reportIssues(List<Object> issues) {
      for (int i = 0; i < issues.length; i += 3) {
        TypeDeclarationBuilder declaration = issues[i];
        Message message = issues[i + 1];
        List<LocatedMessage> context = issues[i + 2];

        addProblem(message, declaration.charOffset, declaration.name.length,
            declaration.fileUri,
            context: context);
      }
    }

    for (Builder declaration in libraryDeclaration.members.values) {
      if (declaration is ClassBuilder) {
        {
          List<Object> issues = getNonSimplicityIssuesForDeclaration(
              declaration,
              performErrorRecovery: true);
          reportIssues(issues);
          count += computeDefaultTypesForVariables(declaration.typeVariables,
              inErrorRecovery: issues.isNotEmpty);

          declaration.constructors.forEach((String name, Builder member) {
            if (member is ProcedureBuilder) {
              assert(member.isFactory,
                  "Unexpected constructor member (${member.runtimeType}).");
              count += computeDefaultTypesForVariables(member.typeVariables,
                  // Type variables are inherited from the class so if the class
                  // has issues, so does the factory constructors.
                  inErrorRecovery: issues.isNotEmpty);
            } else {
              assert(member is ConstructorBuilder,
                  "Unexpected constructor member (${member.runtimeType}).");
            }
          });
        }
        declaration.forEach((String name, Builder member) {
          if (member is ProcedureBuilder) {
            List<Object> issues =
                getNonSimplicityIssuesForTypeVariables(member.typeVariables);
            reportIssues(issues);
            count += computeDefaultTypesForVariables(member.typeVariables,
                inErrorRecovery: issues.isNotEmpty);
          } else {
            assert(member is FieldBuilder,
                "Unexpected class member $member (${member.runtimeType}).");
          }
        });
      } else if (declaration is TypeAliasBuilder) {
        List<Object> issues = getNonSimplicityIssuesForDeclaration(declaration,
            performErrorRecovery: true);
        reportIssues(issues);
        count += computeDefaultTypesForVariables(declaration.typeVariables,
            inErrorRecovery: issues.isNotEmpty);
      } else if (declaration is FunctionBuilder) {
        List<Object> issues =
            getNonSimplicityIssuesForTypeVariables(declaration.typeVariables);
        reportIssues(issues);
        count += computeDefaultTypesForVariables(declaration.typeVariables,
            inErrorRecovery: issues.isNotEmpty);
      } else if (declaration is ExtensionBuilder) {
        {
          List<Object> issues = getNonSimplicityIssuesForDeclaration(
              declaration,
              performErrorRecovery: true);
          reportIssues(issues);
          count += computeDefaultTypesForVariables(declaration.typeParameters,
              inErrorRecovery: issues.isNotEmpty);
        }
        declaration.forEach((String name, Builder member) {
          if (member is ProcedureBuilder) {
            List<Object> issues =
                getNonSimplicityIssuesForTypeVariables(member.typeVariables);
            reportIssues(issues);
            count += computeDefaultTypesForVariables(member.typeVariables,
                inErrorRecovery: issues.isNotEmpty);
          } else {
            assert(member is FieldBuilder,
                "Unexpected extension member $member (${member.runtimeType}).");
          }
        });
      } else {
        assert(
            declaration is FieldBuilder ||
                declaration is PrefixBuilder ||
                declaration is DynamicTypeDeclarationBuilder ||
                declaration is NeverTypeDeclarationBuilder,
            "Unexpected top level member $declaration "
            "(${declaration.runtimeType}).");
      }
    }

    return count;
  }

  @override
  void applyPatches() {
    if (!isPatch) return;

    if (languageVersion != origin.languageVersion) {
      List<LocatedMessage> context = <LocatedMessage>[];
      if (origin.languageVersion.isExplicit) {
        context.add(messageLanguageVersionLibraryContext.withLocation(
            origin.languageVersion.fileUri,
            origin.languageVersion.charOffset,
            origin.languageVersion.charCount));
      }

      if (languageVersion.isExplicit) {
        addProblem(
            messageLanguageVersionMismatchInPatch,
            languageVersion.charOffset,
            languageVersion.charCount,
            languageVersion.fileUri,
            context: context);
      } else {
        addProblem(messageLanguageVersionMismatchInPatch, -1, noLength, fileUri,
            context: context);
      }
    }

    NameIterator originDeclarations = origin.nameIterator;
    while (originDeclarations.moveNext()) {
      String name = originDeclarations.name;
      Builder member = originDeclarations.current;
      bool isSetter = member.isSetter;
      Builder patch = scope.lookupLocalMember(name, setter: isSetter);
      if (patch != null) {
        // [patch] has the same name as a [member] in [origin] library, so it
        // must be a patch to [member].
        member.applyPatch(patch);
        // TODO(ahe): Verify that patch has the @patch annotation.
      } else {
        // No member with [name] exists in this library already. So we need to
        // import it into the patch library. This ensures that the origin
        // library is in scope of the patch library.
        if (isSetter) {
          scopeBuilder.addSetter(name, member);
        } else {
          scopeBuilder.addMember(name, member);
        }
      }
    }
    NameIterator patchDeclarations = nameIterator;
    while (patchDeclarations.moveNext()) {
      String name = patchDeclarations.name;
      Builder member = patchDeclarations.current;
      // We need to inject all non-patch members into the origin library. This
      // should only apply to private members.
      if (member.isPatch) {
        // Ignore patches.
      } else if (name.startsWith("_")) {
        origin.injectMemberFromPatch(name, member);
      } else {
        origin.exportMemberFromPatch(name, member);
      }
    }
  }

  int finishPatchMethods() {
    if (!isPatch) return 0;
    int count = 0;
    Iterator<Builder> iterator = this.iterator;
    while (iterator.moveNext()) {
      count += iterator.current.finishPatch();
    }
    return count;
  }

  void injectMemberFromPatch(String name, Builder member) {
    if (member.isSetter) {
      assert(scope.lookupLocalMember(name, setter: true) == null);
      scopeBuilder.addSetter(name, member);
    } else {
      assert(scope.lookupLocalMember(name, setter: false) == null);
      scopeBuilder.addMember(name, member);
    }
  }

  void exportMemberFromPatch(String name, Builder member) {
    if (importUri.scheme != "dart" || !importUri.path.startsWith("_")) {
      addProblem(templatePatchInjectionFailed.withArguments(name, importUri),
          member.charOffset, noLength, member.fileUri);
    }
    // Platform-private libraries, such as "dart:_internal" have special
    // semantics: public members are injected into the origin library.
    // TODO(ahe): See if we can remove this special case.

    // If this member already exist in the origin library scope, it should
    // have been marked as patch.
    assert((member.isSetter &&
            scope.lookupLocalMember(name, setter: true) == null) ||
        (!member.isSetter &&
            scope.lookupLocalMember(name, setter: false) == null));
    addToExportScope(name, member);
  }

  void reportTypeArgumentIssues(
      Iterable<TypeArgumentIssue> issues, Uri fileUri, int offset,
      {bool inferred,
      TypeArgumentsInfo typeArgumentsInfo,
      DartType targetReceiver,
      String targetName}) {
    for (TypeArgumentIssue issue in issues) {
      DartType argument = issue.argument;
      TypeParameter typeParameter = issue.typeParameter;

      Message message;
      bool issueInferred = inferred ??
          typeArgumentsInfo?.isInferred(issue.index) ??
          inferredTypes.contains(argument);
      offset =
          typeArgumentsInfo?.getOffsetForIndex(issue.index, offset) ?? offset;
      if (argument is FunctionType && argument.typeParameters.length > 0) {
        if (issueInferred) {
          message = templateGenericFunctionTypeInferredAsActualTypeArgument
              .withArguments(argument, isNonNullableByDefault);
        } else {
          message = messageGenericFunctionTypeUsedAsActualTypeArgument;
        }
        typeParameter = null;
      } else {
        if (issue.enclosingType == null && targetReceiver != null) {
          if (issueInferred) {
            message =
                templateIncorrectTypeArgumentQualifiedInferred.withArguments(
                    argument,
                    typeParameter.bound,
                    typeParameter.name,
                    targetReceiver,
                    targetName,
                    isNonNullableByDefault);
          } else {
            message = templateIncorrectTypeArgumentQualified.withArguments(
                argument,
                typeParameter.bound,
                typeParameter.name,
                targetReceiver,
                targetName,
                isNonNullableByDefault);
          }
        } else {
          String enclosingName = issue.enclosingType == null
              ? targetName
              : getGenericTypeName(issue.enclosingType);
          assert(enclosingName != null);
          if (issueInferred) {
            message = templateIncorrectTypeArgumentInferred.withArguments(
                argument,
                typeParameter.bound,
                typeParameter.name,
                enclosingName,
                isNonNullableByDefault);
          } else {
            message = templateIncorrectTypeArgument.withArguments(
                argument,
                typeParameter.bound,
                typeParameter.name,
                enclosingName,
                isNonNullableByDefault);
          }
        }
      }

      reportTypeArgumentIssue(message, fileUri, offset, typeParameter);
    }
  }

  void reportTypeArgumentIssue(Message message, Uri fileUri, int fileOffset,
      TypeParameter typeParameter) {
    List<LocatedMessage> context;
    if (typeParameter != null && typeParameter.fileOffset != -1) {
      // It looks like when parameters come from patch files, they don't
      // have a reportable location.
      context = <LocatedMessage>[
        messageIncorrectTypeArgumentVariable.withLocation(
            typeParameter.location.file, typeParameter.fileOffset, noLength)
      ];
    }
    addProblem(message, fileOffset, noLength, fileUri, context: context);
  }

  void checkTypesInField(
      FieldBuilder fieldBuilder, TypeEnvironment typeEnvironment) {
    // Check the bounds in the field's type.
    checkBoundsInType(fieldBuilder.fieldType, typeEnvironment,
        fieldBuilder.fileUri, fieldBuilder.charOffset,
        allowSuperBounded: true);

    // Check that the field has an initializer if its type is potentially
    // non-nullable.
    if (isNonNullableByDefault) {
      // Only static and top-level fields are checked here.  Instance fields are
      // checked elsewhere.
      DartType fieldType = fieldBuilder.fieldType;
      if (!fieldBuilder.isDeclarationInstanceMember &&
          !fieldBuilder.isLate &&
          !fieldBuilder.isExternal &&
          fieldType is! InvalidType &&
          fieldType.isPotentiallyNonNullable &&
          !fieldBuilder.hasInitializer) {
        addProblem(
            templateFieldNonNullableWithoutInitializerError.withArguments(
                fieldBuilder.name,
                fieldBuilder.fieldType,
                isNonNullableByDefault),
            fieldBuilder.charOffset,
            fieldBuilder.name.length,
            fieldBuilder.fileUri);
      }
    }
  }

  void checkInitializersInFormals(
      List<FormalParameterBuilder> formals, TypeEnvironment typeEnvironment) {
    if (!isNonNullableByDefault) return;

    for (FormalParameterBuilder formal in formals) {
      bool isOptionalPositional = formal.isOptional && formal.isPositional;
      bool isOptionalNamed = !formal.isNamedRequired && formal.isNamed;
      bool isOptional = isOptionalPositional || isOptionalNamed;
      if (isOptional &&
          formal.variable.type.isPotentiallyNonNullable &&
          !formal.hasDeclaredInitializer) {
        addProblem(
            templateOptionalNonNullableWithoutInitializerError.withArguments(
                formal.name, formal.variable.type, isNonNullableByDefault),
            formal.charOffset,
            formal.name.length,
            formal.fileUri);
      }
    }
  }

  void checkBoundsInTypeParameters(TypeEnvironment typeEnvironment,
      List<TypeParameter> typeParameters, Uri fileUri) {
    final DartType bottomType = library.isNonNullableByDefault
        ? const NeverType(Nullability.nonNullable)
        : const NullType();

    // Check in bounds of own type variables.
    for (TypeParameter parameter in typeParameters) {
      Set<TypeArgumentIssue> issues = {};
      issues.addAll(findTypeArgumentIssues(
              library,
              parameter.bound,
              typeEnvironment,
              SubtypeCheckMode.ignoringNullabilities,
              bottomType,
              allowSuperBounded: true) ??
          const []);
      if (library.isNonNullableByDefault) {
        issues.addAll(findTypeArgumentIssues(library, parameter.bound,
                typeEnvironment, SubtypeCheckMode.withNullabilities, bottomType,
                allowSuperBounded: true) ??
            const []);
      }
      for (TypeArgumentIssue issue in issues) {
        DartType argument = issue.argument;
        TypeParameter typeParameter = issue.typeParameter;
        if (inferredTypes.contains(argument)) {
          // Inference in type expressions in the supertypes boils down to
          // instantiate-to-bound which shouldn't produce anything that breaks
          // the bounds after the non-simplicity checks are done.  So, any
          // violation here is the result of non-simple bounds, and the error
          // is reported elsewhere.
          continue;
        }

        if (argument is FunctionType && argument.typeParameters.length > 0) {
          reportTypeArgumentIssue(
              messageGenericFunctionTypeUsedAsActualTypeArgument,
              fileUri,
              parameter.fileOffset,
              null);
        } else {
          reportTypeArgumentIssue(
              templateIncorrectTypeArgument.withArguments(
                  argument,
                  typeParameter.bound,
                  typeParameter.name,
                  getGenericTypeName(issue.enclosingType),
                  library.isNonNullableByDefault),
              fileUri,
              parameter.fileOffset,
              typeParameter);
        }
      }
    }
  }

  void checkBoundsInFunctionNodeParts(
      TypeEnvironment typeEnvironment, Uri fileUri, int fileOffset,
      {List<TypeParameter> typeParameters,
      List<VariableDeclaration> positionalParameters,
      List<VariableDeclaration> namedParameters,
      DartType returnType,
      int requiredParameterCount,
      bool skipReturnType = false}) {
    if (typeParameters != null) {
      for (TypeParameter parameter in typeParameters) {
        checkBoundsInType(
            parameter.bound, typeEnvironment, fileUri, parameter.fileOffset,
            allowSuperBounded: true);
      }
    }
    if (positionalParameters != null) {
      for (int i = 0; i < positionalParameters.length; ++i) {
        VariableDeclaration parameter = positionalParameters[i];
        checkBoundsInType(
            parameter.type, typeEnvironment, fileUri, parameter.fileOffset,
            allowSuperBounded: true);
      }
    }
    if (namedParameters != null) {
      for (int i = 0; i < namedParameters.length; ++i) {
        VariableDeclaration named = namedParameters[i];
        checkBoundsInType(
            named.type, typeEnvironment, fileUri, named.fileOffset,
            allowSuperBounded: true);
      }
    }
    if (!skipReturnType && returnType != null) {
      final DartType bottomType = isNonNullableByDefault
          ? const NeverType(Nullability.nonNullable)
          : const NullType();
      Set<TypeArgumentIssue> issues = {};
      issues.addAll(findTypeArgumentIssues(library, returnType, typeEnvironment,
              SubtypeCheckMode.ignoringNullabilities, bottomType,
              allowSuperBounded: true) ??
          const []);
      if (isNonNullableByDefault) {
        issues.addAll(findTypeArgumentIssues(library, returnType,
                typeEnvironment, SubtypeCheckMode.withNullabilities, bottomType,
                allowSuperBounded: true) ??
            const []);
      }
      for (TypeArgumentIssue issue in issues) {
        DartType argument = issue.argument;
        TypeParameter typeParameter = issue.typeParameter;

        // We don't need to check if [argument] was inferred or specified
        // here, because inference in return types boils down to instantiate-
        // -to-bound, and it can't provide a type that violates the bound.
        if (argument is FunctionType && argument.typeParameters.length > 0) {
          reportTypeArgumentIssue(
              messageGenericFunctionTypeUsedAsActualTypeArgument,
              fileUri,
              fileOffset,
              null);
        } else {
          reportTypeArgumentIssue(
              templateIncorrectTypeArgumentInReturnType.withArguments(
                  argument,
                  typeParameter.bound,
                  typeParameter.name,
                  getGenericTypeName(issue.enclosingType),
                  isNonNullableByDefault),
              fileUri,
              fileOffset,
              typeParameter);
        }
      }
    }
  }

  void checkTypesInProcedureBuilder(
      ProcedureBuilder procedureBuilder, TypeEnvironment typeEnvironment) {
    checkBoundsInFunctionNode(procedureBuilder.procedure.function,
        typeEnvironment, procedureBuilder.fileUri);
    if (procedureBuilder.formals != null &&
        !(procedureBuilder.isAbstract || procedureBuilder.isExternal)) {
      checkInitializersInFormals(procedureBuilder.formals, typeEnvironment);
    }
  }

  void checkTypesInConstructorBuilder(
      ConstructorBuilder constructorBuilder, TypeEnvironment typeEnvironment) {
    checkBoundsInFunctionNode(
        constructorBuilder.constructor.function, typeEnvironment, fileUri);
    if (!constructorBuilder.isExternal && constructorBuilder.formals != null) {
      checkInitializersInFormals(constructorBuilder.formals, typeEnvironment);
    }
  }

  void checkTypesInRedirectingFactoryBuilder(
      RedirectingFactoryBuilder redirectingFactoryBuilder,
      TypeEnvironment typeEnvironment) {
    checkBoundsInFunctionNode(redirectingFactoryBuilder.procedure.function,
        typeEnvironment, redirectingFactoryBuilder.fileUri);
    // Default values are not required on redirecting factory constructors so
    // we don't call [checkInitializersInFormals].
  }

  void checkBoundsInFunctionNode(
      FunctionNode function, TypeEnvironment typeEnvironment, Uri fileUri,
      {bool skipReturnType = false}) {
    checkBoundsInFunctionNodeParts(
        typeEnvironment, fileUri, function.fileOffset,
        typeParameters: function.typeParameters,
        positionalParameters: function.positionalParameters,
        namedParameters: function.namedParameters,
        returnType: function.returnType,
        requiredParameterCount: function.requiredParameterCount,
        skipReturnType: skipReturnType);
  }

  void checkBoundsInListLiteral(
      ListLiteral node, TypeEnvironment typeEnvironment, Uri fileUri,
      {bool inferred = false}) {
    checkBoundsInType(
        node.typeArgument, typeEnvironment, fileUri, node.fileOffset,
        inferred: inferred, allowSuperBounded: true);
  }

  void checkBoundsInSetLiteral(
      SetLiteral node, TypeEnvironment typeEnvironment, Uri fileUri,
      {bool inferred = false}) {
    checkBoundsInType(
        node.typeArgument, typeEnvironment, fileUri, node.fileOffset,
        inferred: inferred, allowSuperBounded: true);
  }

  void checkBoundsInMapLiteral(
      MapLiteral node, TypeEnvironment typeEnvironment, Uri fileUri,
      {bool inferred = false}) {
    checkBoundsInType(node.keyType, typeEnvironment, fileUri, node.fileOffset,
        inferred: inferred, allowSuperBounded: true);
    checkBoundsInType(node.valueType, typeEnvironment, fileUri, node.fileOffset,
        inferred: inferred, allowSuperBounded: true);
  }

  void checkBoundsInType(
      DartType type, TypeEnvironment typeEnvironment, Uri fileUri, int offset,
      {bool inferred, bool allowSuperBounded = true}) {
    final DartType bottomType = isNonNullableByDefault
        ? const NeverType(Nullability.nonNullable)
        : const NullType();
    Set<TypeArgumentIssue> issues = {};
    issues.addAll(findTypeArgumentIssues(library, type, typeEnvironment,
            SubtypeCheckMode.ignoringNullabilities, bottomType,
            allowSuperBounded: allowSuperBounded) ??
        const []);
    if (isNonNullableByDefault) {
      issues.addAll(findTypeArgumentIssues(library, type, typeEnvironment,
              SubtypeCheckMode.withNullabilities, bottomType,
              allowSuperBounded: allowSuperBounded) ??
          const []);
    }
    reportTypeArgumentIssues(issues, fileUri, offset, inferred: inferred);
  }

  void checkBoundsInVariableDeclaration(
      VariableDeclaration node, TypeEnvironment typeEnvironment, Uri fileUri,
      {bool inferred = false}) {
    if (node.type == null) return;
    checkBoundsInType(node.type, typeEnvironment, fileUri, node.fileOffset,
        inferred: inferred, allowSuperBounded: true);
  }

  void checkBoundsInConstructorInvocation(
      ConstructorInvocation node, TypeEnvironment typeEnvironment, Uri fileUri,
      {bool inferred = false}) {
    if (node.arguments.types.isEmpty) return;
    Constructor constructor = node.target;
    Class klass = constructor.enclosingClass;
    DartType constructedType = new InterfaceType(
        klass, klass.enclosingLibrary.nonNullable, node.arguments.types);
    checkBoundsInType(
        constructedType, typeEnvironment, fileUri, node.fileOffset,
        inferred: inferred, allowSuperBounded: false);
  }

  void checkBoundsInFactoryInvocation(
      StaticInvocation node, TypeEnvironment typeEnvironment, Uri fileUri,
      {bool inferred = false}) {
    if (node.arguments.types.isEmpty) return;
    Procedure factory = node.target;
    assert(factory.isFactory);
    Class klass = factory.enclosingClass;
    DartType constructedType = new InterfaceType(
        klass, klass.enclosingLibrary.nonNullable, node.arguments.types);
    checkBoundsInType(
        constructedType, typeEnvironment, fileUri, node.fileOffset,
        inferred: inferred, allowSuperBounded: false);
  }

  void checkBoundsInStaticInvocation(
      StaticInvocation node,
      TypeEnvironment typeEnvironment,
      Uri fileUri,
      TypeArgumentsInfo typeArgumentsInfo) {
    // TODO(johnniwinther): Handle partially inferred type arguments in
    // extension method calls. Currently all are considered inferred in the
    // error messages.
    if (node.arguments.types.isEmpty) return;
    Class klass = node.target.enclosingClass;
    List<TypeParameter> parameters = node.target.function.typeParameters;
    List<DartType> arguments = node.arguments.types;
    // The following error is to be reported elsewhere.
    if (parameters.length != arguments.length) return;

    final DartType bottomType = isNonNullableByDefault
        ? const NeverType(Nullability.nonNullable)
        : const NullType();
    Set<TypeArgumentIssue> issues = {};
    issues.addAll(findTypeArgumentIssuesForInvocation(
            library,
            parameters,
            arguments,
            typeEnvironment,
            SubtypeCheckMode.ignoringNullabilities,
            bottomType) ??
        const []);
    if (isNonNullableByDefault) {
      issues.addAll(findTypeArgumentIssuesForInvocation(
              library,
              parameters,
              arguments,
              typeEnvironment,
              SubtypeCheckMode.withNullabilities,
              bottomType) ??
          const []);
    }
    if (issues.isNotEmpty) {
      DartType targetReceiver;
      if (klass != null) {
        targetReceiver =
            new InterfaceType(klass, klass.enclosingLibrary.nonNullable);
      }
      String targetName = node.target.name.text;
      reportTypeArgumentIssues(issues, fileUri, node.fileOffset,
          typeArgumentsInfo: typeArgumentsInfo,
          targetReceiver: targetReceiver,
          targetName: targetName);
    }
  }

  void checkBoundsInMethodInvocation(
      DartType receiverType,
      TypeEnvironment typeEnvironment,
      ClassHierarchy hierarchy,
      TypeInferrerImpl typeInferrer,
      Name name,
      Member interfaceTarget,
      Arguments arguments,
      Uri fileUri,
      int offset) {
    if (arguments.types.isEmpty) return;
    Class klass;
    List<DartType> receiverTypeArguments;
    if (receiverType is InterfaceType) {
      klass = receiverType.classNode;
      receiverTypeArguments = receiverType.typeArguments;
    } else {
      return;
    }
    // TODO(dmitryas): Find a better way than relying on [interfaceTarget].
    Member method = hierarchy.getDispatchTarget(klass, name) ?? interfaceTarget;
    if (method == null || method is! Procedure) {
      return;
    }
    if (klass != method.enclosingClass) {
      Supertype parent =
          hierarchy.getClassAsInstanceOf(klass, method.enclosingClass);
      klass = method.enclosingClass;
      receiverTypeArguments = parent.typeArguments;
    }
    Map<TypeParameter, DartType> substitutionMap = <TypeParameter, DartType>{};
    for (int i = 0; i < receiverTypeArguments.length; ++i) {
      substitutionMap[klass.typeParameters[i]] = receiverTypeArguments[i];
    }
    List<TypeParameter> methodParameters = method.function.typeParameters;
    // The error is to be reported elsewhere.
    if (methodParameters.length != arguments.types.length) return;
    List<TypeParameter> instantiatedMethodParameters =
        new List<TypeParameter>.filled(methodParameters.length, null);
    for (int i = 0; i < instantiatedMethodParameters.length; ++i) {
      instantiatedMethodParameters[i] =
          new TypeParameter(methodParameters[i].name);
      substitutionMap[methodParameters[i]] =
          new TypeParameterType.forAlphaRenaming(
              methodParameters[i], instantiatedMethodParameters[i]);
    }
    for (int i = 0; i < instantiatedMethodParameters.length; ++i) {
      instantiatedMethodParameters[i].bound =
          substitute(methodParameters[i].bound, substitutionMap);
    }

    final DartType bottomType = isNonNullableByDefault
        ? const NeverType(Nullability.nonNullable)
        : const NullType();
    Set<TypeArgumentIssue> issues = {};
    issues.addAll(findTypeArgumentIssuesForInvocation(
            library,
            instantiatedMethodParameters,
            arguments.types,
            typeEnvironment,
            SubtypeCheckMode.ignoringNullabilities,
            bottomType) ??
        const []);
    if (isNonNullableByDefault) {
      issues.addAll(findTypeArgumentIssuesForInvocation(
              library,
              instantiatedMethodParameters,
              arguments.types,
              typeEnvironment,
              SubtypeCheckMode.withNullabilities,
              bottomType) ??
          const []);
    }
    reportTypeArgumentIssues(issues, fileUri, offset,
        typeArgumentsInfo: getTypeArgumentsInfo(arguments),
        targetReceiver: receiverType,
        targetName: name.text);
  }

  void checkTypesInOutline(TypeEnvironment typeEnvironment) {
    Iterator<Builder> iterator = this.iterator;
    while (iterator.moveNext()) {
      Builder declaration = iterator.current;
      if (declaration is FieldBuilder) {
        checkTypesInField(declaration, typeEnvironment);
      } else if (declaration is ProcedureBuilder) {
        checkTypesInProcedureBuilder(declaration, typeEnvironment);
        if (declaration.isGetter) {
          Builder setterDeclaration =
              scope.lookupLocalMember(declaration.name, setter: true);
          if (setterDeclaration != null) {
            checkGetterSetterTypes(
                declaration, setterDeclaration, typeEnvironment);
          }
        }
      } else if (declaration is SourceClassBuilder) {
        declaration.checkTypesInOutline(typeEnvironment);
      } else if (declaration is SourceExtensionBuilder) {
        declaration.checkTypesInOutline(typeEnvironment);
      } else {
        //assert(false, "Unexpected declaration ${declaration.runtimeType}");
      }
    }
    inferredTypes.clear();
  }

  void registerImplicitlyTypedField(FieldBuilder fieldBuilder) {
    (_implicitlyTypedFields ??= <FieldBuilder>[]).add(fieldBuilder);
  }

  @override
  List<FieldBuilder> takeImplicitlyTypedFields() {
    List<FieldBuilder> result = _implicitlyTypedFields;
    _implicitlyTypedFields = null;
    return result;
  }

  void forEachExtensionInScope(void Function(ExtensionBuilder) f) {
    if (_extensionsInScope == null) {
      _extensionsInScope = <ExtensionBuilder>{};
      scope.forEachExtension(_extensionsInScope.add);
      if (_prefixBuilders != null) {
        for (PrefixBuilder prefix in _prefixBuilders) {
          prefix.exportScope.forEachExtension(_extensionsInScope.add);
        }
      }
    }
    _extensionsInScope.forEach(f);
  }

  void clearExtensionsInScopeCache() {
    _extensionsInScope = null;
  }

  /// Set to some non-null name when entering a class; set to null when leaving
  /// the class.
  ///
  /// Called in OutlineBuilder.beginClassDeclaration,
  /// OutlineBuilder.endClassDeclaration,
  /// OutlineBuilder.beginMixinDeclaration,
  /// OutlineBuilder.endMixinDeclaration.
  void setCurrentClassName(String name) {
    if (name == null) {
      _currentClassReferencesFromIndexed = null;
    } else if (referencesFrom != null) {
      _currentClassReferencesFromIndexed =
          referencesFromIndexed.lookupIndexedClass(name);
    }
  }

  Procedure lookupLibraryReferenceProcedure(String name, bool setter) {
    if (referencesFrom == null) return null;
    if (setter) {
      return referencesFromIndexed.lookupProcedureSetter(name);
    } else {
      return referencesFromIndexed.lookupProcedureNotSetter(name);
    }
  }
}

// The kind of type parameter scope built by a [TypeParameterScopeBuilder]
// object.
enum TypeParameterScopeKind {
  library,
  classOrNamedMixinApplication,
  classDeclaration,
  mixinDeclaration,
  unnamedMixinApplication,
  namedMixinApplication,
  extensionDeclaration,
  typedef,
  staticOrInstanceMethodOrConstructor,
  topLevelMethod,
  factoryMethod,
  functionType,
}

/// A builder object preparing for building declarations that can introduce type
/// parameter and/or members.
///
/// Unlike [Scope], this scope is used during construction of builders to
/// ensure types and members are added to and resolved in the correct location.
class TypeParameterScopeBuilder {
  TypeParameterScopeKind _kind;

  final TypeParameterScopeBuilder parent;

  final Map<String, Builder> members;

  final Map<String, Builder> constructors;

  final Map<String, MemberBuilder> setters;

  final Set<ExtensionBuilder> extensions;

  final List<UnresolvedType> types = <UnresolvedType>[];

  // TODO(johnniwinther): Stop using [_name] for determining the declaration
  // kind.
  String _name;

  /// Offset of name token, updated by the outline builder along
  /// with the name as the current declaration changes.
  int _charOffset;

  List<TypeVariableBuilder> _typeVariables;

  /// The type of `this` in instance methods declared in extension declarations.
  ///
  /// Instance methods declared in extension declarations methods are extended
  /// with a synthesized parameter of this type.
  TypeBuilder _extensionThisType;

  bool declaresConstConstructor = false;

  TypeParameterScopeBuilder(
      this._kind,
      this.members,
      this.setters,
      this.constructors,
      this.extensions,
      this._name,
      this._charOffset,
      this.parent) {
    assert(_name != null);
  }

  TypeParameterScopeBuilder.library()
      : this(
            TypeParameterScopeKind.library,
            <String, Builder>{},
            <String, MemberBuilder>{},
            null, // No support for constructors in library scopes.
            <ExtensionBuilder>{},
            "<library>",
            -1,
            null);

  TypeParameterScopeBuilder createNested(
      TypeParameterScopeKind kind, String name, bool hasMembers) {
    return new TypeParameterScopeBuilder(
        kind,
        hasMembers ? <String, MemberBuilder>{} : null,
        hasMembers ? <String, MemberBuilder>{} : null,
        hasMembers ? <String, MemberBuilder>{} : null,
        null, // No support for extensions in nested scopes.
        name,
        -1,
        this);
  }

  /// Registers that this builder is preparing for a class declaration with the
  /// given [name] and [typeVariables] located [charOffset].
  void markAsClassDeclaration(
      String name, int charOffset, List<TypeVariableBuilder> typeVariables) {
    assert(_kind == TypeParameterScopeKind.classOrNamedMixinApplication,
        "Unexpected declaration kind: $_kind");
    _kind = TypeParameterScopeKind.classDeclaration;
    _name = name;
    _charOffset = charOffset;
    _typeVariables = typeVariables;
  }

  /// Registers that this builder is preparing for a named mixin application
  /// with the given [name] and [typeVariables] located [charOffset].
  void markAsNamedMixinApplication(
      String name, int charOffset, List<TypeVariableBuilder> typeVariables) {
    assert(_kind == TypeParameterScopeKind.classOrNamedMixinApplication,
        "Unexpected declaration kind: $_kind");
    _kind = TypeParameterScopeKind.namedMixinApplication;
    _name = name;
    _charOffset = charOffset;
    _typeVariables = typeVariables;
  }

  /// Registers that this builder is preparing for a mixin declaration with the
  /// given [name] and [typeVariables] located [charOffset].
  void markAsMixinDeclaration(
      String name, int charOffset, List<TypeVariableBuilder> typeVariables) {
    // TODO(johnniwinther): Avoid using 'classOrNamedMixinApplication' for mixin
    // declaration. These are syntactically distinct so we don't need the
    // transition.
    assert(_kind == TypeParameterScopeKind.classOrNamedMixinApplication,
        "Unexpected declaration kind: $_kind");
    _kind = TypeParameterScopeKind.mixinDeclaration;
    _name = name;
    _charOffset = charOffset;
    _typeVariables = typeVariables;
  }

  /// Registers that this builder is preparing for an extension declaration with
  /// the given [name] and [typeVariables] located [charOffset].
  void markAsExtensionDeclaration(
      String name, int charOffset, List<TypeVariableBuilder> typeVariables) {
    assert(_kind == TypeParameterScopeKind.extensionDeclaration,
        "Unexpected declaration kind: $_kind");
    _name = name;
    _charOffset = charOffset;
    _typeVariables = typeVariables;
  }

  /// Registers the 'extension this type' of the extension declaration prepared
  /// for by this builder.
  ///
  /// See [extensionThisType] for terminology.
  void registerExtensionThisType(TypeBuilder type) {
    assert(_kind == TypeParameterScopeKind.extensionDeclaration,
        "DeclarationBuilder.registerExtensionThisType is not supported $_kind");
    assert(_extensionThisType == null,
        "Extension this type has already been set.");
    _extensionThisType = type;
  }

  /// Returns what kind of declaration this [TypeParameterScopeBuilder] is
  /// preparing for.
  ///
  /// This information is transient for some declarations. In particular
  /// classes and named mixin applications are initially created with the kind
  /// [TypeParameterScopeKind.classOrNamedMixinApplication] before a call to
  /// either [markAsClassDeclaration] or [markAsNamedMixinApplication] sets the
  /// value to its actual kind.
  // TODO(johnniwinther): Avoid the transition currently used on mixin
  // declarations.
  TypeParameterScopeKind get kind => _kind;

  String get name => _name;

  int get charOffset => _charOffset;

  List<TypeVariableBuilder> get typeVariables => _typeVariables;

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
    assert(kind == TypeParameterScopeKind.extensionDeclaration,
        "DeclarationBuilder.extensionThisType not supported on $kind.");
    assert(_extensionThisType != null,
        "DeclarationBuilder.extensionThisType has not been set on $this.");
    return _extensionThisType;
  }

  /// Adds the yet unresolved [type] to this scope builder.
  ///
  /// Unresolved type will be resolved through [resolveTypes] when the scope
  /// is fully built. This allows for resolving self-referencing types, like
  /// type parameter used in their own bound, for instance `<T extends A<T>>`.
  void addType(UnresolvedType type) {
    types.add(type);
  }

  /// Resolves type variables in [types] and propagate other types to [parent].
  void resolveTypes(
      List<TypeVariableBuilder> typeVariables, SourceLibraryBuilder library) {
    Map<String, TypeVariableBuilder> map;
    if (typeVariables != null) {
      map = <String, TypeVariableBuilder>{};
      for (TypeVariableBuilder builder in typeVariables) {
        map[builder.name] = builder;
      }
    }
    Scope scope;
    for (UnresolvedType type in types) {
      Object nameOrQualified = type.builder.name;
      String name = nameOrQualified is QualifiedName
          ? nameOrQualified.qualifier
          : nameOrQualified;
      Builder declaration;
      if (name != null) {
        if (members != null) {
          declaration = members[name];
        }
        if (declaration == null && map != null) {
          declaration = map[name];
        }
      }
      if (declaration == null) {
        // Since name didn't resolve in this scope, propagate it to the
        // parent declaration.
        parent.addType(type);
      } else if (nameOrQualified is QualifiedName) {
        NamedTypeBuilder builder = type.builder;
        // Attempt to use a member or type variable as a prefix.
        Message message = templateNotAPrefixInTypeAnnotation.withArguments(
            flattenName(
                nameOrQualified.qualifier, type.charOffset, type.fileUri),
            nameOrQualified.name);
        library.addProblem(message, type.charOffset,
            nameOrQualified.endCharOffset - type.charOffset, type.fileUri);
        builder.bind(builder.buildInvalidTypeDeclarationBuilder(
            message.withLocation(type.fileUri, type.charOffset,
                nameOrQualified.endCharOffset - type.charOffset)));
      } else {
        scope ??= toScope(null).withTypeVariables(typeVariables);
        type.resolveIn(scope, library);
      }
    }
    types.clear();
  }

  Scope toScope(Scope parent) {
    return new Scope(
        local: members,
        setters: setters,
        extensions: extensions,
        parent: parent,
        debugName: name,
        isModifiable: false);
  }

  @override
  String toString() => 'DeclarationBuilder(${hashCode}:kind=$kind,name=$name)';
}

class FieldInfo {
  final String name;
  final int charOffset;
  final Token initializerToken;
  final Token beforeLast;
  final int charEndOffset;

  const FieldInfo(this.name, this.charOffset, this.initializerToken,
      this.beforeLast, this.charEndOffset);
}

class ImplementationInfo {
  final String name;
  final Builder declaration;
  final int charOffset;

  const ImplementationInfo(this.name, this.declaration, this.charOffset);
}

Uri computeLibraryUri(Builder declaration) {
  Builder current = declaration;
  do {
    if (current is LibraryBuilder) return current.importUri;
    current = current.parent;
  } while (current != null);
  return unhandled("no library parent", "${declaration.runtimeType}",
      declaration.charOffset, declaration.fileUri);
}

String extractName(name) => name is QualifiedName ? name.name : name;

class PostponedProblem {
  final Message message;
  final int charOffset;
  final int length;
  final Uri fileUri;

  PostponedProblem(this.message, this.charOffset, this.length, this.fileUri);
}

class LanguageVersion {
  final Version version;
  final Uri fileUri;
  final int charOffset;
  final int charCount;
  final bool isExplicit;
  bool isFinal = false;

  LanguageVersion(this.version, this.fileUri, this.charOffset, this.charCount,
      this.isExplicit);

  bool get valid => true;

  int get hashCode => version.hashCode * 13 + isExplicit.hashCode * 19;

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageVersion &&
        version == other.version &&
        isExplicit == other.isExplicit;
  }

  String toString() {
    return 'LanguageVersion(version=$version,isExplicit=$isExplicit,'
        'fileUri=$fileUri,charOffset=$charOffset,charCount=$charCount)';
  }
}

class InvalidLanguageVersion implements LanguageVersion {
  final Uri fileUri;
  final int charOffset;
  final int charCount;
  final bool isExplicit;
  final Version version;
  bool isFinal = false;

  InvalidLanguageVersion(this.fileUri, this.charOffset, this.charCount,
      this.isExplicit, this.version);

  @override
  bool get valid => false;

  int get hashCode => isExplicit.hashCode * 19;

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvalidLanguageVersion && isExplicit == other.isExplicit;
  }

  String toString() {
    return 'InvalidLanguageVersion(isExplicit=$isExplicit,'
        'fileUri=$fileUri,charOffset=$charOffset,charCount=$charCount)';
  }
}

class ImplicitLanguageVersion implements LanguageVersion {
  @override
  final Version version;
  bool isFinal = false;

  ImplicitLanguageVersion(this.version);

  @override
  bool get valid => true;

  @override
  Uri get fileUri => null;

  @override
  int get charOffset => -1;

  @override
  int get charCount => noLength;

  @override
  bool get isExplicit => false;

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImplicitLanguageVersion && version == other.version;
  }

  @override
  String toString() {
    return 'ImplicitLanguageVersion(version=$version)';
  }
}

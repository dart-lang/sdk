// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_library_builder;

import 'dart:collection';
import 'dart:convert' show jsonEncode;

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:_fe_analyzer_shared/src/util/resolve_relative_uri.dart'
    show resolveRelativeUri;
import 'package:kernel/ast.dart' hide Combinator, MapLiteralEntry;
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClassHierarchyBase, ClassHierarchyMembers;
import 'package:kernel/clone.dart' show CloneVisitorNotMembers;
import 'package:kernel/reference_from_index.dart'
    show IndexedClass, IndexedContainer, IndexedLibrary;
import 'package:kernel/src/bounds_checks.dart'
    show
        TypeArgumentIssue,
        findTypeArgumentIssues,
        findTypeArgumentIssuesForInvocation,
        getGenericTypeName,
        hasGenericFunctionTypeAsTypeArgument;
import 'package:kernel/type_algebra.dart' show Substitution, substitute;
import 'package:kernel/type_environment.dart'
    show SubtypeCheckMode, TypeEnvironment;

import '../../api_prototype/experimental_flags.dart';
import '../../base/nnbd_mode.dart';
import '../builder/builder.dart';
import '../builder/builtin_type_declaration_builder.dart';
import '../builder/class_builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/dynamic_type_declaration_builder.dart';
import '../builder/extension_builder.dart';
import '../builder/field_builder.dart';
import '../builder/fixed_type_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/inline_class_builder.dart';
import '../builder/invalid_type_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/mixin_application_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/named_type_builder.dart';
import '../builder/never_type_declaration_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/record_type_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/type_variable_builder.dart';
import '../builder/void_type_declaration_builder.dart';
import '../combinator.dart' show CombinatorBuilder;
import '../configuration.dart' show Configuration;
import '../dill/dill_library_builder.dart' show DillLibraryBuilder;
import '../export.dart' show Export;
import '../fasta_codes.dart';
import '../identifiers.dart' show QualifiedName, flattenName;
import '../import.dart' show Import;
import '../kernel/body_builder_context.dart';
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/hierarchy/members_builder.dart';
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/load_library_builder.dart';
import '../kernel/macro/macro.dart';
import '../kernel/type_algorithms.dart'
    show
        NonSimplicityIssue,
        calculateBounds,
        computeTypeVariableBuilderVariance,
        findUnaliasedGenericFunctionTypes,
        getInboundReferenceIssuesInType,
        getNonSimplicityIssuesForDeclaration,
        getNonSimplicityIssuesForTypeVariables,
        pendingVariance;
import '../kernel/utils.dart'
    show
        compareProcedures,
        exportDynamicSentinel,
        exportNeverSentinel,
        toKernelCombinators,
        unserializableExportName;
import '../modifier.dart'
    show
        abstractMask,
        constMask,
        externalMask,
        finalMask,
        declaresConstConstructorMask,
        hasInitializerMask,
        initializingFormalMask,
        superInitializingFormalMask,
        lateMask,
        mixinDeclarationMask,
        namedMixinApplicationMask,
        staticMask;
import '../names.dart' show indexSetName;
import '../operator.dart';
import '../problems.dart' show unexpected, unhandled;
import '../scope.dart';
import '../util/helpers.dart';
import 'constructor_declaration.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart' show SourceClassBuilder;
import 'source_constructor_builder.dart';
import 'source_enum_builder.dart';
import 'source_extension_builder.dart';
import 'source_factory_builder.dart';
import 'source_field_builder.dart';
import 'source_function_builder.dart';
import 'source_inline_class_builder.dart';
import 'source_loader.dart' show SourceLoader;
import 'source_member_builder.dart';
import 'source_procedure_builder.dart';
import 'source_type_alias_builder.dart';

class SourceLibraryBuilder extends LibraryBuilderImpl {
  static const String MALFORMED_URI_SCHEME = "org-dartlang-malformed-uri";

  @override
  final SourceLoader loader;

  final TypeParameterScopeBuilder _libraryTypeParameterScopeBuilder;

  final List<ConstructorReferenceBuilder> constructorReferences =
      <ConstructorReferenceBuilder>[];

  final List<LibraryBuilder> parts = <LibraryBuilder>[];

  // Can I use library.parts instead? See SourceLibraryBuilder.addPart.
  final List<int> partOffsets = <int>[];

  final List<Import> imports = <Import>[];

  final List<Export> exports = <Export>[];

  final Scope importScope;

  @override
  final Uri fileUri;

  final Uri? _packageUri;

  Uri? get packageUriForTesting => _packageUri;

  @override
  final bool isUnsupported;

  final List<LibraryAccess> accessors = [];

  @override
  String? name;

  String? partOfName;

  Uri? partOfUri;

  List<MetadataBuilder>? metadata;

  /// The current declaration that is being built. When we start parsing a
  /// declaration (class, method, and so on), we don't have enough information
  /// to create a builder and this object records its members and types until,
  /// for example, [addClass] is called.
  TypeParameterScopeBuilder currentTypeParameterScopeBuilder;

  /// Non-null if this library causes an error upon access, that is, there was
  /// an error reading its source.
  Message? accessProblem;

  @override
  final Library library;

  final LibraryName libraryName;

  final SourceLibraryBuilder? _immediateOrigin;

  final List<SourceFunctionBuilder> nativeMethods = <SourceFunctionBuilder>[];

  final List<TypeVariableBuilder> unboundTypeVariables =
      <TypeVariableBuilder>[];

  final List<PendingBoundsCheck> _pendingBoundsChecks = [];
  final List<GenericFunctionTypeCheck> _pendingGenericFunctionTypeChecks = [];

  // A list of alternating forwarders and the procedures they were generated
  // for.  Note that it may not include a forwarder-origin pair in cases when
  // the former does not need to be updated after the body of the latter was
  // built.
  final List<Procedure> forwardersOrigins = <Procedure>[];

  // While the bounds of type parameters aren't compiled yet, we can't tell the
  // default nullability of the corresponding type-parameter types.  This list
  // is used to collect such type-parameter types in order to set the
  // nullability after the bounds are built.
  final List<PendingNullability> _pendingNullabilities = <PendingNullability>[];

  // A library to use for Names generated when compiling code in this library.
  // This allows code generated in one library to use the private namespace of
  // another, for example during expression compilation (debugging).
  Library get nameOrigin => _nameOrigin?.library ?? library;

  @override
  LibraryBuilder get nameOriginBuilder => _nameOrigin ?? this;
  final LibraryBuilder? _nameOrigin;

  final Library? referencesFrom;
  final IndexedLibrary? referencesFromIndexed;
  IndexedClass? _currentClassReferencesFromIndexed;

  /// Exports that can't be serialized.
  ///
  /// The key is the name of the exported member.
  ///
  /// If the name is `dynamic` or `Never`, this library reexports the
  /// corresponding type from `dart:core`, and the value is the sentinel values
  /// [exportDynamicSentinel] or [exportNeverSentinel], respectively.
  ///
  /// Otherwise, this represents an error (an ambiguous export). In this case,
  /// the error message is the corresponding value in the map.
  Map<String, String>? unserializableExports;

  /// The language version of this library as defined by the language version
  /// of the package it belongs to, if present, or the current language version
  /// otherwise.
  ///
  /// This language version we be used as the language version for the library
  /// if the library does not contain an explicit @dart= annotation.
  final LanguageVersion packageLanguageVersion;

  /// The actual language version of this library. This is initially the
  /// [packageLanguageVersion] but will be updated if the library contains
  /// an explicit @dart= language version annotation.
  LanguageVersion _languageVersion;

  bool postponedProblemsIssued = false;
  List<PostponedProblem>? postponedProblems;

  /// List of [PrefixBuilder]s for imports with prefixes.
  List<PrefixBuilder>? _prefixBuilders;

  /// Set of extension declarations in scope. This is computed lazily in
  /// [forEachExtensionInScope].
  Set<ExtensionBuilder>? _extensionsInScope;

  List<SourceLibraryBuilder>? _patchLibraries;

  int patchIndex = 0;

  /// `true` if this is an augmentation library.
  final bool isAugmentation;

  /// Map from synthesized names used for omitted types to their corresponding
  /// synthesized type declarations.
  ///
  /// This is used in macro generated code to create type annotations from
  /// inferred types in the original code.
  final Map<String, Builder>? _omittedTypeDeclarationBuilders;

  MergedLibraryScope? _mergedScope;

  /// If `null`, [SourceLoader.computeFieldPromotability] hasn't been called
  /// yet, or field promotion is disabled for this library.  If not `null`,
  /// field promotion is enabled for this library and this is the set of private
  /// field names for which promotion is blocked due to the presence of a
  /// non-final field or a concrete getter.
  Set<String>? unpromotablePrivateFieldNames;

  SourceLibraryBuilder.internal(
      SourceLoader loader,
      Uri importUri,
      Uri fileUri,
      Uri? packageUri,
      LanguageVersion packageLanguageVersion,
      Scope? scope,
      SourceLibraryBuilder? origin,
      Library library,
      LibraryBuilder? nameOrigin,
      Library? referencesFrom,
      {bool? referenceIsPartOwner,
      required bool isUnsupported,
      required bool isAugmentation,
      Map<String, Builder>? omittedTypes})
      : this.fromScopes(
            loader,
            importUri,
            fileUri,
            packageUri,
            packageLanguageVersion,
            new TypeParameterScopeBuilder.library(),
            scope ?? new Scope.top(kind: ScopeKind.library),
            origin,
            library,
            nameOrigin,
            referencesFrom,
            isUnsupported: isUnsupported,
            isAugmentation: isAugmentation,
            omittedTypes: omittedTypes);

  SourceLibraryBuilder.fromScopes(
      this.loader,
      this.importUri,
      this.fileUri,
      this._packageUri,
      this.packageLanguageVersion,
      this._libraryTypeParameterScopeBuilder,
      this.importScope,
      SourceLibraryBuilder? origin,
      this.library,
      this._nameOrigin,
      this.referencesFrom,
      {required this.isUnsupported,
      required this.isAugmentation,
      Map<String, Builder>? omittedTypes})
      : _languageVersion = packageLanguageVersion,
        currentTypeParameterScopeBuilder = _libraryTypeParameterScopeBuilder,
        referencesFromIndexed =
            referencesFrom == null ? null : new IndexedLibrary(referencesFrom),
        _immediateOrigin = origin,
        _omittedTypeDeclarationBuilders = omittedTypes,
        libraryName = new LibraryName(library.reference),
        super(
            fileUri,
            _libraryTypeParameterScopeBuilder.toScope(importScope,
                omittedTypeDeclarationBuilders: omittedTypes),
            origin?.exportScope ?? new Scope.top(kind: ScopeKind.library)) {
    assert(
        _packageUri == null ||
            !importUri.isScheme('package') ||
            importUri.path.startsWith(_packageUri!.path),
        "Foreign package uri '$_packageUri' set on library with import uri "
        "'${importUri}'.");
    assert(
        !importUri.isScheme('dart') || _packageUri == null,
        "Package uri '$_packageUri' set on dart: library with import uri "
        "'${importUri}'.");
  }

  MergedLibraryScope get mergedScope {
    return _mergedScope ??=
        isPatch ? origin.mergedScope : new MergedLibraryScope(this);
  }

  TypeParameterScopeBuilder get libraryTypeParameterScopeBuilderForTesting =>
      _libraryTypeParameterScopeBuilder;

  LibraryFeatures? _libraryFeatures;

  /// Returns the state of the experimental features within this library.
  LibraryFeatures get libraryFeatures =>
      _libraryFeatures ??= new LibraryFeatures(loader.target.globalFeatures,
          _packageUri ?? origin.importUri, languageVersion.version);

  /// Reports that [feature] is not enabled, using [charOffset] and
  /// [length] for the location of the message.
  ///
  /// Return the primary message.
  Message reportFeatureNotEnabled(
      LibraryFeature feature, Uri fileUri, int charOffset, int length) {
    assert(!feature.isEnabled);
    Message message;
    if (feature.isSupported) {
      if (languageVersion.isExplicit) {
        message = templateExperimentOptOutExplicit.withArguments(
            feature.flag.name, feature.enabledVersion.toText());
        addProblem(message, charOffset, length, fileUri,
            context: <LocatedMessage>[
              templateExperimentOptOutComment
                  .withArguments(feature.flag.name)
                  .withLocation(languageVersion.fileUri!,
                      languageVersion.charOffset, languageVersion.charCount)
            ]);
      } else {
        message = templateExperimentOptOutImplicit.withArguments(
            feature.flag.name, feature.enabledVersion.toText());
        addProblem(message, charOffset, length, fileUri);
      }
    } else {
      if (feature.flag.isEnabledByDefault) {
        if (languageVersion.version < feature.enabledVersion) {
          message =
              templateExperimentDisabledInvalidLanguageVersion.withArguments(
                  feature.flag.name, feature.enabledVersion.toText());
          addProblem(message, charOffset, length, fileUri);
        } else {
          message = templateExperimentDisabled.withArguments(feature.flag.name);
          addProblem(message, charOffset, length, fileUri);
        }
      } else {
        message = templateExperimentNotEnabledOffByDefault
            .withArguments(feature.flag.name);
        addProblem(message, charOffset, length, fileUri);
      }
    }
    return message;
  }

  void _updateLibraryNNBDSettings() {
    library.isNonNullableByDefault = isNonNullableByDefault;
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
  }

  SourceLibraryBuilder(
      {required Uri importUri,
      required Uri fileUri,
      Uri? packageUri,
      required LanguageVersion packageLanguageVersion,
      required SourceLoader loader,
      SourceLibraryBuilder? origin,
      Scope? scope,
      Library? target,
      LibraryBuilder? nameOrigin,
      Library? referencesFrom,
      bool? referenceIsPartOwner,
      required bool isUnsupported,
      required bool isAugmentation,
      Map<String, Builder>? omittedTypes})
      : this.internal(
            loader,
            importUri,
            fileUri,
            packageUri,
            packageLanguageVersion,
            scope,
            origin,
            target ??
                (origin?.library ??
                    new Library(importUri,
                        fileUri: fileUri,
                        reference: referenceIsPartOwner == true
                            ? null
                            : referencesFrom?.reference)
                  ..setLanguageVersion(packageLanguageVersion.version)),
            nameOrigin,
            referencesFrom,
            referenceIsPartOwner: referenceIsPartOwner,
            isUnsupported: isUnsupported,
            isAugmentation: isAugmentation,
            omittedTypes: omittedTypes);

  @override
  bool get isPart => partOfName != null || partOfUri != null;

  // TODO(johnniwinther): Can avoid using this from outside this class?
  Iterable<SourceLibraryBuilder>? get patchLibraries => _patchLibraries;

  void addPatchLibrary(SourceLibraryBuilder patchLibrary) {
    assert(patchLibrary.isPatch,
        "Library ${patchLibrary} must be a patch library.");
    assert(!patchLibrary.isPart,
        "Patch library ${patchLibrary} cannot be a part .");
    (_patchLibraries ??= []).add(patchLibrary);
    patchLibrary.patchIndex = _patchLibraries!.length;
  }

  /// Creates a synthesized augmentation library for the [source] code and
  /// attach it as a patch library of this library.
  ///
  /// To support the parser of the [source], the library is registered as an
  /// unparsed library on the [loader].
  SourceLibraryBuilder createAugmentationLibrary(String source,
      {Map<String, OmittedTypeBuilder>? omittedTypes}) {
    int index = _patchLibraries?.length ?? 0;
    Uri uri =
        new Uri(scheme: augmentationScheme, path: '${fileUri.path}-$index');
    Map<String, Builder>? omittedTypeDeclarationBuilders;
    if (omittedTypes != null && omittedTypes.isNotEmpty) {
      omittedTypeDeclarationBuilders = {};
      for (MapEntry<String, OmittedTypeBuilder> entry in omittedTypes.entries) {
        omittedTypeDeclarationBuilders[entry.key] =
            new OmittedTypeDeclarationBuilder(entry.key, entry.value, this);
      }
    }
    SourceLibraryBuilder augmentationLibrary = new SourceLibraryBuilder(
        fileUri: uri,
        importUri: uri,
        packageLanguageVersion: packageLanguageVersion,
        loader: loader,
        isUnsupported: false,
        target: library,
        origin: this,
        isAugmentation: true,
        referencesFrom: referencesFrom,
        omittedTypes: omittedTypeDeclarationBuilders);
    addPatchLibrary(augmentationLibrary);
    loader.registerUnparsedLibrarySource(augmentationLibrary, source);
    return augmentationLibrary;
  }

  List<NamedTypeBuilder> get unresolvedNamedTypes =>
      _libraryTypeParameterScopeBuilder.unresolvedNamedTypes;

  @override
  bool get isSynthetic => accessProblem != null;

  NamedTypeBuilder registerUnresolvedNamedType(NamedTypeBuilder type) {
    currentTypeParameterScopeBuilder.registerUnresolvedNamedType(type);
    return type;
  }

  bool get isInferenceUpdate1Enabled =>
      libraryFeatures.inferenceUpdate1.isSupported &&
      languageVersion.version >=
          libraryFeatures.inferenceUpdate1.enabledVersion;

  bool get isInferenceUpdate2Enabled =>
      libraryFeatures.inferenceUpdate2.isEnabled;

  bool? _isNonNullableByDefault;

  @override
  @pragma("vm:prefer-inline")
  bool get isNonNullableByDefault {
    assert(
        _isNonNullableByDefault == null ||
            _isNonNullableByDefault == _computeIsNonNullableByDefault(),
        "Unstable isNonNullableByDefault property, changed "
        "from ${_isNonNullableByDefault} to "
        "${_computeIsNonNullableByDefault()}");
    return _isNonNullableByDefault ?? _ensureIsNonNullableByDefault();
  }

  bool _ensureIsNonNullableByDefault() {
    if (_isNonNullableByDefault == null) {
      _isNonNullableByDefault = _computeIsNonNullableByDefault();
      _updateLibraryNNBDSettings();
    }
    return _isNonNullableByDefault!;
  }

  bool _computeIsNonNullableByDefault() =>
      libraryFeatures.nonNullable.isSupported &&
      languageVersion.version >= libraryFeatures.nonNullable.enabledVersion;

  LanguageVersion get languageVersion {
    assert(
        _languageVersion.isFinal,
        "Attempting to read the language version of ${this} before has been "
        "finalized.");
    return _languageVersion;
  }

  void markLanguageVersionFinal() {
    _languageVersion.isFinal = true;
    _ensureIsNonNullableByDefault();
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
  }

  /// Set the language version to an explicit major and minor version.
  ///
  /// The default language version specified by the `package_config.json` file
  /// is passed to the constructor, but the library can have source code that
  /// specifies another one which should be supported.
  ///
  /// Only the first registered language version is used.
  ///
  /// [offset] and [length] refers to the offset and length of the source code
  /// specifying the language version.
  void registerExplicitLanguageVersion(Version version,
      {int offset = 0, int length = noLength}) {
    if (_languageVersion.isExplicit) {
      // If more than once language version exists we use the first.
      return;
    }
    assert(!_languageVersion.isFinal);

    if (version > loader.target.currentSdkVersion) {
      // If trying to set a language version that is higher than the current sdk
      // version it's an error.
      addPostponedProblem(
          templateLanguageVersionTooHigh.withArguments(
              loader.target.currentSdkVersion.major,
              loader.target.currentSdkVersion.minor),
          offset,
          length,
          fileUri);
      // If the package set an OK version, but the file set an invalid version
      // we want to use the package version.
      _languageVersion = new InvalidLanguageVersion(
          fileUri, offset, length, packageLanguageVersion.version, true);
    } else {
      _languageVersion = new LanguageVersion(version, fileUri, offset, length);
    }
    library.setLanguageVersion(_languageVersion.version);
    _languageVersion.isFinal = true;
  }

  ConstructorReferenceBuilder addConstructorReference(Object name,
      List<TypeBuilder>? typeArguments, String? suffix, int charOffset) {
    ConstructorReferenceBuilder ref = new ConstructorReferenceBuilder(
        name, typeArguments, suffix, this, charOffset);
    constructorReferences.add(ref);
    return ref;
  }

  void beginNestedDeclaration(TypeParameterScopeKind kind, String name,
      {bool hasMembers = true}) {
    currentTypeParameterScopeBuilder =
        currentTypeParameterScopeBuilder.createNested(kind, name, hasMembers);
  }

  TypeParameterScopeBuilder endNestedDeclaration(
      TypeParameterScopeKind kind, String? name) {
    assert(
        currentTypeParameterScopeBuilder.kind == kind,
        "Unexpected declaration. "
        "Trying to end a ${currentTypeParameterScopeBuilder.kind} as a $kind.");
    assert(
        (name?.startsWith(currentTypeParameterScopeBuilder.name) ??
                (name == currentTypeParameterScopeBuilder.name)) ||
            currentTypeParameterScopeBuilder.name == "operator" ||
            (name == null &&
                currentTypeParameterScopeBuilder.name ==
                    UnnamedExtensionName.unnamedExtensionSentinel) ||
            identical(name, "<syntax-error>"),
        "${name} != ${currentTypeParameterScopeBuilder.name}");
    TypeParameterScopeBuilder previous = currentTypeParameterScopeBuilder;
    currentTypeParameterScopeBuilder = currentTypeParameterScopeBuilder.parent!;
    return previous;
  }

  bool uriIsValid(Uri uri) => !uri.isScheme(MALFORMED_URI_SCHEME);

  Uri resolve(Uri baseUri, String? uri, int uriOffset, {isPart = false}) {
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
    if (isPart && baseUri.isScheme("dart")) {
      // Resolve using special rules for dart: URIs
      return resolveRelativeUri(baseUri, parsedUri);
    } else {
      return baseUri.resolveUri(parsedUri);
    }
  }

  String? computeAndValidateConstructorName(Object? name, int charOffset,
      {isFactory = false}) {
    String className = currentTypeParameterScopeBuilder.name;
    String prefix;
    String? suffix;
    if (name is QualifiedName) {
      prefix = name.qualifier as String;
      suffix = name.name;
    } else {
      prefix = name as String;
      suffix = null;
    }
    if (libraryFeatures.constructorTearoffs.isEnabled) {
      suffix = suffix == "new" ? "" : suffix;
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

  @override
  Iterable<Uri> get dependencies sync* {
    for (Export export in exports) {
      yield export.exported.importUri;
    }
    for (Import import in imports) {
      LibraryBuilder? imported = import.imported;
      if (imported != null) {
        yield imported.importUri;
      }
    }
  }

  void addExport(
      List<MetadataBuilder>? metadata,
      String uri,
      List<Configuration>? configurations,
      List<CombinatorBuilder>? combinators,
      int charOffset,
      int uriOffset) {
    if (configurations != null) {
      for (Configuration config in configurations) {
        if (loader.getLibrarySupportValue(config.dottedName) ==
            config.condition) {
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

  void addImport(
      {required List<MetadataBuilder>? metadata,
      required bool isAugmentationImport,
      required String uri,
      required List<Configuration>? configurations,
      required String? prefix,
      required List<CombinatorBuilder>? combinators,
      required bool deferred,
      required int charOffset,
      required int prefixCharOffset,
      required int uriOffset,
      required int importIndex}) {
    if (configurations != null) {
      for (Configuration config in configurations) {
        if (loader.getLibrarySupportValue(config.dottedName) ==
            config.condition) {
          uri = config.importUri;
          break;
        }
      }
    }

    LibraryBuilder? builder = null;
    Uri? resolvedUri;
    String? nativePath;
    const String nativeExtensionScheme = "dart-ext:";
    if (uri.startsWith(nativeExtensionScheme)) {
      addProblem(messageUnsupportedDartExt, charOffset, noLength, fileUri);
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
      builder = loader.read(resolvedUri, uriOffset,
          origin: isAugmentationImport ? this : null,
          accessor: this,
          isAugmentation: isAugmentationImport,
          referencesFrom: isAugmentationImport ? referencesFrom : null);
    }

    imports.add(new Import(
        this,
        builder,
        isAugmentationImport,
        deferred,
        prefix,
        combinators,
        configurations,
        charOffset,
        prefixCharOffset,
        importIndex,
        nativeImportPath: nativePath));
  }

  void addPart(List<MetadataBuilder>? metadata, String uri, int charOffset) {
    Uri resolvedUri;
    Uri newFileUri;
    resolvedUri = resolve(this.importUri, uri, charOffset, isPart: true);
    newFileUri = resolve(fileUri, uri, charOffset);
    // TODO(johnniwinther): Add a LibraryPartBuilder instead of using
    // [LibraryBuilder] to represent both libraries and parts.
    parts.add(loader.read(resolvedUri, charOffset,
        origin: isPatch ? origin : null, fileUri: newFileUri, accessor: this));
    partOffsets.add(charOffset);

    // TODO(ahe): [metadata] should be stored, evaluated, and added to [part].
    LibraryPart part = new LibraryPart(<Expression>[], uri)
      ..fileOffset = charOffset;
    library.addPart(part);
  }

  void addPartOf(List<MetadataBuilder>? metadata, String? name, String? uri,
      int uriOffset) {
    partOfName = name;
    if (uri != null) {
      partOfUri = resolve(this.importUri, uri, uriOffset);
      Uri newFileUri = resolve(fileUri, uri, uriOffset);
      loader.read(partOfUri!, uriOffset, fileUri: newFileUri, accessor: this);
    }
  }

  void addFields(List<MetadataBuilder>? metadata, int modifiers,
      bool isTopLevel, TypeBuilder? type, List<FieldInfo> fieldInfos) {
    for (FieldInfo info in fieldInfos) {
      bool isConst = modifiers & constMask != 0;
      bool isFinal = modifiers & finalMask != 0;
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
      addField(
          metadata,
          modifiers,
          isTopLevel,
          type ?? addInferableType(),
          info.name,
          info.charOffset,
          info.charEndOffset,
          startToken,
          hasInitializer,
          constInitializerToken:
              potentiallyNeedInitializerInOutline ? startToken : null);
    }
  }

  Builder? addBuilder(String name, Builder declaration, int charOffset,
      {Reference? getterReference, Reference? setterReference}) {
    // TODO(ahe): Set the parent correctly here. Could then change the
    // implementation of MemberBuilder.isTopLevel to test explicitly for a
    // LibraryBuilder.
    if (declaration is SourceExtensionBuilder &&
        declaration.isUnnamedExtension) {
      assert(currentTypeParameterScopeBuilder ==
          _libraryTypeParameterScopeBuilder);
      declaration.parent = this;
      currentTypeParameterScopeBuilder.extensions!.add(declaration);
      return declaration;
    }
    if (getterReference != null) {
      loader.buildersCreatedWithReferences[getterReference] = declaration;
    }
    if (setterReference != null) {
      loader.buildersCreatedWithReferences[setterReference] = declaration;
    }
    if (currentTypeParameterScopeBuilder == _libraryTypeParameterScopeBuilder) {
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
      assert(currentTypeParameterScopeBuilder.parent ==
          _libraryTypeParameterScopeBuilder);
    }
    bool isConstructor = declaration is FunctionBuilder &&
        (declaration.isConstructor || declaration.isFactory);
    if (!isConstructor && name == currentTypeParameterScopeBuilder.name) {
      addProblem(
          messageMemberWithSameNameAsClass, charOffset, noLength, fileUri);
    }
    Map<String, Builder> members = isConstructor
        ? currentTypeParameterScopeBuilder.constructors!
        : (declaration.isSetter
            ? currentTypeParameterScopeBuilder.setters!
            : currentTypeParameterScopeBuilder.members!);
    Builder? existing = members[name];

    if (existing == declaration) return existing;

    if (declaration.next != null && declaration.next != existing) {
      unexpected(
          "${declaration.next!.fileUri}@${declaration.next!.charOffset}",
          "${existing?.fileUri}@${existing?.charOffset}",
          declaration.charOffset,
          declaration.fileUri);
    }
    declaration.next = existing;
    if (declaration is PrefixBuilder && existing is PrefixBuilder) {
      assert(existing.next is! PrefixBuilder);
      Builder? deferred;
      Builder? other;
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
                  .withLocation(fileUri, other!.charOffset, noLength)
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
          charOffset, fullName.length, declaration.fileUri!,
          context: <LocatedMessage>[
            templateDuplicatedDeclarationCause
                .withArguments(fullName)
                .withLocation(
                    existing!.fileUri!, existing.charOffset, fullName.length)
          ]);
    } else if (declaration.isExtension) {
      // We add the extension declaration to the extension scope only if its
      // name is unique. Only the first of duplicate extensions is accessible
      // by name or by resolution and the remaining are dropped for the output.
      currentTypeParameterScopeBuilder.extensions!
          .add(declaration as SourceExtensionBuilder);
    }
    if (declaration is PrefixBuilder) {
      _prefixBuilders ??= <PrefixBuilder>[];
      _prefixBuilders!.add(declaration);
    }
    return members[name] = declaration;
  }

  bool isDuplicatedDeclaration(Builder? existing, Builder other) {
    if (existing == null) return false;
    Builder? next = existing.next;
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

  /// Checks [scope] for conflicts between setters and non-setters and reports
  /// them in [sourceLibraryBuilder].
  ///
  /// If [checkForInstanceVsStaticConflict] is `true`, conflicts between
  /// instance and static members of the same name are reported.
  ///
  /// If [checkForMethodVsSetterConflict] is `true`, conflicts between
  /// methods and setters of the same name are reported.
  static void checkMemberConflicts(
      SourceLibraryBuilder sourceLibraryBuilder, Scope scope,
      {required bool checkForInstanceVsStaticConflict,
      required bool checkForMethodVsSetterConflict}) {
    // ignore: unnecessary_null_comparison
    assert(checkForInstanceVsStaticConflict != null);
    // ignore: unnecessary_null_comparison
    assert(checkForMethodVsSetterConflict != null);

    scope.forEachLocalSetter((String name, MemberBuilder setter) {
      Builder? getable = scope.lookupLocalMember(name, setter: false);
      if (getable == null) {
        // Setter without getter.
        return;
      }

      bool isConflictingSetter = false;
      Set<Builder> conflictingGetables = {};
      for (Builder? currentGetable = getable;
          currentGetable != null;
          currentGetable = currentGetable.next) {
        if (currentGetable is FieldBuilder) {
          if (currentGetable.isAssignable) {
            // Setter with writable field.
            isConflictingSetter = true;
            conflictingGetables.add(currentGetable);
          }
        } else if (checkForMethodVsSetterConflict && !currentGetable.isGetter) {
          // Setter with method.
          conflictingGetables.add(currentGetable);
        }
      }
      for (SourceMemberBuilderImpl? currentSetter =
              setter as SourceMemberBuilderImpl?;
          currentSetter != null;
          currentSetter = currentSetter.next as SourceMemberBuilderImpl?) {
        bool conflict = conflictingGetables.isNotEmpty;
        for (Builder? currentGetable = getable;
            currentGetable != null;
            currentGetable = currentGetable.next) {
          if (checkForInstanceVsStaticConflict &&
              currentGetable.isDeclarationInstanceMember !=
                  currentSetter.isDeclarationInstanceMember) {
            conflict = true;
            conflictingGetables.add(currentGetable);
          }
        }
        if (isConflictingSetter) {
          currentSetter.isConflictingSetter = true;
        }
        if (conflict) {
          if (currentSetter.isConflictingSetter) {
            sourceLibraryBuilder.addProblem(
                templateConflictsWithImplicitSetter.withArguments(name),
                currentSetter.charOffset,
                noLength,
                currentSetter.fileUri);
          } else {
            sourceLibraryBuilder.addProblem(
                templateConflictsWithMember.withArguments(name),
                currentSetter.charOffset,
                noLength,
                currentSetter.fileUri);
          }
        }
      }
      for (Builder conflictingGetable in conflictingGetables) {
        // TODO(ahe): Context argument to previous message?
        sourceLibraryBuilder.addProblem(
            templateConflictsWithSetter.withArguments(name),
            conflictingGetable.charOffset,
            noLength,
            conflictingGetable.fileUri!);
      }
    });
  }

  /// Builds the core AST structure of this library as needed for the outline.
  Library buildOutlineNodes(LibraryBuilder coreLibrary,
      {bool modifyTarget = true}) {
    // TODO(johnniwinther): Avoid the need to process patch libraries before
    // the origin. Currently, settings performed by the patch are overridden
    // by the origin. For instance, the `Map` class is abstract in the origin
    // but (unintentionally) concrete in the patch. By processing the origin
    // last the `isAbstract` property set by the patch is corrected by the
    // origin.
    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        patchLibrary.buildOutlineNodes(coreLibrary, modifyTarget: modifyTarget);
      }
    }

    checkMemberConflicts(this, scope,
        checkForInstanceVsStaticConflict: false,
        checkForMethodVsSetterConflict: true);

    Iterator<Builder> iterator = localMembersIterator;
    while (iterator.moveNext()) {
      _buildOutlineNodes(iterator.current, coreLibrary);
    }

    if (!modifyTarget) return library;

    library.isSynthetic = isSynthetic;
    library.isUnsupported = isUnsupported;
    addDependencies(library, new Set<SourceLibraryBuilder>());

    library.name = name;
    library.procedures.sort(compareProcedures);

    if (unserializableExports != null) {
      Name fieldName = new Name(unserializableExportName, library);
      Reference? fieldReference =
          referencesFromIndexed?.lookupFieldReference(fieldName);
      Reference? getterReference =
          referencesFromIndexed?.lookupGetterReference(fieldName);
      library.addField(new Field.immutable(fieldName,
          initializer: new StringLiteral(jsonEncode(unserializableExports)),
          isStatic: true,
          isConst: true,
          fieldReference: fieldReference,
          getterReference: getterReference,
          fileUri: library.fileUri));
    }

    return library;
  }

  void validatePart(SourceLibraryBuilder? library, Set<Uri>? usedParts) {
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
      for (LibraryBuilder part in parts) {
        // Mark this part as used so we don't report it as orphaned.
        usedParts!.add(part.importUri);
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
        if (library != null) {
          // Recovery: Export the main library instead.
          export.exported = library;
          SourceLibraryBuilder exporter =
              export.exporter as SourceLibraryBuilder;
          for (Export export2 in exporter.exports) {
            if (export2.exported == this) {
              export2.exported = library;
            }
          }
        }
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
                    part.partOfLibrary!.fileUri, -1, noLength),
                messagePartOfTwoLibrariesContext.withLocation(
                    this.fileUri, -1, noLength)
              ]);
        } else {
          usedParts.add(part.importUri);
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
        if (uriIsValid(part.partOfUri!) && part.partOfUri != importUri) {
          // This is an error, but the part is not removed from the list of
          // parts, so that metadata annotations can be associated with it.
          addProblem(
              templatePartOfUriMismatch.withArguments(
                  part.fileUri, importUri, part.partOfUri!),
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
                    part.fileUri, name!, part.partOfName!),
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
                  part.fileUri, fileUri, part.partOfName!),
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
              languageVersion.fileUri!,
              languageVersion.charOffset,
              languageVersion.charCount));
        }
        if (part.languageVersion.isExplicit) {
          context.add(messageLanguageVersionPartContext.withLocation(
              part.languageVersion.fileUri!,
              part.languageVersion.charOffset,
              part.languageVersion.charCount));
        }
        addProblem(
            messageLanguageVersionMismatchInPart, partOffset, noLength, fileUri,
            context: context);
      }

      part.validatePart(this, usedParts);
      NameIterator partDeclarations = part.localMembersNameIterator;
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
      unresolvedNamedTypes.addAll(part.unresolvedNamedTypes);
      constructorReferences.addAll(part.constructorReferences);
      part.libraryName.reference = libraryName.reference;
      part.partOfLibrary = this;
      part.scope.becomePartOf(scope);
      // TODO(ahe): Include metadata from part?

      // Recovery: Take on all exporters (i.e. if a library has erroneously
      // exported the part it has (in validatePart) been recovered to import the
      // main library (this) instead --- to make it complete (and set up scopes
      // correctly) the exporters in this has to be updated too).
      exporters.addAll(part.exporters);

      nativeMethods.addAll(part.nativeMethods);
      unboundTypeVariables.addAll(part.unboundTypeVariables);
      // Check that the targets are different. This is not normally a problem
      // but is for patch files.
      if (library != part.library && part.library.problemsAsJson != null) {
        (library.problemsAsJson ??= <String>[])
            .addAll(part.library.problemsAsJson!);
      }
      part.collectInferableTypes(_inferableTypes!);
      part.takeMixinApplications(_mixinApplications!);
      if (library != part.library) {
        // Mark the part library as synthetic as it's not an actual library
        // (anymore).
        part.library.isSynthetic = true;
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
    NameIterator iterator = scope.filteredNameIterator(
        includeDuplicates: false, includeAugmentations: false);
    while (iterator.moveNext()) {
      addToExportScope(iterator.name, iterator.current);
    }
  }

  void addImportsToScope() {
    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        patchLibrary.addImportsToScope();
      }
    }

    bool explicitCoreImport = this == loader.coreLibrary;
    for (Import import in imports) {
      if (import.imported?.isPart ?? false) {
        addProblem(
            templatePartOfInLibrary.withArguments(import.imported!.fileUri),
            import.charOffset,
            noLength,
            fileUri);
        if (import.imported?.partOfLibrary != null) {
          // Recovery: Rewrite to import the "part owner" library.
          // Note that the part will not have a partOfLibrary if it claims to be
          // a part, but isn't mentioned as a part by the (would-be) "parent".
          import.imported = import.imported?.partOfLibrary;
        }
      }
      if (import.imported == loader.coreLibrary) {
        explicitCoreImport = true;
      }
      import.finalizeImports(this);
    }
    if (!explicitCoreImport) {
      NameIterator<Builder> iterator = loader.coreLibrary.exportScope
          .filteredNameIterator(
              includeDuplicates: false, includeAugmentations: false);
      while (iterator.moveNext()) {
        addToScope(iterator.name, iterator.current, -1, true);
      }
    }

    NameIterator<Builder> iterator = exportScope.filteredNameIterator(
        includeDuplicates: false, includeAugmentations: false);
    while (iterator.moveNext()) {
      String name = iterator.name;
      Builder builder = iterator.current;
      if (builder.parent?.origin != origin) {
        if (builder is DynamicTypeDeclarationBuilder) {
          assert(name == 'dynamic',
              "Unexpected export name for 'dynamic': '$name'");
          (unserializableExports ??= {})[name] = exportDynamicSentinel;
        } else if (builder is NeverTypeDeclarationBuilder) {
          assert(
              name == 'Never', "Unexpected export name for 'Never': '$name'");
          (unserializableExports ??= {})[name] = exportNeverSentinel;
        } else {
          if (builder is InvalidTypeDeclarationBuilder) {
            (unserializableExports ??= {})[name] =
                builder.message.problemMessage;
          } else {
            if (builder is ClassBuilder) {
              library.additionalExports.add(builder.cls.reference);
            } else if (builder is InlineClassBuilder) {
              library.additionalExports.add(builder.inlineClass.reference);
            } else if (builder is TypeAliasBuilder) {
              library.additionalExports.add(builder.typedef.reference);
            } else if (builder is ExtensionBuilder) {
              library.additionalExports.add(builder.extension.reference);
            } else if (builder is MemberBuilder) {
              for (Member exportedMember in builder.exportedMembers) {
                if (exportedMember is Field) {
                  // For fields add both getter and setter references
                  // so replacing a field with a getter/setter pair still
                  // exports correctly.
                  library.additionalExports.add(exportedMember.getterReference);
                  if (exportedMember.hasSetter) {
                    library.additionalExports
                        .add(exportedMember.setterReference!);
                  }
                } else {
                  library.additionalExports.add(exportedMember.reference);
                }
              }
            } else {
              unhandled(
                  'member', 'exportScope', builder.charOffset, builder.fileUri);
            }
          }
        }
      }
    }
  }

  @override
  void addToScope(String name, Builder member, int charOffset, bool isImport) {
    Builder? existing =
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
      importScope.addExtension(member as ExtensionBuilder);
    }
  }

  /// Resolves all unresolved types in [unresolvedNamedTypes]. The list of types
  /// is cleared when done.
  int resolveTypes() {
    int typeCount = 0;

    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        typeCount += patchLibrary.resolveTypes();
      }
    }

    typeCount += unresolvedNamedTypes.length;
    for (NamedTypeBuilder namedType in unresolvedNamedTypes) {
      namedType.resolveIn(
          scope, namedType.charOffset!, namedType.fileUri!, this);
    }
    unresolvedNamedTypes.clear();
    return typeCount;
  }

  void installDefaultSupertypes(
      ClassBuilder objectClassBuilder, Class objectClass) {
    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        patchLibrary.installDefaultSupertypes(objectClassBuilder, objectClass);
      }
    }

    Iterator<SourceClassBuilder> iterator = localMembersIteratorOfType();
    while (iterator.moveNext()) {
      SourceClassBuilder declaration = iterator.current;
      Class cls = declaration.cls;
      if (cls != objectClass) {
        cls.supertype ??= objectClass.asRawSupertype;
        declaration.supertypeBuilder ??=
            new NamedTypeBuilder.fromTypeDeclarationBuilder(
                objectClassBuilder, const NullabilityBuilder.omitted(),
                instanceTypeVariableAccess:
                    InstanceTypeVariableAccessState.Unexpected);
      }
      if (declaration.isMixinApplication) {
        cls.mixedInType =
            declaration.mixedInTypeBuilder!.buildMixedInType(this);
      }
    }
  }

  void collectSourceClasses(List<SourceClassBuilder> sourceClasses,
      List<SourceInlineClassBuilder>? inlineClasses) {
    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        patchLibrary.collectSourceClasses(sourceClasses, inlineClasses);
      }
    }

    Iterator<Builder> iterator = localMembersIterator;
    while (iterator.moveNext()) {
      Builder member = iterator.current;
      if (member is SourceClassBuilder && !member.isPatch) {
        sourceClasses.add(member);
      } else if (inlineClasses != null &&
          member is SourceInlineClassBuilder &&
          !member.isPatch) {
        inlineClasses.add(member);
      }
    }
  }

  /// Resolve constructors (lookup names in scope) recorded in this builder and
  /// return the number of constructors resolved.
  int resolveConstructors() {
    int count = 0;

    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        count += patchLibrary.resolveConstructors();
      }
    }

    Iterator<SourceClassBuilder> iterator = localMembersIteratorOfType();
    while (iterator.moveNext()) {
      SourceClassBuilder builder = iterator.current;
      count += builder.resolveConstructors(this);
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
  void recordAccess(
      LibraryBuilder accessor, int charOffset, int length, Uri fileUri) {
    accessors.add(new LibraryAccess(accessor, fileUri, charOffset, length));
    if (accessProblem != null) {
      addProblem(accessProblem!, charOffset, length, fileUri);
    }
  }

  /// Reports [message] on all libraries that access this library.
  void addProblemAtAccessors(Message message) {
    if (accessProblem == null) {
      if (accessors.isEmpty && loader.roots.contains(this.importUri)) {
        // This is the entry point library, and nobody access it directly. So
        // we need to report a problem.
        loader.addProblem(message, -1, 1, null);
      }
      for (int i = 0; i < accessors.length; i++) {
        LibraryAccess access = accessors[i];
        access.accessor.addProblem(
            message, access.charOffset, access.length, access.fileUri);
      }
      accessProblem = message;
    }
  }

  @override
  bool get isPatch => _immediateOrigin != null;

  @override
  SourceLibraryBuilder get origin {
    SourceLibraryBuilder? origin = _immediateOrigin;
    // TODO(johnniwinther): This returns the wrong origin for early queries on
    // augmentations imported into parts.
    if (origin != null && origin.partOfLibrary is SourceLibraryBuilder) {
      origin = origin.partOfLibrary as SourceLibraryBuilder;
    }
    return origin?.origin ?? this;
  }

  @override
  final Uri importUri;

  @override
  void addSyntheticDeclarationOfDynamic() {
    addBuilder("dynamic",
        new DynamicTypeDeclarationBuilder(const DynamicType(), this, -1), -1);
  }

  @override
  void addSyntheticDeclarationOfNever() {
    addBuilder(
        "Never",
        new NeverTypeDeclarationBuilder(
            const NeverType.nonNullable(), this, -1),
        -1);
  }

  @override
  void addSyntheticDeclarationOfNull() {
    // TODO(cstefantsova): Uncomment the following when the Null class is
    // removed from the SDK.
    //addBuilder("Null", new NullTypeBuilder(const NullType(), this, -1), -1);
  }

  List<InferableType>? _inferableTypes = [];

  InferableTypeBuilder addInferableType() {
    InferableTypeBuilder typeBuilder = new InferableTypeBuilder();
    registerInferableType(typeBuilder);
    return typeBuilder;
  }

  void registerInferableType(InferableType inferableType) {
    assert(_inferableTypes != null,
        "Late registration of inferable type $inferableType.");
    _inferableTypes?.add(inferableType);
  }

  void collectInferableTypes(List<InferableType> inferableTypes) {
    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        patchLibrary.collectInferableTypes(inferableTypes);
      }
    }
    if (_inferableTypes != null) {
      inferableTypes.addAll(_inferableTypes!);
    }
    _inferableTypes = null;
  }

  TypeBuilder addNamedType(Object name, NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder>? arguments, int charOffset,
      {required InstanceTypeVariableAccessState instanceTypeVariableAccess}) {
    if (_omittedTypeDeclarationBuilders != null) {
      Builder? builder = _omittedTypeDeclarationBuilders![name];
      if (builder is OmittedTypeDeclarationBuilder) {
        return new DependentTypeBuilder(builder.omittedTypeBuilder);
      }
    }
    return registerUnresolvedNamedType(new NamedTypeBuilder(
        name, nullabilityBuilder,
        arguments: arguments,
        fileUri: fileUri,
        charOffset: charOffset,
        instanceTypeVariableAccess: instanceTypeVariableAccess));
  }

  MixinApplicationBuilder addMixinApplication(
      List<TypeBuilder> mixins, int charOffset) {
    return new MixinApplicationBuilder(mixins, fileUri, charOffset);
  }

  TypeBuilder addVoidType(int charOffset) {
    // 'void' is always nullable.
    return new NamedTypeBuilder.fromTypeDeclarationBuilder(
        new VoidTypeDeclarationBuilder(const VoidType(), this, charOffset),
        const NullabilityBuilder.inherent(),
        charOffset: charOffset,
        fileUri: fileUri,
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);
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
      postponedProblems!
          .add(new PostponedProblem(message, charOffset, length, fileUri));
    }
  }

  void issuePostponedProblems() {
    postponedProblemsIssued = true;
    if (postponedProblems == null) return;
    for (int i = 0; i < postponedProblems!.length; ++i) {
      PostponedProblem postponedProblem = postponedProblems![i];
      addProblem(postponedProblem.message, postponedProblem.charOffset,
          postponedProblem.length, postponedProblem.fileUri);
    }
    postponedProblems = null;
  }

  @override
  FormattedMessage? addProblem(
      Message message, int charOffset, int length, Uri? fileUri,
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      Severity? severity,
      bool problemOnLibrary = false}) {
    FormattedMessage? formattedMessage = super.addProblem(
        message, charOffset, length, fileUri,
        wasHandled: wasHandled,
        context: context,
        severity: severity,
        problemOnLibrary: true);
    if (formattedMessage != null) {
      library.problemsAsJson ??= <String>[];
      library.problemsAsJson!.add(formattedMessage.toJsonString());
    }
    return formattedMessage;
  }

  void addClass(
      List<MetadataBuilder>? metadata,
      int modifiers,
      String className,
      List<TypeVariableBuilder>? typeVariables,
      TypeBuilder? supertype,
      MixinApplicationBuilder? mixins,
      List<TypeBuilder>? interfaces,
      int startOffset,
      int nameOffset,
      int endOffset,
      int supertypeOffset,
      {required bool isMacro,
      required bool isSealed,
      required bool isBase,
      required bool isInterface,
      required bool isFinal,
      required bool isAugmentation,
      required bool isMixinClass}) {
    _addClass(
        TypeParameterScopeKind.classDeclaration,
        metadata,
        modifiers,
        className,
        typeVariables,
        supertype,
        mixins,
        interfaces,
        startOffset,
        nameOffset,
        endOffset,
        supertypeOffset,
        isMacro: isMacro,
        isSealed: isSealed,
        isBase: isBase,
        isInterface: isInterface,
        isFinal: isFinal,
        isAugmentation: isAugmentation,
        isMixinClass: isMixinClass);
  }

  void addMixinDeclaration(
      List<MetadataBuilder>? metadata,
      int modifiers,
      String className,
      List<TypeVariableBuilder>? typeVariables,
      List<TypeBuilder>? supertypeConstraints,
      List<TypeBuilder>? interfaces,
      int startOffset,
      int nameOffset,
      int endOffset,
      int supertypeOffset,
      {required bool isBase,
      required bool isAugmentation}) {
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
    _addClass(
        TypeParameterScopeKind.mixinDeclaration,
        metadata,
        modifiers,
        className,
        typeVariables,
        supertype,
        mixinApplication,
        interfaces,
        startOffset,
        nameOffset,
        endOffset,
        supertypeOffset,
        isMacro: false,
        isSealed: false,
        isBase: isBase,
        isInterface: false,
        isFinal: false,
        isAugmentation: isAugmentation,
        isMixinClass: false);
  }

  void _addClass(
      TypeParameterScopeKind kind,
      List<MetadataBuilder>? metadata,
      int modifiers,
      String className,
      List<TypeVariableBuilder>? typeVariables,
      TypeBuilder? supertype,
      MixinApplicationBuilder? mixins,
      List<TypeBuilder>? interfaces,
      int startOffset,
      int nameOffset,
      int endOffset,
      int supertypeOffset,
      {required bool isMacro,
      required bool isSealed,
      required bool isBase,
      required bool isInterface,
      required bool isFinal,
      required bool isAugmentation,
      required bool isMixinClass}) {
    // Nested declaration began in `OutlineBuilder.beginClassDeclaration`.
    TypeParameterScopeBuilder declaration =
        endNestedDeclaration(kind, className)
          ..resolveNamedTypes(typeVariables, this);
    assert(declaration.parent == _libraryTypeParameterScopeBuilder);
    Map<String, Builder> members = declaration.members!;
    Map<String, MemberBuilder> constructors = declaration.constructors!;
    Map<String, MemberBuilder> setters = declaration.setters!;

    Scope classScope = new Scope(
        kind: ScopeKind.declaration,
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
    SourceClassBuilder classBuilder = new SourceClassBuilder(
        metadata,
        modifiers,
        className,
        typeVariables,
        _applyMixins(supertype, mixins, startOffset, nameOffset, endOffset,
            className, isMixinDeclaration,
            typeVariables: typeVariables,
            isMacro: false,
            isSealed: false,
            isBase: false,
            isInterface: false,
            isFinal: false,
            // TODO(johnniwinther): How can we support class with mixins?
            isAugmentation: false,
            isMixinClass: false),
        interfaces,
        // TODO(johnniwinther): Add the `on` clause types of a mixin declaration
        // here.
        null,
        classScope,
        constructorScope,
        this,
        new List<ConstructorReferenceBuilder>.of(constructorReferences),
        startOffset,
        nameOffset,
        endOffset,
        _currentClassReferencesFromIndexed,
        isMixinDeclaration: isMixinDeclaration,
        isMacro: isMacro,
        isSealed: isSealed,
        isBase: isBase,
        isInterface: isInterface,
        isFinal: isFinal,
        isAugmentation: isAugmentation,
        isMixinClass: isMixinClass);

    constructorReferences.clear();
    Map<String, TypeVariableBuilder>? typeVariablesByName =
        checkTypeVariables(typeVariables, classBuilder);
    void setParent(MemberBuilder? member) {
      while (member != null) {
        member.parent = classBuilder;
        member = member.next as MemberBuilder?;
      }
    }

    void setParentAndCheckConflicts(String name, Builder member) {
      if (typeVariablesByName != null) {
        TypeVariableBuilder? tv = typeVariablesByName[name];
        if (tv != null) {
          classBuilder.addProblem(
              templateConflictsWithTypeVariable.withArguments(name),
              member.charOffset,
              name.length,
              context: [
                messageConflictsWithTypeVariableCause.withLocation(
                    tv.fileUri!, tv.charOffset, name.length)
              ]);
        }
      }
      setParent(member as MemberBuilder);
    }

    members.forEach(setParentAndCheckConflicts);
    constructors.forEach(setParentAndCheckConflicts);
    setters.forEach(setParentAndCheckConflicts);
    addBuilder(className, classBuilder, nameOffset,
        getterReference: _currentClassReferencesFromIndexed?.cls.reference);
  }

  Map<String, TypeVariableBuilder>? checkTypeVariables(
      List<TypeVariableBuilder>? typeVariables, Builder? owner) {
    if (typeVariables == null || typeVariables.isEmpty) return null;
    Map<String, TypeVariableBuilder> typeVariablesByName =
        <String, TypeVariableBuilder>{};
    for (TypeVariableBuilder tv in typeVariables) {
      TypeVariableBuilder? existing = typeVariablesByName[tv.name];
      if (existing != null) {
        if (existing.kind == TypeVariableKind.extensionSynthesized) {
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
    List<TypeParameter>? getterExtensionTypeParameters;
    if (getterBuilder.isExtensionInstanceMember ||
        setterBuilder.isInlineClassInstanceMember) {
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
      // Similarly for inline class instance getters.
      //
      Procedure procedure = getterBuilder.procedure;
      getterType = procedure.function.returnType;
      getterExtensionTypeParameters = procedure.function.typeParameters;
    } else {
      getterType = getterBuilder.procedure.getterType;
    }
    DartType setterType;
    if (setterBuilder.isExtensionInstanceMember ||
        setterBuilder.isInlineClassInstanceMember) {
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
      // Similarly for inline class instance setters.
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
                        getterExtensionTypeParameters![index])))
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
                  .withLocation(setterBuilder.fileUri!,
                      setterBuilder.charOffset, setterBuilder.name.length)
            ]);
      }
    }
  }

  void addExtensionDeclaration(
      List<MetadataBuilder>? metadata,
      int modifiers,
      String? name,
      List<TypeVariableBuilder>? typeVariables,
      TypeBuilder type,
      ExtensionTypeShowHideClauseBuilder extensionTypeShowHideClauseBuilder,
      bool isExtensionTypeDeclaration,
      int startOffset,
      int nameOffset,
      int endOffset) {
    // Nested declaration began in `OutlineBuilder.beginExtensionDeclaration`.
    TypeParameterScopeBuilder declaration =
        endNestedDeclaration(TypeParameterScopeKind.extensionDeclaration, name)
          ..resolveNamedTypes(typeVariables, this);
    assert(declaration.parent == _libraryTypeParameterScopeBuilder);
    Map<String, Builder> members = declaration.members!;
    Map<String, MemberBuilder> constructors = declaration.constructors!;
    Map<String, MemberBuilder> setters = declaration.setters!;

    Scope classScope = new Scope(
        kind: ScopeKind.declaration,
        local: members,
        setters: setters,
        parent: scope.withTypeVariables(typeVariables),
        debugName: "extension $name",
        isModifiable: false);

    Extension? referenceFrom;
    ExtensionName extensionName = declaration.extensionName!;
    if (name != null) {
      referenceFrom = referencesFromIndexed?.lookupExtension(name);
    }

    ExtensionBuilder extensionBuilder = new SourceExtensionBuilder(
        metadata,
        modifiers,
        extensionName,
        typeVariables,
        type,
        extensionTypeShowHideClauseBuilder,
        classScope,
        this,
        isExtensionTypeDeclaration,
        startOffset,
        nameOffset,
        endOffset,
        referenceFrom);
    constructorReferences.clear();
    Map<String, TypeVariableBuilder>? typeVariablesByName =
        checkTypeVariables(typeVariables, extensionBuilder);
    void setParent(MemberBuilder? member) {
      while (member != null) {
        member.parent = extensionBuilder;
        member = member.next as MemberBuilder?;
      }
    }

    void setParentAndCheckConflicts(String name, Builder member) {
      if (typeVariablesByName != null) {
        TypeVariableBuilder? tv = typeVariablesByName[name];
        if (tv != null) {
          extensionBuilder.addProblem(
              templateConflictsWithTypeVariable.withArguments(name),
              member.charOffset,
              name.length,
              context: [
                messageConflictsWithTypeVariableCause.withLocation(
                    tv.fileUri!, tv.charOffset, name.length)
              ]);
        }
      }
      setParent(member as MemberBuilder);
    }

    members.forEach(setParentAndCheckConflicts);
    constructors.forEach(setParentAndCheckConflicts);
    setters.forEach(setParentAndCheckConflicts);
    addBuilder(extensionBuilder.name, extensionBuilder, nameOffset,
        getterReference: referenceFrom?.reference);
  }

  void addInlineClassDeclaration(
      List<MetadataBuilder>? metadata,
      int modifiers,
      String name,
      List<TypeVariableBuilder>? typeVariables,
      List<TypeBuilder>? interfaces,
      int startOffset,
      int nameOffset,
      int endOffset) {
    // Nested declaration began in `OutlineBuilder.beginExtensionDeclaration`.
    TypeParameterScopeBuilder declaration = endNestedDeclaration(
        TypeParameterScopeKind.inlineClassDeclaration, name)
      ..resolveNamedTypes(typeVariables, this);
    assert(declaration.parent == _libraryTypeParameterScopeBuilder);
    Map<String, Builder> members = declaration.members!;
    Map<String, MemberBuilder> constructors = declaration.constructors!;
    Map<String, MemberBuilder> setters = declaration.setters!;

    Scope memberScope = new Scope(
        kind: ScopeKind.declaration,
        local: members,
        setters: setters,
        parent: scope.withTypeVariables(typeVariables),
        debugName: "inline class $name",
        isModifiable: false);
    ConstructorScope constructorScope =
        new ConstructorScope(name, constructors);

    InlineClass? referenceFrom = referencesFromIndexed?.lookupInlineClass(name);

    SourceFieldBuilder? representationFieldBuilder;
    outer:
    for (Builder? member in members.values) {
      while (member != null) {
        if (!member.isDuplicate &&
            member is SourceFieldBuilder &&
            !member.isStatic) {
          representationFieldBuilder = member;
          break outer;
        }
        member = member.next;
      }
    }

    InlineClassBuilder inlineClassBuilder = new SourceInlineClassBuilder(
        metadata,
        modifiers,
        declaration.name,
        typeVariables,
        interfaces,
        memberScope,
        constructorScope,
        this,
        startOffset,
        nameOffset,
        endOffset,
        referenceFrom,
        representationFieldBuilder);
    constructorReferences.clear();
    Map<String, TypeVariableBuilder>? typeVariablesByName =
        checkTypeVariables(typeVariables, inlineClassBuilder);
    void setParent(MemberBuilder? member) {
      while (member != null) {
        member.parent = inlineClassBuilder;
        member = member.next as MemberBuilder?;
      }
    }

    void setParentAndCheckConflicts(String name, Builder member) {
      if (typeVariablesByName != null) {
        TypeVariableBuilder? tv = typeVariablesByName[name];
        if (tv != null) {
          inlineClassBuilder.addProblem(
              templateConflictsWithTypeVariable.withArguments(name),
              member.charOffset,
              name.length,
              context: [
                messageConflictsWithTypeVariableCause.withLocation(
                    tv.fileUri!, tv.charOffset, name.length)
              ]);
        }
      }
      setParent(member as MemberBuilder);
    }

    members.forEach(setParentAndCheckConflicts);
    constructors.forEach(setParentAndCheckConflicts);
    setters.forEach(setParentAndCheckConflicts);
    addBuilder(inlineClassBuilder.name, inlineClassBuilder, nameOffset,
        getterReference: referenceFrom?.reference);
  }

  TypeBuilder? _applyMixins(
      TypeBuilder? supertype,
      MixinApplicationBuilder? mixinApplications,
      int startCharOffset,
      int charOffset,
      int charEndOffset,
      String subclassName,
      bool isMixinDeclaration,
      {List<MetadataBuilder>? metadata,
      String? name,
      List<TypeVariableBuilder>? typeVariables,
      int modifiers = 0,
      List<TypeBuilder>? interfaces,
      required bool isMacro,
      required bool isSealed,
      required bool isBase,
      required bool isInterface,
      required bool isFinal,
      required bool isAugmentation,
      required bool isMixinClass}) {
    if (name == null) {
      // The following parameters should only be used when building a named
      // mixin application.
      if (metadata != null) {
        unhandled("metadata", "unnamed mixin application", charOffset, fileUri);
      } else if (interfaces != null) {
        unhandled(
            "interfaces", "unnamed mixin application", charOffset, fileUri);
      }
    }
    if (mixinApplications != null) {
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
      supertype ??= loader.target.objectType;

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
      Object nameSourceForExtraction;
      if (supertype.name == null) {
        assert(supertype is FunctionTypeBuilder);

        // Function types don't have names, and we can supply any string that
        // doesn't have to be unique. The actual supertype of the mixin will
        // not be built in that case.
        nameSourceForExtraction = "";
      } else {
        nameSourceForExtraction = supertype.name!;
      }
      String runningName = extractName(nameSourceForExtraction);

      /// True when we're building a named mixin application. Notice that for
      /// the `Named` example above, this is only true on the last
      /// iteration because only the full mixin application is named.
      bool isNamedMixinApplication;

      /// The names of the type variables of the subclass.
      Set<String>? typeVariableNames;
      if (typeVariables != null) {
        typeVariableNames = new Set<String>();
        for (TypeVariableBuilder typeVariable in typeVariables) {
          typeVariableNames.add(typeVariable.name);
        }
      }

      /// Helper function that returns `true` if a type variable with a name
      /// from [typeVariableNames] is referenced in [type].
      bool usesTypeVariables(TypeBuilder? type) {
        if (type is NamedTypeBuilder) {
          if (type.declaration is TypeVariableBuilder) {
            return typeVariableNames!.contains(type.declaration!.name);
          }

          List<TypeBuilder>? typeArguments = type.arguments;
          if (typeArguments != null && typeVariables != null) {
            for (TypeBuilder argument in typeArguments) {
              if (usesTypeVariables(argument)) {
                return true;
              }
            }
          }
        } else if (type is FunctionTypeBuilder) {
          if (type.formals != null) {
            for (ParameterBuilder formal in type.formals!) {
              if (usesTypeVariables(formal.type)) {
                return true;
              }
            }
          }
          List<TypeVariableBuilder>? typeVariables = type.typeVariables;
          if (typeVariables != null) {
            for (TypeVariableBuilder variable in typeVariables) {
              if (usesTypeVariables(variable.bound)) {
                return true;
              }
            }
          }
          return usesTypeVariables(type.returnType);
        } else if (type is RecordTypeBuilder) {
          if (type.positionalFields != null) {
            for (RecordTypeFieldBuilder fieldBuilder
                in type.positionalFields!) {
              if (usesTypeVariables(fieldBuilder.type)) {
                return true;
              }
            }
          }
          if (type.namedFields != null) {
            for (RecordTypeFieldBuilder fieldBuilder in type.namedFields!) {
              if (usesTypeVariables(fieldBuilder.type)) {
                return true;
              }
            }
          }
        } else if (type is DependentTypeBuilder) {
          return false;
        } else if (type is FixedTypeBuilder) {
          return false;
        } else if (type is ImplicitTypeBuilder) {
          return false;
        } else if (type is InferableTypeBuilder) {
          return false;
        } else if (type is InvalidTypeBuilder) {
          return false;
        } else if (type is OmittedTypeBuilder) {
          return false;
        } else if (type == null) {
          return false;
        } else {
          return unhandled(
              "${type.runtimeType}",
              "SourceLibraryBuilder._applyMixins.usesTypeVariables",
              type.charOffset ?? TreeNode.noOffset,
              type.fileUri ?? fileUri);
        }
        return false;
      }

      /// Iterate over the mixins from left to right. At the end of each
      /// iteration, a new [supertype] is computed that is the mixin
      /// application of [supertype] with the current mixin.
      for (int i = 0; i < mixinApplications.mixins.length; i++) {
        TypeBuilder mixin = mixinApplications.mixins[i];
        isNamedMixinApplication =
            name != null && mixin == mixinApplications.mixins.last;
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
        List<TypeVariableBuilder>? applicationTypeVariables;
        List<TypeBuilder>? applicationTypeArguments;
        if (isNamedMixinApplication) {
          // If this is a named mixin application, it must be given all the
          // declared type variables.
          applicationTypeVariables = typeVariables;
        } else {
          // Otherwise, we pass the fresh type variables to the mixin
          // application in the same order as they're declared on the subclass.
          if (isGeneric) {
            this.beginNestedDeclaration(
                TypeParameterScopeKind.unnamedMixinApplication,
                "mixin application");

            applicationTypeVariables = copyTypeVariables(
                typeVariables!, currentTypeParameterScopeBuilder,
                kind: TypeVariableKind.extensionSynthesized);

            List<NamedTypeBuilder> newTypes = <NamedTypeBuilder>[];
            if (supertype is NamedTypeBuilder && supertype.arguments != null) {
              for (int i = 0; i < supertype.arguments!.length; ++i) {
                supertype.arguments![i] = supertype.arguments![i]
                    .clone(newTypes, this, currentTypeParameterScopeBuilder);
              }
            }
            if (mixin is NamedTypeBuilder && mixin.arguments != null) {
              for (int i = 0; i < mixin.arguments!.length; ++i) {
                mixin.arguments![i] = mixin.arguments![i]
                    .clone(newTypes, this, currentTypeParameterScopeBuilder);
              }
            }
            for (NamedTypeBuilder newType in newTypes) {
              currentTypeParameterScopeBuilder
                  .registerUnresolvedNamedType(newType);
            }

            TypeParameterScopeBuilder mixinDeclaration = this
                .endNestedDeclaration(
                    TypeParameterScopeKind.unnamedMixinApplication,
                    "mixin application");
            mixinDeclaration.resolveNamedTypes(applicationTypeVariables, this);

            applicationTypeArguments = <TypeBuilder>[];
            for (TypeVariableBuilder typeVariable in typeVariables) {
              applicationTypeArguments.add(
                  new NamedTypeBuilder.fromTypeDeclarationBuilder(
                      // The type variable types passed as arguments to the
                      // generic class representing the anonymous mixin
                      // application should refer back to the type variables of
                      // the class that extend the anonymous mixin application.
                      typeVariable,
                      const NullabilityBuilder.omitted(),
                      fileUri: fileUri,
                      charOffset: charOffset,
                      instanceTypeVariableAccess:
                          InstanceTypeVariableAccessState.Allowed));
            }
          }
        }
        final int computedStartCharOffset =
            !isNamedMixinApplication || metadata == null
                ? startCharOffset
                : metadata.first.charOffset;

        IndexedClass? referencesFromIndexedClass;
        if (referencesFromIndexed != null) {
          referencesFromIndexedClass =
              referencesFromIndexed!.lookupIndexedClass(fullname);
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
                    ? [supertype!, mixin]
                    : null,
            null,
            // No `on` clause types.
            new Scope(
                kind: ScopeKind.declaration,
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
            referencesFromIndexedClass,
            mixedInTypeBuilder: isMixinDeclaration ? null : mixin,
            isMacro: isNamedMixinApplication && isMacro,
            isSealed: isNamedMixinApplication && isSealed,
            isBase: isNamedMixinApplication && isBase,
            isInterface: isNamedMixinApplication && isInterface,
            isFinal: isNamedMixinApplication && isFinal,
            isAugmentation: isNamedMixinApplication && isAugmentation,
            isMixinClass: isNamedMixinApplication && isMixinClass);
        // TODO(ahe, kmillikin): Should always be true?
        // pkg/analyzer/test/src/summary/resynthesize_kernel_test.dart can't
        // handle that :(
        application.cls.isAnonymousMixin = !isNamedMixinApplication;
        addBuilder(fullname, application, charOffset,
            getterReference: referencesFromIndexedClass?.cls.reference);
        supertype = addNamedType(fullname, const NullabilityBuilder.omitted(),
            applicationTypeArguments, charOffset,
            instanceTypeVariableAccess:
                InstanceTypeVariableAccessState.Allowed);
        registerMixinApplication(application, mixin);
      }
      return supertype;
    } else {
      return supertype;
    }
  }

  Map<SourceClassBuilder, TypeBuilder>? _mixinApplications = {};

  /// Registers that [mixinApplication] is a mixin application introduced by
  /// the [mixedInType] in a with-clause.
  ///
  /// This is used to check that super access in mixin declarations have a
  /// concrete target.
  void registerMixinApplication(
      SourceClassBuilder mixinApplication, TypeBuilder mixedInType) {
    assert(
        _mixinApplications != null, "Late registration of mixin application.");
    _mixinApplications![mixinApplication] = mixedInType;
  }

  void takeMixinApplications(
      Map<SourceClassBuilder, TypeBuilder> mixinApplications) {
    assert(_mixinApplications != null,
        "Mixin applications have already been processed.");
    mixinApplications.addAll(_mixinApplications!);
    _mixinApplications = null;
    Iterable<SourceLibraryBuilder>? patchLibraries = this.patchLibraries;
    if (patchLibraries != null) {
      for (SourceLibraryBuilder patchLibrary in patchLibraries) {
        patchLibrary.takeMixinApplications(mixinApplications);
      }
    }
  }

  void addNamedMixinApplication(
      List<MetadataBuilder>? metadata,
      String name,
      List<TypeVariableBuilder>? typeVariables,
      int modifiers,
      TypeBuilder? supertype,
      MixinApplicationBuilder mixinApplication,
      List<TypeBuilder>? interfaces,
      int startCharOffset,
      int charOffset,
      int charEndOffset,
      {required bool isMacro,
      required bool isSealed,
      required bool isBase,
      required bool isInterface,
      required bool isFinal,
      required bool isAugmentation,
      required bool isMixinClass}) {
    // Nested declaration began in `OutlineBuilder.beginNamedMixinApplication`.
    endNestedDeclaration(TypeParameterScopeKind.namedMixinApplication, name)
        .resolveNamedTypes(typeVariables, this);
    supertype = _applyMixins(supertype, mixinApplication, startCharOffset,
        charOffset, charEndOffset, name, false,
        metadata: metadata,
        name: name,
        typeVariables: typeVariables,
        modifiers: modifiers,
        interfaces: interfaces,
        isMacro: isMacro,
        isSealed: isSealed,
        isBase: isBase,
        isInterface: isInterface,
        isFinal: isFinal,
        isAugmentation: isAugmentation,
        isMixinClass: isMixinClass)!;
    checkTypeVariables(typeVariables, supertype.declaration);
  }

  void addField(
      List<MetadataBuilder>? metadata,
      int modifiers,
      bool isTopLevel,
      TypeBuilder type,
      String name,
      int charOffset,
      int charEndOffset,
      Token? initializerToken,
      bool hasInitializer,
      {Token? constInitializerToken}) {
    if (hasInitializer) {
      modifiers |= hasInitializerMask;
    }
    bool isLate = (modifiers & lateMask) != 0;
    bool isFinal = (modifiers & finalMask) != 0;
    bool isStatic = (modifiers & staticMask) != 0;
    bool isExternal = (modifiers & externalMask) != 0;
    final bool fieldIsLateWithLowering = isLate &&
        (loader.target.backendTarget.isLateFieldLoweringEnabled(
                hasInitializer: hasInitializer,
                isFinal: isFinal,
                isStatic: isTopLevel || isStatic) ||
            (loader.target.backendTarget.useStaticFieldLowering &&
                (isStatic || isTopLevel)));

    final bool isInstanceMember = currentTypeParameterScopeBuilder.kind !=
            TypeParameterScopeKind.library &&
        (modifiers & staticMask) == 0;
    final bool isExtensionMember = currentTypeParameterScopeBuilder.kind ==
        TypeParameterScopeKind.extensionDeclaration;
    ContainerType containerType =
        currentTypeParameterScopeBuilder.containerType;
    ContainerName? containerName =
        currentTypeParameterScopeBuilder.containerName;

    Reference? fieldReference;
    Reference? fieldGetterReference;
    Reference? fieldSetterReference;
    Reference? lateIsSetFieldReference;
    Reference? lateIsSetGetterReference;
    Reference? lateIsSetSetterReference;
    Reference? lateGetterReference;
    Reference? lateSetterReference;

    NameScheme nameScheme = new NameScheme(
        isInstanceMember: isInstanceMember,
        containerName: containerName,
        containerType: containerType,
        libraryName: referencesFrom != null
            ? new LibraryName(referencesFrom!.reference)
            : libraryName);
    if (referencesFrom != null) {
      IndexedContainer indexedContainer =
          (_currentClassReferencesFromIndexed ?? referencesFromIndexed)!;
      if (isExtensionMember && isInstanceMember && isExternal) {
        /// An external extension instance field is special. It is treated
        /// as an external getter/setter pair and is therefore encoded as a pair
        /// of top level methods using the extension instance member naming
        /// convention.
        fieldGetterReference = indexedContainer.lookupGetterReference(
            nameScheme.getProcedureMemberName(ProcedureKind.Getter, name).name);
        fieldSetterReference = indexedContainer.lookupGetterReference(
            nameScheme.getProcedureMemberName(ProcedureKind.Setter, name).name);
      } else {
        Name nameToLookup = nameScheme
            .getFieldMemberName(FieldNameType.Field, name,
                isSynthesized: fieldIsLateWithLowering)
            .name;
        fieldReference = indexedContainer.lookupFieldReference(nameToLookup);
        fieldGetterReference =
            indexedContainer.lookupGetterReference(nameToLookup);
        fieldSetterReference =
            indexedContainer.lookupSetterReference(nameToLookup);
      }

      if (fieldIsLateWithLowering) {
        Name lateIsSetName = nameScheme
            .getFieldMemberName(FieldNameType.IsSetField, name,
                isSynthesized: fieldIsLateWithLowering)
            .name;
        lateIsSetFieldReference =
            indexedContainer.lookupFieldReference(lateIsSetName);
        lateIsSetGetterReference =
            indexedContainer.lookupGetterReference(lateIsSetName);
        lateIsSetSetterReference =
            indexedContainer.lookupSetterReference(lateIsSetName);
        lateGetterReference = indexedContainer.lookupGetterReference(nameScheme
            .getFieldMemberName(FieldNameType.Getter, name,
                isSynthesized: fieldIsLateWithLowering)
            .name);
        lateSetterReference = indexedContainer.lookupSetterReference(nameScheme
            .getFieldMemberName(FieldNameType.Setter, name,
                isSynthesized: fieldIsLateWithLowering)
            .name);
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
        nameScheme,
        fieldReference: fieldReference,
        fieldGetterReference: fieldGetterReference,
        fieldSetterReference: fieldSetterReference,
        lateIsSetFieldReference: lateIsSetFieldReference,
        lateIsSetGetterReference: lateIsSetGetterReference,
        lateIsSetSetterReference: lateIsSetSetterReference,
        lateGetterReference: lateGetterReference,
        lateSetterReference: lateSetterReference,
        initializerToken: initializerToken,
        constInitializerToken: constInitializerToken);
    addBuilder(name, fieldBuilder, charOffset,
        getterReference: fieldGetterReference,
        setterReference: fieldSetterReference);
  }

  void addConstructor(
      List<MetadataBuilder>? metadata,
      int modifiers,
      final Object? name,
      String constructorName,
      List<TypeVariableBuilder>? typeVariables,
      List<FormalParameterBuilder>? formals,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String? nativeMethodName,
      {Token? beginInitializers,
      required bool forAbstractClass}) {
    Reference? constructorReference;
    Reference? tearOffReference;
    if (_currentClassReferencesFromIndexed != null) {
      constructorReference = _currentClassReferencesFromIndexed!
          .lookupConstructorReference(new Name(
              constructorName, _currentClassReferencesFromIndexed!.library));
      tearOffReference = _currentClassReferencesFromIndexed!
          .lookupGetterReference(new Name(
              constructorTearOffName(constructorName),
              _currentClassReferencesFromIndexed!.library));
    }
    AbstractSourceConstructorBuilder constructorBuilder;

    ContainerType containerType =
        currentTypeParameterScopeBuilder.containerType;
    ContainerName? containerName =
        currentTypeParameterScopeBuilder.containerName;
    NameScheme nameScheme = new NameScheme(
        isInstanceMember: false,
        containerName: containerName,
        containerType: containerType,
        libraryName: referencesFrom != null
            ? new LibraryName(referencesFrom!.reference)
            : libraryName);
    if (currentTypeParameterScopeBuilder.kind ==
        TypeParameterScopeKind.inlineClassDeclaration) {
      constructorBuilder = new SourceInlineClassConstructorBuilder(
          metadata,
          modifiers & ~abstractMask,
          addInferableType(),
          constructorName,
          typeVariables,
          formals,
          this,
          startCharOffset,
          charOffset,
          charOpenParenOffset,
          charEndOffset,
          constructorReference,
          tearOffReference,
          nameScheme,
          nativeMethodName: nativeMethodName,
          forAbstractClassOrEnum: forAbstractClass);
    } else {
      constructorBuilder = new DeclaredSourceConstructorBuilder(
          metadata,
          modifiers & ~abstractMask,
          addInferableType(),
          constructorName,
          typeVariables,
          formals,
          this,
          startCharOffset,
          charOffset,
          charOpenParenOffset,
          charEndOffset,
          constructorReference,
          tearOffReference,
          nameScheme,
          nativeMethodName: nativeMethodName,
          forAbstractClassOrEnum: forAbstractClass);
    }
    checkTypeVariables(typeVariables, constructorBuilder);
    // TODO(johnniwinther): There is no way to pass the tear off reference here.
    addBuilder(constructorName, constructorBuilder, charOffset,
        getterReference: constructorReference);
    if (nativeMethodName != null) {
      addNativeMethod(constructorBuilder);
    }
    if (constructorBuilder.isConst) {
      currentTypeParameterScopeBuilder.declaresConstConstructor = true;
    }
    if (constructorBuilder.isConst ||
        libraryFeatures.superParameters.isEnabled) {
      // const constructors will have their initializers compiled and written
      // into the outline. In case of super-parameters language feature, the
      // super initializers are required to infer the types of super parameters.
      constructorBuilder.beginInitializers =
          beginInitializers ?? new Token.eof(-1);
    }
  }

  void addProcedure(
      List<MetadataBuilder>? metadata,
      int modifiers,
      TypeBuilder? returnType,
      String name,
      List<TypeVariableBuilder>? typeVariables,
      List<FormalParameterBuilder>? formals,
      ProcedureKind kind,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String? nativeMethodName,
      AsyncMarker asyncModifier,
      {required bool isInstanceMember,
      required bool isExtensionMember}) {
    // ignore: unnecessary_null_comparison
    assert(isInstanceMember != null);
    // ignore: unnecessary_null_comparison
    assert(isExtensionMember != null);
    assert(!isExtensionMember ||
        currentTypeParameterScopeBuilder.kind ==
            TypeParameterScopeKind.extensionDeclaration);
    ContainerType containerType =
        currentTypeParameterScopeBuilder.containerType;
    ContainerName? containerName =
        currentTypeParameterScopeBuilder.containerName;
    NameScheme nameScheme = new NameScheme(
        containerName: containerName,
        containerType: containerType,
        isInstanceMember: isInstanceMember,
        libraryName: referencesFrom != null
            ? new LibraryName(referencesFrom!.reference)
            : libraryName);

    if (returnType == null) {
      if (kind == ProcedureKind.Operator &&
          identical(name, indexSetName.text)) {
        returnType = addVoidType(charOffset);
      } else if (kind == ProcedureKind.Setter) {
        returnType = addVoidType(charOffset);
      }
    }
    Reference? procedureReference;
    Reference? tearOffReference;
    if (referencesFrom != null) {
      Name nameToLookup = nameScheme.getProcedureMemberName(kind, name).name;
      if (_currentClassReferencesFromIndexed != null) {
        if (kind == ProcedureKind.Setter) {
          procedureReference = _currentClassReferencesFromIndexed!
              .lookupSetterReference(nameToLookup);
        } else {
          procedureReference = _currentClassReferencesFromIndexed!
              .lookupGetterReference(nameToLookup);
        }
      } else {
        if (kind == ProcedureKind.Setter &&
            // Extension instance setters are encoded as methods.
            !(isExtensionMember && isInstanceMember)) {
          procedureReference =
              referencesFromIndexed!.lookupSetterReference(nameToLookup);
        } else {
          procedureReference =
              referencesFromIndexed!.lookupGetterReference(nameToLookup);
        }
        if (isExtensionMember && kind == ProcedureKind.Method) {
          tearOffReference = referencesFromIndexed!.lookupGetterReference(
              nameScheme
                  .getProcedureMemberName(ProcedureKind.Getter, name)
                  .name);
        }
      }
    }
    SourceProcedureBuilder procedureBuilder = new SourceProcedureBuilder(
        metadata,
        modifiers,
        returnType ?? addInferableType(),
        name,
        typeVariables,
        formals,
        kind,
        this,
        startCharOffset,
        charOffset,
        charOpenParenOffset,
        charEndOffset,
        procedureReference,
        tearOffReference,
        asyncModifier,
        nameScheme,
        nativeMethodName: nativeMethodName);
    checkTypeVariables(typeVariables, procedureBuilder);
    addBuilder(name, procedureBuilder, charOffset,
        getterReference: procedureReference);
    if (nativeMethodName != null) {
      addNativeMethod(procedureBuilder);
    }
  }

  void addFactoryMethod(
      List<MetadataBuilder>? metadata,
      int modifiers,
      Object name,
      List<FormalParameterBuilder>? formals,
      ConstructorReferenceBuilder? redirectionTarget,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String? nativeMethodName,
      AsyncMarker asyncModifier) {
    TypeBuilder returnType;
    if (currentTypeParameterScopeBuilder.parent?.kind ==
        TypeParameterScopeKind.extensionDeclaration) {
      // Make the synthesized return type invalid for extensions.
      String name = currentTypeParameterScopeBuilder.parent!.name;
      returnType = new NamedTypeBuilder.forInvalidType(
          currentTypeParameterScopeBuilder.parent!.name,
          const NullabilityBuilder.omitted(),
          messageExtensionDeclaresConstructor.withLocation(
              fileUri, charOffset, name.length));
    } else {
      returnType = addNamedType(currentTypeParameterScopeBuilder.parent!.name,
          const NullabilityBuilder.omitted(), <TypeBuilder>[], charOffset,
          instanceTypeVariableAccess: InstanceTypeVariableAccessState.Allowed);
    }
    // Nested declaration began in `OutlineBuilder.beginFactoryMethod`.
    TypeParameterScopeBuilder factoryDeclaration = endNestedDeclaration(
        TypeParameterScopeKind.factoryMethod, "#factory_method");

    // Prepare the simple procedure name.
    String procedureName;
    String? constructorName =
        computeAndValidateConstructorName(name, charOffset, isFactory: true);
    if (constructorName != null) {
      procedureName = constructorName;
    } else {
      procedureName = name as String;
    }

    ContainerType containerType =
        currentTypeParameterScopeBuilder.parent!.containerType;
    ContainerName? containerName =
        currentTypeParameterScopeBuilder.parent!.containerName;

    NameScheme procedureNameScheme = new NameScheme(
        containerName: containerName,
        containerType: containerType,
        isInstanceMember: false,
        libraryName: referencesFrom != null
            ? new LibraryName(
                (_currentClassReferencesFromIndexed ?? referencesFromIndexed)!
                    .library
                    .reference)
            : libraryName);

    Reference? constructorReference;
    Reference? tearOffReference;
    if (_currentClassReferencesFromIndexed != null) {
      constructorReference = _currentClassReferencesFromIndexed!
          .lookupConstructorReference(new Name(
              procedureName, _currentClassReferencesFromIndexed!.library));
      tearOffReference = _currentClassReferencesFromIndexed!
          .lookupGetterReference(new Name(constructorTearOffName(procedureName),
              _currentClassReferencesFromIndexed!.library));
    }

    SourceFactoryBuilder procedureBuilder;
    List<TypeVariableBuilder> typeVariables;
    if (redirectionTarget != null) {
      procedureBuilder = new RedirectingFactoryBuilder(
          metadata,
          staticMask | modifiers,
          returnType,
          procedureName,
          typeVariables = copyTypeVariables(
              currentTypeParameterScopeBuilder.typeVariables ??
                  const <TypeVariableBuilder>[],
              factoryDeclaration,
              kind: TypeVariableKind.function),
          formals,
          this,
          startCharOffset,
          charOffset,
          charOpenParenOffset,
          charEndOffset,
          constructorReference,
          tearOffReference,
          procedureNameScheme,
          nativeMethodName,
          redirectionTarget);
    } else {
      procedureBuilder = new SourceFactoryBuilder(
          metadata,
          staticMask | modifiers,
          returnType,
          procedureName,
          typeVariables = copyTypeVariables(
              currentTypeParameterScopeBuilder.typeVariables ??
                  const <TypeVariableBuilder>[],
              factoryDeclaration,
              kind: TypeVariableKind.function),
          formals,
          this,
          startCharOffset,
          charOffset,
          charOpenParenOffset,
          charEndOffset,
          constructorReference,
          tearOffReference,
          asyncModifier,
          procedureNameScheme,
          nativeMethodName: nativeMethodName);
    }

    TypeParameterScopeBuilder savedDeclaration =
        currentTypeParameterScopeBuilder;
    currentTypeParameterScopeBuilder = factoryDeclaration;
    if (returnType is NamedTypeBuilder && !typeVariables.isEmpty) {
      returnType.arguments =
          new List<TypeBuilder>.generate(typeVariables.length, (int index) {
        return addNamedType(
            typeVariables[index].name,
            const NullabilityBuilder.omitted(),
            null,
            procedureBuilder.charOffset,
            instanceTypeVariableAccess:
                InstanceTypeVariableAccessState.Allowed);
      });
    }
    currentTypeParameterScopeBuilder = savedDeclaration;

    factoryDeclaration.resolveNamedTypes(procedureBuilder.typeVariables, this);
    addBuilder(procedureName, procedureBuilder, charOffset,
        getterReference: constructorReference);
    if (nativeMethodName != null) {
      addNativeMethod(procedureBuilder);
    }
  }

  void addEnum(
      List<MetadataBuilder>? metadata,
      String name,
      List<TypeVariableBuilder>? typeVariables,
      MixinApplicationBuilder? supertypeBuilder,
      List<TypeBuilder>? interfaceBuilders,
      List<EnumConstantInfo?>? enumConstantInfos,
      int startCharOffset,
      int charOffset,
      int charEndOffset) {
    IndexedClass? referencesFromIndexedClass;
    if (referencesFrom != null) {
      referencesFromIndexedClass =
          referencesFromIndexed!.lookupIndexedClass(name);
    }
    // Nested declaration began in `OutlineBuilder.beginEnum`.
    TypeParameterScopeBuilder declaration =
        endNestedDeclaration(TypeParameterScopeKind.enumDeclaration, name)
          ..resolveNamedTypes(typeVariables, this);
    Map<String, Builder> members = declaration.members!;
    Map<String, MemberBuilder> constructors = declaration.constructors!;
    Map<String, MemberBuilder> setters = declaration.setters!;

    SourceEnumBuilder enumBuilder = new SourceEnumBuilder(
        metadata,
        name,
        typeVariables,
        _applyMixins(
            loader.target.underscoreEnumType,
            supertypeBuilder,
            startCharOffset,
            charOffset,
            charEndOffset,
            name,
            /* isMixinDeclaration = */
            false,
            typeVariables: typeVariables,
            isMacro: false,
            isSealed: false,
            isBase: false,
            isInterface: false,
            isFinal: false,
            isAugmentation: false,
            isMixinClass: false),
        interfaceBuilders,
        enumConstantInfos,
        this,
        new List<ConstructorReferenceBuilder>.of(constructorReferences),
        startCharOffset,
        charOffset,
        charEndOffset,
        referencesFromIndexedClass,
        new Scope(
            kind: ScopeKind.declaration,
            local: members,
            setters: setters,
            parent: scope.withTypeVariables(typeVariables),
            debugName: "enum $name",
            isModifiable: false),
        new ConstructorScope(name, constructors),
        loader.coreLibrary);
    constructorReferences.clear();

    Map<String, TypeVariableBuilder>? typeVariablesByName =
        checkTypeVariables(typeVariables, enumBuilder);

    void setParent(MemberBuilder? member) {
      while (member != null) {
        member.parent = enumBuilder;
        member = member.next as MemberBuilder?;
      }
    }

    void setParentAndCheckConflicts(String name, Builder member) {
      if (typeVariablesByName != null) {
        TypeVariableBuilder? tv = typeVariablesByName[name];
        if (tv != null) {
          enumBuilder.addProblem(
              templateConflictsWithTypeVariable.withArguments(name),
              member.charOffset,
              name.length,
              context: [
                messageConflictsWithTypeVariableCause.withLocation(
                    tv.fileUri!, tv.charOffset, name.length)
              ]);
        }
      }
      setParent(member as MemberBuilder);
    }

    members.forEach(setParentAndCheckConflicts);
    constructors.forEach(setParentAndCheckConflicts);
    setters.forEach(setParentAndCheckConflicts);
    addBuilder(name, enumBuilder, charOffset,
        getterReference: referencesFromIndexedClass?.cls.reference);
  }

  void addFunctionTypeAlias(
      List<MetadataBuilder>? metadata,
      String name,
      List<TypeVariableBuilder>? typeVariables,
      TypeBuilder type,
      int charOffset) {
    if (typeVariables != null) {
      for (TypeVariableBuilder typeVariable in typeVariables) {
        typeVariable.variance = pendingVariance;
      }
    }
    Typedef? referenceFrom = referencesFromIndexed?.lookupTypedef(name);
    TypeAliasBuilder typedefBuilder = new SourceTypeAliasBuilder(
        metadata, name, typeVariables, type, this, charOffset,
        referenceFrom: referenceFrom);
    checkTypeVariables(typeVariables, typedefBuilder);
    // Nested declaration began in `OutlineBuilder.beginFunctionTypeAlias`.
    endNestedDeclaration(TypeParameterScopeKind.typedef, "#typedef")
        .resolveNamedTypes(typeVariables, this);
    addBuilder(name, typedefBuilder, charOffset,
        getterReference: referenceFrom?.reference);
  }

  FunctionTypeBuilder addFunctionType(
      TypeBuilder returnType,
      List<TypeVariableBuilder>? typeVariables,
      List<FormalParameterBuilder>? formals,
      NullabilityBuilder nullabilityBuilder,
      Uri fileUri,
      int charOffset) {
    FunctionTypeBuilder builder = new FunctionTypeBuilder(returnType,
        typeVariables, formals, nullabilityBuilder, fileUri, charOffset);
    checkTypeVariables(typeVariables, null);
    if (typeVariables != null) {
      for (TypeVariableBuilder builder in typeVariables) {
        if (builder.metadata != null) {
          if (!libraryFeatures.genericMetadata.isEnabled) {
            addProblem(messageAnnotationOnFunctionTypeTypeVariable,
                builder.charOffset, builder.name.length, builder.fileUri);
          }
        }
      }
    }
    // Nested declaration began in `OutlineBuilder.beginFunctionType` or
    // `OutlineBuilder.beginFunctionTypedFormalParameter`.
    endNestedDeclaration(TypeParameterScopeKind.functionType, "#function_type")
        .resolveNamedTypes(typeVariables, this);
    return builder;
  }

  FormalParameterBuilder addFormalParameter(
      List<MetadataBuilder>? metadata,
      FormalParameterKind kind,
      int modifiers,
      TypeBuilder type,
      String name,
      bool hasThis,
      bool hasSuper,
      int charOffset,
      Token? initializerToken) {
    assert(!hasThis || !hasSuper,
        "Formal parameter '${name}' has both 'this' and 'super' prefixes.");
    if (hasThis) {
      modifiers |= initializingFormalMask;
    }
    if (hasSuper) {
      modifiers |= superInitializingFormalMask;
    }
    FormalParameterBuilder formal = new FormalParameterBuilder(
        metadata, kind, modifiers, type, name, this, charOffset,
        fileUri: fileUri)
      ..initializerToken = initializerToken
      ..hasDeclaredInitializer = (initializerToken != null);
    return formal;
  }

  TypeVariableBuilder addTypeVariable(List<MetadataBuilder>? metadata,
      String name, TypeBuilder? bound, int charOffset, Uri fileUri,
      {required TypeVariableKind kind}) {
    TypeVariableBuilder builder = new TypeVariableBuilder(
        name, this, charOffset, fileUri,
        bound: bound, metadata: metadata, kind: kind);

    unboundTypeVariables.add(builder);
    return builder;
  }

  BodyBuilderContext get bodyBuilderContext =>
      new LibraryBodyBuilderContext(this);

  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      List<DelayedActionPerformer> delayedActionPerformers) {
    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        patchLibrary.buildOutlineExpressions(classHierarchy,
            delayedDefaultValueCloners, delayedActionPerformers);
      }
    }

    MetadataBuilder.buildAnnotations(
        library, metadata, bodyBuilderContext, this, fileUri, scope);

    Iterator<Builder> iterator = localMembersIterator;
    while (iterator.moveNext()) {
      Builder declaration = iterator.current;
      if (declaration is SourceClassBuilder) {
        declaration.buildOutlineExpressions(classHierarchy,
            delayedActionPerformers, delayedDefaultValueCloners);
      } else if (declaration is SourceExtensionBuilder) {
        declaration.buildOutlineExpressions(classHierarchy,
            delayedActionPerformers, delayedDefaultValueCloners);
      } else if (declaration is SourceInlineClassBuilder) {
        declaration.buildOutlineExpressions(classHierarchy,
            delayedActionPerformers, delayedDefaultValueCloners);
      } else if (declaration is SourceMemberBuilder) {
        declaration.buildOutlineExpressions(classHierarchy,
            delayedActionPerformers, delayedDefaultValueCloners);
      } else if (declaration is SourceTypeAliasBuilder) {
        declaration.buildOutlineExpressions(classHierarchy,
            delayedActionPerformers, delayedDefaultValueCloners);
      } else {
        assert(
            declaration is PrefixBuilder ||
                declaration is DynamicTypeDeclarationBuilder ||
                declaration is NeverTypeDeclarationBuilder,
            "Unexpected builder in library: ${declaration} "
            "(${declaration.runtimeType}");
      }
    }
  }

  /// Builds the core AST structures for [declaration] needed for the outline.
  void _buildOutlineNodes(Builder declaration, LibraryBuilder coreLibrary) {
    if (declaration is SourceClassBuilder) {
      Class cls = declaration.build(coreLibrary);
      if (!declaration.isPatch) {
        if (declaration.isDuplicate ||
            declaration.isConflictingAugmentationMember) {
          cls.name = '${cls.name}'
              '#${declaration.duplicateIndex}'
              '#${declaration.libraryBuilder.patchIndex}';
        }
        library.addClass(cls);
      }
    } else if (declaration is SourceExtensionBuilder) {
      Extension extension = declaration.build(coreLibrary,
          addMembersToLibrary: !declaration.isDuplicate);
      if (!declaration.isPatch && !declaration.isDuplicate) {
        if (declaration.isUnnamedExtension) {
          declaration.extensionName.name =
              '_extension#${library.extensions.length}';
        }
        library.addExtension(extension);
      }
    } else if (declaration is SourceInlineClassBuilder) {
      InlineClass inlineClass = declaration.build(coreLibrary,
          addMembersToLibrary: !declaration.isDuplicate);
      if (!declaration.isPatch && !declaration.isDuplicate) {
        library.addInlineClass(inlineClass);
      }
    } else if (declaration is SourceMemberBuilder) {
      declaration
          .buildOutlineNodes((Member member, BuiltMemberKind memberKind) {
        _addMemberToLibrary(declaration, member, memberKind);
      });
    } else if (declaration is SourceTypeAliasBuilder) {
      Typedef typedef = declaration.build();
      if (!declaration.isPatch && !declaration.isDuplicate) {
        library.addTypedef(typedef);
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
    }
  }

  void _addMemberToLibrary(SourceMemberBuilder declaration, Member member,
      BuiltMemberKind memberKind) {
    if (member is Field) {
      member.isStatic = true;
      if (!declaration.isPatch && !declaration.isDuplicate) {
        if (declaration.isConflictingAugmentationMember) {
          member.name = new Name(
              '${member.name.text}#${declaration.libraryBuilder.patchIndex}',
              member.name.library);
        }
        library.addField(member);
      }
    } else if (member is Procedure) {
      member.isStatic = true;
      if (!declaration.isPatch &&
          !declaration.isDuplicate &&
          !declaration.isConflictingSetter) {
        if (declaration.isConflictingAugmentationMember) {
          member.name = new Name(
              '${member.name.text}#${declaration.libraryBuilder.patchIndex}',
              member.name.library);
        }
        library.addProcedure(member);
      }
    } else {
      unhandled("${member.runtimeType}:${memberKind}", "_buildMember",
          declaration.charOffset, declaration.fileUri);
    }
  }

  void addNativeDependency(String nativeImportPath) {
    MemberBuilder constructor = loader.getNativeAnnotation();
    Arguments arguments =
        new Arguments(<Expression>[new StringLiteral(nativeImportPath)]);
    Expression annotation;
    if (constructor.isConstructor) {
      annotation = new ConstructorInvocation(
          constructor.member as Constructor, arguments)
        ..isConst = true;
    } else {
      annotation =
          new StaticInvocation(constructor.member as Procedure, arguments)
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
          addNativeDependency(import.nativeImportPath!);
          continue;
        }

        if (import.deferred && import.prefixBuilder?.dependency != null) {
          library.addDependency(import.prefixBuilder!.dependency!);
        } else {
          LibraryBuilder imported = import.imported!.origin;
          Library targetLibrary = imported.library;
          library.addDependency(new LibraryDependency.import(targetLibrary,
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
      {bool isExport = false, bool isImport = false}) {
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
    Builder? preferred;
    Uri? uri;
    Uri? otherUri;
    if (scope.lookupLocalMember(name, setter: false) == declaration) {
      preferred = declaration;
    } else {
      uri = computeLibraryUri(declaration);
      otherUri = computeLibraryUri(other);
      if (declaration is LoadLibraryBuilder) {
        preferred = declaration;
      } else if (other is LoadLibraryBuilder) {
        preferred = other;
      } else if (otherUri.isScheme("dart") && !uri.isScheme("dart")) {
        preferred = declaration;
      } else if (uri.isScheme("dart") && !otherUri.isScheme("dart")) {
        preferred = other;
      }
    }
    if (preferred != null) {
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
    Uri firstUri = uri!;
    Uri secondUri = otherUri!;
    if (firstUri.toString().compareTo(secondUri.toString()) > 0) {
      firstUri = secondUri;
      secondUri = uri;
    }
    if (isExport) {
      Template<Message Function(String name, Uri uri, Uri uri2)> template =
          templateDuplicatedExport;
      Message message = template.withArguments(name, firstUri, secondUri);
      addProblem(message, charOffset, noLength, fileUri);
    }
    Template<Message Function(String name, Uri uri, Uri uri2)> builderTemplate =
        isExport
            ? templateDuplicatedExportInType
            : templateDuplicatedImportInType;
    Message message = builderTemplate.withArguments(
        name,
        // TODO(ahe): We should probably use a context object here
        // instead of including URIs in this message.
        firstUri,
        secondUri);
    // We report the error lazily (setting suppressMessage to false) because the
    // spec 18.1 states that 'It is not an error if N is introduced by two or
    // more imports but never referred to.'
    return new InvalidTypeDeclarationBuilder(
        name, message.withLocation(fileUri, charOffset, name.length),
        suppressMessage: false);
  }

  int finishDeferredLoadTearoffs() {
    int total = 0;

    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        total += patchLibrary.finishDeferredLoadTearoffs();
      }
    }

    for (Import import in imports) {
      if (import.deferred) {
        Procedure? tearoff = import.prefixBuilder!.loadLibraryBuilder!.tearoff;
        if (tearoff != null) {
          library.addProcedure(tearoff);
        }
        total++;
      }
    }

    return total;
  }

  int finishForwarders() {
    int count = 0;

    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        count += patchLibrary.finishForwarders();
      }
    }

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
              cloner.clone(originParameter.initializer!);
          forwarderParameter.initializer!.parent = forwarderParameter;
        }
      }

      Map<String, VariableDeclaration> originNamedMap =
          <String, VariableDeclaration>{};
      for (VariableDeclaration originNamed in origin.function.namedParameters) {
        originNamedMap[originNamed.name!] = originNamed;
      }
      for (VariableDeclaration forwarderNamed
          in forwarder.function.namedParameters) {
        VariableDeclaration? originNamed = originNamedMap[forwarderNamed.name];
        if (originNamed == null) {
          return unhandled(
              "null", forwarder.name.text, origin.fileOffset, origin.fileUri);
        }
        if (originNamed.initializer == null) continue;
        forwarderNamed.initializer = cloner.clone(originNamed.initializer!);
        forwarderNamed.initializer!.parent = forwarderNamed;
      }

      ++count;
    }
    forwardersOrigins.clear();
    return count;
  }

  void addNativeMethod(SourceFunctionBuilder method) {
    nativeMethods.add(method);
  }

  int finishNativeMethods() {
    int count = 0;

    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        count += patchLibrary.finishNativeMethods();
      }
    }

    for (SourceFunctionBuilder method in nativeMethods) {
      method.becomeNative(loader);
    }
    count += nativeMethods.length;

    return count;
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
      {required TypeVariableKind kind}) {
    List<NamedTypeBuilder> newTypes = <NamedTypeBuilder>[];
    List<TypeVariableBuilder> copy = <TypeVariableBuilder>[];
    for (TypeVariableBuilder variable in original) {
      TypeVariableBuilder newVariable = new TypeVariableBuilder(
          variable.name, this, variable.charOffset, variable.fileUri,
          bound: variable.bound?.clone(newTypes, this, declaration),
          kind: kind,
          variableVariance:
              variable.parameter.isLegacyCovariant ? null : variable.variance);
      copy.add(newVariable);
      unboundTypeVariables.add(newVariable);
    }
    for (NamedTypeBuilder newType in newTypes) {
      declaration.registerUnresolvedNamedType(newType);
    }
    return copy;
  }

  int finishTypeVariables(ClassBuilder object, TypeBuilder dynamicType) {
    int count = 0;

    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        count += patchLibrary.finishTypeVariables(object, dynamicType);
      }
    }

    count += unboundTypeVariables.length;

    // Ensure that type parameters are built after their dependencies by sorting
    // them topologically using references in bounds.
    for (TypeVariableBuilder builder
        in _sortTypeVariablesTopologically(unboundTypeVariables)) {
      builder.finish(this, object, dynamicType);
    }
    unboundTypeVariables.clear();

    processPendingNullabilities();

    return count;
  }

  /// Assigns nullabilities to types in [_pendingNullabilities].
  ///
  /// It's a helper function to assign the nullabilities to type-parameter types
  /// after the corresponding type parameters have their bounds set or changed.
  /// The function takes into account that some of the types in the input list
  /// may be bounds to some of the type parameters of other types from the input
  /// list.
  void processPendingNullabilities() {
    // The bounds of type parameters may be type-parameter types of other
    // parameters from the same declaration.  In this case we need to set the
    // nullability for them first.  To preserve the ordering, we implement a
    // depth-first search over the types.  We use the fact that a nullability
    // of a type parameter type can't ever be 'nullable' if computed from the
    // bound. It allows us to use 'nullable' nullability as the marker in the
    // DFS implementation.

    // We cannot set the declared nullability on the pending types to `null` so
    // we create a map of the pending type parameter type nullabilities.
    Map<TypeParameterType, Nullability?> nullabilityMap =
        new LinkedHashMap.identity();
    Nullability? getDeclaredNullability(TypeParameterType type) {
      if (nullabilityMap.containsKey(type)) {
        return nullabilityMap[type];
      }
      return type.declaredNullability;
    }

    void setDeclaredNullability(
        TypeParameterType type, Nullability nullability) {
      if (nullabilityMap.containsKey(type)) {
        nullabilityMap[type] = nullability;
      }
      type.declaredNullability = nullability;
    }

    Nullability marker = Nullability.nullable;
    List<TypeParameterType?> stack =
        new List<TypeParameterType?>.filled(_pendingNullabilities.length, null);
    int stackTop = 0;
    for (PendingNullability pendingNullability in _pendingNullabilities) {
      nullabilityMap[pendingNullability.type] = null;
    }
    for (PendingNullability pendingNullability in _pendingNullabilities) {
      TypeParameterType type = pendingNullability.type;
      if (getDeclaredNullability(type) != null) {
        // Nullability for [type] was already computed on one of the branches
        // of the depth-first search.  Continue to the next one.
        continue;
      }
      DartType peeledBound = _peelOffFutureOr(type.parameter.bound);
      if (peeledBound is TypeParameterType) {
        TypeParameterType current = type;
        TypeParameterType? next = peeledBound;
        bool isDirectDependency = identical(type.parameter.bound, peeledBound);
        while (next != null && getDeclaredNullability(next) == null) {
          stack[stackTop++] = current;
          setDeclaredNullability(current, marker);

          current = next;
          peeledBound = _peelOffFutureOr(current.parameter.bound);
          isDirectDependency = isDirectDependency &&
              identical(current.parameter.bound, peeledBound);
          if (peeledBound is TypeParameterType) {
            next = peeledBound;
            if (getDeclaredNullability(next) == marker) {
              setDeclaredNullability(next, Nullability.undetermined);
              if (isDirectDependency) {
                current.parameter.bound = const InvalidType();
                current.parameter.defaultType = const InvalidType();
                addProblem(
                    templateCycleInTypeVariables.withArguments(
                        next.parameter.name!, current.parameter.name!),
                    pendingNullability.charOffset,
                    next.parameter.name!.length,
                    pendingNullability.fileUri);
              }
              next = null;
            }
          } else {
            next = null;
          }
        }
        setDeclaredNullability(current,
            TypeParameterType.computeNullabilityFromBound(current.parameter));
        while (stackTop != 0) {
          --stackTop;
          current = stack[stackTop]!;
          setDeclaredNullability(current,
              TypeParameterType.computeNullabilityFromBound(current.parameter));
        }
      } else {
        setDeclaredNullability(type,
            TypeParameterType.computeNullabilityFromBound(type.parameter));
      }
    }
    _pendingNullabilities.clear();
  }

  /// Computes variances of type parameters on typedefs.
  ///
  /// The variance property of type parameters on typedefs is computed from the
  /// use of the parameters in the right-hand side of the typedef definition.
  int computeVariances() {
    int count = 0;

    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        count += patchLibrary.computeVariances();
      }
    }

    for (Builder? declaration
        in _libraryTypeParameterScopeBuilder.members!.values) {
      while (declaration != null) {
        if (declaration is TypeAliasBuilder &&
            declaration.typeVariablesCount > 0) {
          for (TypeVariableBuilder typeParameter
              in declaration.typeVariables!) {
            typeParameter.variance = computeTypeVariableBuilderVariance(
                typeParameter, declaration.type, this);
            ++count;
          }
        }
        declaration = declaration.next;
      }
    }
    return count;
  }

  /// Reports an error on generic function types used as bounds
  ///
  /// The function recursively searches for all generic function types in
  /// [typeVariable.bound] and checks the bounds of type variables of the found
  /// types for being generic function types.  Additionally, the function checks
  /// [typeVariable.bound] for being a generic function type.  Returns `true` if
  /// any errors were reported.
  bool _recursivelyReportGenericFunctionTypesAsBoundsForVariable(
      TypeVariableBuilder typeVariable) {
    if (libraryFeatures.genericMetadata.isEnabled) return false;

    bool hasReportedErrors = false;
    hasReportedErrors =
        _reportGenericFunctionTypeAsBoundIfNeeded(typeVariable) ||
            hasReportedErrors;
    hasReportedErrors = _recursivelyReportGenericFunctionTypesAsBoundsForType(
            typeVariable.bound) ||
        hasReportedErrors;
    return hasReportedErrors;
  }

  /// Reports an error on generic function types used as bounds
  ///
  /// The function recursively searches for all generic function types in
  /// [typeBuilder] and checks the bounds of type variables of the found types
  /// for being generic function types.  Returns `true` if any errors were
  /// reported.
  bool _recursivelyReportGenericFunctionTypesAsBoundsForType(
      TypeBuilder? typeBuilder) {
    if (libraryFeatures.genericMetadata.isEnabled) return false;

    List<FunctionTypeBuilder> genericFunctionTypeBuilders =
        <FunctionTypeBuilder>[];
    findUnaliasedGenericFunctionTypes(typeBuilder,
        result: genericFunctionTypeBuilders);
    bool hasReportedErrors = false;
    for (FunctionTypeBuilder genericFunctionTypeBuilder
        in genericFunctionTypeBuilders) {
      assert(
          genericFunctionTypeBuilder.typeVariables != null,
          "Function 'findUnaliasedGenericFunctionTypes' "
          "returned a function type without type variables.");
      for (TypeVariableBuilder typeVariable
          in genericFunctionTypeBuilder.typeVariables!) {
        hasReportedErrors =
            _reportGenericFunctionTypeAsBoundIfNeeded(typeVariable) ||
                hasReportedErrors;
      }
    }
    return hasReportedErrors;
  }

  /// Reports an error if [typeVariable.bound] is a generic function type
  ///
  /// Returns `true` if any errors were reported.
  bool _reportGenericFunctionTypeAsBoundIfNeeded(
      TypeVariableBuilder typeVariable) {
    if (libraryFeatures.genericMetadata.isEnabled) return false;

    TypeBuilder? bound = typeVariable.bound;
    bool isUnaliasedGenericFunctionType = bound is FunctionTypeBuilder &&
        bound.typeVariables != null &&
        bound.typeVariables!.isNotEmpty;
    bool isAliasedGenericFunctionType = false;
    if (bound is NamedTypeBuilder) {
      TypeDeclarationBuilder? declaration = bound.declaration;
      // TODO(cstefantsova): Unalias beyond the first layer for the check.
      if (declaration is TypeAliasBuilder) {
        TypeBuilder? rhsType = declaration.type;
        if (rhsType is FunctionTypeBuilder &&
            rhsType.typeVariables != null &&
            rhsType.typeVariables!.isNotEmpty) {
          isAliasedGenericFunctionType = true;
        }
      }
    }

    if (isUnaliasedGenericFunctionType || isAliasedGenericFunctionType) {
      addProblem(messageGenericFunctionTypeInBound, typeVariable.charOffset,
          typeVariable.name.length, typeVariable.fileUri);
      return true;
    }
    return false;
  }

  /// This method instantiates type parameters to their bounds in some cases
  /// where they were omitted by the programmer and not provided by the type
  /// inference.  The method returns the number of distinct type variables
  /// that were instantiated in this library.
  int computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder nullType,
      TypeBuilder bottomType, ClassBuilder objectClass) {
    int count = 0;

    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        count += patchLibrary.computeDefaultTypes(
            dynamicType, nullType, bottomType, objectClass);
      }
    }

    int computeDefaultTypesForVariables(List<TypeVariableBuilder>? variables,
        {required bool inErrorRecovery}) {
      if (variables == null) return 0;

      bool haveErroneousBounds = false;
      if (!inErrorRecovery) {
        if (!libraryFeatures.genericMetadata.isEnabled) {
          for (TypeVariableBuilder variable in variables) {
            haveErroneousBounds =
                _recursivelyReportGenericFunctionTypesAsBoundsForVariable(
                        variable) ||
                    haveErroneousBounds;
          }
        }

        if (!haveErroneousBounds) {
          List<NamedTypeBuilder> unboundTypes = [];
          List<TypeVariableBuilder> unboundTypeVariables = [];
          List<TypeBuilder> calculatedBounds = calculateBounds(variables,
              dynamicType, isNonNullableByDefault ? bottomType : nullType,
              unboundTypes: unboundTypes,
              unboundTypeVariables: unboundTypeVariables);
          for (NamedTypeBuilder unboundType in unboundTypes) {
            currentTypeParameterScopeBuilder
                .registerUnresolvedNamedType(unboundType);
          }
          this.unboundTypeVariables.addAll(unboundTypeVariables);
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

    void reportIssues(List<NonSimplicityIssue> issues) {
      for (NonSimplicityIssue issue in issues) {
        addProblem(issue.message, issue.declaration.charOffset,
            issue.declaration.name.length, issue.declaration.fileUri,
            context: issue.context);
      }
    }

    void processSourceProcedureBuilder(SourceProcedureBuilder member) {
      List<NonSimplicityIssue> issues =
          getNonSimplicityIssuesForTypeVariables(member.typeVariables);
      if (member.formals != null && member.formals!.isNotEmpty) {
        for (FormalParameterBuilder formal in member.formals!) {
          issues.addAll(getInboundReferenceIssuesInType(formal.type));
          _recursivelyReportGenericFunctionTypesAsBoundsForType(formal.type);
        }
      }
      if (member.returnType is! OmittedTypeBuilder) {
        issues.addAll(getInboundReferenceIssuesInType(member.returnType));
        _recursivelyReportGenericFunctionTypesAsBoundsForType(
            member.returnType);
      }
      reportIssues(issues);
      count += computeDefaultTypesForVariables(member.typeVariables,
          inErrorRecovery: issues.isNotEmpty);
    }

    void processSourceFieldBuilder(SourceFieldBuilder member) {
      TypeBuilder? fieldType = member.type;
      if (fieldType is! OmittedTypeBuilder) {
        List<NonSimplicityIssue> issues =
            getInboundReferenceIssuesInType(fieldType);
        reportIssues(issues);
        _recursivelyReportGenericFunctionTypesAsBoundsForType(fieldType);
      }
    }

    void processSourceConstructorBuilder(SourceMemberBuilder member,
        {required bool inErrorRecovery}) {
      List<FormalParameterBuilder>? formals;
      if (member is SourceFactoryBuilder) {
        assert(member.isFactory,
            "Unexpected constructor member (${member.runtimeType}).");
        count += computeDefaultTypesForVariables(member.typeVariables,
            // Type variables are inherited from the class so if the class
            // has issues, so does the factory constructors.
            inErrorRecovery: inErrorRecovery);
        formals = member.formals;
      } else {
        assert(member is ConstructorDeclaration,
            "Unexpected constructor member (${member.runtimeType}).");
        formals = (member as ConstructorDeclaration).formals;
      }
      if (formals != null && formals.isNotEmpty) {
        for (FormalParameterBuilder formal in formals) {
          List<NonSimplicityIssue> issues =
              getInboundReferenceIssuesInType(formal.type);
          reportIssues(issues);
          _recursivelyReportGenericFunctionTypesAsBoundsForType(formal.type);
        }
      }
    }

    void processSourceMemberBuilder(SourceMemberBuilder member,
        {required bool inErrorRecovery}) {
      if (member is SourceProcedureBuilder) {
        processSourceProcedureBuilder(member);
      } else if (member is SourceFieldBuilder) {
        processSourceFieldBuilder(member);
      } else {
        processSourceConstructorBuilder(member,
            inErrorRecovery: inErrorRecovery);
      }
    }

    void computeDefaultValuesForDeclaration(Builder declaration) {
      if (declaration is SourceClassBuilder) {
        List<NonSimplicityIssue> issues = getNonSimplicityIssuesForDeclaration(
            declaration,
            performErrorRecovery: true);
        reportIssues(issues);
        count += computeDefaultTypesForVariables(declaration.typeVariables,
            inErrorRecovery: issues.isNotEmpty);

        Iterator<SourceMemberBuilder> iterator = declaration.constructorScope
            .filteredIterator<SourceMemberBuilder>(
                includeDuplicates: false, includeAugmentations: true);
        while (iterator.moveNext()) {
          processSourceMemberBuilder(iterator.current,
              inErrorRecovery: issues.isNotEmpty);
        }

        Iterator<SourceMemberBuilder> memberIterator =
            declaration.fullMemberIterator<SourceMemberBuilder>();
        while (memberIterator.moveNext()) {
          SourceMemberBuilder member = memberIterator.current;
          processSourceMemberBuilder(member,
              inErrorRecovery: issues.isNotEmpty);
        }
      } else if (declaration is SourceTypeAliasBuilder) {
        List<NonSimplicityIssue> issues = getNonSimplicityIssuesForDeclaration(
            declaration,
            performErrorRecovery: true);
        issues.addAll(getInboundReferenceIssuesInType(declaration.type));
        reportIssues(issues);
        count += computeDefaultTypesForVariables(declaration.typeVariables,
            inErrorRecovery: issues.isNotEmpty);
        _recursivelyReportGenericFunctionTypesAsBoundsForType(declaration.type);
      } else if (declaration is SourceMemberBuilder) {
        processSourceMemberBuilder(declaration, inErrorRecovery: false);
      } else if (declaration is SourceExtensionBuilder) {
        List<NonSimplicityIssue> issues = getNonSimplicityIssuesForDeclaration(
            declaration,
            performErrorRecovery: true);
        reportIssues(issues);
        count += computeDefaultTypesForVariables(declaration.typeParameters,
            inErrorRecovery: issues.isNotEmpty);

        declaration.forEach((String name, Builder member) {
          if (member is SourceMemberBuilder) {
            processSourceMemberBuilder(member,
                inErrorRecovery: issues.isNotEmpty);
          } else {
            assert(false,
                "Unexpected extension member $member (${member.runtimeType}).");
          }
        });
      } else if (declaration is SourceInlineClassBuilder) {
        List<NonSimplicityIssue> issues = getNonSimplicityIssuesForDeclaration(
            declaration,
            performErrorRecovery: true);
        reportIssues(issues);
        count += computeDefaultTypesForVariables(declaration.typeParameters,
            inErrorRecovery: issues.isNotEmpty);

        declaration.forEach((String name, Builder member) {
          if (member is SourceMemberBuilder) {
            processSourceMemberBuilder(member,
                inErrorRecovery: issues.isNotEmpty);
          } else {
            assert(
                false,
                "Unexpected inline class member "
                "$member (${member.runtimeType}).");
          }
        });
      } else {
        assert(
            declaration is PrefixBuilder ||
                declaration is DynamicTypeDeclarationBuilder ||
                declaration is NeverTypeDeclarationBuilder,
            "Unexpected top level member $declaration "
            "(${declaration.runtimeType}).");
      }
    }

    for (Builder declaration
        in _libraryTypeParameterScopeBuilder.members!.values) {
      computeDefaultValuesForDeclaration(declaration);
    }
    for (Builder declaration
        in _libraryTypeParameterScopeBuilder.setters!.values) {
      computeDefaultValuesForDeclaration(declaration);
    }
    for (ExtensionBuilder declaration
        in _libraryTypeParameterScopeBuilder.extensions!) {
      if (declaration is SourceExtensionBuilder &&
          declaration.isUnnamedExtension) {
        computeDefaultValuesForDeclaration(declaration);
      }
    }
    return count;
  }

  /// If this is a patch library, apply its patches to [origin].
  void applyPatches() {
    if (!isPatch) return;

    if (languageVersion != origin.languageVersion) {
      List<LocatedMessage> context = <LocatedMessage>[];
      if (origin.languageVersion.isExplicit) {
        context.add(messageLanguageVersionLibraryContext.withLocation(
            origin.languageVersion.fileUri!,
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

    mergedScope.addAugmentationScope(this);
    return;
  }

  /// Builds the AST nodes needed for the full compilation.
  ///
  /// This includes patching member bodies and adding augmented members.
  int buildBodyNodes() {
    int count = 0;

    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        count += patchLibrary.buildBodyNodes();
      }
    }

    Iterator<Builder> iterator = localMembersIterator;
    while (iterator.moveNext()) {
      Builder builder = iterator.current;
      if (builder is SourceMemberBuilder) {
        count +=
            builder.buildBodyNodes((Member member, BuiltMemberKind memberKind) {
          _addMemberToLibrary(builder, member, memberKind);
        });
      } else if (builder is SourceClassBuilder) {
        count += builder.buildBodyNodes();
      } else if (builder is SourceExtensionBuilder) {
        count +=
            builder.buildBodyNodes(addMembersToLibrary: !builder.isDuplicate);
      } else if (builder is SourceInlineClassBuilder) {
        count +=
            builder.buildBodyNodes(addMembersToLibrary: !builder.isDuplicate);
      } else if (builder is SourceClassBuilder) {
        count += builder.buildBodyNodes();
      } else if (builder is SourceTypeAliasBuilder) {
        // Do nothing.
      } else if (builder is PrefixBuilder) {
        // Ignored. Kernel doesn't represent prefixes.
      } else if (builder is BuiltinTypeDeclarationBuilder) {
        // Nothing needed.
      } else {
        unhandled("${builder.runtimeType}", "buildBodyNodes",
            builder.charOffset, builder.fileUri);
      }
    }
    return count;
  }

  void _reportTypeArgumentIssues(
      Iterable<TypeArgumentIssue> issues, Uri fileUri, int offset,
      {bool? inferred,
      TypeArgumentsInfo? typeArgumentsInfo,
      DartType? targetReceiver,
      String? targetName}) {
    for (TypeArgumentIssue issue in issues) {
      DartType argument = issue.argument;
      TypeParameter? typeParameter = issue.typeParameter;

      Message message;
      bool issueInferred =
          inferred ?? typeArgumentsInfo?.isInferred(issue.index) ?? false;
      offset =
          typeArgumentsInfo?.getOffsetForIndex(issue.index, offset) ?? offset;
      if (issue.isGenericTypeAsArgumentIssue) {
        if (issueInferred) {
          message = templateGenericFunctionTypeInferredAsActualTypeArgument
              .withArguments(argument, isNonNullableByDefault);
        } else {
          message = messageGenericFunctionTypeUsedAsActualTypeArgument;
        }
        typeParameter = null;
      } else {
        if (issue.enclosingType == null && targetReceiver != null) {
          if (targetName != null) {
            if (issueInferred) {
              message =
                  templateIncorrectTypeArgumentQualifiedInferred.withArguments(
                      argument,
                      typeParameter.bound,
                      typeParameter.name!,
                      targetReceiver,
                      targetName,
                      isNonNullableByDefault);
            } else {
              message = templateIncorrectTypeArgumentQualified.withArguments(
                  argument,
                  typeParameter.bound,
                  typeParameter.name!,
                  targetReceiver,
                  targetName,
                  isNonNullableByDefault);
            }
          } else {
            if (issueInferred) {
              message = templateIncorrectTypeArgumentInstantiationInferred
                  .withArguments(
                      argument,
                      typeParameter.bound,
                      typeParameter.name!,
                      targetReceiver,
                      isNonNullableByDefault);
            } else {
              message =
                  templateIncorrectTypeArgumentInstantiation.withArguments(
                      argument,
                      typeParameter.bound,
                      typeParameter.name!,
                      targetReceiver,
                      isNonNullableByDefault);
            }
          }
        } else {
          String enclosingName = issue.enclosingType == null
              ? targetName!
              : getGenericTypeName(issue.enclosingType!);
          // ignore: unnecessary_null_comparison
          assert(enclosingName != null);
          if (issueInferred) {
            message = templateIncorrectTypeArgumentInferred.withArguments(
                argument,
                typeParameter.bound,
                typeParameter.name!,
                enclosingName,
                isNonNullableByDefault);
          } else {
            message = templateIncorrectTypeArgument.withArguments(
                argument,
                typeParameter.bound,
                typeParameter.name!,
                enclosingName,
                isNonNullableByDefault);
          }
        }
      }

      // Don't show the hint about an attempted super-bounded type if the issue
      // with the argument is that it's generic.
      reportTypeArgumentIssue(message, fileUri, offset,
          typeParameter: typeParameter,
          superBoundedAttempt:
              issue.isGenericTypeAsArgumentIssue ? null : issue.enclosingType,
          superBoundedAttemptInverted:
              issue.isGenericTypeAsArgumentIssue ? null : issue.invertedType);
    }
  }

  void reportTypeArgumentIssue(Message message, Uri fileUri, int fileOffset,
      {TypeParameter? typeParameter,
      DartType? superBoundedAttempt,
      DartType? superBoundedAttemptInverted}) {
    List<LocatedMessage>? context;
    // Skip reporting location for function-type type parameters as it's a
    // limitation of Kernel.
    if (typeParameter != null &&
        typeParameter.fileOffset != -1 &&
        typeParameter.location != null) {
      // It looks like when parameters come from patch files, they don't
      // have a reportable location.
      (context ??= <LocatedMessage>[]).add(
          messageIncorrectTypeArgumentVariable.withLocation(
              typeParameter.location!.file,
              typeParameter.fileOffset,
              noLength));
    }
    if (superBoundedAttemptInverted != null && superBoundedAttempt != null) {
      (context ??= <LocatedMessage>[]).add(templateSuperBoundedHint
          .withArguments(superBoundedAttempt, superBoundedAttemptInverted,
              isNonNullableByDefault)
          .withLocation(fileUri, fileOffset, noLength));
    }
    addProblem(message, fileOffset, noLength, fileUri, context: context);
  }

  void checkTypesInField(
      SourceFieldBuilder fieldBuilder, TypeEnvironment typeEnvironment) {
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
      bool isOptionalPositional =
          formal.isOptionalPositional && formal.isPositional;
      bool isOptionalNamed = !formal.isRequiredNamed && formal.isNamed;
      bool isOptional = isOptionalPositional || isOptionalNamed;
      if (isOptional &&
          formal.variable!.type.isPotentiallyNonNullable &&
          !formal.hasDeclaredInitializer) {
        addProblem(
            templateOptionalNonNullableWithoutInitializerError.withArguments(
                formal.name, formal.variable!.type, isNonNullableByDefault),
            formal.charOffset,
            formal.name.length,
            formal.fileUri);
      }
    }
  }

  void checkTypesInFunctionBuilder(
      SourceFunctionBuilder procedureBuilder, TypeEnvironment typeEnvironment) {
    if (procedureBuilder.formals != null &&
        !(procedureBuilder.isAbstract || procedureBuilder.isExternal)) {
      checkInitializersInFormals(procedureBuilder.formals!, typeEnvironment);
    }
  }

  void checkTypesInConstructorBuilder(
      SourceConstructorBuilder constructorBuilder,
      List<FormalParameterBuilder>? formals,
      TypeEnvironment typeEnvironment) {
    if (!constructorBuilder.isExternal && formals != null) {
      checkInitializersInFormals(formals, typeEnvironment);
    }
  }

  void checkTypesInRedirectingFactoryBuilder(
      RedirectingFactoryBuilder redirectingFactoryBuilder,
      TypeEnvironment typeEnvironment) {
    // Default values are not required on redirecting factory constructors so
    // we don't call [checkInitializersInFormals].
  }

  void checkBoundsInType(
      DartType type, TypeEnvironment typeEnvironment, Uri fileUri, int offset,
      {bool? inferred, bool allowSuperBounded = true}) {
    List<TypeArgumentIssue> issues = findTypeArgumentIssues(
        type,
        typeEnvironment,
        isNonNullableByDefault
            ? SubtypeCheckMode.withNullabilities
            : SubtypeCheckMode.ignoringNullabilities,
        allowSuperBounded: allowSuperBounded,
        isNonNullableByDefault: library.isNonNullableByDefault,
        areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled);
    _reportTypeArgumentIssues(issues, fileUri, offset, inferred: inferred);
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
    assert(factory.isFactory || factory.isInlineClassMember);
    DartType constructedType = Substitution.fromPairs(
            node.target.function.typeParameters, node.arguments.types)
        .substituteType(node.target.function.returnType);
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
    Class? klass = node.target.enclosingClass;
    List<TypeParameter> parameters = node.target.function.typeParameters;
    List<DartType> arguments = node.arguments.types;
    // The following error is to be reported elsewhere.
    if (parameters.length != arguments.length) return;

    final DartType bottomType = isNonNullableByDefault
        ? const NeverType.nonNullable()
        : const NullType();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
        parameters,
        arguments,
        typeEnvironment,
        isNonNullableByDefault
            ? SubtypeCheckMode.withNullabilities
            : SubtypeCheckMode.ignoringNullabilities,
        bottomType,
        isNonNullableByDefault: library.isNonNullableByDefault,
        areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled);
    if (issues.isNotEmpty) {
      DartType? targetReceiver;
      if (klass != null) {
        targetReceiver =
            new InterfaceType(klass, klass.enclosingLibrary.nonNullable);
      }
      String targetName = node.target.name.text;
      _reportTypeArgumentIssues(issues, fileUri, node.fileOffset,
          typeArgumentsInfo: typeArgumentsInfo,
          targetReceiver: targetReceiver,
          targetName: targetName);
    }
  }

  void checkBoundsInMethodInvocation(
      DartType receiverType,
      TypeEnvironment typeEnvironment,
      ClassHierarchyBase classHierarchy,
      ClassHierarchyMembers membersHierarchy,
      Name name,
      Member? interfaceTarget,
      Arguments arguments,
      Uri fileUri,
      int offset) {
    if (arguments.types.isEmpty) return;
    Class klass;
    List<DartType> receiverTypeArguments;
    Map<TypeParameter, DartType> substitutionMap = <TypeParameter, DartType>{};
    if (receiverType is InterfaceType) {
      klass = receiverType.classNode;
      receiverTypeArguments = receiverType.typeArguments;
      for (int i = 0; i < receiverTypeArguments.length; ++i) {
        substitutionMap[klass.typeParameters[i]] = receiverTypeArguments[i];
      }
    } else {
      return;
    }
    // TODO(cstefantsova): Find a better way than relying on [interfaceTarget].
    Member? method =
        membersHierarchy.getDispatchTarget(klass, name) ?? interfaceTarget;
    // ignore: unnecessary_null_comparison
    if (method == null || method is! Procedure) {
      return;
    }
    if (klass != method.enclosingClass) {
      Supertype parent =
          classHierarchy.getClassAsInstanceOf(klass, method.enclosingClass!)!;
      klass = method.enclosingClass!;
      receiverTypeArguments = parent.typeArguments;
      Map<TypeParameter, DartType> instanceSubstitutionMap = substitutionMap;
      substitutionMap = <TypeParameter, DartType>{};
      for (int i = 0; i < receiverTypeArguments.length; ++i) {
        substitutionMap[klass.typeParameters[i]] =
            substitute(receiverTypeArguments[i], instanceSubstitutionMap);
      }
    }
    List<TypeParameter> methodParameters = method.function.typeParameters;
    // The error is to be reported elsewhere.
    if (methodParameters.length != arguments.types.length) return;
    List<TypeParameter> instantiatedMethodParameters =
        new List<TypeParameter>.generate(methodParameters.length, (int i) {
      TypeParameter instantiatedMethodParameter =
          new TypeParameter(methodParameters[i].name);
      substitutionMap[methodParameters[i]] =
          new TypeParameterType.forAlphaRenaming(
              methodParameters[i], instantiatedMethodParameter);
      return instantiatedMethodParameter;
    }, growable: false);
    for (int i = 0; i < instantiatedMethodParameters.length; ++i) {
      instantiatedMethodParameters[i].bound =
          substitute(methodParameters[i].bound, substitutionMap);
    }

    final DartType bottomType = isNonNullableByDefault
        ? const NeverType.nonNullable()
        : const NullType();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
        instantiatedMethodParameters,
        arguments.types,
        typeEnvironment,
        isNonNullableByDefault
            ? SubtypeCheckMode.withNullabilities
            : SubtypeCheckMode.ignoringNullabilities,
        bottomType,
        isNonNullableByDefault: library.isNonNullableByDefault,
        areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled);
    _reportTypeArgumentIssues(issues, fileUri, offset,
        typeArgumentsInfo: getTypeArgumentsInfo(arguments),
        targetReceiver: receiverType,
        targetName: name.text);
  }

  void checkBoundsInFunctionInvocation(
      TypeEnvironment typeEnvironment,
      FunctionType functionType,
      String? localName,
      Arguments arguments,
      Uri fileUri,
      int offset) {
    if (arguments.types.isEmpty) return;

    List<TypeParameter> functionTypeParameters = functionType.typeParameters;
    // The error is to be reported elsewhere.
    if (functionTypeParameters.length != arguments.types.length) return;
    final DartType bottomType = isNonNullableByDefault
        ? const NeverType.nonNullable()
        : const NullType();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
        functionTypeParameters,
        arguments.types,
        typeEnvironment,
        isNonNullableByDefault
            ? SubtypeCheckMode.withNullabilities
            : SubtypeCheckMode.ignoringNullabilities,
        bottomType,
        isNonNullableByDefault: library.isNonNullableByDefault,
        areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled);
    _reportTypeArgumentIssues(issues, fileUri, offset,
        typeArgumentsInfo: getTypeArgumentsInfo(arguments),
        // TODO(johnniwinther): Special-case messaging on function type
        //  invocation to avoid reference to 'call' and use the function type
        //  instead.
        targetName: localName ?? 'call');
  }

  void checkBoundsInInstantiation(
      TypeEnvironment typeEnvironment,
      FunctionType functionType,
      List<DartType> typeArguments,
      Uri fileUri,
      int offset,
      {required bool inferred}) {
    // ignore: unnecessary_null_comparison
    assert(inferred != null);
    if (typeArguments.isEmpty) return;

    List<TypeParameter> functionTypeParameters = functionType.typeParameters;
    // The error is to be reported elsewhere.
    if (functionTypeParameters.length != typeArguments.length) return;
    final DartType bottomType = isNonNullableByDefault
        ? const NeverType.nonNullable()
        : const NullType();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
        functionTypeParameters,
        typeArguments,
        typeEnvironment,
        isNonNullableByDefault
            ? SubtypeCheckMode.withNullabilities
            : SubtypeCheckMode.ignoringNullabilities,
        bottomType,
        isNonNullableByDefault: library.isNonNullableByDefault,
        areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled);
    _reportTypeArgumentIssues(issues, fileUri, offset,
        targetReceiver: functionType,
        typeArgumentsInfo: inferred
            ? const AllInferredTypeArgumentsInfo()
            : const NoneInferredTypeArgumentsInfo());
  }

  void checkTypesInOutline(TypeEnvironment typeEnvironment) {
    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        patchLibrary.checkTypesInOutline(typeEnvironment);
      }
    }

    Iterator<Builder> iterator = localMembersIterator;
    while (iterator.moveNext()) {
      Builder declaration = iterator.current;
      if (declaration is SourceFieldBuilder) {
        declaration.checkTypes(this, typeEnvironment);
      } else if (declaration is SourceProcedureBuilder) {
        declaration.checkTypes(this, typeEnvironment);
        if (declaration.isGetter) {
          Builder? setterDeclaration =
              scope.lookupLocalMember(declaration.name, setter: true);
          if (setterDeclaration != null) {
            checkGetterSetterTypes(declaration,
                setterDeclaration as ProcedureBuilder, typeEnvironment);
          }
        }
      } else if (declaration is SourceClassBuilder) {
        declaration.checkTypesInOutline(typeEnvironment);
      } else if (declaration is SourceExtensionBuilder) {
        declaration.checkTypesInOutline(typeEnvironment);
      } else if (declaration is SourceInlineClassBuilder) {
        declaration.checkTypesInOutline(typeEnvironment);
      } else if (declaration is SourceTypeAliasBuilder) {
        // Do nothing.
      } else {
        assert(
            declaration is! TypeDeclarationBuilder ||
                declaration is BuiltinTypeDeclarationBuilder,
            "Unexpected declaration ${declaration.runtimeType}");
      }
    }
    checkPendingBoundsChecks(typeEnvironment);
  }

  void computeShowHideElements(ClassMembersBuilder membersBuilder) {
    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        patchLibrary.computeShowHideElements(membersBuilder);
      }
    }

    assert(currentTypeParameterScopeBuilder.kind ==
        TypeParameterScopeKind.library);
    for (ExtensionBuilder _extensionBuilder
        in currentTypeParameterScopeBuilder.extensions!) {
      ExtensionBuilder extensionBuilder = _extensionBuilder;
      if (extensionBuilder is! SourceExtensionBuilder) continue;
      DartType onType = extensionBuilder.extension.onType;
      if (onType is InterfaceType) {
        ExtensionTypeShowHideClause showHideClause =
            extensionBuilder.extension.showHideClause ??
                new ExtensionTypeShowHideClause();

        // TODO(cstefantsova): Handle private names.
        List<Supertype> supertypes = membersBuilder.hierarchyBuilder
            .getNodeFromClass(onType.classNode)
            .superclasses;
        Map<String, Supertype> supertypesByName = <String, Supertype>{};
        for (Supertype supertype in supertypes) {
          // TODO(cstefantsova): Should only non-generic supertypes be allowed?
          supertypesByName[supertype.classNode.name] = supertype;
        }

        // Handling elements of the 'show' clause.
        for (String memberOrTypeName in extensionBuilder
            .extensionTypeShowHideClauseBuilder.shownMembersOrTypes) {
          Member? getableMember = membersBuilder.getInterfaceMember(
              onType.classNode, new Name(memberOrTypeName));
          if (getableMember != null) {
            if (getableMember is Field) {
              showHideClause.shownGetters.add(getableMember.getterReference);
            } else if (getableMember.hasGetter) {
              showHideClause.shownGetters.add(getableMember.reference);
            }
          }
          if (getableMember is Procedure &&
              getableMember.kind == ProcedureKind.Method) {
            showHideClause.shownMethods.add(getableMember.reference);
          }
          Member? setableMember = membersBuilder.getInterfaceMember(
              onType.classNode, new Name(memberOrTypeName),
              setter: true);
          if (setableMember != null) {
            if (setableMember is Field) {
              if (setableMember.setterReference != null) {
                showHideClause.shownSetters.add(setableMember.setterReference!);
              } else {
                // TODO(cstefantsova): Report an error.
              }
            } else if (setableMember.hasSetter) {
              showHideClause.shownSetters.add(setableMember.reference);
            } else {
              // TODO(cstefantsova): Report an error.
            }
          }
          if (getableMember == null && setableMember == null) {
            if (supertypesByName.containsKey(memberOrTypeName)) {
              showHideClause.shownSupertypes
                  .add(supertypesByName[memberOrTypeName]!);
            } else {
              // TODO(cstefantsova): Report an error.
            }
          }
        }
        for (String getterName in extensionBuilder
            .extensionTypeShowHideClauseBuilder.shownGetters) {
          Member? member = membersBuilder.getInterfaceMember(
              onType.classNode, new Name(getterName));
          if (member != null) {
            if (member is Field) {
              showHideClause.shownGetters.add(member.getterReference);
            } else if (member.hasGetter) {
              showHideClause.shownGetters.add(member.reference);
            } else {
              // TODO(cstefantsova): Handle the erroneous case.
            }
          } else {
            // TODO(cstefantsova): Handle the erroneous case.
          }
        }
        for (String setterName in extensionBuilder
            .extensionTypeShowHideClauseBuilder.shownSetters) {
          Member? member = membersBuilder.getInterfaceMember(
              onType.classNode, new Name(setterName),
              setter: true);
          if (member != null) {
            if (member is Field) {
              if (member.setterReference != null) {
                showHideClause.shownSetters.add(member.setterReference!);
              } else {
                // TODO(cstefantsova): Report an error.
              }
            } else if (member.hasSetter) {
              showHideClause.shownSetters.add(member.reference);
            } else {
              // TODO(cstefantsova): Report an error.
            }
          } else {
            // TODO(cstefantsova): Search for a non-setter and report an error.
          }
        }
        for (Operator operator in extensionBuilder
            .extensionTypeShowHideClauseBuilder.shownOperators) {
          Member? member = membersBuilder.getInterfaceMember(
              onType.classNode, new Name(operatorToString(operator)));
          if (member != null) {
            showHideClause.shownOperators.add(member.reference);
          } else {
            // TODO(cstefantsova): Handle the erroneous case.
          }
        }

        // TODO(cstefantsova): Add a helper function to share logic between
        // handling the 'show' and 'hide' parts.

        // Handling elements of the 'hide' clause.
        for (String memberOrTypeName in extensionBuilder
            .extensionTypeShowHideClauseBuilder.hiddenMembersOrTypes) {
          Member? getableMember = membersBuilder.getInterfaceMember(
              onType.classNode, new Name(memberOrTypeName));
          if (getableMember != null) {
            if (getableMember is Field) {
              showHideClause.hiddenGetters.add(getableMember.getterReference);
            } else if (getableMember.hasGetter) {
              showHideClause.hiddenGetters.add(getableMember.reference);
            }
          }
          if (getableMember is Procedure &&
              getableMember.kind == ProcedureKind.Method) {
            showHideClause.hiddenMethods.add(getableMember.reference);
          }
          Member? setableMember = membersBuilder.getInterfaceMember(
              onType.classNode, new Name(memberOrTypeName),
              setter: true);
          if (setableMember != null) {
            if (setableMember is Field) {
              if (setableMember.setterReference != null) {
                showHideClause.hiddenSetters
                    .add(setableMember.setterReference!);
              } else {
                // TODO(cstefantsova): Report an error.
              }
            } else if (setableMember.hasSetter) {
              showHideClause.hiddenSetters.add(setableMember.reference);
            } else {
              // TODO(cstefantsova): Report an error.
            }
          }
          if (getableMember == null && setableMember == null) {
            if (supertypesByName.containsKey(memberOrTypeName)) {
              showHideClause.hiddenSupertypes
                  .add(supertypesByName[memberOrTypeName]!);
            } else {
              // TODO(cstefantsova): Report an error.
            }
          }
        }
        for (String getterName in extensionBuilder
            .extensionTypeShowHideClauseBuilder.hiddenGetters) {
          Member? member = membersBuilder.getInterfaceMember(
              onType.classNode, new Name(getterName));
          if (member != null) {
            if (member is Field) {
              showHideClause.hiddenGetters.add(member.getterReference);
            } else if (member.hasGetter) {
              showHideClause.hiddenGetters.add(member.reference);
            } else {
              // TODO(cstefantsova): Handle the erroneous case.
            }
          } else {
            // TODO(cstefantsova): Handle the erroneous case.
          }
        }
        for (String setterName in extensionBuilder
            .extensionTypeShowHideClauseBuilder.hiddenSetters) {
          Member? member = membersBuilder.getInterfaceMember(
              onType.classNode, new Name(setterName),
              setter: true);
          if (member != null) {
            if (member is Field) {
              if (member.setterReference != null) {
                showHideClause.hiddenSetters.add(member.setterReference!);
              } else {
                // TODO(cstefantsova): Report an error.
              }
            } else if (member.hasSetter) {
              showHideClause.hiddenSetters.add(member.reference);
            } else {
              // TODO(cstefantsova): Report an error.
            }
          } else {
            // TODO(cstefantsova): Search for a non-setter and report an error.
          }
        }
        for (Operator operator in extensionBuilder
            .extensionTypeShowHideClauseBuilder.hiddenOperators) {
          Member? member = membersBuilder.getInterfaceMember(
              onType.classNode, new Name(operatorToString(operator)));
          if (member != null) {
            showHideClause.hiddenOperators.add(member.reference);
          } else {
            // TODO(cstefantsova): Handle the erroneous case.
          }
        }

        extensionBuilder.extension.showHideClause ??= showHideClause;
      }
    }
  }

  void forEachExtensionInScope(void Function(ExtensionBuilder) f) {
    if (_extensionsInScope == null) {
      _extensionsInScope = <ExtensionBuilder>{};
      scope.forEachExtension((e) {
        if (!e.extension.isExtensionTypeDeclaration) {
          _extensionsInScope!.add(e);
        }
      });
      if (_prefixBuilders != null) {
        for (PrefixBuilder prefix in _prefixBuilders!) {
          prefix.exportScope.forEachExtension((e) {
            if (!e.extension.isExtensionTypeDeclaration) {
              _extensionsInScope!.add(e);
            }
          });
        }
      }
    }
    _extensionsInScope!.forEach(f);
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
  void setCurrentClassName(String? name) {
    if (name == null) {
      _currentClassReferencesFromIndexed = null;
    } else if (referencesFrom != null) {
      _currentClassReferencesFromIndexed =
          referencesFromIndexed!.lookupIndexedClass(name);
    }
  }

  void registerPendingNullability(
      Uri fileUri, int charOffset, TypeParameterType type) {
    _pendingNullabilities
        .add(new PendingNullability(fileUri, charOffset, type));
  }

  bool hasPendingNullability(DartType type) {
    type = _peelOffFutureOr(type);
    if (type is TypeParameterType) {
      for (PendingNullability pendingNullability in _pendingNullabilities) {
        if (pendingNullability.type == type) {
          return true;
        }
      }
    }
    return false;
  }

  static DartType _peelOffFutureOr(DartType type) {
    while (type is FutureOrType) {
      type = type.typeArgument;
    }
    return type;
  }

  void registerBoundsCheck(
      DartType type, Uri fileUri, int charOffset, TypeUse typeUse,
      {required bool inferred}) {
    _pendingBoundsChecks.add(new PendingBoundsCheck(
        type, fileUri, charOffset, typeUse,
        inferred: inferred));
  }

  void registerGenericFunctionTypeCheck(
      TypedefType type, Uri fileUri, int charOffset) {
    _pendingGenericFunctionTypeChecks
        .add(new GenericFunctionTypeCheck(type, fileUri, charOffset));
  }

  /// Performs delayed bounds checks.
  void checkPendingBoundsChecks(TypeEnvironment typeEnvironment) {
    for (PendingBoundsCheck pendingBoundsCheck in _pendingBoundsChecks) {
      switch (pendingBoundsCheck.typeUse) {
        case TypeUse.literalTypeArgument:
        case TypeUse.variableType:
        case TypeUse.typeParameterBound:
        case TypeUse.parameterType:
        case TypeUse.recordEntryType:
        case TypeUse.fieldType:
        case TypeUse.returnType:
        case TypeUse.isType:
        case TypeUse.asType:
        case TypeUse.objectPatternType:
        case TypeUse.catchType:
        case TypeUse.constructorTypeArgument:
        case TypeUse.redirectionTypeArgument:
        case TypeUse.tearOffTypeArgument:
        case TypeUse.invocationTypeArgument:
        case TypeUse.typeLiteral:
        case TypeUse.extensionOnType:
        case TypeUse.typeArgument:
          checkBoundsInType(pendingBoundsCheck.type, typeEnvironment,
              pendingBoundsCheck.fileUri, pendingBoundsCheck.charOffset,
              inferred: pendingBoundsCheck.inferred, allowSuperBounded: true);
          break;
        case TypeUse.typedefAlias:
        case TypeUse.superType:
        case TypeUse.mixedInType:
          checkBoundsInType(pendingBoundsCheck.type, typeEnvironment,
              pendingBoundsCheck.fileUri, pendingBoundsCheck.charOffset,
              inferred: pendingBoundsCheck.inferred, allowSuperBounded: false);
          break;
        case TypeUse.instantiation:
          // TODO(johnniwinther): Should we allow super bounded tear offs of
          // non-proper renames?
          checkBoundsInType(pendingBoundsCheck.type, typeEnvironment,
              pendingBoundsCheck.fileUri, pendingBoundsCheck.charOffset,
              inferred: pendingBoundsCheck.inferred, allowSuperBounded: true);
          break;
        case TypeUse.enumSelfType:
          // TODO(johnniwinther): Check/create this type as regular bounded i2b.
          /*
            checkBoundsInType(pendingBoundsCheck.type, typeEnvironment,
                pendingBoundsCheck.fileUri, pendingBoundsCheck.charOffset,
                inferred: pendingBoundsCheck.inferred,
                allowSuperBounded: false);
          */
          break;
        case TypeUse.macroTypeArgument:
        case TypeUse.typeParameterDefaultType:
        case TypeUse.defaultTypeAsTypeArgument:
        case TypeUse.deferredTypeError:
          break;
      }
    }
    _pendingBoundsChecks.clear();

    for (GenericFunctionTypeCheck genericFunctionTypeCheck
        in _pendingGenericFunctionTypeChecks) {
      checkGenericFunctionTypeAsTypeArgumentThroughTypedef(
          genericFunctionTypeCheck.type,
          genericFunctionTypeCheck.fileUri,
          genericFunctionTypeCheck.charOffset);
    }
    _pendingGenericFunctionTypeChecks.clear();
  }

  /// Reports an error if [type] contains is a generic function type used as
  /// a type argument through its alias.
  ///
  /// For instance
  ///
  ///   typedef A = B<void Function<T>(T)>;
  ///
  /// here `A` doesn't use a generic function as type argument directly, but
  /// its unaliased value `B<void Function<T>(T)>` does.
  ///
  /// This is used for reporting generic function types used as a type argument,
  /// which was disallowed before the 'generic-metadata' feature was enabled.
  void checkGenericFunctionTypeAsTypeArgumentThroughTypedef(
      TypedefType type, Uri fileUri, int fileOffset) {
    assert(!libraryFeatures.genericMetadata.isEnabled);
    if (!hasGenericFunctionTypeAsTypeArgument(type)) {
      DartType unaliased = type.unalias;
      if (hasGenericFunctionTypeAsTypeArgument(unaliased)) {
        addProblem(
            templateGenericFunctionTypeAsTypeArgumentThroughTypedef
                .withArguments(unaliased, type, isNonNullableByDefault),
            fileOffset,
            noLength,
            fileUri);
      }
    }
  }

  void installTypedefTearOffs() {
    Iterable<SourceLibraryBuilder>? patches = this.patchLibraries;
    if (patches != null) {
      for (SourceLibraryBuilder patchLibrary in patches) {
        patchLibrary.installTypedefTearOffs();
      }
    }

    Iterator<SourceTypeAliasBuilder> iterator = localMembersIteratorOfType();
    while (iterator.moveNext()) {
      SourceTypeAliasBuilder declaration = iterator.current;
      declaration.buildTypedefTearOffs(this, (Procedure procedure) {
        procedure.isStatic = true;
        if (!declaration.isPatch && !declaration.isDuplicate) {
          library.addProcedure(procedure);
        }
      });
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
  inlineClassDeclaration,
  typedef,
  staticMethod,
  instanceMethod,
  constructor,
  topLevelMethod,
  factoryMethod,
  functionType,
  enumDeclaration,
}

extension on TypeParameterScopeBuilder {
  /// Returns the [ContainerName] corresponding to this type parameter scope,
  /// if any.
  ContainerName? get containerName {
    switch (kind) {
      case TypeParameterScopeKind.library:
        return null;
      case TypeParameterScopeKind.classOrNamedMixinApplication:
      case TypeParameterScopeKind.classDeclaration:
      case TypeParameterScopeKind.mixinDeclaration:
      case TypeParameterScopeKind.unnamedMixinApplication:
      case TypeParameterScopeKind.namedMixinApplication:
      case TypeParameterScopeKind.enumDeclaration:
      case TypeParameterScopeKind.inlineClassDeclaration:
        return new ClassName(name);
      case TypeParameterScopeKind.extensionDeclaration:
        return extensionName;
      case TypeParameterScopeKind.typedef:
      case TypeParameterScopeKind.staticMethod:
      case TypeParameterScopeKind.instanceMethod:
      case TypeParameterScopeKind.constructor:
      case TypeParameterScopeKind.topLevelMethod:
      case TypeParameterScopeKind.factoryMethod:
      case TypeParameterScopeKind.functionType:
        throw new UnsupportedError("Unexpected field container: ${this}");
    }
  }

  /// Returns the [ContainerType] corresponding to this type parameter scope.
  ContainerType get containerType {
    switch (kind) {
      case TypeParameterScopeKind.library:
        return ContainerType.Library;
      case TypeParameterScopeKind.classOrNamedMixinApplication:
      case TypeParameterScopeKind.classDeclaration:
      case TypeParameterScopeKind.mixinDeclaration:
      case TypeParameterScopeKind.unnamedMixinApplication:
      case TypeParameterScopeKind.namedMixinApplication:
      case TypeParameterScopeKind.enumDeclaration:
        return ContainerType.Class;
      case TypeParameterScopeKind.extensionDeclaration:
        return ContainerType.Extension;
      case TypeParameterScopeKind.inlineClassDeclaration:
        return ContainerType.InlineClass;
      case TypeParameterScopeKind.typedef:
      case TypeParameterScopeKind.staticMethod:
      case TypeParameterScopeKind.instanceMethod:
      case TypeParameterScopeKind.constructor:
      case TypeParameterScopeKind.topLevelMethod:
      case TypeParameterScopeKind.factoryMethod:
      case TypeParameterScopeKind.functionType:
        throw new UnsupportedError("Unexpected field container: ${this}");
    }
  }
}

/// A builder object preparing for building declarations that can introduce type
/// parameter and/or members.
///
/// Unlike [Scope], this scope is used during construction of builders to
/// ensure types and members are added to and resolved in the correct location.
class TypeParameterScopeBuilder {
  TypeParameterScopeKind _kind;

  final TypeParameterScopeBuilder? parent;

  final Map<String, Builder>? members;

  final Map<String, MemberBuilder>? constructors;

  final Map<String, MemberBuilder>? setters;

  final Set<ExtensionBuilder>? extensions;

  final List<NamedTypeBuilder> unresolvedNamedTypes = <NamedTypeBuilder>[];

  // TODO(johnniwinther): Stop using [_name] for determining the declaration
  // kind.
  String _name;

  ExtensionName? _extensionName;

  /// Offset of name token, updated by the outline builder along
  /// with the name as the current declaration changes.
  int _charOffset;

  List<TypeVariableBuilder>? _typeVariables;

  /// The type of `this` in instance methods declared in extension declarations.
  ///
  /// Instance methods declared in extension declarations methods are extended
  /// with a synthesized parameter of this type.
  TypeBuilder? _extensionThisType;

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
    // ignore: unnecessary_null_comparison
    assert(_name != null);
  }

  TypeParameterScopeBuilder.library()
      : this(
            TypeParameterScopeKind.library,
            <String, Builder>{},
            <String, MemberBuilder>{},
            null,
            // No support for constructors in library scopes.
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
        null,
        // No support for extensions in nested scopes.
        name,
        -1,
        this);
  }

  /// Registers that this builder is preparing for a class declaration with the
  /// given [name] and [typeVariables] located [charOffset].
  void markAsClassDeclaration(
      String name, int charOffset, List<TypeVariableBuilder>? typeVariables) {
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
      String name, int charOffset, List<TypeVariableBuilder>? typeVariables) {
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
      String name, int charOffset, List<TypeVariableBuilder>? typeVariables) {
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
      String? name, int charOffset, List<TypeVariableBuilder>? typeVariables) {
    assert(_kind == TypeParameterScopeKind.extensionDeclaration,
        "Unexpected declaration kind: $_kind");
    _extensionName = name != null
        ? new FixedExtensionName(name)
        : new UnnamedExtensionName();
    _name = _extensionName!.name;
    _charOffset = charOffset;
    _typeVariables = typeVariables;
  }

  /// Registers that this builder is preparing for an inline class declaration
  /// with the given [name] and [typeVariables] located [charOffset].
  void markAsInlineClassDeclaration(
      String name, int charOffset, List<TypeVariableBuilder>? typeVariables) {
    assert(_kind == TypeParameterScopeKind.classOrNamedMixinApplication,
        "Unexpected declaration kind: $_kind");
    _kind = TypeParameterScopeKind.inlineClassDeclaration;
    _name = name;
    _charOffset = charOffset;
    _typeVariables = typeVariables;
  }

  /// Returns `true` if this scope builder is for an unnamed extension
  /// declaration.
  bool get isUnnamedExtension => extensionName?.isUnnamedExtension ?? false;

  /// Registers that this builder is preparing for an enum declaration with
  /// the given [name] and [typeVariables] located [charOffset].
  void markAsEnumDeclaration(
      String name, int charOffset, List<TypeVariableBuilder>? typeVariables) {
    assert(_kind == TypeParameterScopeKind.enumDeclaration,
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

  ExtensionName? get extensionName => _extensionName;

  int get charOffset => _charOffset;

  List<TypeVariableBuilder>? get typeVariables => _typeVariables;

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
    return _extensionThisType!;
  }

  /// Adds the yet unresolved [type] to this scope builder.
  ///
  /// Unresolved type will be resolved through [resolveNamedTypes] when the
  /// scope is fully built. This allows for resolving self-referencing types,
  /// like type parameter used in their own bound, for instance
  /// `<T extends A<T>>`.
  void registerUnresolvedNamedType(NamedTypeBuilder type) {
    unresolvedNamedTypes.add(type);
  }

  /// Resolves type variables in [unresolvedNamedTypes] and propagate other
  /// types to [parent].
  void resolveNamedTypes(
      List<TypeVariableBuilder>? typeVariables, SourceLibraryBuilder library) {
    Map<String, TypeVariableBuilder>? map;
    if (typeVariables != null) {
      map = <String, TypeVariableBuilder>{};
      for (TypeVariableBuilder builder in typeVariables) {
        map[builder.name] = builder;
      }
    }
    Scope? scope;
    for (NamedTypeBuilder namedTypeBuilder in unresolvedNamedTypes) {
      Object? nameOrQualified = namedTypeBuilder.name;
      String? name = nameOrQualified is QualifiedName
          ? nameOrQualified.qualifier as String
          : nameOrQualified as String?;
      Builder? declaration;
      if (name != null) {
        if (members != null) {
          declaration = members![name];
        }
        if (declaration == null && map != null) {
          declaration = map[name];
        }
      }
      if (declaration == null) {
        // Since name didn't resolve in this scope, propagate it to the
        // parent declaration.
        parent!.registerUnresolvedNamedType(namedTypeBuilder);
      } else if (nameOrQualified is QualifiedName) {
        // Attempt to use a member or type variable as a prefix.
        Message message = templateNotAPrefixInTypeAnnotation.withArguments(
            flattenName(nameOrQualified.qualifier, namedTypeBuilder.charOffset!,
                namedTypeBuilder.fileUri!),
            nameOrQualified.name);
        library.addProblem(
            message,
            namedTypeBuilder.charOffset!,
            nameOrQualified.endCharOffset - namedTypeBuilder.charOffset!,
            namedTypeBuilder.fileUri!);
        namedTypeBuilder.bind(
            library,
            namedTypeBuilder.buildInvalidTypeDeclarationBuilder(
                message.withLocation(
                    namedTypeBuilder.fileUri!,
                    namedTypeBuilder.charOffset!,
                    nameOrQualified.endCharOffset -
                        namedTypeBuilder.charOffset!)));
      } else {
        scope ??= toScope(null).withTypeVariables(typeVariables);
        namedTypeBuilder.resolveIn(scope, namedTypeBuilder.charOffset!,
            namedTypeBuilder.fileUri!, library);
      }
    }
    unresolvedNamedTypes.clear();
  }

  Scope toScope(Scope? parent,
      {Map<String, Builder>? omittedTypeDeclarationBuilders}) {
    if (omittedTypeDeclarationBuilders != null &&
        omittedTypeDeclarationBuilders.isNotEmpty) {
      parent = new Scope(
          kind: ScopeKind.typeParameters,
          local: omittedTypeDeclarationBuilders,
          parent: parent,
          debugName: 'omitted-types',
          isModifiable: false);
    }
    return new Scope(
        kind: ScopeKind.typeParameters,
        local: members ?? const {},
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
  final Token? initializerToken;
  final Token? beforeLast;
  final int charEndOffset;

  const FieldInfo(this.name, this.charOffset, this.initializerToken,
      this.beforeLast, this.charEndOffset);
}

Uri computeLibraryUri(Builder declaration) {
  Builder? current = declaration;
  while (current != null) {
    if (current is LibraryBuilder) return current.importUri;
    current = current.parent;
  }
  return unhandled("no library parent", "${declaration.runtimeType}",
      declaration.charOffset, declaration.fileUri);
}

String extractName(Object name) {
  return name is QualifiedName ? name.name : name as String;
}

class PostponedProblem {
  final Message message;
  final int charOffset;
  final int length;
  final Uri fileUri;

  PostponedProblem(this.message, this.charOffset, this.length, this.fileUri);
}

class LanguageVersion {
  final Version version;
  final Uri? fileUri;
  final int charOffset;
  final int charCount;
  bool isFinal = false;

  LanguageVersion(this.version, this.fileUri, this.charOffset, this.charCount);

  bool get isExplicit => true;

  bool get valid => true;

  @override
  int get hashCode => version.hashCode * 13 + isExplicit.hashCode * 19;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageVersion &&
        version == other.version &&
        isExplicit == other.isExplicit;
  }

  @override
  String toString() {
    return 'LanguageVersion(version=$version,isExplicit=$isExplicit,'
        'fileUri=$fileUri,charOffset=$charOffset,charCount=$charCount)';
  }
}

class InvalidLanguageVersion implements LanguageVersion {
  @override
  final Uri fileUri;
  @override
  final int charOffset;
  @override
  final int charCount;
  @override
  final Version version;
  @override
  final bool isExplicit;
  @override
  bool isFinal = false;

  InvalidLanguageVersion(this.fileUri, this.charOffset, this.charCount,
      this.version, this.isExplicit);

  @override
  bool get valid => false;

  @override
  int get hashCode => isExplicit.hashCode * 19;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvalidLanguageVersion && isExplicit == other.isExplicit;
  }

  @override
  String toString() {
    return 'InvalidLanguageVersion(isExplicit=$isExplicit,'
        'fileUri=$fileUri,charOffset=$charOffset,charCount=$charCount)';
  }
}

class ImplicitLanguageVersion implements LanguageVersion {
  @override
  final Version version;
  @override
  bool isFinal = false;

  ImplicitLanguageVersion(this.version);

  @override
  bool get valid => true;

  @override
  Uri? get fileUri => null;

  @override
  int get charOffset => -1;

  @override
  int get charCount => noLength;

  @override
  bool get isExplicit => false;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImplicitLanguageVersion && version == other.version;
  }

  @override
  String toString() {
    return 'ImplicitLanguageVersion(version=$version)';
  }
}

List<TypeVariableBuilder> _sortTypeVariablesTopologically(
    Iterable<TypeVariableBuilder> typeVariables) {
  Set<TypeVariableBuilder> unhandled = new Set<TypeVariableBuilder>.identity()
    ..addAll(typeVariables);
  List<TypeVariableBuilder> result = <TypeVariableBuilder>[];
  while (unhandled.isNotEmpty) {
    TypeVariableBuilder rootVariable = unhandled.first;
    unhandled.remove(rootVariable);
    if (rootVariable.bound != null) {
      _sortTypeVariablesTopologicallyFromRoot(
          rootVariable.bound!, unhandled, result);
    }
    result.add(rootVariable);
  }
  return result;
}

void _sortTypeVariablesTopologicallyFromRoot(TypeBuilder root,
    Set<TypeVariableBuilder> unhandled, List<TypeVariableBuilder> result) {
  // ignore: unnecessary_null_comparison
  assert(root != null);

  List<TypeVariableBuilder>? typeVariables;
  List<TypeBuilder>? internalDependents;

  if (root is NamedTypeBuilder) {
    TypeDeclarationBuilder? declaration = root.declaration;
    if (declaration is ClassBuilder) {
      if (declaration.typeVariables != null &&
          declaration.typeVariables!.isNotEmpty) {
        typeVariables = declaration.typeVariables;
      }
    } else if (declaration is TypeAliasBuilder) {
      if (declaration.typeVariables != null &&
          declaration.typeVariables!.isNotEmpty) {
        typeVariables = declaration.typeVariables;
      }
      internalDependents = <TypeBuilder>[declaration.type];
    } else if (declaration is TypeVariableBuilder) {
      typeVariables = <TypeVariableBuilder>[declaration];
    }
  } else if (root is FunctionTypeBuilder) {
    if (root.typeVariables != null && root.typeVariables!.isNotEmpty) {
      typeVariables = root.typeVariables;
    }
    if (root.formals != null && root.formals!.isNotEmpty) {
      internalDependents = <TypeBuilder>[];
      for (ParameterBuilder formal in root.formals!) {
        internalDependents.add(formal.type);
      }
    }
    if (root.returnType is! OmittedTypeBuilder) {
      (internalDependents ??= <TypeBuilder>[]).add(root.returnType);
    }
  }

  if (typeVariables != null && typeVariables.isNotEmpty) {
    for (TypeVariableBuilder variable in typeVariables) {
      if (unhandled.contains(variable)) {
        unhandled.remove(variable);
        if (variable.bound != null) {
          _sortTypeVariablesTopologicallyFromRoot(
              variable.bound!, unhandled, result);
        }
        result.add(variable);
      }
    }
  }
  if (internalDependents != null && internalDependents.isNotEmpty) {
    for (TypeBuilder type in internalDependents) {
      _sortTypeVariablesTopologicallyFromRoot(type, unhandled, result);
    }
  }
}

class PendingNullability {
  final Uri fileUri;
  final int charOffset;
  final TypeParameterType type;

  PendingNullability(this.fileUri, this.charOffset, this.type);

  @override
  String toString() {
    return "PendingNullability(${fileUri}, ${charOffset}, ${type})";
  }
}

class PendingBoundsCheck {
  final DartType type;
  final Uri fileUri;
  final int charOffset;
  final TypeUse typeUse;
  final bool inferred;

  PendingBoundsCheck(this.type, this.fileUri, this.charOffset, this.typeUse,
      {required this.inferred});
}

class GenericFunctionTypeCheck {
  final TypedefType type;
  final Uri fileUri;
  final int charOffset;

  GenericFunctionTypeCheck(this.type, this.fileUri, this.charOffset);
}

class LibraryAccess {
  final LibraryBuilder accessor;
  final Uri fileUri;
  final int charOffset;
  final int length;

  LibraryAccess(this.accessor, this.fileUri, this.charOffset, this.length);
}

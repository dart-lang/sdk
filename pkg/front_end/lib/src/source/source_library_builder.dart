// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonEncode, utf8;
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/field_promotability.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_operations.dart';
import 'package:kernel/ast.dart' hide Combinator, MapLiteralEntry;
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClassHierarchyBase, ClassHierarchyMembers;
import 'package:kernel/clone.dart' show CloneVisitorNotMembers;
import 'package:kernel/reference_from_index.dart' show IndexedLibrary;
import 'package:kernel/src/bounds_checks.dart'
    show
        TypeArgumentIssue,
        findTypeArgumentIssues,
        findTypeArgumentIssuesForInvocation,
        getGenericTypeName,
        hasGenericFunctionTypeAsTypeArgument;
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart'
    show SubtypeCheckMode, TypeEnvironment;

import '../api_prototype/experimental_flags.dart';
import '../base/combinator.dart' show CombinatorBuilder;
import '../base/export.dart' show Export;
import '../base/import.dart' show Import;
import '../base/messages.dart';
import '../base/name_space.dart';
import '../base/nnbd_mode.dart';
import '../base/problems.dart' show unexpected, unhandled;
import '../base/scope.dart';
import '../base/uri_offset.dart';
import '../base/uris.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/dynamic_type_declaration_builder.dart';
import '../builder/field_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/named_type_builder.dart';
import '../builder/never_type_declaration_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_builder.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/macro/macro.dart';
import '../kernel/type_algorithms.dart' show ComputeDefaultTypeContext;
import '../kernel/utils.dart'
    show
        compareProcedures,
        exportDynamicSentinel,
        exportNeverSentinel,
        toKernelCombinators,
        unserializableExportName;
import 'builder_factory.dart';
import 'class_declaration.dart';
import 'name_scheme.dart';
import 'offset_map.dart';
import 'outline_builder.dart';
import 'source_builder_factory.dart';
import 'source_builder_mixins.dart';
import 'source_class_builder.dart' show SourceClassBuilder;
import 'source_constructor_builder.dart';
import 'source_extension_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_factory_builder.dart';
import 'source_field_builder.dart';
import 'source_function_builder.dart';
import 'source_loader.dart'
    show CompilationPhaseForProblemReporting, SourceLoader;
import 'source_member_builder.dart';
import 'source_procedure_builder.dart';
import 'source_type_alias_builder.dart';
import 'type_parameter_scope_builder.dart';

part 'source_compilation_unit.dart';

/// Enum that define what state a source library is in, in terms of how far
/// in the compilation it has progressed. This is used to document and assert
/// the requirements of individual methods within the [SourceLibraryBuilder].
enum SourceLibraryBuilderState {
  /// The builder is in its initial state.
  ///
  /// The builder is known to be a library and not a part in this state.
  initial,

  /// The name space has been built for the library.
  nameSpaceBuilt,

  /// Scopes have been built for the library.
  scopesBuilt,

  /// Initial export scope derived from the name space has been built.
  initialExportScopesBuilt,

  /// Full export scope has been built.
  exportScopesBuilt,

  /// Type in the outline have been resolved.
  resolvedTypes,

  /// Default types of type parameters have been computed.
  defaultTypesComputed,

  /// Type parameters have been collected to be checked for cyclic dependencies
  /// and their nullability to be computed.
  unboundTypeParametersCollected,

  /// The AST nodes for the outline have been built.
  outlineNodesBuilt,
  ;

  bool operator <(SourceLibraryBuilderState other) => index < other.index;

  // Coverage-ignore(suite): Not run.
  bool operator <=(SourceLibraryBuilderState other) => index <= other.index;

  // Coverage-ignore(suite): Not run.
  bool operator >(SourceLibraryBuilderState other) => index > other.index;

  bool operator >=(SourceLibraryBuilderState other) => index >= other.index;
}

class SourceLibraryBuilder extends LibraryBuilderImpl {
  SourceLibraryBuilderState _state = SourceLibraryBuilderState.initial;

  final SourceCompilationUnit compilationUnit;

  final LookupScope _importScope;

  final NameSpace _prefixNameSpace;

  final LookupScope _prefixScope;

  final LibraryNameSpaceBuilder _libraryNameSpaceBuilder;

  NameSpace? _nameSpace;

  final NameSpace _exportNameSpace;

  @override
  final SourceLoader loader;

  final List<SourceCompilationUnit> _parts = [];

  @override
  final Uri fileUri;

  final Uri? _packageUri;

  // Coverage-ignore(suite): Not run.
  Uri? get packageUriForTesting => _packageUri;

  @override
  LibraryBuilder? get partOfLibrary => compilationUnit.partOfLibrary;

  List<MetadataBuilder>? get metadata => compilationUnit.metadata;

  @override
  final Library library;

  final LibraryName libraryName;

  final SourceLibraryBuilder? _immediateOrigin;

  final List<PendingBoundsCheck> _pendingBoundsChecks = [];
  final List<GenericFunctionTypeCheck> _pendingGenericFunctionTypeChecks = [];

  // A list of alternating forwarders and the procedures they were generated
  // for.  Note that it may not include a forwarder-origin pair in cases when
  // the former does not need to be updated after the body of the latter was
  // built.
  final List<Procedure> forwardersOrigins = <Procedure>[];

  // A library to use for Names generated when compiling code in this library.
  // This allows code generated in one library to use the private namespace of
  // another, for example during expression compilation (debugging).
  Library get nameOrigin =>
      _nameOrigin
          // Coverage-ignore(suite): Not run.
          ?.library ??
      library;

  @override
  LibraryBuilder get nameOriginBuilder => _nameOrigin ?? this;
  final LibraryBuilder? _nameOrigin;

  /// Index of the library we use references for.
  IndexedLibrary? get indexedLibrary => compilationUnit.indexedLibrary;

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

  List<SourceLibraryBuilder>? _augmentationLibraries;

  int augmentationIndex = 0;

  MergedLibraryScope? _mergedScope;

  /// If `null`, [SourceLoader.computeFieldPromotability] hasn't been called
  /// yet, or field promotion is disabled for this library.  If not `null`,
  /// Information about which fields are promotable in this library, or `null`
  /// if [SourceLoader.computeFieldPromotability] hasn't been called.
  FieldNonPromotabilityInfo? fieldNonPromotabilityInfo;

  /// Redirecting factory builders defined in the library. They should be
  /// collected as they are built, so that we can build the outline expressions
  /// in the right order.
  ///
  /// See [SourceLoader.buildOutlineExpressions] for details.
  List<RedirectingFactoryBuilder>? redirectingFactoryBuilders;

  // TODO(johnniwinther): Remove this.
  final Map<String, List<Builder>>? augmentations;

  // TODO(johnniwinther): Remove this.
  final Map<String, List<Builder>>? setterAugmentations;

  /// Set of extension declarations in scope. This is computed lazily in
  /// [forEachExtensionInScope].
  Set<ExtensionBuilder>? _extensionsInScope;

  factory SourceLibraryBuilder(
      {required SourceCompilationUnit compilationUnit,
      required Uri importUri,
      required Uri fileUri,
      Uri? packageUri,
      required Uri originImportUri,
      required LanguageVersion packageLanguageVersion,
      required SourceLoader loader,
      SourceLibraryBuilder? origin,
      LookupScope? parentScope,
      Library? target,
      LibraryBuilder? nameOrigin,
      IndexedLibrary? indexedLibrary,
      bool? referenceIsPartOwner,
      required bool isUnsupported,
      required bool isAugmentation,
      required bool isPatch,
      Map<String, Builder>? omittedTypes,
      required NameSpace importNameSpace,
      required LibraryNameSpaceBuilder libraryNameSpaceBuilder}) {
    Library library = target ??
        (origin?.library ??
            new Library(importUri,
                fileUri: fileUri,
                reference: referenceIsPartOwner == true
                    ? null
                    : indexedLibrary?.library.reference)
          ..setLanguageVersion(packageLanguageVersion.version));
    LibraryName libraryName = new LibraryName(library.reference);
    LookupScope importScope = new NameSpaceLookupScope(
        importNameSpace, ScopeKind.import, 'import',
        parent: parentScope);
    importScope = new FixedLookupScope(
        ScopeKind.typeParameters, 'omitted-types',
        getables: omittedTypes, parent: importScope);
    NameSpace prefixNameSpace = new NameSpaceImpl();
    LookupScope prefixScope = new NameSpaceLookupScope(
        prefixNameSpace, ScopeKind.prefix, 'prefix',
        parent: importScope);
    NameSpace exportNameSpace = origin?.exportNameSpace ?? new NameSpaceImpl();
    return new SourceLibraryBuilder._(
        compilationUnit: compilationUnit,
        loader: loader,
        importUri: importUri,
        fileUri: fileUri,
        packageUri: packageUri,
        originImportUri: originImportUri,
        packageLanguageVersion: packageLanguageVersion,
        libraryNameSpaceBuilder: libraryNameSpaceBuilder,
        importScope: importScope,
        prefixNameSpace: prefixNameSpace,
        prefixScope: prefixScope,
        exportNameSpace: exportNameSpace,
        origin: origin,
        library: library,
        libraryName: libraryName,
        nameOrigin: nameOrigin,
        indexedLibrary: indexedLibrary,
        isUnsupported: isUnsupported,
        isAugmentation: isAugmentation,
        isPatch: isPatch,
        omittedTypes: omittedTypes,
        augmentations: libraryNameSpaceBuilder.augmentations,
        setterAugmentations: libraryNameSpaceBuilder.setterAugmentations);
  }

  SourceLibraryBuilder._(
      {required this.loader,
      required this.compilationUnit,
      required this.importUri,
      required this.fileUri,
      required Uri? packageUri,
      required Uri originImportUri,
      required LanguageVersion packageLanguageVersion,
      required LibraryNameSpaceBuilder libraryNameSpaceBuilder,
      required LookupScope importScope,
      required NameSpace prefixNameSpace,
      required LookupScope prefixScope,
      required NameSpace exportNameSpace,
      required SourceLibraryBuilder? origin,
      required this.library,
      required this.libraryName,
      required LibraryBuilder? nameOrigin,
      required IndexedLibrary? indexedLibrary,
      required bool isUnsupported,
      required bool isAugmentation,
      required bool isPatch,
      required Map<String, Builder>? omittedTypes,
      required this.augmentations,
      required this.setterAugmentations})
      : _packageUri = packageUri,
        _immediateOrigin = origin,
        _nameOrigin = nameOrigin,
        _importScope = importScope,
        _prefixNameSpace = prefixNameSpace,
        _prefixScope = prefixScope,
        _libraryNameSpaceBuilder = libraryNameSpaceBuilder,
        _exportNameSpace = exportNameSpace,
        super(fileUri) {
    assert(
        _packageUri == null ||
            !importUri.isScheme('package') ||
            // Coverage-ignore(suite): Not run.
            importUri.path.startsWith(_packageUri.path),
        "Foreign package uri '$_packageUri' set on library with import uri "
        "'${importUri}'.");
    assert(
        !importUri.isScheme('dart') || _packageUri == null,
        "Package uri '$_packageUri' set on dart: library with import uri "
        "'${importUri}'.");
  }

  SourceLibraryBuilderState get state => _state;

  void set state(SourceLibraryBuilderState value) {
    assert(_state < value,
        "State $value has already been reached at $_state in $this.");
    assert(
        _state.index + 1 == value.index,
        _state.index + 1 < SourceLibraryBuilderState.values.length
            ? "Expected state "
                "${SourceLibraryBuilderState.values[_state.index + 1]} "
                "to follow from $_state, trying to set next state to $value "
                "in $this."
            : "No more states expected to follow from $_state, trying to set "
                "next state to $value in $this.");
    _state = value;
  }

  bool checkState(
      {List<SourceLibraryBuilderState>? required,
      List<SourceLibraryBuilderState>? pending}) {
    if (required != null) {
      for (SourceLibraryBuilderState requiredState in required) {
        assert(state >= requiredState,
            "State $requiredState required, but found $state in $this.");
      }
    }
    if (pending != null) {
      for (SourceLibraryBuilderState pendingState in pending) {
        assert(
            state < pendingState,
            "State $pendingState must not have been reached, "
            "but found $state in $this.");
      }
    }
    return true;
  }

  @override
  bool get mayImplementRestrictedTypes =>
      compilationUnit.mayImplementRestrictedTypes;

  /// `true` if this is an augmentation library.
  bool get isAugmentationLibrary => compilationUnit.forAugmentationLibrary;

  /// `true` if this is a patch library.
  bool get isPatchLibrary => compilationUnit.forPatchLibrary;

  @override
  bool get isUnsupported => compilationUnit.isUnsupported;

  MergedLibraryScope get mergedScope {
    return _mergedScope ??=
        isAugmenting ? origin.mergedScope : new MergedLibraryScope(this);
  }

  /// Returns the state of the experimental features within this library.
  LibraryFeatures get libraryFeatures => compilationUnit.libraryFeatures;

  /// Reports that [feature] is not enabled, using [charOffset] and
  /// [length] for the location of the message.
  ///
  /// Return the primary message.
  Message reportFeatureNotEnabled(
      LibraryFeature feature, Uri fileUri, int charOffset, int length) {
    return compilationUnit.reportFeatureNotEnabled(
        feature, fileUri, charOffset, length);
  }

  @override
  LookupScope get scope => compilationUnit.scope;

  // Coverage-ignore(suite): Not run.
  LookupScope get importScope => _importScope;

  @override
  NameSpace get libraryNameSpace {
    assert(_nameSpace != null, "Name space has not being computed for $this.");
    return _nameSpace!;
  }

  LookupScope get prefixScope => _prefixScope;

  NameSpace get prefixNameSpace => _prefixNameSpace;

  @override
  NameSpace get exportNameSpace => _exportNameSpace;

  Iterable<SourceCompilationUnit> get parts => _parts;

  @override
  bool get isPart => compilationUnit.isPart;

  @override
  List<Export> get exporters => compilationUnit.exporters;

  @override
  // Coverage-ignore(suite): Not run.
  Iterator<T> fullMemberIterator<T extends Builder>() =>
      new SourceLibraryBuilderMemberIterator<T>(this, includeDuplicates: false);

  @override
  // Coverage-ignore(suite): Not run.
  NameIterator<T> fullMemberNameIterator<T extends Builder>() =>
      new SourceLibraryBuilderMemberNameIterator<T>(this,
          includeDuplicates: false);

  // TODO(johnniwinther): Can avoid using this from outside this class?
  Iterable<SourceLibraryBuilder>? get augmentationLibraries =>
      _augmentationLibraries;

  void addAugmentationLibrary(SourceLibraryBuilder augmentationLibrary) {
    assert(augmentationLibrary.isAugmenting,
        "Library ${augmentationLibrary} must be a augmentation library.");
    assert(!augmentationLibrary.isPart,
        "Augmentation library ${augmentationLibrary} cannot be a part .");
    (_augmentationLibraries ??= []).add(augmentationLibrary);
    augmentationLibrary.augmentationIndex = _augmentationLibraries!.length;
  }

  // Coverage-ignore(suite): Not run.
  /// Creates a synthesized augmentation library for the [source] code and
  /// attach it as an augmentation library of this library.
  ///
  /// To support the parser of the [source], the library is registered as an
  /// unparsed library on the [loader].
  SourceLibraryBuilder createAugmentationLibrary(String source,
      {Map<String, OmittedTypeBuilder>? omittedTypes}) {
    assert(!isAugmenting,
        "createAugmentationLibrary is only supported on the origin library.");
    int index = _augmentationLibraries?.length ?? 0;
    Uri uri = new Uri(
        scheme: intermediateAugmentationScheme, path: '${fileUri.path}-$index');

    if (loader.target.context.options.showGeneratedMacroSourcesForTesting) {
      print('==============================================================');
      print('Origin library: ${importUri}');
      print('Intermediate augmentation library: $uri');
      print('---------------------------source-----------------------------');
      print(source);
      print('==============================================================');
    }

    Map<String, Builder>? omittedTypeDeclarationBuilders;
    if (omittedTypes != null && omittedTypes.isNotEmpty) {
      omittedTypeDeclarationBuilders = {};
      for (MapEntry<String, OmittedTypeBuilder> entry in omittedTypes.entries) {
        omittedTypeDeclarationBuilders[entry.key] =
            new OmittedTypeDeclarationBuilder(entry.key, entry.value, this);
      }
    }
    SourceCompilationUnit augmentationCompilationUnit =
        new SourceCompilationUnitImpl(
      fileUri: uri,
      importUri: uri,
      originImportUri: importUri,
      packageLanguageVersion: compilationUnit.packageLanguageVersion,
      loader: loader,
      isUnsupported: false,
      augmentationRoot: compilationUnit,
      forAugmentationLibrary: true,
      isAugmenting: true,
      forPatchLibrary: false,
      indexedLibrary: indexedLibrary,
      omittedTypeDeclarationBuilders: omittedTypeDeclarationBuilders,
      referenceIsPartOwner: null,
      // TODO(johnniwinther): Shouldn't these be the copied from this
      // library?
      packageUri: null,
      nameOrigin: null,
      mayImplementRestrictedTypes: false,
    );
    SourceLibraryBuilder augmentationLibrary =
        augmentationCompilationUnit.createLibrary(library);
    addAugmentationLibrary(augmentationLibrary);
    Uint8List sourceUtf8 = utf8.encode(source);
    loader.registerUnparsedLibrarySource(
        augmentationCompilationUnit, sourceUtf8);
    return augmentationLibrary;
  }

  @override
  bool get isSynthetic => compilationUnit.isSynthetic;

  bool get isInferenceUpdate1Enabled =>
      libraryFeatures.inferenceUpdate1.isSupported &&
      _languageVersion.version >=
          libraryFeatures.inferenceUpdate1.enabledVersion;

  @override
  Version get languageVersion => _languageVersion.version;

  LanguageVersion get _languageVersion => compilationUnit.languageVersion;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Uri> get dependencies sync* {
    yield* compilationUnit.dependencies;
    for (SourceCompilationUnit part in parts) {
      yield part.importUri;
      yield* part.dependencies;
    }
  }

  /// Checks [nameSpace] for conflicts between setters and non-setters and
  /// reports them in [sourceLibraryBuilder].
  ///
  /// If [checkForInstanceVsStaticConflict] is `true`, conflicts between
  /// instance and static members of the same name are reported.
  ///
  /// If [checkForMethodVsSetterConflict] is `true`, conflicts between
  /// methods and setters of the same name are reported.
  static void checkMemberConflicts(
      SourceLibraryBuilder sourceLibraryBuilder, NameSpace nameSpace,
      {required bool checkForInstanceVsStaticConflict,
      required bool checkForMethodVsSetterConflict}) {
    nameSpace.forEachLocalSetter((String name, MemberBuilder setter) {
      Builder? getable = nameSpace.lookupLocalMember(name, setter: false);
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
                currentSetter.fileOffset,
                noLength,
                currentSetter.fileUri);
          } else {
            sourceLibraryBuilder.addProblem(
                templateConflictsWithMember.withArguments(name),
                currentSetter.fileOffset,
                noLength,
                currentSetter.fileUri);
          }
        }
      }
      for (Builder conflictingGetable in conflictingGetables) {
        // TODO(ahe): Context argument to previous message?
        sourceLibraryBuilder.addProblem(
            templateConflictsWithSetter.withArguments(name),
            conflictingGetable.fileOffset,
            noLength,
            conflictingGetable.fileUri!);
      }
    });
  }

  /// Builds the core AST structure of this library as needed for the outline.
  Library buildOutlineNodes(LibraryBuilder coreLibrary) {
    assert(checkState(
        required: [SourceLibraryBuilderState.unboundTypeParametersCollected]));

    // TODO(johnniwinther): Avoid the need to process augmentation libraries
    // before the origin. Currently, settings performed by the augmentation are
    // overridden by the origin. For instance, the `Map` class is abstract in
    // the origin but (unintentionally) concrete in the patch. By processing the
    // origin last the `isAbstract` property set by the patch is corrected by
    // the origin.
    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.buildOutlineNodes(coreLibrary);
      }
    }
    compilationUnit.buildOutlineNode(library);
    // TODO(johnniwinther): Include [LibraryPart]s from parts to support imports
    // and exports in parts.
    /*for (SourceCompilationUnit part in parts) {
      part.buildOutlineNode(library);
    }*/

    checkMemberConflicts(this, libraryNameSpace,
        checkForInstanceVsStaticConflict: false,
        checkForMethodVsSetterConflict: true);

    Iterator<Builder> iterator = localMembersIterator;
    while (iterator.moveNext()) {
      _buildOutlineNodes(iterator.current, coreLibrary);
    }
    state = SourceLibraryBuilderState.outlineNodesBuilt;

    library.isSynthetic = isSynthetic;
    library.isUnsupported = isUnsupported;
    addDependencies(library, new Set<SourceCompilationUnit>());

    library.name = compilationUnit.name;
    library.procedures.sort(compareProcedures);

    if (unserializableExports != null) {
      Name fieldName = new Name(unserializableExportName, library);
      Reference? fieldReference = indexedLibrary
          // Coverage-ignore(suite): Not run.
          ?.lookupFieldReference(fieldName);
      Reference? getterReference = indexedLibrary
          // Coverage-ignore(suite): Not run.
          ?.lookupGetterReference(fieldName);
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

  void includeParts(Set<Uri> usedParts) {
    compilationUnit.includeParts(this, _parts, usedParts);
  }

  void buildInitialScopes() {
    assert(checkState(required: [SourceLibraryBuilderState.scopesBuilt]));

    NameIterator iterator = libraryNameSpace.filteredNameIterator(
        includeDuplicates: false, includeAugmentations: false);
    UriOffset uriOffset = new UriOffset(fileUri, TreeNode.noOffset);
    while (iterator.moveNext()) {
      addToExportScope(iterator.name, iterator.current, uriOffset: uriOffset);
    }

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        // Augmentation libraries don't have their own export scope.
        augmentationLibrary.state =
            SourceLibraryBuilderState.initialExportScopesBuilt;
      }
    }

    state = SourceLibraryBuilderState.initialExportScopesBuilt;
  }

  void addImportsToScope() {
    assert(checkState(
        required: [SourceLibraryBuilderState.initialExportScopesBuilt]));

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        // Augmentation libraries don't have their own export scope.
        // TODO(johnniwinther): Do we need this?
        augmentationLibrary.addImportsToScope();
      }
    }

    compilationUnit.addImportsToScope();
    for (SourceCompilationUnit part in parts) {
      part.addImportsToScope();
    }

    NameIterator<Builder> iterator = exportNameSpace.filteredNameIterator(
        includeDuplicates: false, includeAugmentations: false);
    while (iterator.moveNext()) {
      String name = iterator.name;
      Builder builder = iterator.current;
      if (builder.parent?.origin != origin) {
        if (builder is TypeDeclarationBuilder) {
          switch (builder) {
            case ClassBuilder():
              library.additionalExports.add(builder.cls.reference);
            case TypeAliasBuilder():
              library.additionalExports.add(builder.reference);
            case ExtensionBuilder():
              library.additionalExports.add(builder.reference);
            case ExtensionTypeDeclarationBuilder():
              library.additionalExports
                  .add(builder.extensionTypeDeclaration.reference);
            case InvalidTypeDeclarationBuilder():
              (unserializableExports ??= {})[name] =
                  builder.message.problemMessage;
            case BuiltinTypeDeclarationBuilder():
              if (builder is DynamicTypeDeclarationBuilder) {
                assert(name == 'dynamic',
                    "Unexpected export name for 'dynamic': '$name'");
                (unserializableExports ??= {})[name] = exportDynamicSentinel;
              } else if (builder is NeverTypeDeclarationBuilder) {
                assert(name == 'Never',
                    "Unexpected export name for 'Never': '$name'");
                (unserializableExports ??= // Coverage-ignore(suite): Not run.
                    {})[name] = exportNeverSentinel;
              }
            // Coverage-ignore(suite): Not run.
            // TODO(johnniwinther): How should we handle this case?
            case OmittedTypeDeclarationBuilder():
            case NominalParameterBuilder():
            case StructuralParameterBuilder():
              unhandled(
                  'member', 'exportScope', builder.fileOffset, builder.fileUri);
          }
        } else if (builder is MemberBuilder) {
          library.additionalExports.addAll(builder.exportedMemberReferences);
        } else {
          unhandled(
              'member', 'exportScope', builder.fileOffset, builder.fileUri);
        }
      }
    }

    state = SourceLibraryBuilderState.exportScopesBuilt;
  }

  void buildNameSpace() {
    assert(checkState(required: [SourceLibraryBuilderState.initial]));

    assert(
        _nameSpace == null, "Name space has already being computed for $this.");

    assert(
        _mixinApplications != null, "Late registration of mixin application.");

    _nameSpace = _libraryNameSpaceBuilder.toNameSpace(
        problemReporting: this,
        enclosingLibraryBuilder: this,
        mixinApplications: _mixinApplications!,
        unboundNominalVariables: _unboundNominalVariables,
        indexedLibrary: indexedLibrary);

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.buildNameSpace();
      }
    }

    state = SourceLibraryBuilderState.nameSpaceBuilt;
  }

  void buildScopes(LibraryBuilder coreLibrary) {
    assert(checkState(required: [SourceLibraryBuilderState.nameSpaceBuilt]));

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.buildScopes(coreLibrary);
      }
    }

    Iterator<Builder> iterator = localMembersIterator;
    while (iterator.moveNext()) {
      Builder builder = iterator.current;
      if (builder is SourceDeclarationBuilder) {
        builder.buildScopes(coreLibrary);
      }
    }

    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.applyAugmentations();
      }
    }

    state = SourceLibraryBuilderState.scopesBuilt;
  }

  /// Resolves all unresolved types in [unresolvedNamedTypes]. The list of types
  /// is cleared when done.
  int resolveTypes() {
    assert(checkState(required: [SourceLibraryBuilderState.exportScopesBuilt]));
    int typeCount = 0;

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        typeCount += augmentationLibrary.resolveTypes();
      }
    }

    typeCount += compilationUnit.resolveTypes(this);
    for (SourceCompilationUnit part in parts) {
      typeCount += part.resolveTypes(this);
    }

    state = SourceLibraryBuilderState.resolvedTypes;
    return typeCount;
  }

  void installDefaultSupertypes(
      ClassBuilder objectClassBuilder, Class objectClass) {
    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.installDefaultSupertypes(
            objectClassBuilder, objectClass);
      }
    }

    Iterator<SourceClassBuilder> iterator = localMembersIteratorOfType();
    while (iterator.moveNext()) {
      SourceClassBuilder declaration = iterator.current;
      Class cls = declaration.cls;
      if (cls != objectClass) {
        cls.supertype ??= objectClass.asRawSupertype;
        declaration.supertypeBuilder ??=
            new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
                objectClassBuilder, const NullabilityBuilder.omitted(),
                instanceTypeParameterAccess:
                    InstanceTypeParameterAccessState.Unexpected);
      }
      if (declaration.isMixinApplication) {
        cls.mixedInType =
            declaration.mixedInTypeBuilder!.buildMixedInType(this);
      }
    }
  }

  void collectSourceClassesAndExtensionTypes(
      List<SourceClassBuilder> sourceClasses,
      List<SourceExtensionTypeDeclarationBuilder> sourceExtensionTypes) {
    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.collectSourceClassesAndExtensionTypes(
            sourceClasses, sourceExtensionTypes);
      }
    }

    Iterator<Builder> iterator = localMembersIterator;
    while (iterator.moveNext()) {
      Builder member = iterator.current;
      if (member is SourceClassBuilder && !member.isAugmenting) {
        sourceClasses.add(member);
      } else if (member is SourceExtensionTypeDeclarationBuilder &&
          !member.isAugmenting) {
        sourceExtensionTypes.add(member);
      }
    }
  }

  /// Resolve constructors (lookup names in scope) recorded in this builder and
  /// return the number of constructors resolved.
  int resolveConstructors() {
    int count = 0;

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        count += augmentationLibrary.resolveConstructors();
      }
    }

    Iterator<ClassDeclaration> iterator = localMembersIteratorOfType();
    while (iterator.moveNext()) {
      ClassDeclaration builder = iterator.current;
      count += builder.resolveConstructors(this);
    }
    return count;
  }

  /// Sets [fieldNonPromotabilityInfo] based on the contents of this library.
  void computeFieldPromotability() {
    _FieldPromotability fieldPromotability = new _FieldPromotability();
    Map<Member, PropertyNonPromotabilityReason> individualPropertyReasons = {};

    // Iterate through all the classes, enums, and mixins in the library,
    // recording the non-synthetic instance fields and getters of each.
    Iterator<SourceClassBuilder> classIterator = localMembersIteratorOfType();
    while (classIterator.moveNext()) {
      SourceClassBuilder class_ = classIterator.current;
      ClassInfo<Class> classInfo = fieldPromotability.addClass(class_.actualCls,
          isAbstract: class_.isAbstract);
      Iterator<SourceMemberBuilder> memberIterator =
          class_.fullMemberIterator<SourceMemberBuilder>();
      while (memberIterator.moveNext()) {
        SourceMemberBuilder member = memberIterator.current;
        if (member.isStatic) continue;
        if (member is SourceFieldBuilder) {
          if (member.isSynthesized) continue;
          PropertyNonPromotabilityReason? reason = fieldPromotability.addField(
              classInfo, member, member.name,
              isFinal: member.isFinal,
              isAbstract: member.isAbstract,
              isExternal: member.isExternal);
          if (reason != null) {
            individualPropertyReasons[member.readTarget] = reason;
          }
        } else if (member is SourceProcedureBuilder && member.isGetter) {
          if (member.isSynthetic) continue;
          PropertyNonPromotabilityReason? reason = fieldPromotability.addGetter(
              classInfo, member, member.name,
              isAbstract: member.isAbstract);
          if (reason != null) {
            individualPropertyReasons[member.procedure] = reason;
          }
        }
      }
    }

    // And for each getter in an extension or extension type, make a note of why
    // it's not promotable.
    Iterator<SourceExtensionBuilder> extensionIterator =
        localMembersIteratorOfType();
    while (extensionIterator.moveNext()) {
      SourceExtensionBuilder extension_ = extensionIterator.current;
      for (Builder member in extension_.nameSpace.localMembers) {
        if (member is SourceProcedureBuilder &&
            !member.isStatic &&
            member.isGetter) {
          individualPropertyReasons[member.procedure] =
              member.memberName.isPrivate
                  ? PropertyNonPromotabilityReason.isNotField
                  : PropertyNonPromotabilityReason.isNotPrivate;
        }
      }
    }
    Iterator<SourceExtensionTypeDeclarationBuilder> extensionTypeIterator =
        localMembersIteratorOfType();
    while (extensionTypeIterator.moveNext()) {
      SourceExtensionTypeDeclarationBuilder extensionType =
          extensionTypeIterator.current;
      Member? representationGetter =
          extensionType.representationFieldBuilder?.readTarget;
      if (representationGetter != null &&
          !representationGetter.name.isPrivate) {
        individualPropertyReasons[representationGetter] =
            PropertyNonPromotabilityReason.isNotPrivate;
      }
      for (Builder member in extensionType.nameSpace.localMembers) {
        if (member is SourceProcedureBuilder &&
            !member.isStatic &&
            member.isGetter) {
          individualPropertyReasons[member.procedure] =
              member.memberName.isPrivate
                  ? PropertyNonPromotabilityReason.isNotField
                  : PropertyNonPromotabilityReason.isNotPrivate;
        }
      }
    }

    // Compute information about field non-promotability.
    fieldNonPromotabilityInfo = new FieldNonPromotabilityInfo(
        fieldNameInfo: fieldPromotability.computeNonPromotabilityInfo(),
        individualPropertyReasons: individualPropertyReasons);
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors {
    // TODO(ahe): Consider if we should use relativizeUri here. The downside to
    // doing that is that this URI may be used in an error message. Ideally, we
    // should create a class that represents qualified names that we can
    // relativize when printing a message, but still store the full URI in
    // .dill files.
    return compilationUnit.name ?? "<library '$fileUri'>";
  }

  @override
  bool get isAugmenting => compilationUnit.isAugmenting;

  @override
  SourceLibraryBuilder get origin => _immediateOrigin ?? this;

  @override
  final Uri importUri;

  @override
  // Coverage-ignore(suite): Not run.
  void becomeCoreLibrary() {
    assert(checkState(required: [SourceLibraryBuilderState.nameSpaceBuilt]));

    if (libraryNameSpace.lookupLocalMember("dynamic", setter: false) == null) {
      libraryNameSpace.addLocalMember("dynamic",
          new DynamicTypeDeclarationBuilder(const DynamicType(), this, -1),
          setter: false);
    }
    if (libraryNameSpace.lookupLocalMember("Never", setter: false) == null) {
      libraryNameSpace.addLocalMember(
          "Never",
          new NeverTypeDeclarationBuilder(
              const NeverType.nonNullable(), this, -1),
          setter: false);
    }
    assert(libraryNameSpace.lookupLocalMember("Null", setter: false) != null,
        "No class 'Null' found in dart:core.");
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

  void addProblemForRedirectingFactory(RedirectingFactoryBuilder factory,
      Message message, int charOffset, int length, Uri fileUri) {
    addProblem(message, charOffset, length, fileUri);
    String text = loader.target.context
        .format(
            message.withLocation(fileUri, charOffset, length), Severity.error)
        .plain;
    factory.setRedirectingFactoryError(text);
  }

  void checkGetterSetterTypes(ProcedureBuilder getterBuilder,
      ProcedureBuilder setterBuilder, TypeEnvironment typeEnvironment) {
    DartType getterType;
    List<TypeParameter>? getterExtensionTypeParameters;
    if (getterBuilder.isExtensionInstanceMember ||
        setterBuilder.isExtensionTypeInstanceMember) {
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
      // Similarly for extension type instance getters.
      //
      Procedure procedure = getterBuilder.procedure;
      getterType = procedure.function.returnType;
      getterExtensionTypeParameters = procedure.function.typeParameters;
    } else {
      getterType = getterBuilder.procedure.getterType;
    }
    DartType setterType;
    if (setterBuilder.isExtensionInstanceMember ||
        setterBuilder.isExtensionTypeInstanceMember) {
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
      // Similarly for extension type instance setters.
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
          getterType, setterType, SubtypeCheckMode.withNullabilities);
      if (!isValid) {
        String getterMemberName = getterBuilder.fullNameForErrors;
        String setterMemberName = setterBuilder.fullNameForErrors;
        addProblem(
            templateInvalidGetterSetterType.withArguments(
                getterType, getterMemberName, setterType, setterMemberName),
            getterBuilder.fileOffset,
            getterBuilder.name.length,
            getterBuilder.fileUri,
            context: [
              templateInvalidGetterSetterTypeSetterContext
                  .withArguments(setterMemberName)
                  .withLocation(setterBuilder.fileUri!,
                      setterBuilder.fileOffset, setterBuilder.name.length)
            ]);
      }
    }
  }

  /// Map from mixin application classes to their mixin types.
  ///
  /// This is used to check that super access in mixin declarations have a
  /// concrete target.
  Map<SourceClassBuilder, TypeBuilder>? _mixinApplications = {};

  void takeMixinApplications(
      Map<SourceClassBuilder, TypeBuilder> mixinApplications) {
    assert(_mixinApplications != null,
        "Mixin applications have already been processed.");
    mixinApplications.addAll(_mixinApplications!);
    _mixinApplications = null;

    compilationUnit.takeMixinApplications(mixinApplications);
    for (SourceCompilationUnit part in parts) {
      part.takeMixinApplications(mixinApplications);
    }

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.takeMixinApplications(mixinApplications);
      }
    }
  }

  BodyBuilderContext createBodyBuilderContext() {
    return new LibraryBodyBuilderContext(this);
  }

  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      }
    }

    MetadataBuilder.buildAnnotations(
        library, metadata, createBodyBuilderContext(), this, fileUri, scope,
        createFileUriExpression: isAugmenting);

    Iterator<Builder> iterator = localMembersIterator;
    while (iterator.moveNext()) {
      Builder declaration = iterator.current;
      if (declaration is SourceClassBuilder) {
        declaration.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      } else if (declaration is SourceExtensionBuilder) {
        declaration.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      } else if (declaration is SourceExtensionTypeDeclarationBuilder) {
        declaration.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      } else if (declaration is SourceMemberBuilder) {
        declaration.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      } else if (declaration is SourceTypeAliasBuilder) {
        declaration.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      } else {
        // Coverage-ignore-block(suite): Not run.
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
      if (!declaration.isAugmenting) {
        if (!declaration.isAugmentation) {
          if (declaration.isDuplicate ||
              declaration.isConflictingAugmentationMember) {
            cls.name = '${cls.name}'
                '#${declaration.duplicateIndex}'
                '#${declaration.libraryBuilder.augmentationIndex}';
          }
        } else {
          // The following is a recovery to prevent cascading errors.
          int nameIndex = 0;
          String baseName = cls.name;
          String? nameOfErroneousAugmentation;
          while (nameOfErroneousAugmentation == null) {
            nameOfErroneousAugmentation =
                "_#${baseName}#augmentationWithoutOrigin${nameIndex}";
            for (Class class_ in library.classes) {
              if (class_.name == nameOfErroneousAugmentation) {
                nameOfErroneousAugmentation = null;
                break;
              }
            }
            nameIndex++;
          }
          cls.name = nameOfErroneousAugmentation;
        }
        library.addClass(cls);
      }
    } else if (declaration is SourceExtensionBuilder) {
      Extension extension = declaration.build(coreLibrary,
          addMembersToLibrary: !declaration.isDuplicate);
      if (!declaration.isAugmenting && !declaration.isDuplicate) {
        if (declaration.isUnnamedExtension) {
          declaration.extensionName.name =
              '_extension#${library.extensions.length}';
        }
        library.addExtension(extension);
      }
    } else if (declaration is SourceExtensionTypeDeclarationBuilder) {
      ExtensionTypeDeclaration extensionTypeDeclaration = declaration
          .build(coreLibrary, addMembersToLibrary: !declaration.isDuplicate);
      if (!declaration.isAugmenting && !declaration.isDuplicate) {
        library.addExtensionTypeDeclaration(extensionTypeDeclaration);
      }
    } else if (declaration is SourceMemberBuilder) {
      declaration.buildOutlineNodes((
          {required Member member,
          Member? tearOff,
          required BuiltMemberKind kind}) {
        _addMemberToLibrary(declaration, member);
        if (tearOff != null) {
          // Coverage-ignore-block(suite): Not run.
          _addMemberToLibrary(declaration, tearOff);
        }
      });
    } else if (declaration is SourceTypeAliasBuilder) {
      Typedef typedef = declaration.build();
      if (!declaration.isAugmenting && !declaration.isDuplicate) {
        library.addTypedef(typedef);
      }
    }
    // Coverage-ignore(suite): Not run.
    else if (declaration is PrefixBuilder) {
      // Ignored. Kernel doesn't represent prefixes.
      return;
    } else if (declaration is BuiltinTypeDeclarationBuilder) {
      // Nothing needed.
      return;
    } else {
      unhandled("${declaration.runtimeType}", "buildBuilder",
          declaration.fileOffset, declaration.fileUri);
    }
  }

  void _addMemberToLibrary(SourceMemberBuilder declaration, Member member) {
    if (member is Field) {
      member.isStatic = true;
      if (!declaration.isAugmenting && !declaration.isDuplicate) {
        if (declaration.isConflictingAugmentationMember) {
          // Coverage-ignore-block(suite): Not run.
          member.name = new Name(
              '${member.name.text}'
              '#${declaration.libraryBuilder.augmentationIndex}',
              member.name.library);
        }
        library.addField(member);
      }
    } else if (member is Procedure) {
      member.isStatic = true;
      if (!declaration.isAugmenting &&
          !declaration.isDuplicate &&
          !declaration.isConflictingSetter) {
        if (declaration.isConflictingAugmentationMember) {
          member.name = new Name(
              '${member.name.text}'
              '#${declaration.libraryBuilder.augmentationIndex}',
              member.name.library);
        }
        library.addProcedure(member);
      }
    } else {
      unhandled("${member.runtimeType}", "_buildMember", declaration.fileOffset,
          declaration.fileUri);
    }
  }

  void addDependencies(Library library, Set<SourceCompilationUnit> seen) {
    assert(checkState(required: [SourceLibraryBuilderState.outlineNodesBuilt]));
    compilationUnit.addDependencies(library, seen);
    for (SourceCompilationUnit part in parts) {
      part.addDependencies(library, seen);
    }
  }

  int finishDeferredLoadTearOffs() {
    int total = 0;

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        total += augmentationLibrary.finishDeferredLoadTearOffs();
      }
    }

    total += compilationUnit.finishDeferredLoadTearOffs(library);
    for (SourceCompilationUnit part in parts) {
      total += part.finishDeferredLoadTearOffs(library);
    }
    return total;
  }

  int finishForwarders() {
    int count = 0;

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        count += augmentationLibrary.finishForwarders();
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

  int finishNativeMethods() {
    int count = 0;

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        count += augmentationLibrary.finishNativeMethods();
      }
    }

    count += compilationUnit.finishNativeMethods();
    for (SourceCompilationUnit part in parts) {
      count += part.finishNativeMethods();
    }

    return count;
  }

  final List<NominalParameterBuilder> _unboundNominalVariables = [];

  /// Adds all unbound nominal parameters to [nominalParameters] and unbound
  /// structural parameters to [structuralParameters], mapping them to this
  /// library.
  ///
  /// This is used to compute the bounds of type parameter while taking the
  /// bound dependencies, which might span multiple libraries, into account.
  void collectUnboundTypeParameters(
      Map<NominalParameterBuilder, SourceLibraryBuilder> nominalParameters,
      Map<StructuralParameterBuilder, SourceLibraryBuilder>
          structuralParameters) {
    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.collectUnboundTypeParameters(
            nominalParameters, structuralParameters);
      }
    }
    compilationUnit.collectUnboundTypeParameters(
        this, nominalParameters, structuralParameters);
    for (SourceCompilationUnit part in parts) {
      part.collectUnboundTypeParameters(
          this, nominalParameters, structuralParameters);
    }
    for (NominalParameterBuilder builder in _unboundNominalVariables) {
      nominalParameters[builder] = this;
    }
    _unboundNominalVariables.clear();

    state = SourceLibraryBuilderState.unboundTypeParametersCollected;
  }

  /// Computes variances of type parameters on typedefs.
  ///
  /// The variance property of type parameters on typedefs is computed from the
  /// use of the parameters in the right-hand side of the typedef definition.
  int computeVariances() {
    int count = 0;

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        count += augmentationLibrary.computeVariances();
      }
    }

    count += compilationUnit.computeVariances();

    return count;
  }

  /// This method instantiates type parameters to their bounds in some cases
  /// where they were omitted by the programmer and not provided by the type
  /// inference.  The method returns the number of distinct type parameters
  /// that were instantiated in this library.
  int computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder nullType,
      TypeBuilder bottomType, ClassBuilder objectClass) {
    assert(checkState(
        required: [SourceLibraryBuilderState.resolvedTypes],
        pending: [SourceLibraryBuilderState.unboundTypeParametersCollected]));
    int count = 0;

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        count += augmentationLibrary.computeDefaultTypes(
            dynamicType, nullType, bottomType, objectClass);
      }
    }

    count += compilationUnit.computeDefaultTypes(
        dynamicType, nullType, bottomType, objectClass);

    state = SourceLibraryBuilderState.defaultTypesComputed;
    return count;
  }

  /// If this is an augmentation library, apply its augmentations to [origin].
  void applyAugmentations() {
    if (!isAugmenting) return;

    if (_languageVersion != origin._languageVersion) {
      // Coverage-ignore-block(suite): Not run.
      List<LocatedMessage> context = <LocatedMessage>[];
      if (origin._languageVersion.isExplicit) {
        context.add(messageLanguageVersionLibraryContext.withLocation(
            origin._languageVersion.fileUri!,
            origin._languageVersion.charOffset,
            origin._languageVersion.charCount));
      }

      if (_languageVersion.isExplicit) {
        addProblem(
            messageLanguageVersionMismatchInPatch,
            _languageVersion.charOffset,
            _languageVersion.charCount,
            _languageVersion.fileUri,
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
  /// This includes augmenting member bodies and adding augmented members.
  int buildBodyNodes() {
    int count = 0;

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        count += augmentationLibrary.buildBodyNodes();
      }
    }

    Iterator<Builder> iterator = localMembersIterator;
    while (iterator.moveNext()) {
      Builder builder = iterator.current;
      if (builder is SourceMemberBuilder) {
        count += builder.buildBodyNodes((
            {required Member member,
            Member? tearOff,
            required BuiltMemberKind kind}) {
          _addMemberToLibrary(builder, member);
          if (tearOff != null) {
            // Coverage-ignore-block(suite): Not run.
            _addMemberToLibrary(builder, tearOff);
          }
        });
      } else if (builder is SourceClassBuilder) {
        count += builder.buildBodyNodes();
      } else if (builder is SourceExtensionBuilder) {
        count +=
            builder.buildBodyNodes(addMembersToLibrary: !builder.isDuplicate);
      } else if (builder is SourceExtensionTypeDeclarationBuilder) {
        count +=
            builder.buildBodyNodes(addMembersToLibrary: !builder.isDuplicate);
      } else if (builder is SourceClassBuilder) {
        // Coverage-ignore-block(suite): Not run.
        count += builder.buildBodyNodes();
      } else if (builder is SourceTypeAliasBuilder) {
        // Do nothing.
      }
      // Coverage-ignore(suite): Not run.
      else if (builder is PrefixBuilder) {
        // Ignored. Kernel doesn't represent prefixes.
      } else if (builder is BuiltinTypeDeclarationBuilder) {
        // Nothing needed.
      } else {
        unhandled("${builder.runtimeType}", "buildBodyNodes",
            builder.fileOffset, builder.fileUri);
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
              .withArguments(argument);
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
                      targetName);
            } else {
              message = templateIncorrectTypeArgumentQualified.withArguments(
                  argument,
                  typeParameter.bound,
                  typeParameter.name!,
                  targetReceiver,
                  targetName);
            }
          } else {
            if (issueInferred) {
              // Coverage-ignore-block(suite): Not run.
              message = templateIncorrectTypeArgumentInstantiationInferred
                  .withArguments(argument, typeParameter.bound,
                      typeParameter.name!, targetReceiver);
            } else {
              message =
                  templateIncorrectTypeArgumentInstantiation.withArguments(
                      argument,
                      typeParameter.bound,
                      typeParameter.name!,
                      targetReceiver);
            }
          }
        } else {
          String enclosingName = issue.enclosingType == null
              ? targetName!
              : getGenericTypeName(issue.enclosingType!);
          if (issueInferred) {
            message = templateIncorrectTypeArgumentInferred.withArguments(
                argument,
                typeParameter.bound,
                typeParameter.name!,
                enclosingName);
          } else {
            message = templateIncorrectTypeArgument.withArguments(argument,
                typeParameter.bound, typeParameter.name!, enclosingName);
          }
        }
      }

      // Don't show the hint about an attempted super-bounded type if the issue
      // with the argument is that it's generic.
      reportTypeArgumentIssueForStructuralParameter(message, fileUri, offset,
          typeParameter: typeParameter,
          superBoundedAttempt:
              issue.isGenericTypeAsArgumentIssue ? null : issue.enclosingType,
          superBoundedAttemptInverted:
              issue.isGenericTypeAsArgumentIssue ? null : issue.invertedType);
    }
  }

  // Coverage-ignore(suite): Not run.
  void reportTypeArgumentIssue(Message message, Uri fileUri, int fileOffset,
      {TypeParameter? typeParameter,
      DartType? superBoundedAttempt,
      DartType? superBoundedAttemptInverted}) {
    List<LocatedMessage>? context;
    // Skip reporting location for function-type type parameters as it's a
    // limitation of Kernel.
    if (typeParameter != null &&
        typeParameter.fileOffset != -1 &&
        typeParameter.location?.file != null) {
      // It looks like when parameters come from augmentation libraries, they
      // don't have a reportable location.
      (context ??= <LocatedMessage>[]).add(
          messageIncorrectTypeArgumentVariable.withLocation(
              typeParameter.location!.file,
              typeParameter.fileOffset,
              noLength));
    }
    if (superBoundedAttemptInverted != null && superBoundedAttempt != null) {
      (context ??= <LocatedMessage>[]).add(templateSuperBoundedHint
          .withArguments(superBoundedAttempt, superBoundedAttemptInverted)
          .withLocation(fileUri, fileOffset, noLength));
    }
    addProblem(message, fileOffset, noLength, fileUri, context: context);
  }

  void reportTypeArgumentIssueForStructuralParameter(
      Message message, Uri fileUri, int fileOffset,
      {TypeParameter? typeParameter,
      DartType? superBoundedAttempt,
      DartType? superBoundedAttemptInverted}) {
    List<LocatedMessage>? context;
    // Skip reporting location for function-type type parameters as it's a
    // limitation of Kernel.
    if (typeParameter != null && typeParameter.location != null) {
      // It looks like when parameters come from augmentation libraries, they
      // don't have a reportable location.
      (context ??= <LocatedMessage>[]).add(
          messageIncorrectTypeArgumentVariable.withLocation(
              typeParameter.location!.file,
              typeParameter.fileOffset,
              noLength));
    }
    if (superBoundedAttemptInverted != null && superBoundedAttempt != null) {
      (context ??= // Coverage-ignore(suite): Not run.
              <LocatedMessage>[])
          .add(templateSuperBoundedHint
              .withArguments(superBoundedAttempt, superBoundedAttemptInverted)
              .withLocation(fileUri, fileOffset, noLength));
    }
    addProblem(message, fileOffset, noLength, fileUri, context: context);
  }

  void checkTypesInField(
      SourceFieldBuilder fieldBuilder, TypeEnvironment typeEnvironment) {
    // Check that the field has an initializer if its type is potentially
    // non-nullable.

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
              fieldBuilder.name, fieldBuilder.fieldType),
          fieldBuilder.fileOffset,
          fieldBuilder.name.length,
          fieldBuilder.fileUri);
    }
  }

  void checkInitializersInFormals(
      List<FormalParameterBuilder> formals, TypeEnvironment typeEnvironment) {
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
                formal.name, formal.variable!.type),
            formal.fileOffset,
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
        type, typeEnvironment, SubtypeCheckMode.withNullabilities,
        allowSuperBounded: allowSuperBounded,
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
    assert(factory.isFactory || factory.isExtensionTypeMember);
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
    if (parameters.length != arguments.length) {
      assert(loader.assertProblemReportedElsewhere(
          "SourceLibraryBuilder.checkBoundsInStaticInvocation: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline));
      return;
    }

    final DartType bottomType = const NeverType.nonNullable();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
        parameters,
        arguments,
        typeEnvironment,
        SubtypeCheckMode.withNullabilities,
        bottomType,
        areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled);
    if (issues.isNotEmpty) {
      DartType? targetReceiver;
      if (klass != null) {
        // Coverage-ignore-block(suite): Not run.
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
    if (methodParameters.length != arguments.types.length) {
      assert(loader.assertProblemReportedElsewhere(
          "SourceLibraryBuilder.checkBoundsInMethodInvocation: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline));
      return;
    }
    List<TypeParameter> methodTypeParametersOfInstantiated =
        getFreshTypeParameters(methodParameters).freshTypeParameters;
    for (TypeParameter typeParameter in methodTypeParametersOfInstantiated) {
      typeParameter.bound = substitute(typeParameter.bound, substitutionMap);
      typeParameter.defaultType =
          substitute(typeParameter.defaultType, substitutionMap);
    }

    final DartType bottomType = const NeverType.nonNullable();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
        methodTypeParametersOfInstantiated,
        arguments.types,
        typeEnvironment,
        SubtypeCheckMode.withNullabilities,
        bottomType,
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

    if (functionType.typeParameters.length != arguments.types.length) {
      assert(loader.assertProblemReportedElsewhere(
          "SourceLibraryBuilder.checkBoundsInFunctionInvocation: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline));
      return;
    }
    final DartType bottomType = const NeverType.nonNullable();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
        getFreshTypeParametersFromStructuralParameters(
                functionType.typeParameters)
            .freshTypeParameters,
        arguments.types,
        typeEnvironment,
        SubtypeCheckMode.withNullabilities,
        bottomType,
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
    if (typeArguments.isEmpty) return;

    if (functionType.typeParameters.length != typeArguments.length) {
      // Coverage-ignore-block(suite): Not run.
      assert(loader.assertProblemReportedElsewhere(
          "SourceLibraryBuilder.checkBoundsInInstantiation: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline));
      return;
    }
    final DartType bottomType = const NeverType.nonNullable();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
        getFreshTypeParametersFromStructuralParameters(
                functionType.typeParameters)
            .freshTypeParameters,
        typeArguments,
        typeEnvironment,
        SubtypeCheckMode.withNullabilities,
        bottomType,
        areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled);
    _reportTypeArgumentIssues(issues, fileUri, offset,
        targetReceiver: functionType,
        typeArgumentsInfo: inferred
            ? const AllInferredTypeArgumentsInfo()
            : const NoneInferredTypeArgumentsInfo());
  }

  void checkTypesInOutline(TypeEnvironment typeEnvironment) {
    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.checkTypesInOutline(typeEnvironment);
      }
    }

    Iterator<Builder> iterator = localMembersIterator;
    while (iterator.moveNext()) {
      Builder declaration = iterator.current;
      if (declaration is SourceFieldBuilder) {
        declaration.checkTypes(this, typeEnvironment);
      } else if (declaration is SourceProcedureBuilder) {
        List<TypeParameterBuilder>? typeParameters = declaration.typeParameters;
        if (typeParameters != null && typeParameters.isNotEmpty) {
          checkTypeParameterDependencies(typeParameters);
        }
        declaration.checkTypes(this, typeEnvironment);
        if (declaration.isGetter) {
          Builder? setterDeclaration = libraryNameSpace
              .lookupLocalMember(declaration.name, setter: true);
          if (setterDeclaration != null) {
            checkGetterSetterTypes(declaration,
                setterDeclaration as ProcedureBuilder, typeEnvironment);
          }
        }
      } else if (declaration is SourceClassBuilder) {
        List<TypeParameterBuilder>? typeParameters = declaration.typeParameters;
        if (typeParameters != null && typeParameters.isNotEmpty) {
          checkTypeParameterDependencies(typeParameters);
        }
        declaration.checkTypesInOutline(typeEnvironment);
      } else if (declaration is SourceExtensionBuilder) {
        List<TypeParameterBuilder>? typeParameters = declaration.typeParameters;
        if (typeParameters != null && typeParameters.isNotEmpty) {
          checkTypeParameterDependencies(typeParameters);
        }
        declaration.checkTypesInOutline(typeEnvironment);
      } else if (declaration is SourceExtensionTypeDeclarationBuilder) {
        List<TypeParameterBuilder>? typeParameters = declaration.typeParameters;
        if (typeParameters != null && typeParameters.isNotEmpty) {
          checkTypeParameterDependencies(typeParameters);
        }
        declaration.checkTypesInOutline(typeEnvironment);
      } else if (declaration is SourceTypeAliasBuilder) {
        List<TypeParameterBuilder>? typeParameters = declaration.typeParameters;
        if (typeParameters != null && typeParameters.isNotEmpty) {
          checkTypeParameterDependencies(typeParameters);
        }
      } else {
        // Coverage-ignore-block(suite): Not run.
        assert(
            declaration is! TypeDeclarationBuilder ||
                declaration is BuiltinTypeDeclarationBuilder,
            "Unexpected declaration ${declaration.runtimeType}");
      }
    }
    checkPendingBoundsChecks(typeEnvironment);
  }

  void checkTypeParameterDependencies(
      List<TypeParameterBuilder> typeParameters) {
    Map<TypeParameterBuilder, TraversalState> typeParametersTraversalState =
        <TypeParameterBuilder, TraversalState>{};
    for (TypeParameterBuilder typeParameter in typeParameters) {
      if ((typeParametersTraversalState[typeParameter] ??=
              TraversalState.unvisited) ==
          TraversalState.unvisited) {
        TypeParameterCyclicDependency? dependency =
            typeParameter.findCyclicDependency(
                typeParametersTraversalState: typeParametersTraversalState);
        if (dependency != null) {
          Message message;
          if (dependency.viaTypeParameters != null) {
            message = templateCycleInTypeParameters.withArguments(
                dependency.typeParameterBoundOfItself.name,
                dependency.viaTypeParameters!.map((v) => v.name).join("', '"));
          } else {
            message = templateDirectCycleInTypeParameters
                .withArguments(dependency.typeParameterBoundOfItself.name);
          }
          addProblem(
              message,
              dependency.typeParameterBoundOfItself.fileOffset,
              dependency.typeParameterBoundOfItself.name.length,
              dependency.typeParameterBoundOfItself.fileUri);

          typeParameter.bound = new NamedTypeBuilderImpl(
              new SyntheticTypeName(
                  typeParameter.name, typeParameter.fileOffset),
              const NullabilityBuilder.omitted(),
              fileUri: typeParameter.fileUri,
              charOffset: typeParameter.fileOffset,
              instanceTypeParameterAccess:
                  InstanceTypeParameterAccessState.Unexpected)
            ..bind(
                this,
                new InvalidTypeDeclarationBuilder(
                    typeParameter.name,
                    message.withLocation(
                        dependency.typeParameterBoundOfItself
                                .fileUri ?? // Coverage-ignore(suite): Not run.
                            fileUri,
                        dependency.typeParameterBoundOfItself.fileOffset,
                        dependency.typeParameterBoundOfItself.name.length)));
        }
      }
    }
    _computeTypeParameterNullabilities(typeParameters);
  }

  void _computeTypeParameterNullabilities(
      List<TypeParameterBuilder> typeParameters) {
    Map<TypeParameterBuilder, TraversalState> typeParametersTraversalState =
        <TypeParameterBuilder, TraversalState>{};
    for (TypeParameterBuilder typeParameter in typeParameters) {
      if ((typeParametersTraversalState[typeParameter] ??=
              TraversalState.unvisited) ==
          TraversalState.unvisited) {
        typeParameter.computeNullability(
            typeParametersTraversalState: typeParametersTraversalState);
      }
    }
  }

  void forEachExtensionInScope(void Function(ExtensionBuilder) f) {
    if (_extensionsInScope == null) {
      _extensionsInScope = <ExtensionBuilder>{};
      scope.forEachExtension((e) {
        _extensionsInScope!.add(e);
      });
      Iterator<PrefixBuilder> iterator = prefixNameSpace.filteredIterator(
          includeDuplicates: false, includeAugmentations: false);
      while (iterator.moveNext()) {
        iterator.current.forEachExtension((e) {
          _extensionsInScope!.add(e);
        });
      }
    }
    _extensionsInScope!.forEach(f);
  }

  // Coverage-ignore(suite): Not run.
  void clearExtensionsInScopeCache() {
    _extensionsInScope = null;
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
        case TypeUse.extensionTypeRepresentationType:
        case TypeUse.typeArgument:
          checkBoundsInType(pendingBoundsCheck.type, typeEnvironment,
              pendingBoundsCheck.fileUri, pendingBoundsCheck.charOffset,
              inferred: pendingBoundsCheck.inferred, allowSuperBounded: true);
          break;
        case TypeUse.typedefAlias:
        case TypeUse.classExtendsType:
        case TypeUse.classImplementsType:
        // TODO(johnniwinther): Is this a correct handling wrt well-boundedness
        //  for mixin on clause?
        case TypeUse.mixinOnType:
        case TypeUse.extensionTypeImplementsType:
        case TypeUse.classWithType:
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
        // Coverage-ignore(suite): Not run.
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
                .withArguments(unaliased, type),
            fileOffset,
            noLength,
            fileUri);
      }
    }
  }

  List<DelayedDefaultValueCloner>? installTypedefTearOffs() {
    List<DelayedDefaultValueCloner>? delayedDefaultValueCloners;

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        List<DelayedDefaultValueCloner>?
            augmentationLibraryDelayedDefaultValueCloners =
            augmentationLibrary.installTypedefTearOffs();
        if (augmentationLibraryDelayedDefaultValueCloners != null) {
          // Coverage-ignore-block(suite): Not run.
          (delayedDefaultValueCloners ??= [])
              .addAll(augmentationLibraryDelayedDefaultValueCloners);
        }
      }
    }

    Iterator<SourceTypeAliasBuilder> iterator = localMembersIteratorOfType();
    while (iterator.moveNext()) {
      SourceTypeAliasBuilder declaration = iterator.current;
      DelayedDefaultValueCloner? delayedDefaultValueCloner =
          declaration.buildTypedefTearOffs(this, (Procedure procedure) {
        procedure.isStatic = true;
        if (!declaration.isAugmenting && !declaration.isDuplicate) {
          library.addProcedure(procedure);
        }
      });
      if (delayedDefaultValueCloner != null) {
        (delayedDefaultValueCloners ??= []).add(delayedDefaultValueCloner);
      }
    }

    return delayedDefaultValueCloners;
  }
}

/// This class examines all the [Class]es in a library and determines which
/// fields are promotable within that library.
class _FieldPromotability extends FieldPromotability<Class, SourceFieldBuilder,
    SourceProcedureBuilder> {
  @override
  Iterable<Class> getSuperclasses(Class class_,
      {required bool ignoreImplements}) {
    List<Class> result = [];
    Class? superclass = class_.superclass;
    if (superclass != null) {
      result.add(superclass);
    }
    Class? mixedInClass = class_.mixedInClass;
    if (mixedInClass != null) {
      result.add(mixedInClass);
    }
    if (!ignoreImplements) {
      for (Supertype interface in class_.implementedTypes) {
        result.add(interface.classNode);
      }
      if (class_.isMixinDeclaration) {
        for (Supertype supertype in class_.onClause) {
          result.add(supertype.classNode);
        }
      }
    }
    return result;
  }
}

/// Information about which fields are promotable in a given library.
class FieldNonPromotabilityInfo {
  /// Map whose keys are private field names for which promotion is blocked, and
  /// whose values are [FieldNameNonPromotabilityInfo] objects containing
  /// information about why promotion is blocked for the given name.
  ///
  /// This map is the final arbiter on whether a given property access is
  /// considered promotable, but since it is keyed on the field name, it doesn't
  /// always provide the most specific information about *why* a given property
  /// isn't promotable; for more detailed information about a specific property,
  /// see [individualPropertyReasons].
  final Map<
      String,
      FieldNameNonPromotabilityInfo<Class, SourceFieldBuilder,
          SourceProcedureBuilder>> fieldNameInfo;

  /// Map whose keys are the members that a property get might resolve to, and
  /// whose values are the reasons why the given property couldn't be promoted.
  final Map<Member, PropertyNonPromotabilityReason> individualPropertyReasons;

  FieldNonPromotabilityInfo(
      {required this.fieldNameInfo, required this.individualPropertyReasons});
}

Uri computeLibraryUri(Builder declaration) {
  Builder? current = declaration;
  while (current != null) {
    if (current is LibraryBuilder) return current.importUri;
    current = current.parent;
  }
  return unhandled("no library parent", "${declaration.runtimeType}",
      declaration.fileOffset, declaration.fileUri);
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

  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
  bool get valid => true;

  @override
  // Coverage-ignore(suite): Not run.
  Uri? get fileUri => null;

  @override
  // Coverage-ignore(suite): Not run.
  int get charOffset => -1;

  @override
  // Coverage-ignore(suite): Not run.
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
  final CompilationUnit accessor;
  final Uri fileUri;
  final int charOffset;
  final int length;

  LibraryAccess(this.accessor, this.fileUri, this.charOffset, this.length);
}

// Coverage-ignore(suite): Not run.
class SourceLibraryBuilderMemberIterator<T extends Builder>
    implements Iterator<T> {
  Iterator<T>? _iterator;
  Iterator<SourceLibraryBuilder>? augmentationBuilders;
  final bool includeDuplicates;

  factory SourceLibraryBuilderMemberIterator(
      SourceLibraryBuilder libraryBuilder,
      {required bool includeDuplicates}) {
    return new SourceLibraryBuilderMemberIterator._(libraryBuilder.origin,
        libraryBuilder.origin.augmentationLibraries?.iterator,
        includeDuplicates: includeDuplicates);
  }

  SourceLibraryBuilderMemberIterator._(
      SourceLibraryBuilder libraryBuilder, this.augmentationBuilders,
      {required this.includeDuplicates})
      : _iterator = libraryBuilder.libraryNameSpace.filteredIterator<T>(
            parent: libraryBuilder,
            includeDuplicates: includeDuplicates,
            includeAugmentations: false);

  @override
  bool moveNext() {
    if (_iterator != null) {
      if (_iterator!.moveNext()) {
        return true;
      }
    }
    if (augmentationBuilders != null && augmentationBuilders!.moveNext()) {
      SourceLibraryBuilder augmentationLibraryBuilder =
          augmentationBuilders!.current;
      _iterator = augmentationLibraryBuilder.libraryNameSpace
          .filteredIterator<T>(
              parent: augmentationLibraryBuilder,
              includeDuplicates: includeDuplicates,
              includeAugmentations: false);
    }
    if (_iterator != null) {
      if (_iterator!.moveNext()) {
        return true;
      }
    }
    return false;
  }

  @override
  T get current => _iterator?.current ?? (throw new StateError('No element'));
}

// Coverage-ignore(suite): Not run.
class SourceLibraryBuilderMemberNameIterator<T extends Builder>
    implements NameIterator<T> {
  NameIterator<T>? _iterator;
  Iterator<SourceLibraryBuilder>? augmentationBuilders;
  final bool includeDuplicates;

  factory SourceLibraryBuilderMemberNameIterator(
      SourceLibraryBuilder libraryBuilder,
      {required bool includeDuplicates}) {
    return new SourceLibraryBuilderMemberNameIterator._(libraryBuilder.origin,
        libraryBuilder.origin.augmentationLibraries?.iterator,
        includeDuplicates: includeDuplicates);
  }

  SourceLibraryBuilderMemberNameIterator._(
      SourceLibraryBuilder libraryBuilder, this.augmentationBuilders,
      {required this.includeDuplicates})
      : _iterator = libraryBuilder.libraryNameSpace.filteredNameIterator<T>(
            parent: libraryBuilder,
            includeDuplicates: includeDuplicates,
            includeAugmentations: false);

  @override
  bool moveNext() {
    if (_iterator != null) {
      if (_iterator!.moveNext()) {
        return true;
      }
    }
    if (augmentationBuilders != null && augmentationBuilders!.moveNext()) {
      SourceLibraryBuilder augmentationLibraryBuilder =
          augmentationBuilders!.current;
      _iterator = augmentationLibraryBuilder.libraryNameSpace
          .filteredNameIterator<T>(
              parent: augmentationLibraryBuilder,
              includeDuplicates: includeDuplicates,
              includeAugmentations: false);
    }
    if (_iterator != null) {
      if (_iterator!.moveNext()) {
        return true;
      }
    }
    return false;
  }

  @override
  T get current => _iterator?.current ?? (throw new StateError('No element'));

  @override
  String get name => _iterator?.name ?? (throw new StateError('No element'));
}

class Part {
  final int offset;
  final CompilationUnit compilationUnit;

  Part(this.offset, this.compilationUnit);
}

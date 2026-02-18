// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/class_member_parser.dart'
    show ClassMemberParser;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:_fe_analyzer_shared/src/util/libraries_specification.dart'
    show Importability;
import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart' hide Combinator, MapLiteralEntry;
import 'package:kernel/reference_from_index.dart' show IndexedLibrary;

import '../api_prototype/experimental_flags.dart';
import '../base/combinator.dart' show CombinatorBuilder;
import '../base/directives.dart';
import '../base/export.dart' show Export;
import '../base/extension_scope.dart';
import '../base/import.dart' show Import;
import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/name_space.dart';
import '../base/scope.dart';
import '../base/uri_offset.dart';
import '../base/uris.dart';
import '../builder/builder.dart';
import '../builder/compilation_unit.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/dynamic_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/never_type_declaration_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/property_builder.dart';
import '../builder/type_builder.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/type_algorithms.dart' show ComputeDefaultTypeContext;
import '../kernel/utils.dart' show toCombinators;
import 'fragment_factory.dart';
import 'fragment_factory_impl.dart';
import 'name_space_builder.dart';
import 'native_method_registry.dart';
import 'offset_map.dart';
import 'outline_builder.dart';
import 'source_declaration_builder.dart';
import 'source_library_builder.dart';
import 'source_loader.dart' show SourceLoader;
import 'source_member_builder.dart';
import 'source_type_alias_builder.dart';
import 'type_parameter_factory.dart';
import 'type_scope.dart';

/// Enum that define what state a source compilation unit is in, in terms of how
/// far in the compilation it has progressed. This is used to document and
/// assert the requirements of individual methods within the
/// [SourceCompilationUnitImpl].
enum SourceCompilationUnitState {
  initial,
  importsAddedToScope;

  bool operator <(SourceCompilationUnitState other) => index < other.index;

  // Coverage-ignore(suite): Not run.
  bool operator <=(SourceCompilationUnitState other) => index <= other.index;

  // Coverage-ignore(suite): Not run.
  bool operator >(SourceCompilationUnitState other) => index > other.index;

  bool operator >=(SourceCompilationUnitState other) => index >= other.index;
}

class SourceCompilationUnitImpl implements SourceCompilationUnit {
  SourceCompilationUnitState _state = SourceCompilationUnitState.initial;

  @override
  final Uri fileUri;

  @override
  final Uri importUri;

  final Uri? _packageUri;

  @override
  final Uri originImportUri;

  @override
  final SourceLoader loader;

  SourceLibraryBuilder? _libraryBuilder;

  // TODO(johnniwinther): Can we avoid this?
  final bool? _referenceIsPartOwner;

  // TODO(johnniwinther): Pass only the [Reference] instead.
  final LibraryBuilder? _nameOrigin;

  final LookupScope? _parentScope;

  final ExtensionScope? _parentExtensionScope;

  SourceCompilationUnit? _parentCompilationUnit;

  /// Map used to find objects created in the [OutlineBuilder] from within
  /// the [DietListener].
  ///
  /// This is meant to be written once and read once.
  OffsetMap? _offsetMap;

  LibraryBuilder? _partOfLibrary;

  final LibraryProblemReporting _problemReporting;

  @override
  final List<Export> exporters = <Export>[];

  /// The language version of this library as defined by the language version
  /// of the package it belongs to, if present, or the current language version
  /// otherwise.
  ///
  /// This language version will be used as the language version for the library
  /// if the library does not contain an explicit @dart= annotation.
  @override
  final LanguageVersion packageLanguageVersion;

  /// The actual language version of this library. This is initially the
  /// [packageLanguageVersion] but will be updated if the library contains
  /// an explicit @dart= language version annotation.
  LanguageVersion _languageVersion;

  bool _postponedProblemsIssued = false;
  List<PostponedProblem>? _postponedProblems;

  /// Index of the library we use references for.
  @override
  final IndexedLibrary? indexedLibrary;

  final _CompilationUnitData _compilationUnitData = new _CompilationUnitData();

  final NativeMethodRegistry _native = new NativeMethodRegistry();

  final TypeParameterFactory _typeParameterFactory = new TypeParameterFactory();

  final LibraryNameSpaceBuilder _libraryNameSpaceBuilder;

  final SourceCompilationUnit? _augmentationRoot;

  final ComputedMutableNameSpace _importNameSpace;

  final ExtensionsBuilder _importedExtensions = new ExtensionsBuilder();

  late final LookupScope _importScope;

  final MutableNameSpace _prefixNameSpace;

  late final LookupScope _prefixScope;

  late final ExtensionScope _prefixExtensionScope;

  LibraryFeatures? _libraryFeatures;

  @override
  final bool forAugmentationLibrary;

  @override
  final bool forPatchLibrary;

  @override
  final bool isAugmenting;

  @override
  final bool conditionalImportSupported;

  @override
  final Importability importability;

  late final LookupScope _compilationUnitScope;

  late final ExtensionScope _compilationUnitExtensionScope;

  late final TypeScope _typeScope;

  @override
  final bool mayImplementRestrictedTypes;

  factory SourceCompilationUnitImpl({
    required Uri importUri,
    required Uri fileUri,
    required Uri? packageUri,
    required LanguageVersion packageLanguageVersion,
    required Uri originImportUri,
    required IndexedLibrary? indexedLibrary,
    Map<String, Builder>? omittedTypeDeclarationBuilders,
    LookupScope? parentScope,
    ExtensionScope? parentExtensionScope,
    required bool forAugmentationLibrary,
    required SourceCompilationUnit? augmentationRoot,
    required LibraryBuilder? resolveInLibrary,
    required bool? referenceIsPartOwner,
    required bool forPatchLibrary,
    required bool isAugmenting,
    required bool conditionalImportSupported,
    required Importability importability,
    required SourceLoader loader,
    required bool mayImplementRestrictedTypes,
  }) {
    LibraryNameSpaceBuilder libraryNameSpaceBuilder =
        new LibraryNameSpaceBuilder();
    ComputedMutableNameSpace importNameSpace = new ComputedMutableNameSpace();
    ComputedMutableNameSpace prefixNameSpace = new ComputedMutableNameSpace();
    return new SourceCompilationUnitImpl._(
      libraryNameSpaceBuilder,
      importUri: importUri,
      fileUri: fileUri,
      packageUri: packageUri,
      packageLanguageVersion: packageLanguageVersion,
      originImportUri: originImportUri,
      indexedLibrary: indexedLibrary,
      parentScope: parentScope,
      parentExtensionScope: parentExtensionScope,
      importNameSpace: importNameSpace,
      prefixNameSpace: prefixNameSpace,
      forAugmentationLibrary: forAugmentationLibrary,
      augmentationRoot: augmentationRoot,
      resolveInLibrary: resolveInLibrary,
      referenceIsPartOwner: referenceIsPartOwner,
      forPatchLibrary: forPatchLibrary,
      isAugmenting: isAugmenting,
      conditionalImportSupported: conditionalImportSupported,
      importability: importability,
      loader: loader,
      mayImplementRestrictedTypes: mayImplementRestrictedTypes,
    );
  }

  SourceCompilationUnitImpl._(
    LibraryNameSpaceBuilder libraryNameSpaceBuilder, {
    required this.importUri,
    required this.fileUri,
    required Uri? packageUri,
    required this.packageLanguageVersion,
    required this.originImportUri,
    required this.indexedLibrary,
    LookupScope? parentScope,
    ExtensionScope? parentExtensionScope,
    required ComputedMutableNameSpace importNameSpace,
    required ComputedMutableNameSpace prefixNameSpace,
    required this.forAugmentationLibrary,
    required SourceCompilationUnit? augmentationRoot,
    required LibraryBuilder? resolveInLibrary,
    required bool? referenceIsPartOwner,
    required this.forPatchLibrary,
    required this.isAugmenting,
    required this.conditionalImportSupported,
    required this.importability,
    required this.loader,
    required this.mayImplementRestrictedTypes,
  }) : _languageVersion = packageLanguageVersion,
       _packageUri = packageUri,
       _libraryNameSpaceBuilder = libraryNameSpaceBuilder,
       _importNameSpace = importNameSpace,
       _prefixNameSpace = prefixNameSpace,
       _nameOrigin = resolveInLibrary,
       _parentScope = parentScope,
       _parentExtensionScope = parentExtensionScope,
       _referenceIsPartOwner = referenceIsPartOwner,
       _problemReporting = new LibraryProblemReporting(loader, fileUri),
       _augmentationRoot = augmentationRoot {
    CompilationUnitImportScope importScope = _importScope =
        new CompilationUnitImportScope(this, _importNameSpace);
    ExtensionScope extensionScope = new CompilationUnitImportExtensionScope(
      this,
      _importedExtensions,
    );
    _prefixScope = new CompilationUnitPrefixScope(
      prefixNameSpace,
      parent: importScope,
    );
    _prefixExtensionScope = new CompilationUnitPrefixExtensionScope(
      prefixNameSpace,
      parent: extensionScope,
    );
    LookupScope libraryScope = _prefixScope;
    ExtensionScope libraryExtensionScope = _prefixExtensionScope;
    if (resolveInLibrary != null) {
      // Coverage-ignore-block(suite): Not run.
      libraryScope = new NameSpaceLookupScope(
        resolveInLibrary.libraryNameSpace,
        parent: libraryScope,
      );
      libraryExtensionScope = new ParentLibraryExtensionScope(
        resolveInLibrary.libraryExtensions,
        parent: libraryExtensionScope,
      );
    }
    _compilationUnitScope = new CompilationUnitScope(
      this,
      parent: libraryScope,
    );
    _compilationUnitExtensionScope = new CompilationUnitExtensionScope(
      this,
      parent: libraryExtensionScope,
    );
    _typeScope = new TypeScope(TypeScopeKind.library, _compilationUnitScope);
  }

  SourceCompilationUnitState get state => _state;

  void set state(SourceCompilationUnitState value) {
    assert(
      _state < value,
      "State $value has already been reached at $_state in $this.",
    );
    assert(
      _state.index + 1 == value.index,
      _state.index + 1 < SourceCompilationUnitState.values.length
          ? "Expected state "
                "${SourceCompilationUnitState.values[_state.index + 1]} "
                "to follow from $_state, trying to set next state to $value "
                "in $this."
          : "No more states expected to follow from $_state, trying to set "
                "next state to $value in $this.",
    );
    _state = value;
  }

  bool checkState({
    List<SourceCompilationUnitState>? required,
    List<SourceCompilationUnitState>? pending,
  }) {
    if (required != null) {
      for (SourceCompilationUnitState requiredState in required) {
        assert(
          state >= requiredState,
          "State $requiredState required, but found $state in $this.",
        );
      }
    }
    if (pending != null) {
      // Coverage-ignore-block(suite): Not run.
      for (SourceCompilationUnitState pendingState in pending) {
        assert(
          state < pendingState,
          "State $pendingState must not have been reached, "
          "but found $state in $this.",
        );
      }
    }
    return true;
  }

  @override
  LibraryFeatures get libraryFeatures =>
      _libraryFeatures ??= new LibraryFeatures(
        loader.target.globalFeatures,
        _packageUri ?? originImportUri,
        languageVersion.version,
      );

  @override
  bool get isDartLibrary =>
      originImportUri.isScheme("dart") || fileUri.isScheme("org-dartlang-sdk");

  @override
  bool get isPatch => forPatchLibrary;

  /// Returns the map of objects created in the [OutlineBuilder].
  ///
  /// This should only be called once.
  @override
  OffsetMap get offsetMap {
    assert(_offsetMap != null, "No OffsetMap for $this");
    OffsetMap map = _offsetMap!;
    _offsetMap = null;
    return map;
  }

  @override
  SourceLibraryBuilder get libraryBuilder {
    assert(
      _libraryBuilder != null,
      "Library builder for $this has not been computed yet.",
    );
    return _libraryBuilder!;
  }

  List<CompilationUnit>? _augmentations;

  @override
  void registerAugmentation(CompilationUnit augmentation) {
    (_augmentations ??= []).add(augmentation);
  }

  @override
  SourceCompilationUnit? get parentCompilationUnit => _parentCompilationUnit;

  @override
  void addExporter(
    SourceCompilationUnit exporter,
    List<CombinatorBuilder>? combinators,
    int charOffset,
  ) {
    exporters.add(new Export(exporter, this, combinators, charOffset));
  }

  @override
  void addProblem(
    Message message,
    int charOffset,
    int length,
    Uri? fileUri, {
    bool wasHandled = false,
    List<LocatedMessage>? context,
    CfeSeverity? severity,
    bool problemOnLibrary = false,
  }) {
    _problemReporting.addProblem(
      message,
      charOffset,
      length,
      fileUri,
      wasHandled: wasHandled,
      context: context,
      severity: severity,
      problemOnLibrary: problemOnLibrary,
    );
  }

  @override
  final List<LibraryAccess> accessors = [];

  @override
  Message? accessProblem;

  @override
  void addProblemAtAccessors(Message message) {
    if (accessProblem == null) {
      if (accessors.isEmpty &&
          // Coverage-ignore(suite): Not run.
          loader.roots.contains(this.importUri)) {
        // Coverage-ignore-block(suite): Not run.
        // This is the entry point library, and nobody access it directly. So
        // we need to report a problem.
        loader.addProblem(message, -1, 1, null);
      }
      for (int i = 0; i < accessors.length; i++) {
        LibraryAccess access = accessors[i];
        access.accessor.addProblem(
          message,
          access.charOffset,
          access.length,
          access.fileUri,
        );
      }
      accessProblem = message;
    }
  }

  @override
  LanguageVersion get languageVersion {
    assert(
      _languageVersion.isFinal,
      "Attempting to read the language version of ${this} before has been "
      "finalized.",
    );
    return _languageVersion;
  }

  @override
  void markLanguageVersionFinal() {
    _languageVersion.isFinal = true;
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
  @override
  void registerExplicitLanguageVersion(
    Version version, {
    int offset = 0,
    int length = noLength,
  }) {
    if (_languageVersion.isExplicit) {
      // If more than once language version exists we use the first.
      return;
    }
    assert(!_languageVersion.isFinal);

    if (version > loader.target.currentSdkVersion) {
      // If trying to set a language version that is higher than the current sdk
      // version it's an error.
      addPostponedProblem(
        diag.languageVersionTooHighExplicit.withArguments(
          specifiedMajor: version.major,
          specifiedMinor: version.minor,
          highestSupportedMajor: loader.target.currentSdkVersion.major,
          highestSupportedMinor: loader.target.currentSdkVersion.minor,
        ),
        offset,
        length,
        fileUri,
      );
      // If the package set an OK version, but the file set an invalid version
      // we want to use the package version.
      _languageVersion = new InvalidLanguageVersion(
        fileUri,
        offset,
        length,
        packageLanguageVersion.version,
        true,
      );
    } else if (version < loader.target.leastSupportedVersion) {
      addPostponedProblem(
        diag.languageVersionTooLowExplicit.withArguments(
          specifiedMajor: version.major,
          specifiedMinor: version.minor,
          lowestSupportedMajor: loader.target.leastSupportedVersion.major,
          lowestSupportedMinor: loader.target.leastSupportedVersion.minor,
        ),
        offset,
        length,
        fileUri,
      );
      _languageVersion = new InvalidLanguageVersion(
        fileUri,
        offset,
        length,
        loader.target.leastSupportedVersion,
        true,
      );
    } else {
      _languageVersion = new LanguageVersion(version, fileUri, offset, length);
    }
    _languageVersion.isFinal = true;
  }

  @override
  void addPostponedProblem(
    Message message,
    int charOffset,
    int length,
    Uri fileUri,
  ) {
    if (_postponedProblemsIssued) {
      // Coverage-ignore-block(suite): Not run.
      addProblem(message, charOffset, length, fileUri);
    } else {
      _postponedProblems ??= <PostponedProblem>[];
      _postponedProblems!.add(
        new PostponedProblem(message, charOffset, length, fileUri),
      );
    }
  }

  @override
  void issuePostponedProblems() {
    _postponedProblemsIssued = true;
    if (_postponedProblems == null) return;
    for (int i = 0; i < _postponedProblems!.length; ++i) {
      PostponedProblem postponedProblem = _postponedProblems![i];
      addProblem(
        postponedProblem.message,
        postponedProblem.charOffset,
        postponedProblem.length,
        postponedProblem.fileUri,
      );
    }
    _postponedProblems = null;
  }

  @override
  Iterable<Uri> get dependencies sync* {
    for (Export export in _compilationUnitData.exports) {
      yield export.exportedCompilationUnit.importUri;
    }
    for (Import import in _compilationUnitData.imports) {
      CompilationUnit? imported = import.importedCompilationUnit;
      if (imported != null) {
        yield imported.importUri;
      }
    }
  }

  @override
  bool get isPart => _compilationUnitData.isPart;

  @override
  bool get isSynthetic => accessProblem != null;

  @override
  LibraryBuilder? get partOfLibrary => _partOfLibrary;

  @override
  void recordAccess(
    CompilationUnit accessor,
    int charOffset,
    int length,
    Uri fileUri,
  ) {
    accessors.add(new LibraryAccess(accessor, fileUri, charOffset, length));
    if (accessProblem != null) {
      // Coverage-ignore-block(suite): Not run.
      addProblem(accessProblem!, charOffset, length, fileUri);
    }
  }

  @override
  void buildOutline(Token tokens) {
    assert(_offsetMap == null, "OffsetMap has already been set for $this");

    // TODO(johnniwinther): Create these in [createOutlineBuilder].
    FragmentFactory fragmentFactory = new FragmentFactoryImpl(
      compilationUnit: this,
      augmentationRoot: _augmentationRoot ?? this,
      libraryNameSpaceBuilder: _libraryNameSpaceBuilder,
      problemReporting: _problemReporting,
      scope: _compilationUnitScope,
      indexedLibrary: indexedLibrary,
      typeParameterFactory: _typeParameterFactory,
      typeScope: _typeScope,
      compilationUnitRegistry: _compilationUnitData,
      nativeMethodRegistry: _native,
    );

    OutlineBuilder listener = new OutlineBuilder(
      _problemReporting,
      this,
      fragmentFactory,
      _offsetMap = new OffsetMap(fileUri),
    );

    new ClassMemberParser(
      listener,
      experimentalFeatures: new LibraryExperimentalFeatures(libraryFeatures),
    ).parseUnit(tokens);
  }

  @override
  SourceLibraryBuilder createLibrary([Library? library]) {
    assert(
      _languageVersion.isFinal,
      "Can not create a SourceLibraryBuilder before the language version of "
      "the compilation unit is finalized.",
    );
    assert(
      _libraryBuilder == null,
      "Source library builder as already been created for $this.",
    );
    SourceLibraryBuilder libraryBuilder = _libraryBuilder =
        new SourceLibraryBuilder(
          compilationUnit: this,
          importUri: importUri,
          fileUri: fileUri,
          packageUri: _packageUri,
          originImportUri: originImportUri,
          packageLanguageVersion: packageLanguageVersion,
          loader: loader,
          nameOrigin: _nameOrigin,
          target: library,
          indexedLibrary: indexedLibrary,
          referenceIsPartOwner: _referenceIsPartOwner,
          conditionalImportSupported: conditionalImportSupported,
          isAugmentation: forAugmentationLibrary,
          isPatch: forPatchLibrary,
          parentScope: _parentScope,
          parentExtensionScope: _parentExtensionScope,
          importNameSpace: _importNameSpace,
          libraryNameSpaceBuilder: _libraryNameSpaceBuilder,
        );
    _problemReporting.registerLibrary(libraryBuilder.library);
    if (isPart) {
      // This is a part with no enclosing library.
      addProblem(diag.partOrphan, 0, 1, fileUri);
      _compilationUnitData.parts.clear();
      _reportExporters();
    }
    return libraryBuilder;
  }

  @override
  String toString() => 'SourceCompilationUnitImpl($fileUri)';

  void _addNativeDependency(Library library, String nativeImportPath) {
    MemberBuilder constructor = loader.getNativeAnnotation();
    Arguments arguments = new Arguments(<Expression>[
      new StringLiteral(nativeImportPath),
    ]);
    Expression annotation;
    if (constructor is ConstructorBuilder) {
      annotation = new ConstructorInvocation(
        constructor.invokeTarget as Constructor,
        arguments,
      )..isConst = true;
    } else {
      // Coverage-ignore-block(suite): Not run.
      annotation = new StaticInvocation(
        constructor.invokeTarget as Procedure,
        arguments,
      )..isConst = true;
    }
    library.addAnnotation(annotation);
  }

  @override
  void addDependencies({
    required Library library,
    required Set<SourceCompilationUnit> seen,
    required Map<String, int> deferredNames,
  }) {
    assert(
      checkState(required: [SourceCompilationUnitState.importsAddedToScope]),
    );

    if (!seen.add(this)) {
      return;
    }

    for (Import import in _compilationUnitData.imports) {
      // Rather than add a LibraryDependency, we attach an annotation.
      if (import.nativeImportPath != null) {
        _addNativeDependency(library, import.nativeImportPath!);
        continue;
      }

      LibraryDependency libraryDependency;
      if (import.deferred &&
          import.prefixFragment?.builder.dependency != null) {
        libraryDependency = import.prefixFragment!.builder.dependency!;
        int? index = deferredNames[import.prefix!];
        if (index != null) {
          libraryDependency.name = '${libraryDependency.name}#$index';
          index++;
        } else {
          index = 1;
        }
        deferredNames[import.prefix!] = index;
      } else {
        LibraryBuilder imported = import.importedLibraryBuilder!;
        Library targetLibrary = imported.library;
        libraryDependency = new LibraryDependency.import(
          targetLibrary,
          name: import.prefix,
          combinators: toCombinators(import.combinators),
        )..fileOffset = import.importOffset;
      }
      library.addDependency(libraryDependency);
      import.libraryDependency = libraryDependency;
    }
    for (Export export in _compilationUnitData.exports) {
      LibraryDependency libraryDependency = new LibraryDependency.export(
        export.exportedLibraryBuilder.library,
        combinators: toCombinators(export.combinators),
      )..fileOffset = export.charOffset;
      library.addDependency(libraryDependency);
      export.libraryDependency = libraryDependency;
    }
  }

  @override
  PartOf? get partOfDirective => _compilationUnitData.partOf;

  @override
  ExtensionScope get extensionScope => _compilationUnitExtensionScope;

  @override
  LookupScope get compilationUnitScope => _compilationUnitScope;

  // Coverage-ignore(suite): Not run.
  LookupScope get importScope => _importScope;

  @override
  LookupScope get prefixScope => _prefixScope;

  @override
  ExtensionScope get prefixExtensionScope => _prefixExtensionScope;

  @override
  NameSpace get prefixNameSpace => _prefixNameSpace;

  @override
  PrefixBuilder? lookupPrefixBuilder(String name) {
    LookupResult? prefixLookupResult = prefixScope.lookup(name);
    if (prefixLookupResult != null) {
      if (!prefixLookupResult.isInvalidLookup &&
          prefixLookupResult.getable is PrefixBuilder) {
        PrefixBuilder prefixBuilder =
            prefixLookupResult.getable as PrefixBuilder;
        if (prefixBuilder.deferred) {
          // Deferred prefixes are not extended.
          return null;
        } else {
          // The parent scope has a non-deferred prefix by the same name.
          return prefixLookupResult.getable as PrefixBuilder;
        }
      } else {
        // A non-prefix builder shadows the parent prefix scope of the same
        // name.
        return null;
      }
    } else {
      return parentCompilationUnit?.lookupPrefixBuilder(name);
    }
  }

  @override
  void includeParts(
    List<SourceCompilationUnit> includedParts,
    Set<Uri> usedParts,
  ) {
    _includeParts(
      libraryBuilder: libraryBuilder,
      libraryNameSpaceBuilder: _libraryNameSpaceBuilder,
      includedParts: includedParts,
      usedParts: usedParts,
    );
  }

  void _includeParts({
    required SourceLibraryBuilder libraryBuilder,
    required LibraryNameSpaceBuilder libraryNameSpaceBuilder,
    required List<SourceCompilationUnit> includedParts,
    required Set<Uri> usedParts,
  }) {
    Set<Uri> seenParts = new Set<Uri>();
    for (Part part in _compilationUnitData.parts) {
      if (part.compilationUnit == this) {
        addProblem(diag.partOfSelf, part.fileOffset, noLength, part.fileUri);
      } else if (seenParts.add(part.compilationUnit.fileUri)) {
        if (part.compilationUnit.partOfLibrary != null) {
          addProblem(
            diag.partOfTwoLibraries,
            part.fileOffset,
            noLength,
            part.fileUri,
            context: [
              diag.partOfTwoLibrariesContext.withLocation(
                part.compilationUnit.partOfLibrary!.fileUri,
                -1,
                noLength,
              ),
              diag.partOfTwoLibrariesContext.withLocation(
                fileUri,
                -1,
                noLength,
              ),
            ],
          );
        } else {
          usedParts.add(part.compilationUnit.importUri);
          _includePartIfValid(
            libraryBuilder: libraryBuilder,
            libraryNameSpaceBuilder: libraryNameSpaceBuilder,
            parentCompilationUnit: this,
            includedParts: includedParts,
            part: part.compilationUnit,
            usedParts: usedParts,
            partOffset: part.fileOffset,
            partUri: fileUri,
          );
        }
      } else {
        addProblem(
          diag.partTwice.withArguments(uri: part.compilationUnit.fileUri),
          part.fileOffset,
          noLength,
          part.fileUri,
        );
      }
    }
    if (_augmentations != null) {
      for (CompilationUnit augmentation in _augmentations!) {
        switch (augmentation) {
          case SourceCompilationUnit():
            _includePart(
              libraryBuilder,
              libraryNameSpaceBuilder,
              this,
              includedParts,
              augmentation,
              usedParts,
              partOffset: -1,
              partUri: augmentation.fileUri,
              allowPartInParts: true,
            );
          // Coverage-ignore(suite): Not run.
          case DillCompilationUnit():
            // TODO(johnniwinther): Report an error here.
            throw new UnsupportedError("Unexpected augmentation $augmentation");
        }
      }
    }
  }

  void _includePartIfValid({
    required SourceLibraryBuilder libraryBuilder,
    required LibraryNameSpaceBuilder libraryNameSpaceBuilder,
    required SourceCompilationUnit parentCompilationUnit,
    required List<SourceCompilationUnit> includedParts,
    required CompilationUnit part,
    required Set<Uri> usedParts,
    required Uri partUri,
    required int partOffset,
  }) {
    switch (part) {
      case SourceCompilationUnit():
        PartOf? partOf = part.partOfDirective;
        if (partOf != null) {
          Uri? partOfUri = partOf.parentUri;
          if (partOfUri != null) {
            if (isNotMalformedUriScheme(partOfUri) &&
                partOfUri != parentCompilationUnit.importUri) {
              parentCompilationUnit.addProblem(
                diag.partOfUriMismatch.withArguments(
                  partUri: part.fileUri,
                  libraryUri: parentCompilationUnit.importUri,
                  partOfUri: partOfUri,
                ),
                partOffset,
                noLength,
                parentCompilationUnit.fileUri,
              );
              return;
            }
          } else {
            String partOfName = partOf.name!;
            String? libraryName = parentCompilationUnit.libraryDirective?.name;
            if (libraryName != null) {
              if (partOfName != libraryName) {
                parentCompilationUnit.addProblem(
                  diag.partOfLibraryNameMismatch.withArguments(
                    uri: part.fileUri,
                    libraryName: libraryName,
                    partOfName: partOfName,
                  ),
                  partOffset,
                  noLength,
                  parentCompilationUnit.fileUri,
                );
                return;
              }
            } else {
              parentCompilationUnit.addProblem(
                diag.partOfUseUri.withArguments(
                  partFileUri: part.fileUri,
                  libraryUri: parentCompilationUnit.fileUri,
                  partOfName: partOfName,
                ),
                partOffset,
                noLength,
                parentCompilationUnit.fileUri,
              );
              return;
            }
          }
          LibraryDirective? libraryDirective = part.libraryDirective;
          if (libraryDirective != null) {
            part.addProblem(
              diag.partWithLibraryDirective,
              libraryDirective.fileOffset,
              noLength,
              libraryDirective.fileUri,
            );
          }
        } else {
          assert(!part.isPart);
          if (isNotMalformedUriScheme(part.fileUri)) {
            parentCompilationUnit.addProblem(
              diag.missingPartOf.withArguments(uri: part.fileUri),
              partOffset,
              noLength,
              parentCompilationUnit.fileUri,
            );
          }
          return;
        }
        _includePart(
          libraryBuilder,
          libraryNameSpaceBuilder,
          parentCompilationUnit,
          includedParts,
          part,
          usedParts,
          partOffset: partOffset,
          partUri: partUri,
          allowPartInParts:
              parentCompilationUnit.libraryFeatures.enhancedParts.isEnabled,
        );
      case DillCompilationUnit():
        // Trying to add a dill library builder as a part means that it exists
        // as a stand-alone library in the dill file.
        // This means, that it's not a part (if it had been it would be been
        // "merged in" to the real library and thus not been a library on its
        // own) so we behave like if it's a library with a missing "part of"
        // declaration (i.e. as it was a SourceLibraryBuilder without a
        // "part of" declaration).
        if (isNotMalformedUriScheme(part.fileUri)) {
          parentCompilationUnit.addProblem(
            diag.missingPartOf.withArguments(uri: part.fileUri),
            partOffset,
            noLength,
            parentCompilationUnit.fileUri,
          );
        }
    }
  }

  void _includePart(
    SourceLibraryBuilder libraryBuilder,
    LibraryNameSpaceBuilder libraryNameSpaceBuilder,
    SourceCompilationUnit parentCompilationUnit,
    List<SourceCompilationUnit> includedParts,
    SourceCompilationUnit part,
    Set<Uri> usedParts, {
    required int partOffset,
    required Uri partUri,
    required bool allowPartInParts,
  }) {
    // Language versions have to match. Except if (at least) one of them is
    // invalid in which case we've already gotten an error about this.
    if (parentCompilationUnit.languageVersion != part.languageVersion &&
        parentCompilationUnit.languageVersion.valid &&
        part.languageVersion.valid) {
      // This is an error, but the part is not removed from the list of
      // parts, so that metadata annotations can be associated with it.
      List<LocatedMessage> context = <LocatedMessage>[];
      if (parentCompilationUnit.languageVersion.isExplicit) {
        context.add(
          diag.languageVersionLibraryContext.withLocation(
            parentCompilationUnit.languageVersion.fileUri!,
            parentCompilationUnit.languageVersion.charOffset,
            parentCompilationUnit.languageVersion.charCount,
          ),
        );
      }

      if (part.isPatch) {
        // Coverage-ignore-block(suite): Not run.
        if (part.languageVersion.isExplicit) {
          // Patches are implicitly include, so if we have an explicit language
          // version, then point to this instead of the top of the file.
          partOffset = part.languageVersion.charOffset;
          partUri = part.languageVersion.fileUri!;
          context.add(
            diag.languageVersionPatchContext.withLocation(
              part.languageVersion.fileUri!,
              part.languageVersion.charOffset,
              part.languageVersion.charCount,
            ),
          );
        }
        parentCompilationUnit.addProblem(
          diag.languageVersionMismatchInPatch,
          partOffset,
          noLength,
          partUri,
          context: context,
        );
      } else {
        if (part.languageVersion.isExplicit) {
          context.add(
            diag.languageVersionPartContext.withLocation(
              part.languageVersion.fileUri!,
              part.languageVersion.charOffset,
              part.languageVersion.charCount,
            ),
          );
        }
        parentCompilationUnit.addProblem(
          diag.languageVersionMismatchInPart,
          partOffset,
          noLength,
          partUri,
          context: context,
        );
      }
    }

    includedParts.add(part);
    part.becomePart(
      libraryBuilder,
      libraryNameSpaceBuilder,
      parentCompilationUnit,
      includedParts,
      usedParts,
      allowPartInParts: allowPartInParts,
    );
  }

  void _becomePart(
    SourceLibraryBuilder libraryBuilder,
    LibraryNameSpaceBuilder libraryNameSpaceBuilder,
  ) {
    libraryNameSpaceBuilder.includeBuilders(_libraryNameSpaceBuilder);

    // TODO(ahe): Include metadata from part?

    // Recovery: Take on all exporters (i.e. if a library has erroneously
    // exported the part it has (in validatePart) been recovered to import
    // the main library (this) instead --- to make it complete (and set up
    // scopes correctly) the exporters in this has to be updated too).
    libraryBuilder.exporters.addAll(exporters);

    // Check that the targets are different. This is not normally a problem
    // but is for augmentation libraries.

    _problemReporting.registerLibrary(libraryBuilder.library);
  }

  @override
  int resolveTypes(ProblemReporting problemReporting) {
    return _typeScope.resolveTypes(problemReporting);
  }

  @override
  int finishNativeMethods(SourceLoader loader) {
    return _native.finishNativeMethods(loader);
  }

  void _reportExporters() {
    if (exporters.isNotEmpty) {
      List<LocatedMessage> context = <LocatedMessage>[
        diag.partExportContext.withLocation(fileUri, -1, 1),
      ];
      for (Export export in exporters) {
        export.exporter.addProblem(
          diag.partExport,
          export.charOffset,
          "export".length,
          null,
          context: context,
        );
      }
    }
  }

  @override
  void becomePart(
    SourceLibraryBuilder libraryBuilder,
    LibraryNameSpaceBuilder libraryNameSpaceBuilder,
    SourceCompilationUnit parentCompilationUnit,
    List<SourceCompilationUnit> includedParts,
    Set<Uri> usedParts, {
    required bool allowPartInParts,
  }) {
    assert(
      _libraryBuilder == null,
      "Compilation unit $this is already part of library $_libraryBuilder. "
      "Trying to include it in $libraryBuilder.",
    );
    _libraryBuilder = libraryBuilder;
    _partOfLibrary = libraryBuilder;
    _parentCompilationUnit = parentCompilationUnit;
    if (!allowPartInParts) {
      if (_compilationUnitData.parts.isNotEmpty) {
        List<LocatedMessage> context = <LocatedMessage>[
          diag.partInPartLibraryContext.withLocation(
            libraryBuilder.fileUri,
            -1,
            1,
          ),
        ];
        for (Part part in _compilationUnitData.parts) {
          addProblem(
            diag.partInPart,
            part.fileOffset,
            noLength,
            fileUri,
            context: context,
          );
          // Mark this part as used so we don't report it as orphaned.
          usedParts.add(part.compilationUnit.importUri);
        }
      }
      _compilationUnitData.parts.clear();
      _reportExporters();
      _becomePart(libraryBuilder, libraryNameSpaceBuilder);
    } else {
      _reportExporters();
      _becomePart(libraryBuilder, libraryNameSpaceBuilder);
      _includeParts(
        libraryBuilder: libraryBuilder,
        libraryNameSpaceBuilder: libraryNameSpaceBuilder,
        includedParts: includedParts,
        usedParts: usedParts,
      );
    }
  }

  @override
  void buildOutlineExpressions({
    required Annotatable annotatable,
    required Uri annotatableFileUri,
    required BodyBuilderContext bodyBuilderContext,
  }) {
    MetadataBuilder.buildAnnotations(
      annotatable: annotatable,
      annotatableFileUri: annotatableFileUri,
      metadata: metadata,
      annotationsFileUri: fileUri,
      bodyBuilderContext: bodyBuilderContext,
      libraryBuilder: libraryBuilder,
      extensionScope: extensionScope,
      scope: compilationUnitScope,
    );
  }

  @override
  List<TypeParameterBuilder> collectUnboundTypeParameters() {
    return _typeParameterFactory.collectTypeParameters();
  }

  @override
  // Coverage-ignore(suite): Not run.
  void addSyntheticImport({
    required Uri importUri,
    required String? prefix,
    required List<CombinatorBuilder>? combinators,
    required bool deferred,
  }) {
    assert(
      checkState(pending: [SourceCompilationUnitState.importsAddedToScope]),
    );
    CompilationUnit? compilationUnit = loader.read(
      importUri,
      -1,
      origin: null,
      accessor: this,
      isAugmentation: false,
      referencesFromIndex: indexedLibrary,
    );
    Import import = new Import(
      this,
      compilationUnit,
      false,
      deferred,
      prefix,
      combinators,
      null,
      fileUri,
      -1,
      -1,
      nativeImportPath: null,
    );
    _compilationUnitData.registerImport(import);
  }

  @override
  void addImportsToScope() {
    assert(checkState(required: [SourceCompilationUnitState.initial]));

    bool hasCoreImport =
        originImportUri == dartCore &&
        // Coverage-ignore(suite): Not run.
        !forPatchLibrary;
    for (Import import in _compilationUnitData.imports) {
      if (import.importedCompilationUnit?.isPart ?? false) {
        addProblem(
          diag.partOfInLibrary.withArguments(
            uri: import.importedCompilationUnit!.fileUri,
          ),
          import.importOffset,
          noLength,
          fileUri,
        );
      }
      if (import.importedLibraryBuilder == loader.coreLibrary) {
        hasCoreImport = true;
      }
      import.finalizeImports(this);
    }
    if (parentCompilationUnit == null && !hasCoreImport) {
      // 'dart:core' should only be implicitly imported into the root
      // compilation unit. Parts without imports will have access to 'dart:core'
      // from the parent compilation unit.

      // TODO(johnniwinther): Can we create the core import as a parent scope
      //  instead of copying it everywhere?
      Iterator<NamedBuilder> iterator = loader.coreLibrary.exportNameSpace
          .filteredIterator();
      while (iterator.moveNext()) {
        NamedBuilder builder = iterator.current;
        addImportedBuilderToScope(
          name: builder.name,
          builder: builder,
          charOffset: -1,
        );
      }
    }

    state = SourceCompilationUnitState.importsAddedToScope;
  }

  @override
  void addImportedBuilderToScope({
    required String name,
    required NamedBuilder builder,
    required int charOffset,
  }) {
    bool isSetter = isMappedAsSetter(builder);
    LookupResult? result = _importNameSpace.lookup(name);

    NamedBuilder? existing = isSetter ? result?.setable : result?.getable;
    if (existing != null) {
      if (existing != builder) {
        _importNameSpace.replaceLocalMember(
          name,
          computeAmbiguousDeclarationForImport(
            _problemReporting,
            name,
            existing,
            builder,
            uriOffset: new UriOffset(fileUri, charOffset),
          ),
          setter: isSetter,
        );
      }
    } else {
      _importNameSpace.addLocalMember(name, builder, setter: isSetter);
    }
    if (builder is ExtensionBuilder) {
      _importedExtensions.addExtension(builder);
    }
  }

  @override
  void buildOutlineNode(Library library) {
    for (LibraryPart libraryPart in _compilationUnitData.libraryParts) {
      library.addPart(libraryPart);
    }
  }

  @override
  int finishDeferredLoadTearOffs(Library library) {
    assert(
      checkState(required: [SourceCompilationUnitState.importsAddedToScope]),
    );

    int total = 0;
    for (Import import in _compilationUnitData.imports) {
      if (import.deferred) {
        Procedure? tearoff =
            import.prefixFragment!.builder.loadLibraryBuilder?.tearoff;
        // In case of conflict between deferred and non-deferred prefixes of
        // the same name, the [PrefixBuilder] might not have a load library
        // function.
        if (tearoff != null) {
          library.addProcedure(tearoff);
        }
        total++;
      }
    }
    return total;
  }

  @override
  List<MetadataBuilder>? get metadata => _compilationUnitData.metadata;

  @override
  LibraryDirective? get libraryDirective =>
      _compilationUnitData.libraryDirective;

  @override
  int computeDefaultTypes(
    TypeBuilder dynamicType,
    TypeBuilder nullType,
    TypeBuilder bottomType,
    ClassBuilder objectClass,
  ) {
    int count = 0;

    ComputeDefaultTypeContext context = new ComputeDefaultTypeContext(
      _problemReporting,
      libraryFeatures,
      _typeParameterFactory,
      dynamicType: dynamicType,
      bottomType: bottomType,
    );

    Iterator<NamedBuilder> iterator = libraryBuilder.unfilteredMembersIterator;
    while (iterator.moveNext()) {
      NamedBuilder declaration = iterator.current;
      if (declaration is SourceDeclarationBuilder) {
        count += declaration.computeDefaultTypes(context);
      } else if (declaration is SourceTypeAliasBuilder) {
        count += declaration.computeDefaultType(context);
      } else if (declaration is SourceMemberBuilder) {
        count += declaration.computeDefaultTypes(
          context,
          inErrorRecovery: false,
        );
      } else {
        // Coverage-ignore-block(suite): Not run.
        assert(
          declaration is PrefixBuilder ||
              declaration is DynamicTypeDeclarationBuilder ||
              declaration is NeverTypeDeclarationBuilder,
          "Unexpected top level member $declaration "
          "(${declaration.runtimeType}).",
        );
      }
    }

    return count;
  }

  @override
  int computeVariances() {
    int count = 0;

    Iterator<NamedBuilder> iterator = libraryBuilder.unfilteredMembersIterator;
    while (iterator.moveNext()) {
      NamedBuilder? declaration = iterator.current;
      while (declaration != null) {
        if (declaration is TypeAliasBuilder &&
            declaration.typeParametersCount > 0) {
          for (NominalParameterBuilder typeParameter
              in declaration.typeParameters!) {
            typeParameter.variance = declaration.type
                .computeTypeParameterBuilderVariance(
                  typeParameter,
                  sourceLoader: libraryBuilder.loader,
                )
                .variance!;
            ++count;
          }
        }
        declaration = declaration.next;
      }
    }
    return count;
  }

  @override
  Message reportFeatureNotEnabled(
    LibraryFeature feature,
    Uri fileUri,
    int charOffset,
    int length,
  ) {
    assert(!feature.isEnabled);
    Message message;
    if (feature.isSupported) {
      // TODO(johnniwinther): Ideally the error should actually be special-cased
      // to mention that it is an experimental feature.
      String enabledVersionText = feature.flag.isEnabledByDefault
          ? feature.enabledVersion.toText()
          : "the current release";
      if (_languageVersion.isExplicit) {
        message = diag.experimentOptOutExplicit.withArguments(
          featureName: feature.flag.name,
          enabledVersion: enabledVersionText,
        );
        addProblem(
          message,
          charOffset,
          length,
          fileUri,
          context: <LocatedMessage>[
            diag.experimentOptOutComment
                .withArguments(featureName: feature.flag.name)
                .withLocation(
                  _languageVersion.fileUri!,
                  _languageVersion.charOffset,
                  _languageVersion.charCount,
                ),
          ],
        );
      } else {
        message = diag.experimentOptOutImplicit.withArguments(
          featureName: feature.flag.name,
          enabledVersion: enabledVersionText,
        );
        addProblem(message, charOffset, length, fileUri);
      }
    } else {
      if (feature.flag.isEnabledByDefault) {
        // Coverage-ignore-block(suite): Not run.
        if (_languageVersion.version < feature.enabledVersion) {
          message = diag.experimentDisabledInvalidLanguageVersion.withArguments(
            featureName: feature.flag.name,
            requiredLanguageVersion: feature.enabledVersion.toText(),
          );
          addProblem(message, charOffset, length, fileUri);
        } else {
          message = diag.experimentDisabled.withArguments(
            featureName: feature.flag.name,
          );
          addProblem(message, charOffset, length, fileUri);
        }
      } else {
        message = diag.experimentNotEnabledOffByDefault.withArguments(
          featureName: feature.flag.name,
        );
        addProblem(message, charOffset, length, fileUri);
      }
    }
    return message;
  }

  @override
  bool addPrefixFragment(
    String name,
    PrefixFragment prefixFragment,
    int charOffset,
  ) {
    Builder? existing = prefixNameSpace.lookup(name)?.getable;
    if (existing is PrefixBuilder) {
      assert(existing.next is! PrefixBuilder);
      int? deferredFileOffset;
      int? otherFileOffset;
      if (prefixFragment.deferred) {
        deferredFileOffset = prefixFragment.prefixOffset;
        otherFileOffset = existing.fileOffset;
      } else if (existing.deferred) {
        deferredFileOffset = existing.fileOffset;
        otherFileOffset = prefixFragment.prefixOffset;
      }
      if (deferredFileOffset != null) {
        _problemReporting.addProblem(
          diag.deferredPrefixDuplicated.withArguments(prefixName: name),
          deferredFileOffset,
          noLength,
          fileUri,
          context: [
            diag.deferredPrefixDuplicatedCause
                .withArguments(prefixName: name)
                .withLocation(fileUri, otherFileOffset!, noLength),
          ],
        );
      }
      prefixFragment.builder = existing;
      return false;
    }

    LookupResult? result = libraryBuilder.libraryNameSpace.lookup(name);
    if (result != null) {
      NamedBuilder existing = result.getable ?? result.setable!;
      String fullName = name;
      _problemReporting.addProblem(
        diag.duplicatedDeclaration.withArguments(name: fullName),
        charOffset,
        fullName.length,
        prefixFragment.fileUri,
        context: <LocatedMessage>[
          diag.duplicatedDeclarationCause
              .withArguments(name: fullName)
              .withLocation(
                existing.fileUri!,
                existing.fileOffset,
                fullName.length,
              ),
        ],
      );
    }

    _prefixNameSpace.addLocalMember(
      name,
      prefixFragment.createPrefixBuilder(
        prefixFragment.deferred
            // Deferred prefixes do not extend parent prefixes.
            ? null
            : parentCompilationUnit?.lookupPrefixBuilder(name),
      ),
      setter: false,
    );
    return true;
  }
}

class _CompilationUnitData implements CompilationUnitRegistry {
  LibraryDirective? _libraryDirective;

  PartOf? _partOf;

  List<MetadataBuilder>? _metadata;

  /// The part directives in this compilation unit.
  final List<Part> _parts = [];

  final List<LibraryPart> _libraryParts = [];

  final List<Import> _imports = <Import>[];

  final List<Export> _exports = <Export>[];

  @override
  void registerLibraryDirective({
    required LibraryDirective libraryDirective,
    required List<MetadataBuilder>? metadata,
  }) {
    _libraryDirective = libraryDirective;
    _metadata = metadata;
  }

  @override
  void registerPartOf(PartOf partOf) {
    _partOf = partOf;
  }

  @override
  void registerPart(Part part) {
    _parts.add(part);
  }

  @override
  void registerLibraryPart(LibraryPart libraryPart) {
    _libraryParts.add(libraryPart);
  }

  @override
  void registerImport(Import import) {
    _imports.add(import);
  }

  @override
  void registerExport(Export export) {
    _exports.add(export);
  }

  LibraryDirective? get libraryDirective => _libraryDirective;

  List<MetadataBuilder>? get metadata => _metadata;

  bool get isPart => _partOf != null;

  PartOf? get partOf => _partOf;

  List<Part> get parts => _parts;

  List<LibraryPart> get libraryParts => _libraryParts;

  List<Import> get imports => _imports;

  List<Export> get exports => _exports;
}

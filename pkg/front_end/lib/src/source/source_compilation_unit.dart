// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'source_library_builder.dart';

/// Enum that define what state a source compilation unit is in, in terms of how
/// far in the compilation it has progressed. This is used to document and
/// assert the requirements of individual methods within the
/// [SourceCompilationUnitImpl].
enum SourceCompilationUnitState {
  initial,
  importsAddedToScope,
  ;

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

  /// The object used as the root for creating augmentation libraries.
  // TODO(johnniwinther): Remove this once parts support augmentations.
  final SourceCompilationUnit? _augmentationRoot;

  // TODO(johnniwinther): Can we avoid this?
  final bool? _referenceIsPartOwner;

  // TODO(johnniwinther): Pass only the [Reference] instead.
  final LibraryBuilder? _nameOrigin;

  final LookupScope? _parentScope;

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

  late final BuilderFactoryImpl _builderFactory;

  late final BuilderFactoryResult _builderFactoryResult;

  final LibraryNameSpaceBuilder _libraryNameSpaceBuilder;

  final NameSpace _importNameSpace;

  LibraryFeatures? _libraryFeatures;

  @override
  final bool forAugmentationLibrary;

  @override
  final bool forPatchLibrary;

  @override
  final bool isAugmenting;

  @override
  final bool isUnsupported;

  late final LookupScope _scope;

  @override
  final bool mayImplementRestrictedTypes;

  final Map<String, Builder>? _omittedTypeDeclarationBuilders;

  factory SourceCompilationUnitImpl(
      {required Uri importUri,
      required Uri fileUri,
      required Uri? packageUri,
      required LanguageVersion packageLanguageVersion,
      required Uri originImportUri,
      required IndexedLibrary? indexedLibrary,
      Map<String, Builder>? omittedTypeDeclarationBuilders,
      LookupScope? parentScope,
      required bool forAugmentationLibrary,
      required SourceCompilationUnit? augmentationRoot,
      required LibraryBuilder? nameOrigin,
      required bool? referenceIsPartOwner,
      required bool forPatchLibrary,
      required bool isAugmenting,
      required bool isUnsupported,
      required SourceLoader loader,
      required bool mayImplementRestrictedTypes}) {
    LibraryNameSpaceBuilder libraryNameSpaceBuilder =
        new LibraryNameSpaceBuilder();
    NameSpace importNameSpace = new NameSpaceImpl();
    return new SourceCompilationUnitImpl._(libraryNameSpaceBuilder,
        importUri: importUri,
        fileUri: fileUri,
        packageUri: packageUri,
        packageLanguageVersion: packageLanguageVersion,
        originImportUri: originImportUri,
        indexedLibrary: indexedLibrary,
        omittedTypeDeclarationBuilders: omittedTypeDeclarationBuilders,
        parentScope: parentScope,
        importNameSpace: importNameSpace,
        forAugmentationLibrary: forAugmentationLibrary,
        augmentationRoot: augmentationRoot,
        nameOrigin: nameOrigin,
        referenceIsPartOwner: referenceIsPartOwner,
        forPatchLibrary: forPatchLibrary,
        isAugmenting: isAugmenting,
        isUnsupported: isUnsupported,
        loader: loader,
        mayImplementRestrictedTypes: mayImplementRestrictedTypes);
  }

  SourceCompilationUnitImpl._(LibraryNameSpaceBuilder libraryNameSpaceBuilder,
      {required this.importUri,
      required this.fileUri,
      required Uri? packageUri,
      required this.packageLanguageVersion,
      required this.originImportUri,
      required this.indexedLibrary,
      Map<String, Builder>? omittedTypeDeclarationBuilders,
      LookupScope? parentScope,
      required NameSpace importNameSpace,
      required this.forAugmentationLibrary,
      required SourceCompilationUnit? augmentationRoot,
      required LibraryBuilder? nameOrigin,
      required bool? referenceIsPartOwner,
      required this.forPatchLibrary,
      required this.isAugmenting,
      required this.isUnsupported,
      required this.loader,
      required this.mayImplementRestrictedTypes})
      : _languageVersion = packageLanguageVersion,
        _packageUri = packageUri,
        _libraryNameSpaceBuilder = libraryNameSpaceBuilder,
        _importNameSpace = importNameSpace,
        _augmentationRoot = augmentationRoot,
        _nameOrigin = nameOrigin,
        _parentScope = parentScope,
        _referenceIsPartOwner = referenceIsPartOwner,
        _omittedTypeDeclarationBuilders = omittedTypeDeclarationBuilders,
        _problemReporting = new LibraryProblemReporting(loader, fileUri) {
    _scope = new SourceLibraryBuilderScope(
        this, ScopeKind.typeParameters, 'library');

    // TODO(johnniwinther): Create these in [createOutlineBuilder].
    _builderFactoryResult = _builderFactory = new BuilderFactoryImpl(
        compilationUnit: this,
        augmentationRoot: augmentationRoot ?? this,
        libraryNameSpaceBuilder: libraryNameSpaceBuilder,
        problemReporting: _problemReporting,
        scope: _scope,
        indexedLibrary: indexedLibrary,
        omittedTypeDeclarationBuilders: omittedTypeDeclarationBuilders);
  }

  SourceCompilationUnitState get state => _state;

  void set state(SourceCompilationUnitState value) {
    assert(_state < value,
        "State $value has already been reached at $_state in $this.");
    assert(
        _state.index + 1 == value.index,
        _state.index + 1 < SourceCompilationUnitState.values.length
            ? "Expected state "
                "${SourceCompilationUnitState.values[_state.index + 1]} "
                "to follow from $_state, trying to set next state to $value "
                "in $this."
            : "No more states expected to follow from $_state, trying to set "
                "next state to $value in $this.");
    _state = value;
  }

  bool checkState(
      {List<SourceCompilationUnitState>? required,
      List<SourceCompilationUnitState>? pending}) {
    if (required != null) {
      for (SourceCompilationUnitState requiredState in required) {
        assert(state >= requiredState,
            "State $requiredState required, but found $state in $this.");
      }
    }
    if (pending != null) {
      // Coverage-ignore-block(suite): Not run.
      for (SourceCompilationUnitState pendingState in pending) {
        assert(
            state < pendingState,
            "State $pendingState must not have been reached, "
            "but found $state in $this.");
      }
    }
    return true;
  }

  @override
  LibraryFeatures get libraryFeatures =>
      _libraryFeatures ??= new LibraryFeatures(loader.target.globalFeatures,
          _packageUri ?? originImportUri, languageVersion.version);

  @override
  bool get isDartLibrary =>
      originImportUri.isScheme("dart") || fileUri.isScheme("org-dartlang-sdk");

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
    assert(_libraryBuilder != null,
        "Library builder for $this has not been computed yet.");
    return _libraryBuilder!;
  }

  @override
  void addExporter(CompilationUnit exporter,
      List<CombinatorBuilder>? combinators, int charOffset) {
    exporters.add(new Export(exporter, this, combinators, charOffset));
  }

  @override
  void addProblem(Message message, int charOffset, int length, Uri? fileUri,
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      Severity? severity,
      bool problemOnLibrary = false}) {
    _problemReporting.addProblem(message, charOffset, length, fileUri,
        wasHandled: wasHandled,
        context: context,
        severity: severity,
        problemOnLibrary: problemOnLibrary);
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
            message, access.charOffset, access.length, access.fileUri);
      }
      accessProblem = message;
    }
  }

  @override
  LanguageVersion get languageVersion {
    assert(
        _languageVersion.isFinal,
        "Attempting to read the language version of ${this} before has been "
        "finalized.");
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
  void registerExplicitLanguageVersion(Version version,
      {int offset = 0, int length = noLength}) {
    if (_languageVersion.isExplicit) {
      // If more than once language version exists we use the first.
      return;
    }
    assert(!_languageVersion.isFinal);

    if (version > loader.target.currentSdkVersion) {
      // Coverage-ignore-block(suite): Not run.
      // If trying to set a language version that is higher than the current sdk
      // version it's an error.
      addPostponedProblem(
          templateLanguageVersionTooHighExplicit.withArguments(
              version.major,
              version.minor,
              loader.target.currentSdkVersion.major,
              loader.target.currentSdkVersion.minor),
          offset,
          length,
          fileUri);
      // If the package set an OK version, but the file set an invalid version
      // we want to use the package version.
      _languageVersion = new InvalidLanguageVersion(
          fileUri, offset, length, packageLanguageVersion.version, true);
    } else if (version < loader.target.leastSupportedVersion) {
      addPostponedProblem(
          templateLanguageVersionTooLowExplicit.withArguments(
              version.major,
              version.minor,
              loader.target.leastSupportedVersion.major,
              loader.target.leastSupportedVersion.minor),
          offset,
          length,
          fileUri);
      _languageVersion = new InvalidLanguageVersion(
          fileUri, offset, length, loader.target.leastSupportedVersion, true);
    } else {
      _languageVersion = new LanguageVersion(version, fileUri, offset, length);
    }
    _languageVersion.isFinal = true;
  }

  @override
  void addPostponedProblem(
      Message message, int charOffset, int length, Uri fileUri) {
    if (_postponedProblemsIssued) {
      // Coverage-ignore-block(suite): Not run.
      addProblem(message, charOffset, length, fileUri);
    } else {
      _postponedProblems ??= <PostponedProblem>[];
      _postponedProblems!
          .add(new PostponedProblem(message, charOffset, length, fileUri));
    }
  }

  @override
  void issuePostponedProblems() {
    _postponedProblemsIssued = true;
    if (_postponedProblems == null) return;
    for (int i = 0; i < _postponedProblems!.length; ++i) {
      PostponedProblem postponedProblem = _postponedProblems![i];
      addProblem(postponedProblem.message, postponedProblem.charOffset,
          postponedProblem.length, postponedProblem.fileUri);
    }
    _postponedProblems = null;
  }

  @override
  Iterable<Uri> get dependencies sync* {
    for (Export export in _builderFactoryResult.exports) {
      yield export.exportedCompilationUnit.importUri;
    }
    for (Import import in _builderFactoryResult.imports) {
      CompilationUnit? imported = import.importedCompilationUnit;
      if (imported != null) {
        yield imported.importUri;
      }
    }
  }

  @override
  bool get isPart => _builderFactoryResult.isPart;

  @override
  bool get isSynthetic => accessProblem != null;

  @override
  LibraryBuilder? get partOfLibrary => _partOfLibrary;

  @override
  void recordAccess(
      CompilationUnit accessor, int charOffset, int length, Uri fileUri) {
    accessors.add(new LibraryAccess(accessor, fileUri, charOffset, length));
    if (accessProblem != null) {
      // Coverage-ignore-block(suite): Not run.
      addProblem(accessProblem!, charOffset, length, fileUri);
    }
  }

  @override
  OutlineBuilder createOutlineBuilder() {
    assert(_offsetMap == null, "OffsetMap has already been set for $this");
    return new OutlineBuilder(
        this, _builderFactory, _offsetMap = new OffsetMap(fileUri));
  }

  @override
  SourceLibraryBuilder createLibrary([Library? library]) {
    assert(_libraryBuilder == null,
        "Source library builder as already been created for $this.");
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
            origin: _augmentationRoot?.libraryBuilder,
            target: library,
            indexedLibrary: indexedLibrary,
            referenceIsPartOwner: _referenceIsPartOwner,
            isUnsupported: isUnsupported,
            isAugmentation: forAugmentationLibrary,
            isPatch: forPatchLibrary,
            parentScope: _parentScope,
            importNameSpace: _importNameSpace,
            libraryNameSpaceBuilder: _libraryNameSpaceBuilder,
            omittedTypes: _omittedTypeDeclarationBuilders);
    _problemReporting.registerLibrary(libraryBuilder.library);
    if (isPart) {
      // Coverage-ignore-block(suite): Not run.
      // This is a part with no enclosing library.
      addProblem(messagePartOrphan, 0, 1, fileUri);
      _clearPartsAndReportExporters();
    }
    return libraryBuilder;
  }

  @override
  String toString() => 'SourceCompilationUnitImpl($fileUri)';

  void _addNativeDependency(Library library, String nativeImportPath) {
    MemberBuilder constructor = loader.getNativeAnnotation();
    Arguments arguments =
        new Arguments(<Expression>[new StringLiteral(nativeImportPath)]);
    Expression annotation;
    if (constructor.isConstructor) {
      annotation = new ConstructorInvocation(
          constructor.invokeTarget as Constructor, arguments)
        ..isConst = true;
    } else {
      // Coverage-ignore-block(suite): Not run.
      annotation =
          new StaticInvocation(constructor.invokeTarget as Procedure, arguments)
            ..isConst = true;
    }
    library.addAnnotation(annotation);
  }

  @override
  void addDependencies(Library library, Set<SourceCompilationUnit> seen) {
    assert(
        checkState(required: [SourceCompilationUnitState.importsAddedToScope]));

    if (!seen.add(this)) {
      return;
    }

    for (Import import in _builderFactoryResult.imports) {
      // Rather than add a LibraryDependency, we attach an annotation.
      if (import.nativeImportPath != null) {
        _addNativeDependency(library, import.nativeImportPath!);
        continue;
      }

      LibraryDependency libraryDependency;
      if (import.deferred &&
          import.prefixFragment?.builder.dependency != null) {
        libraryDependency = import.prefixFragment!.builder.dependency!;
      } else {
        LibraryBuilder imported = import.importedLibraryBuilder!.origin;
        Library targetLibrary = imported.library;
        libraryDependency = new LibraryDependency.import(targetLibrary,
            name: import.prefix,
            combinators: toKernelCombinators(import.combinators))
          ..fileOffset = import.importOffset;
      }
      library.addDependency(libraryDependency);
      import.libraryDependency = libraryDependency;
    }
    for (Export export in _builderFactoryResult.exports) {
      LibraryDependency libraryDependency = new LibraryDependency.export(
          export.exportedLibraryBuilder.library,
          combinators: toKernelCombinators(export.combinators))
        ..fileOffset = export.charOffset;
      library.addDependency(libraryDependency);
      export.libraryDependency = libraryDependency;
    }
  }

  @override
  String? get partOfName => _builderFactoryResult.partOfName;

  @override
  Uri? get partOfUri => _builderFactoryResult.partOfUri;

  @override
  LookupScope get scope => _scope;

  @override
  void takeMixinApplications(
      Map<SourceClassBuilder, TypeBuilder> mixinApplications) {
    _builderFactoryResult.takeMixinApplications(mixinApplications);
  }

  @override
  void includeParts(SourceLibraryBuilder libraryBuilder,
      List<SourceCompilationUnit> includedParts, Set<Uri> usedParts) {
    Set<Uri> seenParts = new Set<Uri>();
    int index = 0;
    while (index < _builderFactoryResult.parts.length) {
      Part part = _builderFactoryResult.parts[index];
      bool keepPart = true;
      // TODO(johnniwinther): Use [part.offset] in messages.
      if (part.compilationUnit == this) {
        addProblem(messagePartOfSelf, -1, noLength, fileUri);
        keepPart = false;
      } else if (seenParts.add(part.compilationUnit.fileUri)) {
        if (part.compilationUnit.partOfLibrary != null) {
          addProblem(messagePartOfTwoLibraries, -1, noLength,
              part.compilationUnit.fileUri,
              context: [
                messagePartOfTwoLibrariesContext.withLocation(
                    part.compilationUnit.partOfLibrary!.fileUri, -1, noLength),
                messagePartOfTwoLibrariesContext.withLocation(
                    fileUri, -1, noLength)
              ]);
          keepPart = false;
        } else {
          usedParts.add(part.compilationUnit.importUri);
          keepPart = _includePart(libraryBuilder, this, includedParts,
              part.compilationUnit, usedParts, part.offset);
        }
      } else {
        addProblem(
            templatePartTwice.withArguments(part.compilationUnit.fileUri),
            -1,
            noLength,
            fileUri);
        keepPart = false;
      }
      if (keepPart) {
        index++;
      } else {
        // TODO(johnniwinther): Stop removing parts.
        _builderFactoryResult.parts.removeAt(index);
      }
    }
  }

  bool _includePart(
      SourceLibraryBuilder libraryBuilder,
      SourceCompilationUnit parentCompilationUnit,
      List<SourceCompilationUnit> includedParts,
      CompilationUnit part,
      Set<Uri> usedParts,
      int partOffset) {
    switch (part) {
      case SourceCompilationUnit():
        if (part.partOfUri != null) {
          if (isNotMalformedUriScheme(part.partOfUri!) &&
              part.partOfUri != parentCompilationUnit.importUri) {
            // This is an error, but the part is not removed from the list of
            // parts, so that metadata annotations can be associated with it.
            parentCompilationUnit.addProblem(
                templatePartOfUriMismatch.withArguments(part.fileUri,
                    parentCompilationUnit.importUri, part.partOfUri!),
                partOffset,
                noLength,
                parentCompilationUnit.fileUri);
            return false;
          }
        } else if (part.partOfName != null) {
          if (parentCompilationUnit.name != null) {
            if (part.partOfName != parentCompilationUnit.name) {
              // This is an error, but the part is not removed from the list of
              // parts, so that metadata annotations can be associated with it.
              parentCompilationUnit.addProblem(
                  templatePartOfLibraryNameMismatch.withArguments(part.fileUri,
                      parentCompilationUnit.name!, part.partOfName!),
                  partOffset,
                  noLength,
                  parentCompilationUnit.fileUri);
              return false;
            }
          } else {
            // This is an error, but the part is not removed from the list of
            // parts, so that metadata annotations can be associated with it.
            parentCompilationUnit.addProblem(
                templatePartOfUseUri.withArguments(part.fileUri,
                    parentCompilationUnit.fileUri, part.partOfName!),
                partOffset,
                noLength,
                parentCompilationUnit.fileUri);
            return false;
          }
        } else {
          // This is an error, but the part is not removed from the list of
          // parts, so that metadata annotations can be associated with it.
          assert(!part.isPart);
          if (isNotMalformedUriScheme(part.fileUri)) {
            parentCompilationUnit.addProblem(
                templateMissingPartOf.withArguments(part.fileUri),
                partOffset,
                noLength,
                parentCompilationUnit.fileUri);
          }
          return false;
        }

        // Language versions have to match. Except if (at least) one of them is
        // invalid in which case we've already gotten an error about this.
        if (parentCompilationUnit.languageVersion != part.languageVersion &&
            // Coverage-ignore(suite): Not run.
            parentCompilationUnit.languageVersion.valid &&
            // Coverage-ignore(suite): Not run.
            part.languageVersion.valid) {
          // Coverage-ignore-block(suite): Not run.
          // This is an error, but the part is not removed from the list of
          // parts, so that metadata annotations can be associated with it.
          List<LocatedMessage> context = <LocatedMessage>[];
          if (parentCompilationUnit.languageVersion.isExplicit) {
            context.add(messageLanguageVersionLibraryContext.withLocation(
                parentCompilationUnit.languageVersion.fileUri!,
                parentCompilationUnit.languageVersion.charOffset,
                parentCompilationUnit.languageVersion.charCount));
          }
          if (part.languageVersion.isExplicit) {
            context.add(messageLanguageVersionPartContext.withLocation(
                part.languageVersion.fileUri!,
                part.languageVersion.charOffset,
                part.languageVersion.charCount));
          }
          parentCompilationUnit.addProblem(messageLanguageVersionMismatchInPart,
              partOffset, noLength, parentCompilationUnit.fileUri,
              context: context);
        }

        part.validatePart(libraryBuilder, _libraryNameSpaceBuilder, usedParts);
        includedParts.add(part);
        return true;
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
              templateMissingPartOf.withArguments(part.fileUri),
              partOffset,
              noLength,
              parentCompilationUnit.fileUri);
        }
        return false;
    }
  }

  void _becomePart(SourceLibraryBuilder libraryBuilder,
      LibraryNameSpaceBuilder libraryNameSpaceBuilder) {
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
    return _builderFactoryResult.typeScope.resolveTypes(problemReporting);
  }

  @override
  int finishNativeMethods() {
    return _builderFactoryResult.finishNativeMethods();
  }

  void _clearPartsAndReportExporters() {
    assert(_libraryBuilder != null, "Library has not be set.");
    _builderFactoryResult.parts.clear();
    if (exporters.isNotEmpty) {
      // Coverage-ignore-block(suite): Not run.
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

  @override
  void validatePart(SourceLibraryBuilder libraryBuilder,
      LibraryNameSpaceBuilder libraryNameSpaceBuilder, Set<Uri>? usedParts) {
    _libraryBuilder = libraryBuilder;
    _partOfLibrary = libraryBuilder;
    if (_builderFactoryResult.parts.isNotEmpty) {
      List<LocatedMessage> context = <LocatedMessage>[
        messagePartInPartLibraryContext.withLocation(
            libraryBuilder.fileUri, -1, 1),
      ];
      for (Part part in _builderFactoryResult.parts) {
        addProblem(messagePartInPart, part.offset, noLength, fileUri,
            context: context);
        // Mark this part as used so we don't report it as orphaned.
        usedParts!.add(part.compilationUnit.importUri);
      }
    }
    _clearPartsAndReportExporters();
    _becomePart(libraryBuilder, libraryNameSpaceBuilder);
  }

  @override
  void collectUnboundTypeVariables(
      SourceLibraryBuilder libraryBuilder,
      Map<NominalVariableBuilder, SourceLibraryBuilder> nominalVariables,
      Map<StructuralVariableBuilder, SourceLibraryBuilder>
          structuralVariables) {
    _builderFactoryResult.collectUnboundTypeVariables(
        libraryBuilder, nominalVariables, structuralVariables);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void addSyntheticImport(
      {required String uri,
      required String? prefix,
      required List<CombinatorBuilder>? combinators,
      required bool deferred}) {
    assert(
        checkState(pending: [SourceCompilationUnitState.importsAddedToScope]));
    _builderFactory.addImport(
        metadata: null,
        isAugmentationImport: false,
        uri: uri,
        configurations: null,
        prefix: prefix,
        combinators: combinators,
        deferred: deferred,
        charOffset: -1,
        prefixCharOffset: -1,
        uriOffset: -1);
  }

  @override
  void addImportsToScope() {
    assert(checkState(required: [SourceCompilationUnitState.initial]));

    bool hasCoreImport = originImportUri == dartCore &&
        // Coverage-ignore(suite): Not run.
        !forPatchLibrary;
    for (Import import in _builderFactoryResult.imports) {
      if (import.importedCompilationUnit?.isPart ?? false) {
        // Coverage-ignore-block(suite): Not run.
        addProblem(
            templatePartOfInLibrary
                .withArguments(import.importedCompilationUnit!.fileUri),
            import.importOffset,
            noLength,
            fileUri);
      }
      if (import.importedLibraryBuilder == loader.coreLibrary) {
        hasCoreImport = true;
      }
      import.finalizeImports(this);
    }
    if (!hasCoreImport) {
      NameIterator<Builder> iterator = loader.coreLibrary.exportNameSpace
          .filteredNameIterator(
              includeDuplicates: false, includeAugmentations: false);
      while (iterator.moveNext()) {
        addImportedBuilderToScope(
            name: iterator.name, builder: iterator.current, charOffset: -1);
      }
    }

    state = SourceCompilationUnitState.importsAddedToScope;
  }

  @override
  void addImportedBuilderToScope(
      {required String name,
      required Builder builder,
      required int charOffset}) {
    Builder? existing =
        _importNameSpace.lookupLocalMember(name, setter: builder.isSetter);
    if (existing != null) {
      if (existing != builder) {
        _importNameSpace.addLocalMember(
            name,
            computeAmbiguousDeclarationForImport(
                _problemReporting, name, existing, builder,
                uriOffset: new UriOffset(fileUri, charOffset)),
            setter: builder.isSetter);
      }
    } else {
      _importNameSpace.addLocalMember(name, builder, setter: builder.isSetter);
    }
    if (builder.isExtension) {
      _importNameSpace.addExtension(builder as ExtensionBuilder);
    }
  }

  @override
  void buildOutlineNode(Library library) {
    library.setLanguageVersion(_languageVersion.version);
    switch (loader.nnbdMode) {
      case NnbdMode.Weak:
        library.nonNullableByDefaultCompiledMode =
            NonNullableByDefaultCompiledMode.Weak;
        break;
      case NnbdMode.Strong:
        library.nonNullableByDefaultCompiledMode =
            NonNullableByDefaultCompiledMode.Strong;
        break;
    }
    for (LibraryPart libraryPart in _builderFactoryResult.libraryParts) {
      library.addPart(libraryPart);
    }
  }

  @override
  int finishDeferredLoadTearOffs(Library library) {
    assert(
        checkState(required: [SourceCompilationUnitState.importsAddedToScope]));

    int total = 0;
    for (Import import in _builderFactoryResult.imports) {
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
  List<MetadataBuilder>? get metadata => _builderFactoryResult.metadata;

  @override
  String? get name => _builderFactoryResult.name;

  @override
  int computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder nullType,
      TypeBuilder bottomType, ClassBuilder objectClass) {
    int count = 0;

    int computeDefaultTypesForVariables(List<NominalVariableBuilder>? variables,
        {required bool inErrorRecovery}) {
      if (variables == null) return 0;

      bool haveErroneousBounds = false;
      if (!inErrorRecovery) {
        if (!libraryFeatures.genericMetadata.isEnabled) {
          for (NominalVariableBuilder variable in variables) {
            haveErroneousBounds =
                _recursivelyReportGenericFunctionTypesAsBoundsForVariable(
                        variable) ||
                    haveErroneousBounds;
          }
        }

        if (!haveErroneousBounds) {
          List<StructuralVariableBuilder> unboundTypeVariables = [];
          List<TypeBuilder> calculatedBounds = calculateBounds(
              variables, dynamicType, bottomType,
              unboundTypeVariables: unboundTypeVariables);
          _builderFactoryResult
              .registerUnresolvedStructuralVariables(unboundTypeVariables);

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

    void processSourceConstructorBuilder(SourceFunctionBuilder member,
        {required bool inErrorRecovery}) {
      count += computeDefaultTypesForVariables(member.typeVariables,
          // Type variables are inherited from the enclosing declaration, so if
          // it has issues, so do the constructors.
          inErrorRecovery: inErrorRecovery);
      List<FormalParameterBuilder>? formals = member.formals;
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
        assert(member is SourceFactoryBuilder ||
            member is SourceConstructorBuilder);
        processSourceConstructorBuilder(member as SourceFunctionBuilder,
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

        Iterator<SourceMemberBuilder> iterator = declaration.nameSpace
            .filteredConstructorIterator<SourceMemberBuilder>(
                parent: declaration,
                includeDuplicates: false,
                includeAugmentations: true);
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
            // Coverage-ignore-block(suite): Not run.
            assert(false,
                "Unexpected extension member $member (${member.runtimeType}).");
          }
        });
      } else if (declaration is SourceExtensionTypeDeclarationBuilder) {
        List<NonSimplicityIssue> issues = getNonSimplicityIssuesForDeclaration(
            declaration,
            performErrorRecovery: true);
        reportIssues(issues);
        count += computeDefaultTypesForVariables(declaration.typeParameters,
            inErrorRecovery: issues.isNotEmpty);

        Iterator<SourceMemberBuilder> iterator = declaration.nameSpace
            .filteredConstructorIterator<SourceMemberBuilder>(
                parent: declaration,
                includeDuplicates: false,
                includeAugmentations: true);
        while (iterator.moveNext()) {
          processSourceMemberBuilder(iterator.current,
              inErrorRecovery: issues.isNotEmpty);
        }

        declaration.forEach((String name, Builder member) {
          if (member is SourceMemberBuilder) {
            processSourceMemberBuilder(member,
                inErrorRecovery: issues.isNotEmpty);
          } else {
            // Coverage-ignore-block(suite): Not run.
            assert(
                false,
                "Unexpected extension type member "
                "$member (${member.runtimeType}).");
          }
        });
      } else {
        // Coverage-ignore-block(suite): Not run.
        assert(
            declaration is PrefixBuilder ||
                declaration is DynamicTypeDeclarationBuilder ||
                declaration is NeverTypeDeclarationBuilder,
            "Unexpected top level member $declaration "
            "(${declaration.runtimeType}).");
      }
    }

    Iterator<Builder> iterator = libraryBuilder.localMembersIterator;
    while (iterator.moveNext()) {
      computeDefaultValuesForDeclaration(iterator.current);
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
      NominalVariableBuilder typeVariable) {
    if (libraryFeatures.genericMetadata.isEnabled) return false;

    bool hasReportedErrors = false;
    hasReportedErrors = _reportGenericFunctionTypeAsBoundIfNeeded(
            typeVariable.bound,
            typeVariableName: typeVariable.name,
            fileUri: typeVariable.fileUri,
            charOffset: typeVariable.charOffset) ||
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
      for (StructuralVariableBuilder typeVariable
          in genericFunctionTypeBuilder.typeVariables!) {
        hasReportedErrors = _reportGenericFunctionTypeAsBoundIfNeeded(
                typeVariable.bound,
                typeVariableName: typeVariable.name,
                fileUri: typeVariable.fileUri,
                charOffset: typeVariable.charOffset) ||
            hasReportedErrors;
      }
    }
    return hasReportedErrors;
  }

  /// Reports an error if [bound] is a generic function type
  ///
  /// Returns `true` if any errors were reported.
  bool _reportGenericFunctionTypeAsBoundIfNeeded(TypeBuilder? bound,
      {required String typeVariableName,
      Uri? fileUri,
      required int charOffset}) {
    if (libraryFeatures.genericMetadata.isEnabled) return false;

    bool isUnaliasedGenericFunctionType = bound is FunctionTypeBuilder &&
        bound.typeVariables != null &&
        bound.typeVariables!.isNotEmpty;
    bool isAliasedGenericFunctionType = false;
    TypeDeclarationBuilder? declaration = bound?.declaration;
    // TODO(cstefantsova): Unalias beyond the first layer for the check.
    if (declaration is TypeAliasBuilder) {
      // Coverage-ignore-block(suite): Not run.
      TypeBuilder? rhsType = declaration.type;
      if (rhsType is FunctionTypeBuilder &&
          rhsType.typeVariables != null &&
          rhsType.typeVariables!.isNotEmpty) {
        isAliasedGenericFunctionType = true;
      }
    }

    if (isUnaliasedGenericFunctionType || isAliasedGenericFunctionType) {
      addProblem(messageGenericFunctionTypeInBound, charOffset,
          typeVariableName.length, fileUri);
      return true;
    }
    return false;
  }

  @override
  int computeVariances() {
    int count = 0;

    Iterator<Builder> iterator = libraryBuilder.localMembersIterator;
    while (iterator.moveNext()) {
      Builder? declaration = iterator.current;
      while (declaration != null) {
        if (declaration is TypeAliasBuilder &&
            declaration.typeVariablesCount > 0) {
          for (NominalVariableBuilder typeParameter
              in declaration.typeVariables!) {
            typeParameter.variance = declaration.type
                .computeTypeVariableBuilderVariance(typeParameter,
                    sourceLoader: libraryBuilder.loader)
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
      LibraryFeature feature, Uri fileUri, int charOffset, int length) {
    assert(!feature.isEnabled);
    Message message;
    if (feature.isSupported) {
      // TODO(johnniwinther): Ideally the error should actually be special-cased
      // to mention that it is an experimental feature.
      String enabledVersionText = feature.flag.isEnabledByDefault
          ? feature.enabledVersion.toText()
          : "the current release";
      if (_languageVersion.isExplicit) {
        message = templateExperimentOptOutExplicit.withArguments(
            feature.flag.name, enabledVersionText);
        addProblem(message, charOffset, length, fileUri,
            context: <LocatedMessage>[
              templateExperimentOptOutComment
                  .withArguments(feature.flag.name)
                  .withLocation(_languageVersion.fileUri!,
                      _languageVersion.charOffset, _languageVersion.charCount)
            ]);
      } else {
        message = templateExperimentOptOutImplicit.withArguments(
            feature.flag.name, enabledVersionText);
        addProblem(message, charOffset, length, fileUri);
      }
    } else {
      if (feature.flag.isEnabledByDefault) {
        // Coverage-ignore-block(suite): Not run.
        if (_languageVersion.version < feature.enabledVersion) {
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

  @override
  bool addPrefixFragment(
      String name, PrefixFragment prefixFragment, int charOffset) {
    Builder? existing =
        libraryBuilder.prefixNameSpace.lookupLocalMember(name, setter: false);
    existing ??=
        libraryBuilder.libraryNameSpace.lookupLocalMember(name, setter: false);
    if (existing is PrefixBuilder) {
      assert(existing.next is! PrefixBuilder);
      int? deferredFileOffset;
      int? otherFileOffset;
      if (prefixFragment.deferred) {
        deferredFileOffset = prefixFragment.prefixOffset;
        otherFileOffset = existing.charOffset;
      } else if (existing.deferred) {
        deferredFileOffset = existing.charOffset;
        otherFileOffset = prefixFragment.prefixOffset;
      }
      if (deferredFileOffset != null) {
        _problemReporting.addProblem(
            templateDeferredPrefixDuplicated.withArguments(name),
            deferredFileOffset,
            noLength,
            fileUri,
            context: [
              templateDeferredPrefixDuplicatedCause
                  .withArguments(name)
                  .withLocation(fileUri, otherFileOffset!, noLength)
            ]);
      }
      prefixFragment.builder = existing;
      return false;
    } else if (existing != null) {
      String fullName = name;
      _problemReporting.addProblem(
          templateDuplicatedDeclaration.withArguments(fullName),
          charOffset,
          fullName.length,
          prefixFragment.fileUri,
          context: <LocatedMessage>[
            templateDuplicatedDeclarationCause
                .withArguments(fullName)
                .withLocation(
                    existing.fileUri!, existing.charOffset, fullName.length)
          ]);
    }
    // TODO(johnniwinther): For enhanced parts, this should be the prefix name
    //  space for the compilation unit.
    libraryBuilder.prefixNameSpace.addLocalMember(
        name, prefixFragment.createPrefixBuilder(),
        setter: false);
    return true;
  }
}

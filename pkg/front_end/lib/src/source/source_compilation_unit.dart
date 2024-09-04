// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'source_library_builder.dart';

class SourceCompilationUnitImpl
    implements SourceCompilationUnit, ProblemReporting {
  @override
  final Uri fileUri;

  @override
  final Uri importUri;

  final Uri? _packageUri;

  @override
  final Uri originImportUri;

  @override
  final SourceLoader loader;

  final SourceLibraryBuilder _sourceLibraryBuilder;

  SourceLibraryBuilder? _libraryBuilder;

  /// Map used to find objects created in the [OutlineBuilder] from within
  /// the [DietListener].
  ///
  /// This is meant to be written once and read once.
  OffsetMap? _offsetMap;

  LibraryBuilder? _partOfLibrary;

  @override
  final List<Export> exporters = <Export>[];

  /// Set of extension declarations in scope. This is computed lazily in
  /// [forEachExtensionInScope].
  Set<ExtensionBuilder>? _extensionsInScope;

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

  final LibraryName _libraryName;

  late final BuilderFactoryImpl _builderFactory;

  late final BuilderFactoryResult _builderFactoryResult;

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

  SourceCompilationUnitImpl(this._sourceLibraryBuilder,
      TypeParameterScopeBuilder libraryTypeParameterScopeBuilder,
      {required this.importUri,
      required this.fileUri,
      required Uri? packageUri,
      required this.packageLanguageVersion,
      required this.originImportUri,
      required this.indexedLibrary,
      required LibraryName libraryName,
      Map<String, Builder>? omittedTypeDeclarationBuilders,
      required NameSpace importNameSpace,
      required this.forAugmentationLibrary,
      required this.forPatchLibrary,
      required this.isAugmenting,
      required this.isUnsupported,
      required this.loader})
      : _libraryName = libraryName,
        _languageVersion = packageLanguageVersion,
        _packageUri = packageUri,
        _importNameSpace = importNameSpace {
    // TODO(johnniwinther): Create these in [createOutlineBuilder].
    _builderFactoryResult = _builderFactory = new BuilderFactoryImpl(
        compilationUnit: this,
        augmentationRoot: _sourceLibraryBuilder,
        parent: _sourceLibraryBuilder,
        libraryTypeParameterScopeBuilder: libraryTypeParameterScopeBuilder,
        problemReporting: this,
        scope: _scope,
        nameSpace: _nameSpace,
        libraryName: _libraryName,
        indexedLibrary: indexedLibrary,
        omittedTypeDeclarationBuilders: omittedTypeDeclarationBuilders);
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
    assert(
        _offsetMap != null, // Coverage-ignore(suite): Not run.
        "No OffsetMap for $this");
    OffsetMap map = _offsetMap!;
    _offsetMap = null;
    return map;
  }

  @override
  SourceLibraryBuilder get libraryBuilder {
    assert(
        _libraryBuilder != null,
        // Coverage-ignore(suite): Not run.
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
    _sourceLibraryBuilder.addProblem(message, charOffset, length, fileUri,
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
        // Coverage-ignore(suite): Not run.
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
    } else if (version < loader.target.leastSupportedVersion) {
      addPostponedProblem(
          templateLanguageVersionTooLow.withArguments(
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
  NameIterator<Builder> get localMembersNameIterator =>
      _sourceLibraryBuilder.localMembersNameIterator;

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
    assert(
        _offsetMap == null, // Coverage-ignore(suite): Not run.
        "OffsetMap has already been set for $this");
    return new OutlineBuilder(
        this, _builderFactory, _offsetMap = new OffsetMap(fileUri));
  }

  @override
  SourceLibraryBuilder createLibrary() {
    assert(
        _libraryBuilder == null,
        // Coverage-ignore(suite): Not run.
        "Source library builder as already been created for $this.");
    _libraryBuilder = _sourceLibraryBuilder;
    if (isPart) {
      // Coverage-ignore-block(suite): Not run.
      // This is a part with no enclosing library.
      addProblem(messagePartOrphan, 0, 1, fileUri);
      _clearPartsAndReportExporters();
    }
    return _sourceLibraryBuilder;
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
          constructor.member as Constructor, arguments)
        ..isConst = true;
    } else {
      // Coverage-ignore-block(suite): Not run.
      annotation =
          new StaticInvocation(constructor.member as Procedure, arguments)
            ..isConst = true;
    }
    library.addAnnotation(annotation);
  }

  @override
  void addDependencies(Library library, Set<SourceCompilationUnit> seen) {
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
      if (import.deferred && import.prefixBuilder?.dependency != null) {
        libraryDependency = import.prefixBuilder!.dependency!;
      } else {
        LibraryBuilder imported = import.importedLibraryBuilder!.origin;
        Library targetLibrary = imported.library;
        libraryDependency = new LibraryDependency.import(targetLibrary,
            name: import.prefix,
            combinators: toKernelCombinators(import.combinators))
          ..fileOffset = import.charOffset;
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

  LookupScope get _scope => _sourceLibraryBuilder.scope;

  NameSpace get _nameSpace => _sourceLibraryBuilder.nameSpace;

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

        part.validatePart(libraryBuilder, usedParts);
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

  void _becomePart(SourceLibraryBuilder libraryBuilder) {
    NameIterator partDeclarations = localMembersNameIterator;
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
        // Duplicated declarations are handled by creating a linked list
        // using the `next` field. This is preferred over making all scope
        // entries be a `List<Declaration>`.
        //
        // We maintain the linked list so that the last entry is easy to
        // recognize (it's `next` field is null). This means that it is
        // reversed with respect to source code order. Since kernel doesn't
        // allow duplicated declarations, we ensure that we only add the
        // first declaration to the kernel tree.
        //
        // Since the duplicated declarations are stored in reverse order, we
        // iterate over them in reverse order as this is simpler and
        // normally not a problem. However, in this case we need to call
        // [addBuilder] in source order as it would otherwise create cycles.
        //
        // We also need to be careful preserving the order of the links. The
        // part library still keeps these declarations in its scope so that
        // DietListener can find them.
        for (int i = duplicated.length; i > 0; i--) {
          Builder declaration = duplicated[i - 1];
          // No reference: There should be no duplicates when using
          // references.
          libraryBuilder.addBuilder(name, declaration, declaration.charOffset);
        }
      } else {
        // No reference: The part is in the same loader so the reference
        // - if needed - was already added.
        libraryBuilder.addBuilder(name, declaration, declaration.charOffset);
      }
    }
    _libraryName.reference = libraryBuilder.libraryName.reference;

    // TODO(johnniwinther): Avoid these. The compilation unit should not have
    // a name space and its import scope should be nested within its parent's
    // import scope.
    _sourceLibraryBuilder._nameSpace = libraryBuilder.nameSpace;
    _sourceLibraryBuilder._importScope = libraryBuilder.importScope;

    // TODO(ahe): Include metadata from part?

    // Recovery: Take on all exporters (i.e. if a library has erroneously
    // exported the part it has (in validatePart) been recovered to import
    // the main library (this) instead --- to make it complete (and set up
    // scopes correctly) the exporters in this has to be updated too).
    libraryBuilder.exporters.addAll(exporters);

    // Check that the targets are different. This is not normally a problem
    // but is for augmentation libraries.

    Library library = _sourceLibraryBuilder.library;
    if (libraryBuilder.library != library && library.problemsAsJson != null) {
      (libraryBuilder.library.problemsAsJson ??= <String>[])
          .addAll(library.problemsAsJson!);
    }
    if (libraryBuilder.library != library) {
      // Mark the part library as synthetic as it's not an actual library
      // (anymore).
      library.isSynthetic = true;
    }
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
  void validatePart(SourceLibraryBuilder libraryBuilder, Set<Uri>? usedParts) {
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
    _becomePart(libraryBuilder);
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
        uriOffset: -1,
        importIndex: -1);
  }

  @override
  void addImportsToScope() {
    bool hasCoreImport = originImportUri == dartCore &&
        // Coverage-ignore(suite): Not run.
        !forPatchLibrary;
    for (Import import in _builderFactoryResult.imports) {
      if (import.importedCompilationUnit?.isPart ?? false) {
        // Coverage-ignore-block(suite): Not run.
        addProblem(
            templatePartOfInLibrary
                .withArguments(import.importedCompilationUnit!.fileUri),
            import.charOffset,
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
        addToScope(iterator.name, iterator.current, -1, true);
      }
    }
  }

  @override
  void addToScope(String name, Builder member, int charOffset, bool isImport) {
    Builder? existing =
        _importNameSpace.lookupLocalMember(name, setter: member.isSetter);
    if (existing != null) {
      if (existing != member) {
        _importNameSpace.addLocalMember(
            name,
            computeAmbiguousDeclarationForScope(
                this, _nameSpace, name, existing, member,
                uriOffset: new UriOffset(fileUri, charOffset),
                isImport: isImport),
            setter: member.isSetter);
      }
    } else {
      _importNameSpace.addLocalMember(name, member, setter: member.isSetter);
    }
    if (member.isExtension) {
      _importNameSpace.addExtension(member as ExtensionBuilder);
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
    int total = 0;
    for (Import import in _builderFactoryResult.imports) {
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

  @override
  List<MetadataBuilder>? get metadata => _builderFactoryResult.metadata;

  @override
  String? get name => _builderFactoryResult.name;

  @override
  void forEachExtensionInScope(void Function(ExtensionBuilder) f) {
    if (_extensionsInScope == null) {
      _extensionsInScope = <ExtensionBuilder>{};
      _scope.forEachExtension((e) {
        _extensionsInScope!.add(e);
      });
      List<PrefixBuilder>? prefixBuilders =
          _builderFactoryResult.prefixBuilders;
      if (prefixBuilders != null) {
        for (PrefixBuilder prefix in prefixBuilders) {
          prefix.forEachExtension((e) {
            _extensionsInScope!.add(e);
          });
        }
      }
    }
    _extensionsInScope!.forEach(f);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void clearExtensionsInScopeCache() {
    _extensionsInScope = null;
  }

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
          List<NamedTypeBuilder> unboundTypes = [];
          List<StructuralVariableBuilder> unboundTypeVariables = [];
          List<TypeBuilder> calculatedBounds = calculateBounds(
              variables, dynamicType, bottomType,
              unboundTypes: unboundTypes,
              unboundTypeVariables: unboundTypeVariables);
          _builderFactoryResult.registerUnresolvedNamedTypes(unboundTypes);
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
                includeDuplicates: false, includeAugmentations: true);
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
        assert(
            declaration is PrefixBuilder ||
                // Coverage-ignore(suite): Not run.
                declaration is DynamicTypeDeclarationBuilder ||
                // Coverage-ignore(suite): Not run.
                declaration is NeverTypeDeclarationBuilder,
            // Coverage-ignore(suite): Not run.
            "Unexpected top level member $declaration "
            "(${declaration.runtimeType}).");
      }
    }

    for (Builder declaration in _builderFactoryResult.members) {
      computeDefaultValuesForDeclaration(declaration);
    }
    for (Builder declaration in _builderFactoryResult.setters) {
      computeDefaultValuesForDeclaration(declaration);
    }
    for (ExtensionBuilder declaration in _builderFactoryResult.extensions) {
      if (declaration is SourceExtensionBuilder &&
          declaration.isUnnamedExtension) {
        computeDefaultValuesForDeclaration(declaration);
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

    for (Builder? declaration in _builderFactoryResult.members) {
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
    return _sourceLibraryBuilder.reportFeatureNotEnabled(
        feature, fileUri, charOffset, length);
  }

  @override
  Builder addBuilder(String name, Builder declaration, int charOffset) {
    return _builderFactory.addBuilder(name, declaration, charOffset);
  }
}

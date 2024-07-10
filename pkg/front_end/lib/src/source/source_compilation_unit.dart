// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'source_library_builder.dart';

class SourceCompilationUnitImpl
    implements SourceCompilationUnit, ProblemReporting, BuilderFactory {
  @override
  final Uri fileUri;

  @override
  final Uri importUri;

  final SourceLibraryBuilder _sourceLibraryBuilder;

  SourceLibraryBuilder? _libraryBuilder;

  final TypeParameterScopeBuilder _libraryTypeParameterScopeBuilder;

  @override
  TypeParameterScopeBuilder currentTypeParameterScopeBuilder;

  /// Map used to find objects created in the [OutlineBuilder] from within
  /// the [DietListener].
  ///
  /// This is meant to be written once and read once.
  OffsetMap? _offsetMap;

  String? _name;

  Uri? _partOfUri;

  String? _partOfName;

  LibraryBuilder? _partOfLibrary;

  List<MetadataBuilder>? _metadata;

  /// The part directives in this compilation unit.
  final List<Part> _parts = [];

  final List<Import> imports = <Import>[];

  final List<Export> exports = <Export>[];

  @override
  final List<Export> exporters = <Export>[];

  /// List of [PrefixBuilder]s for imports with prefixes.
  List<PrefixBuilder>? _prefixBuilders;

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

  bool postponedProblemsIssued = false;
  List<PostponedProblem>? postponedProblems;

  /// Index of the library we use references for.
  @override
  final IndexedLibrary? indexedLibrary;

  final List<NominalVariableBuilder> _unboundNominalVariables =
      <NominalVariableBuilder>[];

  final List<StructuralVariableBuilder> _unboundStructuralVariables =
      <StructuralVariableBuilder>[];

  SourceCompilationUnitImpl(
      this._sourceLibraryBuilder, this._libraryTypeParameterScopeBuilder,
      {required this.importUri,
      required this.fileUri,
      required this.packageLanguageVersion,
      required this.indexedLibrary})
      : currentTypeParameterScopeBuilder = _libraryTypeParameterScopeBuilder,
        _languageVersion = packageLanguageVersion;

  @override
  LibraryFeatures get libraryFeatures => _sourceLibraryBuilder.libraryFeatures;

  @override
  bool get forAugmentationLibrary =>
      _sourceLibraryBuilder.isAugmentationLibrary;

  @override
  bool get forPatchLibrary => _sourceLibraryBuilder.isPatchLibrary;

  @override
  bool get isDartLibrary =>
      _sourceLibraryBuilder.origin.importUri.isScheme("dart") ||
      fileUri.isScheme("org-dartlang-sdk");

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
  void beginNestedDeclaration(TypeParameterScopeKind kind, String name,
      {bool hasMembers = true}) {
    currentTypeParameterScopeBuilder =
        currentTypeParameterScopeBuilder.createNested(kind, name, hasMembers);
  }

  @override
  TypeParameterScopeBuilder endNestedDeclaration(
      TypeParameterScopeKind kind, String? name) {
    assert(
        currentTypeParameterScopeBuilder.kind == kind,
        // Coverage-ignore(suite): Not run.
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
        // Coverage-ignore(suite): Not run.
        "${name} != ${currentTypeParameterScopeBuilder.name}");
    TypeParameterScopeBuilder previous = currentTypeParameterScopeBuilder;
    currentTypeParameterScopeBuilder = currentTypeParameterScopeBuilder.parent!;
    return previous;
  }

  // TODO(johnniwinther): Use [_indexedContainer] for library members and make
  // it [null] when there is null corresponding [IndexedContainer].
  IndexedContainer? _indexedContainer;

  @override
  void beginIndexedContainer(String name,
      {required bool isExtensionTypeDeclaration}) {
    if (indexedLibrary != null) {
      if (isExtensionTypeDeclaration) {
        _indexedContainer =
            indexedLibrary!.lookupIndexedExtensionTypeDeclaration(name);
      } else {
        _indexedContainer = indexedLibrary!.lookupIndexedClass(name);
      }
    }
  }

  @override
  void endIndexedContainer() {
    _indexedContainer = null;
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
  void addExporter(LibraryBuilder exporter,
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
    _updateLibraryNNBDSettings();
  }

  void _updateLibraryNNBDSettings() {
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
    library.setLanguageVersion(_languageVersion.version);
    _languageVersion.isFinal = true;
  }

  @override
  void addPostponedProblem(
      Message message, int charOffset, int length, Uri fileUri) {
    if (postponedProblemsIssued) {
      // Coverage-ignore-block(suite): Not run.
      addProblem(message, charOffset, length, fileUri);
    } else {
      postponedProblems ??= <PostponedProblem>[];
      postponedProblems!
          .add(new PostponedProblem(message, charOffset, length, fileUri));
    }
  }

  @override
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
  Iterable<Uri> get dependencies sync* {
    for (Export export in exports) {
      yield export.exportedCompilationUnit.importUri;
    }
    for (Import import in imports) {
      CompilationUnit? imported = import.importedCompilationUnit;
      if (imported != null) {
        yield imported.importUri;
      }
    }
  }

  @override
  bool get isAugmenting => _sourceLibraryBuilder.isAugmenting;

  @override
  bool get isPart => _partOfName != null || _partOfUri != null;

  @override
  bool get isSynthetic => accessProblem != null;

  @override
  bool get isUnsupported => _sourceLibraryBuilder.isUnsupported;

  @override
  SourceLoader get loader => _sourceLibraryBuilder.loader;

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
        this, this, this, _offsetMap = new OffsetMap(fileUri));
  }

  @override
  SourceLibraryBuilder createLibrary() {
    assert(
        _libraryBuilder == null,
        // Coverage-ignore(suite): Not run.
        "Source library builder as already been created for $this.");
    _libraryBuilder = _sourceLibraryBuilder;
    if (isPart) {
      // This is a part with no enclosing library.
      addProblem(messagePartOrphan, 0, 1, fileUri);
      _clearPartsAndReportExporters();
    }
    return _sourceLibraryBuilder;
  }

  @override
  String toString() => 'SourceCompilationUnitImpl($fileUri)';

  @override
  void addDependencies(Library library, Set<SourceCompilationUnit> seen) {
    if (!seen.add(this)) {
      return;
    }

    for (Import import in imports) {
      // Rather than add a LibraryDependency, we attach an annotation.
      if (import.nativeImportPath != null) {
        _sourceLibraryBuilder.addNativeDependency(import.nativeImportPath!);
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
    for (Export export in exports) {
      LibraryDependency libraryDependency = new LibraryDependency.export(
          export.exportedLibraryBuilder.library,
          combinators: toKernelCombinators(export.combinators))
        ..fileOffset = export.charOffset;
      library.addDependency(libraryDependency);
      export.libraryDependency = libraryDependency;
    }
  }

  @override
  void collectInferableTypes(List<InferableType> inferableTypes) {
    _sourceLibraryBuilder.collectInferableTypes(inferableTypes);
  }

  @override
  List<ConstructorReferenceBuilder> get constructorReferences =>
      _sourceLibraryBuilder.constructorReferences;

  @override
  Library get library => _sourceLibraryBuilder.library;

  @override
  LibraryName get libraryName => _sourceLibraryBuilder.libraryName;

  @override
  List<SourceFunctionBuilder> get nativeMethods =>
      _sourceLibraryBuilder.nativeMethods;

  @override
  String? get partOfName => _partOfName;

  @override
  Uri? get partOfUri => _partOfUri;

  @override
  Scope get scope => _sourceLibraryBuilder.scope;

  Map<SourceClassBuilder, TypeBuilder>? _mixinApplications = {};

  @override
  void takeMixinApplications(
      Map<SourceClassBuilder, TypeBuilder> mixinApplications) {
    assert(_mixinApplications != null,
        "Mixin applications have already been processed.");
    mixinApplications.addAll(_mixinApplications!);
    _mixinApplications = null;
  }

  @override
  List<NamedTypeBuilder> get unresolvedNamedTypes =>
      _libraryTypeParameterScopeBuilder.unresolvedNamedTypes;

  @override
  void includeParts(SourceLibraryBuilder libraryBuilder,
      List<SourceCompilationUnit> includedParts, Set<Uri> usedParts) {
    Set<Uri> seenParts = new Set<Uri>();
    int index = 0;
    while (index < _parts.length) {
      Part part = _parts[index];
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
        _parts.removeAt(index);
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
              libraryBuilder.addBuilder(
                  name, declaration, declaration.charOffset);
            }
          } else {
            // No reference: The part is in the same loader so the reference
            // - if needed - was already added.
            libraryBuilder.addBuilder(
                name, declaration, declaration.charOffset);
          }
        }
        libraryBuilder.unresolvedNamedTypes.addAll(part.unresolvedNamedTypes);
        libraryBuilder.constructorReferences.addAll(part.constructorReferences);
        part.libraryName.reference =
            parentCompilationUnit.libraryName.reference;
        part.scope.becomePartOf(libraryBuilder.scope);
        // TODO(ahe): Include metadata from part?

        // Recovery: Take on all exporters (i.e. if a library has erroneously
        // exported the part it has (in validatePart) been recovered to import
        // the main library (this) instead --- to make it complete (and set up
        // scopes correctly) the exporters in this has to be updated too).
        libraryBuilder.exporters.addAll(part.exporters);

        libraryBuilder.nativeMethods.addAll(part.nativeMethods);
        // Check that the targets are different. This is not normally a problem
        // but is for augmentation libraries.
        if (libraryBuilder.library != part.library &&
            part.library.problemsAsJson != null) {
          (libraryBuilder.library.problemsAsJson ??= <String>[])
              .addAll(part.library.problemsAsJson!);
        }
        part.collectInferableTypes(libraryBuilder._inferableTypes!);
        if (libraryBuilder.library != part.library) {
          // Mark the part library as synthetic as it's not an actual library
          // (anymore).
          part.library.isSynthetic = true;
        }
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

  void _clearPartsAndReportExporters() {
    assert(_libraryBuilder != null, "Library has not be set.");
    _parts.clear();
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
  void validatePart(SourceLibraryBuilder library, Set<Uri>? usedParts) {
    _libraryBuilder = library;
    _partOfLibrary = library;
    if (_parts.isNotEmpty) {
      List<LocatedMessage> context = <LocatedMessage>[
        messagePartInPartLibraryContext.withLocation(library.fileUri, -1, 1),
      ];
      for (Part part in _parts) {
        addProblem(messagePartInPart, part.offset, noLength, fileUri,
            context: context);
        // Mark this part as used so we don't report it as orphaned.
        usedParts!.add(part.compilationUnit.importUri);
      }
    }
    _clearPartsAndReportExporters();
  }

  Uri _resolve(Uri baseUri, String? uri, int uriOffset, {isPart = false}) {
    if (uri == null) {
      // Coverage-ignore-block(suite): Not run.
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
      addProblem(
          templateCouldNotParseUri.withArguments(uri, e.message),
          uriOffset +
              1 +
              (e.offset ?? // Coverage-ignore(suite): Not run.
                  -1),
          1,
          fileUri);
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
  void collectUnboundTypeVariables(
      SourceLibraryBuilder libraryBuilder,
      Map<NominalVariableBuilder, SourceLibraryBuilder> nominalVariables,
      Map<StructuralVariableBuilder, SourceLibraryBuilder>
          structuralVariables) {
    for (NominalVariableBuilder builder in _unboundNominalVariables) {
      nominalVariables[builder] = libraryBuilder;
    }
    for (StructuralVariableBuilder builder in _unboundStructuralVariables) {
      structuralVariables[builder] = libraryBuilder;
    }
    _unboundStructuralVariables.clear();
    _unboundNominalVariables.clear();
  }

  @override
  List<StructuralVariableBuilder> copyStructuralVariables(
      List<StructuralVariableBuilder> original,
      TypeParameterScopeBuilder declaration,
      {required TypeVariableKind kind}) {
    List<NamedTypeBuilder> newTypes = <NamedTypeBuilder>[];
    List<StructuralVariableBuilder> copy = <StructuralVariableBuilder>[];
    for (StructuralVariableBuilder variable in original) {
      StructuralVariableBuilder newVariable = new StructuralVariableBuilder(
          variable.name,
          _sourceLibraryBuilder,
          variable.charOffset,
          variable.fileUri,
          bound: variable.bound?.clone(newTypes, this, declaration),
          variableVariance: variable.parameter.isLegacyCovariant
              ? null
              :
              // Coverage-ignore(suite): Not run.
              variable.variance,
          isWildcard: variable.isWildcard);
      copy.add(newVariable);
      _unboundStructuralVariables.add(newVariable);
    }
    for (NamedTypeBuilder newType in newTypes) {
      declaration.registerUnresolvedNamedType(newType);
    }
    return copy;
  }

  @override
  void registerUnboundStructuralVariables(
      List<StructuralVariableBuilder> variableBuilders) {
    _unboundStructuralVariables.addAll(variableBuilders);
  }

  @override
  void addPart(OffsetMap offsetMap, Token partKeyword,
      List<MetadataBuilder>? metadata, String uri, int charOffset) {
    Uri resolvedUri = _resolve(this.importUri, uri, charOffset, isPart: true);
    // To support absolute paths from within packages in the part uri, we try to
    // translate the file uri from the resolved import uri before resolving
    // through the file uri of this library. See issue #52964.
    Uri newFileUri = loader.target.uriTranslator.translate(resolvedUri) ??
        _resolve(fileUri, uri, charOffset);
    // TODO(johnniwinther): Add a LibraryPartBuilder instead of using
    // [LibraryBuilder] to represent both libraries and parts.
    CompilationUnit compilationUnit = loader.read(resolvedUri, charOffset,
        origin: isAugmenting ? _sourceLibraryBuilder.origin : null,
        fileUri: newFileUri,
        accessor: this,
        isPatch: isAugmenting);
    _parts.add(new Part(charOffset, compilationUnit));

    // TODO(ahe): [metadata] should be stored, evaluated, and added to [part].
    LibraryPart part = new LibraryPart(<Expression>[], uri)
      ..fileOffset = charOffset;
    library.addPart(part);
    offsetMap.registerPart(partKeyword, part);
  }

  @override
  void addPartOf(List<MetadataBuilder>? metadata, String? name, String? uri,
      int uriOffset) {
    _partOfName = name;
    if (uri != null) {
      Uri resolvedUri = _partOfUri = _resolve(this.importUri, uri, uriOffset);
      // To support absolute paths from within packages in the part of uri, we
      // try to translate the file uri from the resolved import uri before
      // resolving through the file uri of this library. See issue #52964.
      Uri newFileUri = loader.target.uriTranslator.translate(resolvedUri) ??
          _resolve(fileUri, uri, uriOffset);
      loader.read(partOfUri!, uriOffset, fileUri: newFileUri, accessor: this);
    }
    if (_scriptTokenOffset != null) {
      addProblem(
          messageScriptTagInPartFile, _scriptTokenOffset!, noLength, fileUri);
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

    CompilationUnit? compilationUnit = null;
    Uri? resolvedUri;
    String? nativePath;
    const String nativeExtensionScheme = "dart-ext:";
    if (uri.startsWith(nativeExtensionScheme)) {
      addProblem(messageUnsupportedDartExt, charOffset, noLength, fileUri);
      String strippedUri = uri.substring(nativeExtensionScheme.length);
      if (strippedUri.startsWith("package")) {
        // Coverage-ignore-block(suite): Not run.
        resolvedUri = _resolve(this.importUri, strippedUri,
            uriOffset + nativeExtensionScheme.length);
        resolvedUri = loader.target.translateUri(resolvedUri);
        nativePath = resolvedUri.toString();
      } else {
        resolvedUri = new Uri(scheme: "dart-ext", pathSegments: [uri]);
        nativePath = uri;
      }
    } else {
      resolvedUri = _resolve(this.importUri, uri, uriOffset);
      compilationUnit = loader.read(resolvedUri, uriOffset,
          origin: isAugmentationImport ? _sourceLibraryBuilder : null,
          accessor: this,
          isAugmentation: isAugmentationImport,
          referencesFromIndex: isAugmentationImport ? indexedLibrary : null);
    }

    Import import = new Import(
        _sourceLibraryBuilder,
        compilationUnit,
        isAugmentationImport,
        deferred,
        prefix,
        combinators,
        configurations,
        charOffset,
        prefixCharOffset,
        importIndex,
        nativeImportPath: nativePath);
    imports.add(import);
    offsetMap?.registerImport(importKeyword!, import);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void addSyntheticImport(
      {required String uri,
      required String? prefix,
      required List<CombinatorBuilder>? combinators,
      required bool deferred}) {
    addImport(
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
    bool explicitCoreImport = _sourceLibraryBuilder == loader.coreLibrary;
    for (Import import in imports) {
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
        explicitCoreImport = true;
      }
      import.finalizeImports(_sourceLibraryBuilder);
    }
    if (!explicitCoreImport) {
      NameIterator<Builder> iterator = loader.coreLibrary.exportScope
          .filteredNameIterator(
              includeDuplicates: false, includeAugmentations: false);
      while (iterator.moveNext()) {
        _sourceLibraryBuilder.addToScope(
            iterator.name, iterator.current, -1, true);
      }
    }
  }

  @override
  int finishDeferredLoadTearoffs() {
    int total = 0;
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
        _resolve(this.importUri, uri, uriOffset), charOffset,
        accessor: this);
    exportedLibrary.addExporter(_sourceLibraryBuilder, combinators, charOffset);
    Export export = new Export(
        _sourceLibraryBuilder, exportedLibrary, combinators, charOffset);
    exports.add(export);
    offsetMap.registerExport(exportKeyword, export);
  }

  @override
  void addClass(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      int modifiers,
      Identifier identifier,
      List<NominalVariableBuilder>? typeVariables,
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
        offsetMap,
        TypeParameterScopeKind.classDeclaration,
        metadata,
        modifiers,
        identifier,
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

  @override
  void addEnum(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      Identifier identifier,
      List<NominalVariableBuilder>? typeVariables,
      MixinApplicationBuilder? supertypeBuilder,
      List<TypeBuilder>? interfaceBuilders,
      List<EnumConstantInfo?>? enumConstantInfos,
      int startCharOffset,
      int charEndOffset) {
    String name = identifier.name;
    int charOffset = identifier.nameOffset;

    IndexedClass? referencesFromIndexedClass;
    if (indexedLibrary != null) {
      referencesFromIndexedClass = indexedLibrary!.lookupIndexedClass(name);
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
        _sourceLibraryBuilder,
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

    Map<String, NominalVariableBuilder>? typeVariablesByName =
        _checkTypeVariables(typeVariables, enumBuilder);

    void setParent(MemberBuilder? member) {
      while (member != null) {
        member.parent = enumBuilder;
        member = member.next as MemberBuilder?;
      }
    }

    void setParentAndCheckConflicts(String name, Builder member) {
      if (typeVariablesByName != null) {
        NominalVariableBuilder? tv = typeVariablesByName[name];
        if (tv != null) {
          // Coverage-ignore-block(suite): Not run.
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

    offsetMap.registerNamedDeclaration(identifier, enumBuilder);
  }

  @override
  void addMixinDeclaration(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      int modifiers,
      Identifier identifier,
      List<NominalVariableBuilder>? typeVariables,
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
        offsetMap,
        TypeParameterScopeKind.mixinDeclaration,
        metadata,
        modifiers,
        identifier,
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
      OffsetMap offsetMap,
      TypeParameterScopeKind kind,
      List<MetadataBuilder>? metadata,
      int modifiers,
      Identifier identifier,
      List<NominalVariableBuilder>? typeVariables,
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
    String className = identifier.name;
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
        _sourceLibraryBuilder,
        new List<ConstructorReferenceBuilder>.of(constructorReferences),
        startOffset,
        nameOffset,
        endOffset,
        _indexedContainer,
        isMixinDeclaration: isMixinDeclaration,
        isMacro: isMacro,
        isSealed: isSealed,
        isBase: isBase,
        isInterface: isInterface,
        isFinal: isFinal,
        isAugmentation: isAugmentation,
        isMixinClass: isMixinClass);

    constructorReferences.clear();
    Map<String, NominalVariableBuilder>? typeVariablesByName =
        _checkTypeVariables(typeVariables, classBuilder);
    void setParent(MemberBuilder? member) {
      while (member != null) {
        member.parent = classBuilder;
        member = member.next as MemberBuilder?;
      }
    }

    void setParentAndCheckConflicts(String name, Builder member) {
      if (typeVariablesByName != null) {
        NominalVariableBuilder? tv = typeVariablesByName[name];
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
        getterReference: _indexedContainer?.reference);
    offsetMap.registerNamedDeclaration(identifier, classBuilder);
  }

  @override
  MixinApplicationBuilder addMixinApplication(
      List<TypeBuilder> mixins, int charOffset) {
    return new MixinApplicationBuilder(mixins, fileUri, charOffset);
  }

  @override
  void addNamedMixinApplication(
      List<MetadataBuilder>? metadata,
      String name,
      List<NominalVariableBuilder>? typeVariables,
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
    _checkTypeVariables(typeVariables, supertype.declaration);
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
      List<NominalVariableBuilder>? typeVariables,
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

      /// The names of the type variables of the subclass.
      Set<String>? typeVariableNames;
      if (typeVariables != null) {
        typeVariableNames = new Set<String>();
        for (NominalVariableBuilder typeVariable in typeVariables) {
          typeVariableNames.add(typeVariable.name);
        }
      }

      /// Helper function that returns `true` if a type variable with a name
      /// from [typeVariableNames] is referenced in [type].
      bool usesTypeVariables(TypeBuilder? type) {
        switch (type) {
          case NamedTypeBuilder(
              :TypeDeclarationBuilder? declaration,
              typeArguments: List<TypeBuilder>? arguments
            ):
            if (declaration is NominalVariableBuilder) {
              return typeVariableNames!.contains(declaration.name);
            }
            if (declaration is StructuralVariableBuilder) {
              // Coverage-ignore-block(suite): Not run.
              return typeVariableNames!.contains(declaration.name);
            }

            if (arguments != null && typeVariables != null) {
              for (TypeBuilder argument in arguments) {
                if (usesTypeVariables(argument)) {
                  return true;
                }
              }
            }
          case FunctionTypeBuilder(
              :List<ParameterBuilder>? formals,
              :List<StructuralVariableBuilder>? typeVariables
            ):
            if (formals != null) {
              for (ParameterBuilder formal in formals) {
                if (usesTypeVariables(formal.type)) {
                  return true;
                }
              }
            }
            if (typeVariables != null) {
              for (StructuralVariableBuilder variable in typeVariables) {
                if (usesTypeVariables(variable.bound)) {
                  return true;
                }
              }
            }
            return usesTypeVariables(type.returnType);
          case RecordTypeBuilder(
              :List<RecordTypeFieldBuilder>? positionalFields,
              :List<RecordTypeFieldBuilder>? namedFields
            ):
            if (positionalFields != null) {
              for (RecordTypeFieldBuilder fieldBuilder in positionalFields) {
                if (usesTypeVariables(fieldBuilder.type)) {
                  return true;
                }
              }
            }
            if (namedFields != null) {
              // Coverage-ignore-block(suite): Not run.
              for (RecordTypeFieldBuilder fieldBuilder in namedFields) {
                if (usesTypeVariables(fieldBuilder.type)) {
                  return true;
                }
              }
            }
          case FixedTypeBuilder():
          case InvalidTypeBuilder():
          case OmittedTypeBuilder():
          case null:
            return false;
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
            runningName += "&${mixin.typeName.name}";
            isGeneric = isGeneric || usesTypeVariables(mixin);
          }
        }
        String fullname =
            isNamedMixinApplication ? name : "_$subclassName&$runningName";
        List<NominalVariableBuilder>? applicationTypeVariables;
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
            if (supertype is NamedTypeBuilder &&
                supertype.typeArguments != null) {
              for (int i = 0; i < supertype.typeArguments!.length; ++i) {
                supertype.typeArguments![i] = supertype.typeArguments![i]
                    .clone(newTypes, this, currentTypeParameterScopeBuilder);
              }
            }
            if (mixin is NamedTypeBuilder && mixin.typeArguments != null) {
              for (int i = 0; i < mixin.typeArguments!.length; ++i) {
                mixin.typeArguments![i] = mixin.typeArguments![i]
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
            for (NominalVariableBuilder typeVariable in typeVariables) {
              applicationTypeArguments.add(
                  new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
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
        if (indexedLibrary != null) {
          referencesFromIndexedClass =
              indexedLibrary!.lookupIndexedClass(fullname);
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
            _sourceLibraryBuilder,
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
        supertype = new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
            application, const NullabilityBuilder.omitted(),
            arguments: applicationTypeArguments,
            fileUri: fileUri,
            charOffset: charOffset,
            instanceTypeVariableAccess:
                InstanceTypeVariableAccessState.Allowed);
        _registerMixinApplication(application, mixin);
      }
      return supertype;
    } else {
      return supertype;
    }
  }

  /// Registers that [mixinApplication] is a mixin application introduced by
  /// the [mixedInType] in a with-clause.
  ///
  /// This is used to check that super access in mixin declarations have a
  /// concrete target.
  void _registerMixinApplication(
      SourceClassBuilder mixinApplication, TypeBuilder mixedInType) {
    assert(
        _mixinApplications != null, "Late registration of mixin application.");
    _mixinApplications![mixinApplication] = mixedInType;
  }

  @override
  void addExtensionDeclaration(
      OffsetMap offsetMap,
      Token beginToken,
      List<MetadataBuilder>? metadata,
      int modifiers,
      Identifier? identifier,
      List<NominalVariableBuilder>? typeVariables,
      TypeBuilder type,
      int startOffset,
      int nameOffset,
      int endOffset) {
    String? name = identifier?.name;
    // Nested declaration began in
    // `OutlineBuilder.beginExtensionDeclarationPrelude`.
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
      referenceFrom = indexedLibrary?.lookupExtension(name);
    }

    ExtensionBuilder extensionBuilder = new SourceExtensionBuilder(
        metadata,
        modifiers,
        extensionName,
        typeVariables,
        type,
        classScope,
        _sourceLibraryBuilder,
        startOffset,
        nameOffset,
        endOffset,
        referenceFrom);
    constructorReferences.clear();
    Map<String, NominalVariableBuilder>? typeVariablesByName =
        _checkTypeVariables(typeVariables, extensionBuilder);
    void setParent(MemberBuilder? member) {
      while (member != null) {
        member.parent = extensionBuilder;
        member = member.next as MemberBuilder?;
      }
    }

    void setParentAndCheckConflicts(String name, Builder member) {
      if (typeVariablesByName != null) {
        NominalVariableBuilder? tv = typeVariablesByName[name];
        if (tv != null) {
          // Coverage-ignore-block(suite): Not run.
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
    if (identifier != null) {
      offsetMap.registerNamedDeclaration(identifier, extensionBuilder);
    } else {
      offsetMap.registerUnnamedDeclaration(beginToken, extensionBuilder);
    }
  }

  @override
  void addExtensionTypeDeclaration(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      int modifiers,
      Identifier identifier,
      List<NominalVariableBuilder>? typeVariables,
      List<TypeBuilder>? interfaces,
      int startOffset,
      int endOffset) {
    String name = identifier.name;
    // Nested declaration began in `OutlineBuilder.beginExtensionDeclaration`.
    TypeParameterScopeBuilder declaration = endNestedDeclaration(
        TypeParameterScopeKind.extensionTypeDeclaration, name)
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
        debugName: "extension type $name",
        isModifiable: false);
    ConstructorScope constructorScope =
        new ConstructorScope(name, constructors);

    IndexedContainer? indexedContainer =
        indexedLibrary?.lookupIndexedExtensionTypeDeclaration(name);

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

    ExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
        new SourceExtensionTypeDeclarationBuilder(
            metadata,
            modifiers,
            declaration.name,
            typeVariables,
            interfaces,
            memberScope,
            constructorScope,
            _sourceLibraryBuilder,
            new List<ConstructorReferenceBuilder>.of(constructorReferences),
            startOffset,
            identifier.nameOffset,
            endOffset,
            indexedContainer,
            representationFieldBuilder);
    constructorReferences.clear();
    Map<String, NominalVariableBuilder>? typeVariablesByName =
        _checkTypeVariables(typeVariables, extensionTypeDeclarationBuilder);
    void setParent(MemberBuilder? member) {
      while (member != null) {
        member.parent = extensionTypeDeclarationBuilder;
        member = member.next as MemberBuilder?;
      }
    }

    void setParentAndCheckConflicts(String name, Builder member) {
      if (typeVariablesByName != null) {
        NominalVariableBuilder? tv = typeVariablesByName[name];
        if (tv != null) {
          // Coverage-ignore-block(suite): Not run.
          extensionTypeDeclarationBuilder.addProblem(
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
    addBuilder(extensionTypeDeclarationBuilder.name,
        extensionTypeDeclarationBuilder, identifier.nameOffset,
        getterReference: indexedContainer?.reference);
    offsetMap.registerNamedDeclaration(
        identifier, extensionTypeDeclarationBuilder);
  }

  @override
  void addFunctionTypeAlias(
      List<MetadataBuilder>? metadata,
      String name,
      List<NominalVariableBuilder>? typeVariables,
      TypeBuilder type,
      int charOffset) {
    if (typeVariables != null) {
      for (NominalVariableBuilder typeVariable in typeVariables) {
        typeVariable.varianceCalculationValue =
            VarianceCalculationValue.pending;
      }
    }
    Typedef? referenceFrom = indexedLibrary?.lookupTypedef(name);
    TypeAliasBuilder typedefBuilder = new SourceTypeAliasBuilder(
        metadata, name, typeVariables, type, _sourceLibraryBuilder, charOffset,
        referenceFrom: referenceFrom);
    _checkTypeVariables(typeVariables, typedefBuilder);
    // Nested declaration began in `OutlineBuilder.beginFunctionTypeAlias`.
    endNestedDeclaration(TypeParameterScopeKind.typedef, "#typedef")
        .resolveNamedTypes(typeVariables, this);
    addBuilder(name, typedefBuilder, charOffset,
        getterReference: referenceFrom?.reference);
  }

  @override
  void addConstructor(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      int modifiers,
      Identifier identifier,
      String constructorName,
      List<NominalVariableBuilder>? typeVariables,
      List<FormalParameterBuilder>? formals,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String? nativeMethodName,
      {Token? beginInitializers,
      required bool forAbstractClassOrMixin}) {
    SourceFunctionBuilder builder = _addConstructor(
        metadata,
        modifiers,
        constructorName,
        typeVariables,
        formals,
        startCharOffset,
        charOffset,
        charOpenParenOffset,
        charEndOffset,
        nativeMethodName,
        beginInitializers: beginInitializers,
        forAbstractClassOrMixin: forAbstractClassOrMixin);
    offsetMap.registerConstructor(identifier, builder);
  }

  @override
  void addPrimaryConstructor(
      {required OffsetMap offsetMap,
      required Token beginToken,
      required String constructorName,
      required List<NominalVariableBuilder>? typeVariables,
      required List<FormalParameterBuilder>? formals,
      required int charOffset,
      required bool isConst}) {
    SourceFunctionBuilder builder = _addConstructor(
        null,
        isConst ? constMask : 0,
        constructorName,
        typeVariables,
        formals,
        /* startCharOffset = */ charOffset,
        charOffset,
        /* charOpenParenOffset = */ charOffset,
        /* charEndOffset = */ charOffset,
        /* nativeMethodName = */ null,
        forAbstractClassOrMixin: false);
    offsetMap.registerPrimaryConstructor(beginToken, builder);
  }

  @override
  void addPrimaryConstructorField(
      {required List<MetadataBuilder>? metadata,
      required TypeBuilder type,
      required String name,
      required int charOffset}) {
    _addField(
        metadata,
        finalMask,
        /* isTopLevel = */ false,
        type,
        name,
        /* charOffset = */ charOffset,
        /* charEndOffset = */ charOffset,
        /* initializerToken = */ null,
        /* hasInitializer = */ false);
  }

  SourceFunctionBuilder _addConstructor(
      List<MetadataBuilder>? metadata,
      int modifiers,
      String constructorName,
      List<NominalVariableBuilder>? typeVariables,
      List<FormalParameterBuilder>? formals,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String? nativeMethodName,
      {Token? beginInitializers,
      required bool forAbstractClassOrMixin}) {
    ContainerType containerType =
        currentTypeParameterScopeBuilder.containerType;
    ContainerName? containerName =
        currentTypeParameterScopeBuilder.containerName;
    NameScheme nameScheme = new NameScheme(
        isInstanceMember: false,
        containerName: containerName,
        containerType: containerType,
        libraryName: indexedLibrary != null
            ? new LibraryName(indexedLibrary!.library.reference)
            : libraryName);

    Reference? constructorReference;
    Reference? tearOffReference;

    IndexedContainer? indexedContainer = _indexedContainer;
    if (indexedContainer != null) {
      constructorReference = indexedContainer.lookupConstructorReference(
          nameScheme
              .getConstructorMemberName(constructorName, isTearOff: false)
              .name);
      tearOffReference = indexedContainer.lookupGetterReference(nameScheme
          .getConstructorMemberName(constructorName, isTearOff: true)
          .name);
    }
    AbstractSourceConstructorBuilder constructorBuilder;

    if (currentTypeParameterScopeBuilder.kind ==
        TypeParameterScopeKind.extensionTypeDeclaration) {
      constructorBuilder = new SourceExtensionTypeConstructorBuilder(
          metadata,
          modifiers & ~abstractMask,
          addInferableType(),
          constructorName,
          typeVariables,
          formals,
          _sourceLibraryBuilder,
          startCharOffset,
          charOffset,
          charOpenParenOffset,
          charEndOffset,
          constructorReference,
          tearOffReference,
          nameScheme,
          nativeMethodName: nativeMethodName,
          forAbstractClassOrEnumOrMixin: forAbstractClassOrMixin);
    } else {
      constructorBuilder = new DeclaredSourceConstructorBuilder(
          metadata,
          modifiers & ~abstractMask,
          addInferableType(),
          constructorName,
          typeVariables,
          formals,
          _sourceLibraryBuilder,
          startCharOffset,
          charOffset,
          charOpenParenOffset,
          charEndOffset,
          constructorReference,
          tearOffReference,
          nameScheme,
          nativeMethodName: nativeMethodName,
          forAbstractClassOrEnumOrMixin: forAbstractClassOrMixin);
    }
    _checkTypeVariables(typeVariables, constructorBuilder);
    // TODO(johnniwinther): There is no way to pass the tear off reference here.
    addBuilder(constructorName, constructorBuilder, charOffset,
        getterReference: constructorReference);
    if (nativeMethodName != null) {
      _addNativeMethod(constructorBuilder);
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
    return constructorBuilder;
  }

  @override
  void addFactoryMethod(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      int modifiers,
      Identifier identifier,
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
      returnType = new NamedTypeBuilderImpl.forInvalidType(
          currentTypeParameterScopeBuilder.parent!.name,
          const NullabilityBuilder.omitted(),
          messageExtensionDeclaresConstructor.withLocation(
              fileUri, charOffset, name.length));
    } else {
      returnType = addNamedType(
          new SyntheticTypeName(
              currentTypeParameterScopeBuilder.parent!.name, charOffset),
          const NullabilityBuilder.omitted(),
          <TypeBuilder>[],
          charOffset,
          instanceTypeVariableAccess: InstanceTypeVariableAccessState.Allowed);
    }
    // Nested declaration began in `OutlineBuilder.beginFactoryMethod`.
    TypeParameterScopeBuilder factoryDeclaration = endNestedDeclaration(
        TypeParameterScopeKind.factoryMethod, "#factory_method");

    // Prepare the simple procedure name.
    String procedureName;
    String? constructorName =
        computeAndValidateConstructorName(identifier, isFactory: true);
    if (constructorName != null) {
      procedureName = constructorName;
    } else {
      procedureName = identifier.name;
    }

    ContainerType containerType =
        currentTypeParameterScopeBuilder.containerType;
    ContainerName? containerName =
        currentTypeParameterScopeBuilder.containerName;

    NameScheme procedureNameScheme = new NameScheme(
        containerName: containerName,
        containerType: containerType,
        isInstanceMember: false,
        libraryName: indexedLibrary != null
            ? new LibraryName(
                (_indexedContainer ?? // Coverage-ignore(suite): Not run.
                        indexedLibrary)!
                    .library
                    .reference)
            : libraryName);

    Reference? constructorReference;
    Reference? tearOffReference;
    if (_indexedContainer != null) {
      constructorReference = _indexedContainer!.lookupConstructorReference(
          procedureNameScheme
              .getConstructorMemberName(procedureName, isTearOff: false)
              .name);
      tearOffReference = _indexedContainer!.lookupGetterReference(
          procedureNameScheme
              .getConstructorMemberName(procedureName, isTearOff: true)
              .name);
    } else if (indexedLibrary != null) {
      // Coverage-ignore-block(suite): Not run.
      constructorReference = indexedLibrary!.lookupGetterReference(
          procedureNameScheme
              .getConstructorMemberName(procedureName, isTearOff: false)
              .name);
      tearOffReference = indexedLibrary!.lookupGetterReference(
          procedureNameScheme
              .getConstructorMemberName(procedureName, isTearOff: true)
              .name);
    }

    SourceFactoryBuilder procedureBuilder;
    List<NominalVariableBuilder> typeVariables;
    if (redirectionTarget != null) {
      procedureBuilder = new RedirectingFactoryBuilder(
          metadata,
          staticMask | modifiers,
          returnType,
          procedureName,
          typeVariables = copyTypeVariables(
              currentTypeParameterScopeBuilder.typeVariables ??
                  const <NominalVariableBuilder>[],
              factoryDeclaration,
              kind: TypeVariableKind.function),
          formals,
          _sourceLibraryBuilder,
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
                  const <NominalVariableBuilder>[],
              factoryDeclaration,
              kind: TypeVariableKind.function),
          formals,
          _sourceLibraryBuilder,
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
    if (returnType is NamedTypeBuilderImpl && !typeVariables.isEmpty) {
      returnType.typeArguments =
          new List<TypeBuilder>.generate(typeVariables.length, (int index) {
        return addNamedType(
            new SyntheticTypeName(
                typeVariables[index].name, procedureBuilder.charOffset),
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
      _addNativeMethod(procedureBuilder);
    }
    offsetMap.registerConstructor(identifier, procedureBuilder);
  }

  void _addNativeMethod(SourceFunctionBuilder method) {
    nativeMethods.add(method);
  }

  @override
  String? computeAndValidateConstructorName(Identifier identifier,
      {isFactory = false}) {
    String className = currentTypeParameterScopeBuilder.name;
    String prefix;
    String? suffix;
    int charOffset;
    if (identifier is QualifiedName) {
      Identifier qualifier = identifier.qualifier as Identifier;
      prefix = qualifier.name;
      suffix = identifier.name;
      charOffset = qualifier.nameOffset;
    } else {
      prefix = identifier.name;
      suffix = null;
      charOffset = identifier.nameOffset;
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
  ConstructorReferenceBuilder addConstructorReference(TypeName name,
      List<TypeBuilder>? typeArguments, String? suffix, int charOffset) {
    ConstructorReferenceBuilder ref = new ConstructorReferenceBuilder(
        name, typeArguments, suffix, fileUri, charOffset);
    constructorReferences.add(ref);
    return ref;
  }

  @override
  void addProcedure(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      int modifiers,
      TypeBuilder? returnType,
      Identifier identifier,
      String name,
      List<NominalVariableBuilder>? typeVariables,
      List<FormalParameterBuilder>? formals,
      ProcedureKind kind,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String? nativeMethodName,
      AsyncMarker asyncModifier,
      {required bool isInstanceMember,
      required bool isExtensionMember,
      required bool isExtensionTypeMember}) {
    assert(!isExtensionMember ||
        currentTypeParameterScopeBuilder.kind ==
            TypeParameterScopeKind.extensionDeclaration);
    assert(!isExtensionTypeMember ||
        currentTypeParameterScopeBuilder.kind ==
            TypeParameterScopeKind.extensionTypeDeclaration);
    ContainerType containerType =
        currentTypeParameterScopeBuilder.containerType;
    ContainerName? containerName =
        currentTypeParameterScopeBuilder.containerName;
    NameScheme nameScheme = new NameScheme(
        containerName: containerName,
        containerType: containerType,
        isInstanceMember: isInstanceMember,
        libraryName: indexedLibrary != null
            ? new LibraryName(indexedLibrary!.library.reference)
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
    IndexedContainer? indexedContainer = _indexedContainer ?? indexedLibrary;

    bool isAugmentation = isAugmenting && (modifiers & augmentMask) != 0;
    if (indexedContainer != null && !isAugmentation) {
      Name nameToLookup = nameScheme.getProcedureMemberName(kind, name).name;
      if (kind == ProcedureKind.Setter) {
        if ((isExtensionMember || isExtensionTypeMember) && isInstanceMember) {
          // Extension (type) instance setters are encoded as methods.
          procedureReference =
              indexedContainer.lookupGetterReference(nameToLookup);
        } else {
          procedureReference =
              indexedContainer.lookupSetterReference(nameToLookup);
        }
      } else {
        procedureReference =
            indexedContainer.lookupGetterReference(nameToLookup);
        if ((isExtensionMember || isExtensionTypeMember) &&
            kind == ProcedureKind.Method) {
          tearOffReference = indexedContainer.lookupGetterReference(nameScheme
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
        _sourceLibraryBuilder,
        startCharOffset,
        charOffset,
        charOpenParenOffset,
        charEndOffset,
        procedureReference,
        tearOffReference,
        asyncModifier,
        nameScheme,
        nativeMethodName: nativeMethodName);
    _checkTypeVariables(typeVariables, procedureBuilder);
    addBuilder(name, procedureBuilder, charOffset,
        getterReference: procedureReference);
    if (nativeMethodName != null) {
      _addNativeMethod(procedureBuilder);
    }
    offsetMap.registerProcedure(identifier, procedureBuilder);
  }

  @override
  void addFields(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      int modifiers,
      bool isTopLevel,
      TypeBuilder? type,
      List<FieldInfo> fieldInfos) {
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
      offsetMap.registerField(
          info.identifier,
          _addField(
              metadata,
              modifiers,
              isTopLevel,
              type ?? addInferableType(),
              info.identifier.name,
              info.identifier.nameOffset,
              info.charEndOffset,
              startToken,
              hasInitializer,
              constInitializerToken:
                  potentiallyNeedInitializerInOutline ? startToken : null));
    }
  }

  SourceFieldBuilder _addField(
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
    final bool isExtensionTypeMember = currentTypeParameterScopeBuilder.kind ==
        TypeParameterScopeKind.extensionTypeDeclaration;
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
        libraryName: indexedLibrary != null
            ? new LibraryName(indexedLibrary!.reference)
            : libraryName);
    IndexedContainer? indexedContainer = _indexedContainer ?? indexedLibrary;
    if (indexedContainer != null) {
      if ((isExtensionMember || isExtensionTypeMember) &&
          isInstanceMember &&
          isExternal) {
        /// An external extension (type) instance field is special. It is
        /// treated as an external getter/setter pair and is therefore encoded
        /// as a pair of top level methods using the extension instance member
        /// naming convention.
        fieldGetterReference = indexedContainer.lookupGetterReference(
            nameScheme.getProcedureMemberName(ProcedureKind.Getter, name).name);
        fieldSetterReference = indexedContainer.lookupGetterReference(
            nameScheme.getProcedureMemberName(ProcedureKind.Setter, name).name);
      } else if (isExtensionTypeMember && isInstanceMember) {
        Name nameToLookup = nameScheme
            .getFieldMemberName(FieldNameType.RepresentationField, name,
                isSynthesized: true)
            .name;
        fieldGetterReference =
            indexedContainer.lookupGetterReference(nameToLookup);
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
        _sourceLibraryBuilder,
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
    return fieldBuilder;
  }

  @override
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
    assert(
        !hasThis || !hasSuper,
        // Coverage-ignore(suite): Not run.
        "Formal parameter '${name}' has both 'this' and 'super' prefixes.");
    if (hasThis) {
      modifiers |= initializingFormalMask;
    }
    if (hasSuper) {
      modifiers |= superInitializingFormalMask;
    }
    FormalParameterBuilder formal = new FormalParameterBuilder(
        kind, modifiers, type, name, _sourceLibraryBuilder, charOffset,
        fileUri: fileUri,
        hasImmediatelyDeclaredInitializer: initializerToken != null,
        isWildcard: libraryFeatures.wildcardVariables.isEnabled && name == '_')
      ..initializerToken = initializerToken;
    return formal;
  }

  @override
  TypeBuilder addNamedType(
      TypeName typeName,
      NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder>? arguments,
      int charOffset,
      {required InstanceTypeVariableAccessState instanceTypeVariableAccess}) {
    if (_sourceLibraryBuilder._omittedTypeDeclarationBuilders != null) {
      // Coverage-ignore-block(suite): Not run.
      Builder? builder =
          _sourceLibraryBuilder._omittedTypeDeclarationBuilders[typeName.name];
      if (builder is OmittedTypeDeclarationBuilder) {
        return new DependentTypeBuilder(builder.omittedTypeBuilder);
      }
    }
    return _registerUnresolvedNamedType(new NamedTypeBuilderImpl(
        typeName, nullabilityBuilder,
        arguments: arguments,
        fileUri: fileUri,
        charOffset: charOffset,
        instanceTypeVariableAccess: instanceTypeVariableAccess));
  }

  NamedTypeBuilder _registerUnresolvedNamedType(NamedTypeBuilder type) {
    currentTypeParameterScopeBuilder.registerUnresolvedNamedType(type);
    return type;
  }

  @override
  FunctionTypeBuilder addFunctionType(
      TypeBuilder returnType,
      List<StructuralVariableBuilder>? structuralVariableBuilders,
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
    _checkStructuralVariables(structuralVariableBuilders, null);
    if (structuralVariableBuilders != null) {
      for (StructuralVariableBuilder builder in structuralVariableBuilders) {
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
        .resolveNamedTypesWithStructuralVariables(
            structuralVariableBuilders, _sourceLibraryBuilder);
    return builder;
  }

  Map<String, StructuralVariableBuilder>? _checkStructuralVariables(
      List<StructuralVariableBuilder>? typeVariables, Builder? owner) {
    if (typeVariables == null || typeVariables.isEmpty) return null;
    Map<String, StructuralVariableBuilder> typeVariablesByName =
        <String, StructuralVariableBuilder>{};
    for (StructuralVariableBuilder tv in typeVariables) {
      if (tv.isWildcard) continue;
      StructuralVariableBuilder? existing = typeVariablesByName[tv.name];
      if (existing != null) {
        // Coverage-ignore-block(suite): Not run.
        addProblem(messageTypeVariableDuplicatedName, tv.charOffset,
            tv.name.length, fileUri,
            context: [
              templateTypeVariableDuplicatedNameCause
                  .withArguments(tv.name)
                  .withLocation(
                      fileUri, existing.charOffset, existing.name.length)
            ]);
      } else {
        typeVariablesByName[tv.name] = tv;
        if (owner is ClassBuilder) {
          // Coverage-ignore-block(suite): Not run.
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

  @override
  TypeBuilder addVoidType(int charOffset) {
    // 'void' is always nullable.
    return new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
        new VoidTypeDeclarationBuilder(
            const VoidType(), _sourceLibraryBuilder, charOffset),
        const NullabilityBuilder.inherent(),
        charOffset: charOffset,
        fileUri: fileUri,
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);
  }

  @override
  NominalVariableBuilder addNominalTypeVariable(List<MetadataBuilder>? metadata,
      String name, TypeBuilder? bound, int charOffset, Uri fileUri,
      {required TypeVariableKind kind}) {
    NominalVariableBuilder builder = new NominalVariableBuilder(
        name, _sourceLibraryBuilder, charOffset, fileUri,
        bound: bound,
        metadata: metadata,
        kind: kind,
        isWildcard: libraryFeatures.wildcardVariables.isEnabled && name == '_');

    _unboundNominalVariables.add(builder);
    return builder;
  }

  @override
  StructuralVariableBuilder addStructuralTypeVariable(
      List<MetadataBuilder>? metadata,
      String name,
      TypeBuilder? bound,
      int charOffset,
      Uri fileUri) {
    StructuralVariableBuilder builder = new StructuralVariableBuilder(
        name, _sourceLibraryBuilder, charOffset, fileUri,
        bound: bound,
        metadata: metadata,
        isWildcard: libraryFeatures.wildcardVariables.isEnabled && name == '_');

    _unboundStructuralVariables.add(builder);
    return builder;
  }

  Map<String, NominalVariableBuilder>? _checkTypeVariables(
      List<NominalVariableBuilder>? typeVariables, Builder? owner) {
    if (typeVariables == null || typeVariables.isEmpty) return null;
    Map<String, NominalVariableBuilder> typeVariablesByName =
        <String, NominalVariableBuilder>{};
    for (NominalVariableBuilder tv in typeVariables) {
      NominalVariableBuilder? existing = typeVariablesByName[tv.name];
      if (tv.isWildcard) continue;
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
        if (owner is TypeDeclarationBuilder) {
          // Only classes and extension types and type variables can't have the
          // same name. See
          // [#29555](https://github.com/dart-lang/sdk/issues/29555) and
          // [#54602](https://github.com/dart-lang/sdk/issues/54602).
          switch (owner) {
            case ClassBuilder():
            case ExtensionBuilder():
            case ExtensionTypeDeclarationBuilder():
              if (tv.name == owner.name) {
                addProblem(messageTypeVariableSameNameAsEnclosing,
                    tv.charOffset, tv.name.length, fileUri);
              }
            case TypeAliasBuilder():
            // Coverage-ignore(suite): Not run.
            case NominalVariableBuilder():
            // Coverage-ignore(suite): Not run.
            case StructuralVariableBuilder():
            // Coverage-ignore(suite): Not run.
            case InvalidTypeDeclarationBuilder():
            // Coverage-ignore(suite): Not run.
            case BuiltinTypeDeclarationBuilder():
            // Coverage-ignore(suite): Not run.
            // TODO(johnniwinther): How should we handle this case?
            case OmittedTypeDeclarationBuilder():
          }
        }
      }
    }
    return typeVariablesByName;
  }

  @override
  List<NominalVariableBuilder> copyTypeVariables(
      List<NominalVariableBuilder> original,
      TypeParameterScopeBuilder declaration,
      {required TypeVariableKind kind}) {
    List<NamedTypeBuilder> newTypes = <NamedTypeBuilder>[];
    List<NominalVariableBuilder> copy = <NominalVariableBuilder>[];
    for (NominalVariableBuilder variable in original) {
      NominalVariableBuilder newVariable = new NominalVariableBuilder(
          variable.name,
          _sourceLibraryBuilder,
          variable.charOffset,
          variable.fileUri,
          bound: variable.bound?.clone(newTypes, this, declaration),
          kind: kind,
          variableVariance: variable.parameter.isLegacyCovariant
              ? null
              :
              // Coverage-ignore(suite): Not run.
              variable.variance,
          isWildcard: variable.isWildcard);
      copy.add(newVariable);
      _unboundNominalVariables.add(newVariable);
    }
    for (NamedTypeBuilder newType in newTypes) {
      declaration.registerUnresolvedNamedType(newType);
    }
    return copy;
  }

  @override
  List<MetadataBuilder>? get metadata => _metadata;

  @override
  String? get name => _name;

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
    return _sourceLibraryBuilder.addInferableType();
  }

  @override
  Message reportFeatureNotEnabled(
      LibraryFeature feature, Uri fileUri, int charOffset, int length) {
    return _sourceLibraryBuilder.reportFeatureNotEnabled(
        feature, fileUri, charOffset, length);
  }

  @override
  Builder addBuilder(String name, Builder declaration, int charOffset,
      {Reference? getterReference, Reference? setterReference}) {
    // TODO(ahe): Set the parent correctly here. Could then change the
    // implementation of MemberBuilder.isTopLevel to test explicitly for a
    // LibraryBuilder.
    if (declaration is SourceExtensionBuilder &&
        declaration.isUnnamedExtension) {
      assert(currentTypeParameterScopeBuilder ==
          _libraryTypeParameterScopeBuilder);
      declaration.parent = _sourceLibraryBuilder;
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
        declaration.parent = _sourceLibraryBuilder;
      } else if (declaration is TypeDeclarationBuilder) {
        declaration.parent = _sourceLibraryBuilder;
      } else if (declaration is PrefixBuilder) {
        assert(declaration.parent == _sourceLibraryBuilder);
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

    if (existing == declaration) return declaration;

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
        // Coverage-ignore-block(suite): Not run.
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
          return _sourceLibraryBuilder.computeAmbiguousDeclaration(
              name, existing, member, charOffset);
        });
    } else if (_isDuplicatedDeclaration(existing, declaration)) {
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
    } else if (declaration.isAugment) {
      if (existing != null) {
        if (declaration.isSetter) {
          (currentTypeParameterScopeBuilder.setterAugmentations[name] ??= [])
              .add(declaration);
        } else {
          (currentTypeParameterScopeBuilder.augmentations[name] ??= [])
              .add(declaration);
        }
      } else {
        // TODO(cstefantsova): Report an error.
      }
    } else if (declaration is PrefixBuilder) {
      _prefixBuilders ??= <PrefixBuilder>[];
      _prefixBuilders!.add(declaration);
    }
    return members[name] = declaration;
  }

  bool _isDuplicatedDeclaration(Builder? existing, Builder other) {
    if (existing == null) return false;
    if (other.isAugment) return false;
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
      return !existing.isMixinApplication ||
          // Coverage-ignore(suite): Not run.
          !other.isMixinApplication;
    }
    return true;
  }

  @override
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
          for (NamedTypeBuilder unboundType in unboundTypes) {
            // Coverage-ignore-block(suite): Not run.
            currentTypeParameterScopeBuilder
                .registerUnresolvedNamedType(unboundType);
          }
          this._unboundStructuralVariables.addAll(unboundTypeVariables);
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

        Iterator<SourceMemberBuilder> iterator = declaration.constructorScope
            .filteredIterator<SourceMemberBuilder>(
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
    if (bound is NamedTypeBuilder) {
      TypeDeclarationBuilder? declaration = bound.declaration;
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

    for (Builder? declaration
        in _libraryTypeParameterScopeBuilder.members!.values) {
      while (declaration != null) {
        if (declaration is TypeAliasBuilder &&
            declaration.typeVariablesCount > 0) {
          for (NominalVariableBuilder typeParameter
              in declaration.typeVariables!) {
            typeParameter.variance = computeTypeVariableBuilderVariance(
                    typeParameter, declaration.type)
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
  void computeShowHideElements(ClassMembersBuilder membersBuilder) {
    assert(currentTypeParameterScopeBuilder.kind ==
        TypeParameterScopeKind.library);
    for (ExtensionBuilder _extensionBuilder
        in currentTypeParameterScopeBuilder.extensions!) {
      ExtensionBuilder extensionBuilder = _extensionBuilder;
      if (extensionBuilder is! SourceExtensionBuilder) continue;
      DartType onType = extensionBuilder.extension.onType;
      if (onType is InterfaceType) {
        // TODO(cstefantsova): Handle private names.
        List<Supertype> supertypes = membersBuilder.hierarchyBuilder
            .getNodeFromClass(onType.classNode)
            .superclasses;
        Map<String, Supertype> supertypesByName = <String, Supertype>{};
        for (Supertype supertype in supertypes) {
          // TODO(cstefantsova): Should only non-generic supertypes be allowed?
          supertypesByName[supertype.classNode.name] = supertype;
        }
      }
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  // TODO(johnniwinther): Avoid using [_sourceLibraryBuilder.library] here.
  Uri get originImportUri => _sourceLibraryBuilder.library.importUri;
}

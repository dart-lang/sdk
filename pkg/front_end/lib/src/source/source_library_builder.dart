// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_library_builder;

import 'dart:collection';
import 'dart:convert' show jsonEncode;

import 'package:_fe_analyzer_shared/src/field_promotability.dart';
import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_operations.dart';
import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:_fe_analyzer_shared/src/util/resolve_relative_uri.dart'
    show resolveRelativeUri;
import 'package:kernel/ast.dart' hide Combinator, MapLiteralEntry;
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClassHierarchyBase, ClassHierarchyMembers;
import 'package:kernel/clone.dart' show CloneVisitorNotMembers;
import 'package:kernel/names.dart' show indexSetName;
import 'package:kernel/reference_from_index.dart'
    show IndexedClass, IndexedContainer, IndexedLibrary;
import 'package:kernel/src/bounds_checks.dart'
    show
        TypeArgumentIssue,
        VarianceCalculationValue,
        findTypeArgumentIssues,
        findTypeArgumentIssuesForInvocation,
        getGenericTypeName,
        hasGenericFunctionTypeAsTypeArgument;
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart'
    show SubtypeCheckMode, TypeEnvironment;

import '../api_prototype/experimental_flags.dart';
import '../base/combinator.dart' show CombinatorBuilder;
import '../base/configuration.dart' show Configuration;
import '../base/export.dart' show Export;
import '../base/identifiers.dart' show Identifier, QualifiedName;
import '../base/import.dart' show Import;
import '../base/messages.dart';
import '../base/modifier.dart'
    show
        abstractMask,
        augmentMask,
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
import '../base/nnbd_mode.dart';
import '../base/problems.dart' show unexpected, unhandled;
import '../base/scope.dart';
import '../base/uris.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/dynamic_type_declaration_builder.dart';
import '../builder/field_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/inferable_type_builder.dart';
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
import '../builder/type_builder.dart';
import '../builder/void_type_declaration_builder.dart';
import '../kernel/body_builder_context.dart';
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
        getNonSimplicityIssuesForTypeVariables;
import '../kernel/utils.dart'
    show
        compareProcedures,
        exportDynamicSentinel,
        exportNeverSentinel,
        toKernelCombinators,
        unserializableExportName;
import '../util/helpers.dart';
import 'builder_factory.dart';
import 'class_declaration.dart';
import 'name_scheme.dart';
import 'offset_map.dart';
import 'outline_builder.dart';
import 'source_class_builder.dart' show SourceClassBuilder;
import 'source_constructor_builder.dart';
import 'source_enum_builder.dart';
import 'source_extension_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_factory_builder.dart';
import 'source_field_builder.dart';
import 'source_function_builder.dart';
import 'source_loader.dart' show SourceLoader;
import 'source_member_builder.dart';
import 'source_procedure_builder.dart';
import 'source_type_alias_builder.dart';

part 'source_compilation_unit.dart';

class SourceLibraryBuilder extends LibraryBuilderImpl {
  late final SourceCompilationUnit compilationUnit;

  @override
  final SourceLoader loader;

  final List<ConstructorReferenceBuilder> constructorReferences =
      <ConstructorReferenceBuilder>[];

  final List<SourceCompilationUnit> _parts = [];

  final Scope importScope;

  @override
  final Uri fileUri;

  final Uri? _packageUri;

  // Coverage-ignore(suite): Not run.
  Uri? get packageUriForTesting => _packageUri;

  @override
  final bool isUnsupported;

  @override
  String? name;

  String? partOfName;

  Uri? partOfUri;

  @override
  LibraryBuilder? partOfLibrary;

  List<MetadataBuilder>? metadata;

  @override
  final Library library;

  final LibraryName libraryName;

  final SourceLibraryBuilder? _immediateOrigin;

  final List<SourceFunctionBuilder> nativeMethods = <SourceFunctionBuilder>[];

  final List<NominalVariableBuilder> unboundNominalVariables =
      <NominalVariableBuilder>[];

  final List<StructuralVariableBuilder> unboundStructuralVariables =
      <StructuralVariableBuilder>[];

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
  Library get nameOrigin =>
      _nameOrigin
          // Coverage-ignore(suite): Not run.
          ?.library ??
      library;

  @override
  LibraryBuilder get nameOriginBuilder => _nameOrigin ?? this;
  final LibraryBuilder? _nameOrigin;

  /// Index of the library we use references for.
  // TODO(johnniwinther): Move this to [SourceCompilationUnitImpl].
  final IndexedLibrary? indexedLibrary;

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
  /// This language version will be used as the language version for the library
  /// if the library does not contain an explicit @dart= annotation.
  final LanguageVersion packageLanguageVersion;

  /// The actual language version of this library. This is initially the
  /// [packageLanguageVersion] but will be updated if the library contains
  /// an explicit @dart= language version annotation.
  LanguageVersion _languageVersion;

  bool postponedProblemsIssued = false;
  List<PostponedProblem>? postponedProblems;

  List<SourceLibraryBuilder>? _augmentationLibraries;

  int augmentationIndex = 0;

  /// `true` if this is an augmentation library.
  final bool isAugmentationLibrary;

  /// `true` if this is a patch library.
  final bool isPatchLibrary;

  /// Map from synthesized names used for omitted types to their corresponding
  /// synthesized type declarations.
  ///
  /// This is used in macro generated code to create type annotations from
  /// inferred types in the original code.
  // TODO(johnniwinther): Move to [SourceCompilationUnitImpl].
  final Map<String, Builder>? _omittedTypeDeclarationBuilders;

  MergedLibraryScope? _mergedScope;

  /// If `null`, [SourceLoader.computeFieldPromotability] hasn't been called
  /// yet, or field promotion is disabled for this library.  If not `null`,
  /// Information about which fields are promotable in this library, or `null`
  /// if [SourceLoader.computeFieldPromotability] hasn't been called.
  FieldNonPromotabilityInfo? fieldNonPromotabilityInfo;

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
      IndexedLibrary? referencesFromIndex,
      {bool? referenceIsPartOwner,
      required bool isUnsupported,
      required bool isAugmentation,
      required bool isPatch,
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
            referencesFromIndex,
            isUnsupported: isUnsupported,
            isAugmentation: isAugmentation,
            isPatch: isPatch,
            omittedTypes: omittedTypes);

  SourceLibraryBuilder.fromScopes(
      this.loader,
      this.importUri,
      this.fileUri,
      this._packageUri,
      this.packageLanguageVersion,
      TypeParameterScopeBuilder libraryTypeParameterScopeBuilder,
      this.importScope,
      SourceLibraryBuilder? origin,
      this.library,
      this._nameOrigin,
      this.indexedLibrary,
      {required this.isUnsupported,
      required bool isAugmentation,
      required bool isPatch,
      Map<String, Builder>? omittedTypes})
      : _languageVersion = packageLanguageVersion,
        _immediateOrigin = origin,
        _omittedTypeDeclarationBuilders = omittedTypes,
        libraryName = new LibraryName(library.reference),
        isAugmentationLibrary = isAugmentation,
        isPatchLibrary = isPatch,
        super(
            fileUri,
            libraryTypeParameterScopeBuilder.toScope(importScope,
                omittedTypeDeclarationBuilders: omittedTypes),
            origin?.exportScope ?? new Scope.top(kind: ScopeKind.library)) {
    assert(
        _packageUri == null ||
            !importUri.isScheme('package') ||
            // Coverage-ignore(suite): Not run.
            importUri.path.startsWith(_packageUri.path),
        // Coverage-ignore(suite): Not run.
        "Foreign package uri '$_packageUri' set on library with import uri "
        "'${importUri}'.");
    assert(
        !importUri.isScheme('dart') || _packageUri == null,
        // Coverage-ignore(suite): Not run.
        "Package uri '$_packageUri' set on dart: library with import uri "
        "'${importUri}'.");
    compilationUnit =
        new SourceCompilationUnitImpl(this, libraryTypeParameterScopeBuilder);
  }

  MergedLibraryScope get mergedScope {
    return _mergedScope ??=
        isAugmenting ? origin.mergedScope : new MergedLibraryScope(this);
  }

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
      // TODO(johnniwinther): Ideally the error should actually be special-cased
      // to mention that it is an experimental feature.
      String enabledVersionText = feature.flag.isEnabledByDefault
          ? feature.enabledVersion.toText()
          : "the current release";
      if (languageVersion.isExplicit) {
        message = templateExperimentOptOutExplicit.withArguments(
            feature.flag.name, enabledVersionText);
        addProblem(message, charOffset, length, fileUri,
            context: <LocatedMessage>[
              templateExperimentOptOutComment
                  .withArguments(feature.flag.name)
                  .withLocation(languageVersion.fileUri!,
                      languageVersion.charOffset, languageVersion.charCount)
            ]);
      } else {
        message = templateExperimentOptOutImplicit.withArguments(
            feature.flag.name, enabledVersionText);
        addProblem(message, charOffset, length, fileUri);
      }
    } else {
      if (feature.flag.isEnabledByDefault) {
        // Coverage-ignore-block(suite): Not run.
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
      IndexedLibrary? referencesFromIndex,
      bool? referenceIsPartOwner,
      required bool isUnsupported,
      required bool isAugmentation,
      required bool isPatch,
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
                            : referencesFromIndex?.library.reference)
                  ..setLanguageVersion(packageLanguageVersion.version)),
            nameOrigin,
            referencesFromIndex,
            referenceIsPartOwner: referenceIsPartOwner,
            isUnsupported: isUnsupported,
            isAugmentation: isAugmentation,
            isPatch: isPatch,
            omittedTypes: omittedTypes);

  Iterable<SourceCompilationUnit> get parts => _parts;

  @override
  bool get isPart => partOfName != null || partOfUri != null;

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
    assert(
        augmentationLibrary.isAugmenting,
        // Coverage-ignore(suite): Not run.
        "Library ${augmentationLibrary} must be a augmentation library.");
    assert(
        !augmentationLibrary.isPart,
        // Coverage-ignore(suite): Not run.
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
    SourceLibraryBuilder augmentationLibrary = new SourceLibraryBuilder(
        fileUri: uri,
        importUri: uri,
        packageLanguageVersion: packageLanguageVersion,
        loader: loader,
        isUnsupported: false,
        target: library,
        origin: this,
        isAugmentation: true,
        isPatch: false,
        referencesFromIndex: indexedLibrary,
        omittedTypes: omittedTypeDeclarationBuilders);
    addAugmentationLibrary(augmentationLibrary);
    loader.registerUnparsedLibrarySource(
        augmentationLibrary.compilationUnit, source);
    return augmentationLibrary;
  }

  List<NamedTypeBuilder> get unresolvedNamedTypes =>
      compilationUnit.unresolvedNamedTypes;

  @override
  bool get isSynthetic => compilationUnit.isSynthetic;

  bool get isInferenceUpdate1Enabled =>
      libraryFeatures.inferenceUpdate1.isSupported &&
      languageVersion.version >=
          libraryFeatures.inferenceUpdate1.enabledVersion;

  LanguageVersion get languageVersion {
    assert(
        _languageVersion.isFinal,
        // Coverage-ignore(suite): Not run.
        "Attempting to read the language version of ${this} before has been "
        "finalized.");
    return _languageVersion;
  }

  void markLanguageVersionFinal() {
    _languageVersion.isFinal = true;
    _updateLibraryNNBDSettings();
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
  // Coverage-ignore(suite): Not run.
  Iterable<Uri> get dependencies sync* {
    yield* compilationUnit.dependencies;
    for (SourceCompilationUnit part in parts) {
      yield part.importUri;
      yield* part.dependencies;
    }
  }

  Builder addBuilder(String name, Builder declaration, int charOffset) {
    return compilationUnit.addBuilder(name, declaration, charOffset);
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
  Library buildOutlineNodes(LibraryBuilder coreLibrary) {
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

    checkMemberConflicts(this, scope,
        checkForInstanceVsStaticConflict: false,
        checkForMethodVsSetterConflict: true);

    Iterator<Builder> iterator = localMembersIterator;
    while (iterator.moveNext()) {
      _buildOutlineNodes(iterator.current, coreLibrary);
    }

    library.isSynthetic = isSynthetic;
    library.isUnsupported = isUnsupported;
    addDependencies(library, new Set<SourceCompilationUnit>());

    library.name = name;
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
    NameIterator iterator = scope.filteredNameIterator(
        includeDuplicates: false, includeAugmentations: false);
    while (iterator.moveNext()) {
      addToExportScope(iterator.name, iterator.current);
    }
  }

  void addImportsToScope() {
    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.addImportsToScope();
      }
    }

    compilationUnit.addImportsToScope();
    // TODO(johnniwinther): Support imports into parts.
    /*for (SourceCompilationUnit part in parts) {
      part.addImportsToScope();
    }*/

    NameIterator<Builder> iterator = exportScope.filteredNameIterator(
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
              library.additionalExports.add(builder.typedef.reference);
            case ExtensionBuilder():
              library.additionalExports.add(builder.extension.reference);
            case ExtensionTypeDeclarationBuilder():
              library.additionalExports
                  .add(builder.extensionTypeDeclaration.reference);
            case InvalidTypeDeclarationBuilder():
              (unserializableExports ??= {})[name] =
                  builder.message.problemMessage;
            case BuiltinTypeDeclarationBuilder():
              if (builder is DynamicTypeDeclarationBuilder) {
                assert(
                    name == 'dynamic',
                    // Coverage-ignore(suite): Not run.
                    "Unexpected export name for 'dynamic': '$name'");
                (unserializableExports ??= {})[name] = exportDynamicSentinel;
              } else if (builder is NeverTypeDeclarationBuilder) {
                assert(
                    name == 'Never',
                    // Coverage-ignore(suite): Not run.
                    "Unexpected export name for 'Never': '$name'");
                (unserializableExports ??= // Coverage-ignore(suite): Not run.
                    {})[name] = exportNeverSentinel;
              }
            // Coverage-ignore(suite): Not run.
            // TODO(johnniwinther): How should we handle this case?
            case OmittedTypeDeclarationBuilder():
            case NominalVariableBuilder():
            case StructuralVariableBuilder():
              unhandled(
                  'member', 'exportScope', builder.charOffset, builder.fileUri);
          }
        } else if (builder is MemberBuilder) {
          for (Member exportedMember in builder.exportedMembers) {
            if (exportedMember is Field) {
              // For fields add both getter and setter references
              // so replacing a field with a getter/setter pair still
              // exports correctly.
              library.additionalExports.add(exportedMember.getterReference);
              if (exportedMember.hasSetter) {
                library.additionalExports.add(exportedMember.setterReference!);
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

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        typeCount += augmentationLibrary.resolveTypes();
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
                instanceTypeVariableAccess:
                    InstanceTypeVariableAccessState.Unexpected);
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
      for (Builder member in extension_.scope.localMembers) {
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
      for (Builder member in extensionType.scope.localMembers) {
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
    return name ?? "<library '$fileUri'>";
  }

  @override
  bool get isAugmenting => _immediateOrigin != null;

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
  // Coverage-ignore(suite): Not run.
  void becomeCoreLibrary() {
    if (scope.lookupLocalMember("dynamic", setter: false) == null) {
      addBuilder("dynamic",
          new DynamicTypeDeclarationBuilder(const DynamicType(), this, -1), -1);
    }
    if (scope.lookupLocalMember("Never", setter: false) == null) {
      addBuilder(
          "Never",
          new NeverTypeDeclarationBuilder(
              const NeverType.nonNullable(), this, -1),
          -1);
    }
    assert(scope.lookupLocalMember("Null", setter: false) != null,
        "No class 'Null' found in dart:core.");
  }

  List<InferableType>? _inferableTypes = [];

  InferableTypeBuilder addInferableType() {
    InferableTypeBuilder typeBuilder = new InferableTypeBuilder();
    registerInferableType(typeBuilder);
    return typeBuilder;
  }

  void registerInferableType(InferableType inferableType) {
    assert(
        _inferableTypes != null,
        // Coverage-ignore(suite): Not run.
        "Late registration of inferable type $inferableType.");
    _inferableTypes?.add(inferableType);
  }

  void collectInferableTypes(List<InferableType> inferableTypes) {
    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.collectInferableTypes(inferableTypes);
      }
    }
    if (_inferableTypes != null) {
      inferableTypes.addAll(_inferableTypes!);
    }
    _inferableTypes = null;
  }

  /// Add a problem that might not be reported immediately.
  ///
  /// Problems will be issued after source information has been added.
  /// Once the problems has been issued, adding a new "postponed" problem will
  /// be issued immediately.
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

  // TODO(johnniwinther): Move this to [SourceCompilationUnitImpl].
  Map<SourceClassBuilder, TypeBuilder>? _mixinApplications = {};

  // TODO(johnniwinther): Move access to [_mixinApplications] to
  //  [SourceCompilationUnitImpl].
  void takeMixinApplications(
      Map<SourceClassBuilder, TypeBuilder> mixinApplications) {
    assert(_mixinApplications != null,
        "Mixin applications have already been processed.");
    mixinApplications.addAll(_mixinApplications!);
    _mixinApplications = null;
    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.takeMixinApplications(mixinApplications);
      }
    }
  }

  BodyBuilderContext createBodyBuilderContext(
      {required bool inOutlineBuildingPhase,
      required bool inMetadata,
      required bool inConstFields}) {
    return new LibraryBodyBuilderContext(this,
        inOutlineBuildingPhase: inOutlineBuildingPhase,
        inMetadata: inMetadata,
        inConstFields: inConstFields);
  }

  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      List<DelayedActionPerformer> delayedActionPerformers) {
    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.buildOutlineExpressions(classHierarchy,
            delayedDefaultValueCloners, delayedActionPerformers);
      }
    }

    MetadataBuilder.buildAnnotations(
        library,
        metadata,
        createBodyBuilderContext(
            inOutlineBuildingPhase: true,
            inMetadata: true,
            inConstFields: false),
        this,
        fileUri,
        scope,
        createFileUriExpression: isAugmenting);

    Iterator<Builder> iterator = localMembersIterator;
    while (iterator.moveNext()) {
      Builder declaration = iterator.current;
      if (declaration is SourceClassBuilder) {
        declaration.buildOutlineExpressions(classHierarchy,
            delayedActionPerformers, delayedDefaultValueCloners);
      } else if (declaration is SourceExtensionBuilder) {
        declaration.buildOutlineExpressions(classHierarchy,
            delayedActionPerformers, delayedDefaultValueCloners);
      } else if (declaration is SourceExtensionTypeDeclarationBuilder) {
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
                // Coverage-ignore(suite): Not run.
                declaration is DynamicTypeDeclarationBuilder ||
                // Coverage-ignore(suite): Not run.
                declaration is NeverTypeDeclarationBuilder,
            // Coverage-ignore(suite): Not run.
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
    } else if (declaration is PrefixBuilder) {
      // Ignored. Kernel doesn't represent prefixes.
      return;
    }
    // Coverage-ignore(suite): Not run.
    else if (declaration is BuiltinTypeDeclarationBuilder) {
      // Nothing needed.
      return;
    } else {
      unhandled("${declaration.runtimeType}", "buildBuilder",
          declaration.charOffset, declaration.fileUri);
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
      unhandled("${member.runtimeType}", "_buildMember", declaration.charOffset,
          declaration.fileUri);
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
      // Coverage-ignore-block(suite): Not run.
      annotation =
          new StaticInvocation(constructor.member as Procedure, arguments)
            ..isConst = true;
    }
    library.addAnnotation(annotation);
  }

  void addDependencies(Library library, Set<SourceCompilationUnit> seen) {
    compilationUnit.addDependencies(library, seen);
    for (SourceCompilationUnit part in parts) {
      part.addDependencies(library, seen);
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
      // Coverage-ignore-block(suite): Not run.
      AccessErrorBuilder error = declaration;
      declaration = error.builder;
    }
    if (other is AccessErrorBuilder) {
      // Coverage-ignore-block(suite): Not run.
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
      if (isImport &&
          declaration is PrefixBuilder &&
          // Coverage-ignore(suite): Not run.
          other is PrefixBuilder) {
        // Coverage-ignore-block(suite): Not run.
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

    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        total += augmentationLibrary.finishDeferredLoadTearoffs();
      }
    }

    total += compilationUnit.finishDeferredLoadTearoffs();
    for (SourceCompilationUnit part in parts) {
      total += part.finishDeferredLoadTearoffs();
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

    for (SourceFunctionBuilder method in nativeMethods) {
      method.becomeNative(loader);
    }
    count += nativeMethods.length;

    return count;
  }

  List<StructuralVariableBuilder> copyStructuralVariables(
      List<StructuralVariableBuilder> original,
      TypeParameterScopeBuilder declaration,
      {required TypeVariableKind kind}) {
    List<NamedTypeBuilder> newTypes = <NamedTypeBuilder>[];
    List<StructuralVariableBuilder> copy = <StructuralVariableBuilder>[];
    for (StructuralVariableBuilder variable in original) {
      StructuralVariableBuilder newVariable = new StructuralVariableBuilder(
          variable.name, this, variable.charOffset, variable.fileUri,
          bound: variable.bound?.clone(newTypes, this, declaration),
          variableVariance: variable.parameter.isLegacyCovariant
              ? null
              :
              // Coverage-ignore(suite): Not run.
              variable.variance,
          isWildcard: variable.isWildcard);
      copy.add(newVariable);
      unboundStructuralVariables.add(newVariable);
    }
    for (NamedTypeBuilder newType in newTypes) {
      declaration.registerUnresolvedNamedType(newType);
    }
    return copy;
  }

  /// Adds all [unboundNominalVariables] to [typeVariableBuilders], mapping them
  /// to this library.
  ///
  /// This is used to compute the bounds of type variable while taking the
  /// bound dependencies, which might span multiple libraries, into account.
  void collectUnboundTypeVariables(
      Map<NominalVariableBuilder, SourceLibraryBuilder> typeVariableBuilders,
      Map<StructuralVariableBuilder, SourceLibraryBuilder>
          functionTypeTypeVariableBuilders) {
    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.collectUnboundTypeVariables(
            typeVariableBuilders, functionTypeTypeVariableBuilders);
      }
    }
    for (NominalVariableBuilder builder in unboundNominalVariables) {
      typeVariableBuilders[builder] = this;
    }
    for (StructuralVariableBuilder builder in unboundStructuralVariables) {
      functionTypeTypeVariableBuilders[builder] = this;
    }
    unboundNominalVariables.clear();
  }

  /// Assigns nullabilities to types in [_pendingNullabilities].
  ///
  /// It's a helper function to assign the nullabilities to type-parameter types
  /// after the corresponding type parameters have their bounds set or changed.
  /// The function takes into account that some of the types in the input list
  /// may be bounds to some of the type parameters of other types from the input
  /// list.
  void processPendingNullabilities({Set<DartType>? typeFilter}) {
    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.processPendingNullabilities();
      }
    }

    // The bounds of type parameters may be type-parameter types of other
    // parameters from the same declaration.  In this case we need to set the
    // nullability for them first.  To preserve the ordering, we implement a
    // depth-first search over the types.  We use the fact that a nullability
    // of a type parameter type can't ever be 'nullable' if computed from the
    // bound. It allows us to use 'nullable' nullability as the marker in the
    // DFS implementation.

    // We cannot set the declared nullability on the pending types to `null` so
    // we create a map of the pending type parameter type nullabilities.
    Map< /* TypeParameterType | StructuralParameterType */ DartType,
        Nullability?> nullabilityMap = new LinkedHashMap.identity();
    Nullability? getDeclaredNullability(
        /* TypeParameterType | StructuralParameterType */ DartType type) {
      assert(type is TypeParameterType || type is StructuralParameterType);
      if (nullabilityMap.containsKey(type)) {
        return nullabilityMap[type];
      }
      return type.declaredNullability;
    }

    void setDeclaredNullability(
        /* TypeParameterType | StructuralParameterType */ DartType type,
        Nullability nullability) {
      assert(type is TypeParameterType || type is StructuralParameterType);
      if (nullabilityMap.containsKey(type)) {
        nullabilityMap[type] = nullability;
      }
      if (type is TypeParameterType) {
        type.declaredNullability = nullability;
      } else {
        type as StructuralParameterType;
        type.declaredNullability = nullability;
      }
    }

    DartType getBound(
        /* TypeParameterType | StructuralParameterType */ DartType type) {
      assert(type is TypeParameterType || type is StructuralParameterType);
      if (type is TypeParameterType) {
        return type.parameter.bound;
      } else {
        type as StructuralParameterType;
        return type.parameter.bound;
      }
    }

    // Coverage-ignore(suite): Not run.
    void setBoundAndDefaultType(
        /* TypeParameterType | StructuralParameterType */ type,
        DartType bound,
        DartType defaultType) {
      assert(type is TypeParameterType || type is StructuralParameterType);
      if (type is TypeParameterType) {
        type.parameter.bound = bound;
        type.parameter.defaultType = defaultType;
      } else {
        type as StructuralParameterType;
        type.parameter.bound = bound;
        type.parameter.defaultType = defaultType;
      }
    }

    Nullability computeNullabilityFromBound(
        /* TypeParameterType | StructuralParameterType */ DartType type) {
      assert(type is TypeParameterType || type is StructuralParameterType);
      if (type is TypeParameterType) {
        return TypeParameterType.computeNullabilityFromBound(type.parameter);
      } else {
        type as StructuralParameterType;
        return StructuralParameterType.computeNullabilityFromBound(
            type.parameter);
      }
    }

    Nullability marker = Nullability.nullable;
    List< /* TypeParameterType | StructuralParameterType */ DartType?> stack =
        new List<DartType?>.filled(_pendingNullabilities.length, null);
    int stackTop = 0;
    for (PendingNullability pendingNullability in _pendingNullabilities) {
      if (typeFilter != null &&
          // Coverage-ignore(suite): Not run.
          !typeFilter.contains(pendingNullability.type)) {
        continue;
      }
      nullabilityMap[pendingNullability.type] = null;
    }
    for (PendingNullability pendingNullability in _pendingNullabilities) {
      if (typeFilter != null &&
          // Coverage-ignore(suite): Not run.
          !typeFilter.contains(pendingNullability.type)) {
        continue;
      }
      DartType type = pendingNullability.type;
      if (getDeclaredNullability(type) != null) {
        // Nullability for [type] was already computed on one of the branches
        // of the depth-first search.  Continue to the next one.
        continue;
      }
      DartType peeledBound = _peelOffFutureOr(getBound(type));
      if (peeledBound is TypeParameterType) {
        DartType current = type;
        DartType? next = peeledBound;
        bool isDirectDependency = identical(getBound(type), peeledBound);
        while (next != null && getDeclaredNullability(next) == null) {
          stack[stackTop++] = current;
          setDeclaredNullability(current, marker);

          current = next;
          peeledBound = _peelOffFutureOr(getBound(current));
          isDirectDependency =
              isDirectDependency && identical(getBound(current), peeledBound);
          if (peeledBound is TypeParameterType) {
            next = peeledBound;
            if (getDeclaredNullability(next) == marker) {
              setDeclaredNullability(next, Nullability.undetermined);
              if (isDirectDependency) {
                // Coverage-ignore-block(suite): Not run.
                // The dependency error is reported elsewhere.
                setBoundAndDefaultType(
                    current, const InvalidType(), const InvalidType());
              }
              next = null;
            }
          } else {
            next = null;
          }
        }
        setDeclaredNullability(current, computeNullabilityFromBound(current));
        while (stackTop != 0) {
          --stackTop;
          current = stack[stackTop]!;
          setDeclaredNullability(current, computeNullabilityFromBound(current));
        }
      } else if (peeledBound is StructuralParameterType) {
        // Coverage-ignore-block(suite): Not run.
        DartType current = type;
        DartType? next = peeledBound;
        bool isDirectDependency = identical(getBound(type), peeledBound);
        while (next != null && getDeclaredNullability(next) == null) {
          stack[stackTop++] = current;
          setDeclaredNullability(current, marker);

          current = next;
          peeledBound = _peelOffFutureOr(getBound(current));
          isDirectDependency =
              isDirectDependency && identical(getBound(current), peeledBound);
          if (peeledBound is StructuralParameterType) {
            next = peeledBound;
            if (getDeclaredNullability(next) == marker) {
              setDeclaredNullability(next, Nullability.undetermined);
              if (isDirectDependency) {
                // The dependency error is reported elsewhere.
                setBoundAndDefaultType(
                    current, const InvalidType(), const InvalidType());
              }
              next = null;
            }
          } else {
            next = null;
          }
        }
        setDeclaredNullability(current, computeNullabilityFromBound(current));
        while (stackTop != 0) {
          --stackTop;
          current = stack[stackTop]!;
          setDeclaredNullability(current, computeNullabilityFromBound(current));
        }
      } else {
        setDeclaredNullability(type, computeNullabilityFromBound(type));
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
  /// inference.  The method returns the number of distinct type variables
  /// that were instantiated in this library.
  int computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder nullType,
      TypeBuilder bottomType, ClassBuilder objectClass) {
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

    return count;
  }

  /// If this is an augmentation library, apply its augmentations to [origin].
  void applyAugmentations() {
    if (!isAugmenting) return;

    if (languageVersion != origin.languageVersion) {
      // Coverage-ignore-block(suite): Not run.
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
      } else if (builder is PrefixBuilder) {
        // Ignored. Kernel doesn't represent prefixes.
      }
      // Coverage-ignore(suite): Not run.
      else if (builder is BuiltinTypeDeclarationBuilder) {
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
          fieldBuilder.charOffset,
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
        // Wildcard optional parameters can't be used so we allow having no
        // initializer.
        if (libraryFeatures.wildcardVariables.isEnabled &&
            formal.isWildcard &&
            !formal.isSuperInitializingFormal &&
            !formal.isInitializingFormal) {
          continue;
        }
        addProblem(
            templateOptionalNonNullableWithoutInitializerError.withArguments(
                formal.name, formal.variable!.type),
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
    // The following error is to be reported elsewhere.
    if (parameters.length != arguments.length) return;

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
    // The error is to be reported elsewhere.
    if (methodParameters.length != arguments.types.length) return;
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

    // The error is to be reported elsewhere.
    if (functionType.typeParameters.length != arguments.types.length) return;
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

    // The error is to be reported elsewhere.
    if (functionType.typeParameters.length != typeArguments.length) {
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
        List<TypeVariableBuilderBase>? typeVariables =
            declaration.typeVariables;
        if (typeVariables != null && typeVariables.isNotEmpty) {
          checkTypeVariableDependencies(typeVariables);
        }
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
        List<TypeVariableBuilderBase>? typeVariables =
            declaration.typeVariables;
        if (typeVariables != null && typeVariables.isNotEmpty) {
          checkTypeVariableDependencies(typeVariables);
        }
        declaration.checkTypesInOutline(typeEnvironment);
      } else if (declaration is SourceExtensionBuilder) {
        List<TypeVariableBuilderBase>? typeVariables =
            declaration.typeParameters;
        if (typeVariables != null && typeVariables.isNotEmpty) {
          checkTypeVariableDependencies(typeVariables);
        }
        declaration.checkTypesInOutline(typeEnvironment);
      } else if (declaration is SourceExtensionTypeDeclarationBuilder) {
        List<TypeVariableBuilderBase>? typeVariables =
            declaration.typeParameters;
        if (typeVariables != null && typeVariables.isNotEmpty) {
          checkTypeVariableDependencies(typeVariables);
        }
        declaration.checkTypesInOutline(typeEnvironment);
      } else if (declaration is SourceTypeAliasBuilder) {
        List<TypeVariableBuilderBase>? typeVariables =
            declaration.typeVariables;
        if (typeVariables != null && typeVariables.isNotEmpty) {
          checkTypeVariableDependencies(typeVariables);
        }
      } else {
        assert(
            declaration is! TypeDeclarationBuilder ||
                // Coverage-ignore(suite): Not run.
                declaration is BuiltinTypeDeclarationBuilder,
            // Coverage-ignore(suite): Not run.
            "Unexpected declaration ${declaration.runtimeType}");
      }
    }
    checkPendingBoundsChecks(typeEnvironment);
  }

  void checkTypeVariableDependencies(
      List<TypeVariableBuilderBase> typeVariables) {
    Map<TypeVariableBuilderBase, TypeVariableTraversalState>
        typeVariablesTraversalState =
        <TypeVariableBuilderBase, TypeVariableTraversalState>{};
    for (TypeVariableBuilderBase typeVariable in typeVariables) {
      if ((typeVariablesTraversalState[typeVariable] ??=
              TypeVariableTraversalState.unvisited) ==
          TypeVariableTraversalState.unvisited) {
        TypeVariableCyclicDependency? dependency =
            typeVariable.findCyclicDependency(
                typeVariablesTraversalState: typeVariablesTraversalState);
        if (dependency != null) {
          Message message;
          if (dependency.viaTypeVariables != null) {
            message = templateCycleInTypeVariables.withArguments(
                dependency.typeVariableBoundOfItself.name,
                dependency.viaTypeVariables!.map((v) => v.name).join("', '"));
          } else {
            message = templateDirectCycleInTypeVariables
                .withArguments(dependency.typeVariableBoundOfItself.name);
          }
          addProblem(
              message,
              dependency.typeVariableBoundOfItself.charOffset,
              dependency.typeVariableBoundOfItself.name.length,
              dependency.typeVariableBoundOfItself.fileUri);

          typeVariable.bound = new NamedTypeBuilderImpl(
              new SyntheticTypeName(typeVariable.name, typeVariable.charOffset),
              const NullabilityBuilder.omitted(),
              fileUri: typeVariable.fileUri,
              charOffset: typeVariable.charOffset,
              instanceTypeVariableAccess:
                  InstanceTypeVariableAccessState.Unexpected)
            ..bind(
                this,
                new InvalidTypeDeclarationBuilder(
                    typeVariable.name,
                    message.withLocation(
                        dependency.typeVariableBoundOfItself
                                .fileUri ?? // Coverage-ignore(suite): Not run.
                            fileUri,
                        dependency.typeVariableBoundOfItself.charOffset,
                        dependency.typeVariableBoundOfItself.name.length)));
        }
      }
    }
  }

  void computeShowHideElements(ClassMembersBuilder membersBuilder) {
    Iterable<SourceLibraryBuilder>? augmentationLibraries =
        this.augmentationLibraries;
    if (augmentationLibraries != null) {
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.computeShowHideElements(membersBuilder);
      }
    }

    compilationUnit.computeShowHideElements(membersBuilder);
  }

  void forEachExtensionInScope(void Function(ExtensionBuilder) f) {
    compilationUnit.forEachExtensionInScope(f);
  }

  // Coverage-ignore(suite): Not run.
  void clearExtensionsInScopeCache() {
    compilationUnit.clearExtensionsInScopeCache();
  }

  void registerPendingNullability(
      Uri fileUri, int charOffset, TypeParameterType type) {
    _pendingNullabilities
        .add(new PendingNullability(fileUri, charOffset, type));
  }

  void registerPendingFunctionTypeNullability(
      Uri fileUri, int charOffset, StructuralParameterType type) {
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

// The kind of type parameter scope built by a [TypeParameterScopeBuilder]
// object.
enum TypeParameterScopeKind {
  library,
  classOrNamedMixinApplication,
  classDeclaration,
  mixinDeclaration,
  unnamedMixinApplication,
  namedMixinApplication,
  extensionOrExtensionTypeDeclaration,
  extensionDeclaration,
  extensionTypeDeclaration,
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
      case TypeParameterScopeKind.extensionTypeDeclaration:
        return new ClassName(name);
      case TypeParameterScopeKind.extensionDeclaration:
        return extensionName;
      // Coverage-ignore(suite): Not run.
      case TypeParameterScopeKind.typedef:
      case TypeParameterScopeKind.staticMethod:
      case TypeParameterScopeKind.instanceMethod:
      case TypeParameterScopeKind.constructor:
      case TypeParameterScopeKind.topLevelMethod:
      case TypeParameterScopeKind.factoryMethod:
      case TypeParameterScopeKind.functionType:
      case TypeParameterScopeKind.extensionOrExtensionTypeDeclaration:
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
      case TypeParameterScopeKind.extensionTypeDeclaration:
        return ContainerType.ExtensionType;
      // Coverage-ignore(suite): Not run.
      case TypeParameterScopeKind.typedef:
      case TypeParameterScopeKind.staticMethod:
      case TypeParameterScopeKind.instanceMethod:
      case TypeParameterScopeKind.constructor:
      case TypeParameterScopeKind.topLevelMethod:
      case TypeParameterScopeKind.factoryMethod:
      case TypeParameterScopeKind.functionType:
      case TypeParameterScopeKind.extensionOrExtensionTypeDeclaration:
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

  final Map<String, List<Builder>> augmentations = <String, List<Builder>>{};

  final Map<String, List<Builder>> setterAugmentations =
      <String, List<Builder>>{};

  // TODO(johnniwinther): Stop using [_name] for determining the declaration
  // kind.
  String _name;

  ExtensionName? _extensionName;

  /// Offset of name token, updated by the outline builder along
  /// with the name as the current declaration changes.
  int _charOffset;

  List<NominalVariableBuilder>? _typeVariables;

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
      this.parent);

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
  void markAsClassDeclaration(String name, int charOffset,
      List<NominalVariableBuilder>? typeVariables) {
    assert(
        _kind == TypeParameterScopeKind.classOrNamedMixinApplication,
        // Coverage-ignore(suite): Not run.
        "Unexpected declaration kind: $_kind");
    _kind = TypeParameterScopeKind.classDeclaration;
    _name = name;
    _charOffset = charOffset;
    _typeVariables = typeVariables;
  }

  /// Registers that this builder is preparing for a named mixin application
  /// with the given [name] and [typeVariables] located [charOffset].
  void markAsNamedMixinApplication(String name, int charOffset,
      List<NominalVariableBuilder>? typeVariables) {
    assert(
        _kind == TypeParameterScopeKind.classOrNamedMixinApplication,
        // Coverage-ignore(suite): Not run.
        "Unexpected declaration kind: $_kind");
    _kind = TypeParameterScopeKind.namedMixinApplication;
    _name = name;
    _charOffset = charOffset;
    _typeVariables = typeVariables;
  }

  /// Registers that this builder is preparing for a mixin declaration with the
  /// given [name] and [typeVariables] located [charOffset].
  void markAsMixinDeclaration(String name, int charOffset,
      List<NominalVariableBuilder>? typeVariables) {
    // TODO(johnniwinther): Avoid using 'classOrNamedMixinApplication' for mixin
    // declaration. These are syntactically distinct so we don't need the
    // transition.
    assert(
        _kind == TypeParameterScopeKind.classOrNamedMixinApplication,
        // Coverage-ignore(suite): Not run.
        "Unexpected declaration kind: $_kind");
    _kind = TypeParameterScopeKind.mixinDeclaration;
    _name = name;
    _charOffset = charOffset;
    _typeVariables = typeVariables;
  }

  /// Registers that this builder is preparing for an extension declaration with
  /// the given [name] and [typeVariables] located [charOffset].
  void markAsExtensionDeclaration(String? name, int charOffset,
      List<NominalVariableBuilder>? typeVariables) {
    assert(
        _kind == TypeParameterScopeKind.extensionOrExtensionTypeDeclaration,
        // Coverage-ignore(suite): Not run.
        "Unexpected declaration kind: $_kind");
    _kind = TypeParameterScopeKind.extensionDeclaration;
    _extensionName = name != null
        ? new FixedExtensionName(name)
        : new UnnamedExtensionName();
    _name = _extensionName!.name;
    _charOffset = charOffset;
    _typeVariables = typeVariables;
  }

  /// Registers that this builder is preparing for an extension type declaration
  /// with the given [name] and [typeVariables] located [charOffset].
  void markAsExtensionTypeDeclaration(String name, int charOffset,
      List<NominalVariableBuilder>? typeVariables) {
    assert(
        _kind == TypeParameterScopeKind.extensionOrExtensionTypeDeclaration,
        // Coverage-ignore(suite): Not run.
        "Unexpected declaration kind: $_kind");
    _kind = TypeParameterScopeKind.extensionTypeDeclaration;
    _name = name;
    _charOffset = charOffset;
    _typeVariables = typeVariables;
  }

  /// Registers that this builder is preparing for an enum declaration with
  /// the given [name] and [typeVariables] located [charOffset].
  void markAsEnumDeclaration(String name, int charOffset,
      List<NominalVariableBuilder>? typeVariables) {
    assert(
        _kind == TypeParameterScopeKind.enumDeclaration,
        // Coverage-ignore(suite): Not run.
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
    assert(
        _kind == TypeParameterScopeKind.extensionDeclaration,
        // Coverage-ignore(suite): Not run.
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

  List<NominalVariableBuilder>? get typeVariables => _typeVariables;

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
    assert(
        kind == TypeParameterScopeKind.extensionDeclaration,
        // Coverage-ignore(suite): Not run.
        "DeclarationBuilder.extensionThisType not supported on $kind.");
    assert(
        _extensionThisType != null,
        // Coverage-ignore(suite): Not run.
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
  void resolveNamedTypes(List<NominalVariableBuilder>? typeVariables,
      ProblemReporting problemReporting) {
    Map<String, NominalVariableBuilder>? map;
    if (typeVariables != null) {
      map = <String, NominalVariableBuilder>{};
      for (NominalVariableBuilder builder in typeVariables) {
        if (builder.isWildcard) continue;
        map[builder.name] = builder;
      }
    }
    Scope? scope;
    for (NamedTypeBuilder namedTypeBuilder in unresolvedNamedTypes) {
      TypeName typeName = namedTypeBuilder.typeName;
      String? qualifier = typeName.qualifier;
      String? name = qualifier ?? typeName.name;
      Builder? declaration;
      if (members != null) {
        declaration = members![name];
      }
      if (declaration == null && map != null) {
        declaration = map[name];
      }
      if (declaration == null) {
        // Since name didn't resolve in this scope, propagate it to the
        // parent declaration.
        parent!.registerUnresolvedNamedType(namedTypeBuilder);
      } else if (qualifier != null) {
        // Attempt to use a member or type variable as a prefix.
        int nameOffset = typeName.fullNameOffset;
        int nameLength = typeName.fullNameLength;
        Message message = templateNotAPrefixInTypeAnnotation.withArguments(
            qualifier, typeName.name);
        problemReporting.addProblem(
            message, nameOffset, nameLength, namedTypeBuilder.fileUri!);
        namedTypeBuilder.bind(
            problemReporting,
            namedTypeBuilder.buildInvalidTypeDeclarationBuilder(
                message.withLocation(
                    namedTypeBuilder.fileUri!, nameOffset, nameLength)));
      } else {
        scope ??= toScope(null).withTypeVariables(typeVariables);
        namedTypeBuilder.resolveIn(scope, namedTypeBuilder.charOffset!,
            namedTypeBuilder.fileUri!, problemReporting);
      }
    }
    unresolvedNamedTypes.clear();
  }

  /// Resolves type variables in [unresolvedNamedTypes] and propagate other
  /// types to [parent].
  void resolveNamedTypesWithStructuralVariables(
      List<StructuralVariableBuilder>? typeVariables,
      SourceLibraryBuilder library) {
    Map<String, StructuralVariableBuilder>? map;
    if (typeVariables != null) {
      map = <String, StructuralVariableBuilder>{};
      for (StructuralVariableBuilder builder in typeVariables) {
        map[builder.name] = builder;
      }
    }
    Scope? scope;
    for (NamedTypeBuilder namedTypeBuilder in unresolvedNamedTypes) {
      TypeName typeName = namedTypeBuilder.typeName;
      String? qualifier = typeName.qualifier;
      String name = qualifier ?? typeName.name;
      Builder? declaration;
      if (members != null) {
        // Coverage-ignore-block(suite): Not run.
        declaration = members![name];
      }
      if (declaration == null && map != null) {
        declaration = map[name];
      }
      if (declaration == null) {
        // Since name didn't resolve in this scope, propagate it to the
        // parent declaration.
        parent!.registerUnresolvedNamedType(namedTypeBuilder);
      } else if (qualifier != null) {
        // Coverage-ignore-block(suite): Not run.
        // Attempt to use a member or type variable as a prefix.
        int nameOffset = typeName.fullNameOffset;
        int nameLength = typeName.fullNameLength;
        Message message = templateNotAPrefixInTypeAnnotation.withArguments(
            qualifier, namedTypeBuilder.typeName.name);
        library.addProblem(
            message, nameOffset, nameLength, namedTypeBuilder.fileUri!);
        namedTypeBuilder.bind(
            library,
            namedTypeBuilder.buildInvalidTypeDeclarationBuilder(
                message.withLocation(
                    namedTypeBuilder.fileUri!, nameOffset, nameLength)));
      } else {
        scope ??= toScope(null).withStructuralVariables(typeVariables);
        namedTypeBuilder.resolveIn(scope, namedTypeBuilder.charOffset!,
            namedTypeBuilder.fileUri!, library);
      }
    }
    unresolvedNamedTypes.clear();
  }

  Scope toScope(Scope? parent,
      {Map<String, Builder>? omittedTypeDeclarationBuilders}) {
    // Coverage-ignore(suite): Not run.
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
        isModifiable: false,
        augmentations: augmentations,
        setterAugmentations: setterAugmentations);
  }

  @override
  String toString() => 'DeclarationBuilder(${hashCode}:kind=$kind,name=$name)';
}

class FieldInfo {
  final Identifier identifier;
  final Token? initializerToken;
  final Token? beforeLast;
  final int charEndOffset;

  const FieldInfo(this.identifier, this.initializerToken, this.beforeLast,
      this.charEndOffset);
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
      declaration.charOffset, declaration.fileUri);
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

class PendingNullability {
  final Uri fileUri;
  final int charOffset;
  final /* TypeParameterType | StructuralParameterType */ DartType type;

  PendingNullability(this.fileUri, this.charOffset, this.type)
      : assert(type is TypeParameterType || type is StructuralParameterType);

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
      : _iterator = libraryBuilder.scope.filteredIterator<T>(
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
      _iterator = augmentationLibraryBuilder.scope.filteredIterator<T>(
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
      : _iterator = libraryBuilder.scope.filteredNameIterator<T>(
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
      _iterator = augmentationLibraryBuilder.scope.filteredNameIterator<T>(
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

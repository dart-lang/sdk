// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show Queue;
import 'dart:convert' show utf8;
import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/parser/forwarding_listener.dart'
    show ForwardingListener;
import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show Parser, lengthForToken;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show
        ErrorToken,
        LanguageVersionToken,
        Scanner,
        ScannerConfiguration,
        ScannerResult,
        Token,
        scan;
import 'package:_fe_analyzer_shared/src/util/libraries_specification.dart'
    show Importability;
import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:front_end/src/kernel/internal_ast.dart'
    show VariableDeclarationImpl;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/reference_from_index.dart'
    show IndexedLibrary, ReferenceFromIndex;
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';
import 'package:kernel/util/graph.dart';
import 'package:package_config/package_config.dart' as package_config;

import '../api_prototype/experimental_flags.dart';
import '../api_prototype/file_system.dart';
import '../base/common.dart';
import '../base/export.dart' show Export;
import '../base/extension_scope.dart';
import '../base/import_chains.dart';
import '../base/loader.dart' show Loader, untranslatableUriScheme;
import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/problems.dart' show internalProblem;
import '../base/scope.dart';
import '../base/ticker.dart' show Ticker;
import '../base/uri_offset.dart';
import '../base/uris.dart';
import '../builder/builder.dart';
import '../builder/compilation_unit.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/type_builder.dart';
import '../codes/denylisted_classes.dart'
    show denylistedCoreClasses, denylistedTypedDataClasses;
import '../dill/dill_library_builder.dart';
import '../kernel/benchmarker.dart' show BenchmarkSubdivides;
import '../kernel/body_builder_context.dart';
import '../kernel/exhaustiveness.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/delayed.dart';
import '../kernel/hierarchy/hierarchy_builder.dart';
import '../kernel/hierarchy/hierarchy_node.dart';
import '../kernel/hierarchy/members_builder.dart';
import '../kernel/kernel_helper.dart'
    show DelayedDefaultValueCloner, TypeDependency;
import '../kernel/kernel_target.dart' show KernelTarget;
import '../kernel/resolver.dart';
import '../kernel/type_builder_computer.dart' show TypeBuilderComputer;
import '../type_inference/inference_visitor.dart'
    show ExpressionEvaluationHelper;
import '../type_inference/type_inference_engine.dart';
import '../util/reference_map.dart';
import 'diet_listener.dart' show DietListener;
import 'diet_parser.dart' show DietParser;
import 'offset_map.dart';
import 'outline_builder.dart' show OutlineBuilder;
import 'source_class_builder.dart' show SourceClassBuilder;
import 'source_compilation_unit.dart' show SourceCompilationUnitImpl;
import 'source_enum_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_factory_builder.dart';
import 'source_library_builder.dart'
    show
        ImplicitLanguageVersion,
        InvalidLanguageVersion,
        LanguageVersion,
        LibraryAccess,
        SourceLibraryBuilder;
import 'stack_listener_impl.dart' show offsetForToken;
import 'type_parameter_factory.dart';

class SourceLoader extends Loader implements ProblemReportingHelper {
  /// The [FileSystem] which should be used to access files.
  final FileSystem fileSystem;

  /// Whether comments should be scanned and parsed.
  final bool includeComments;

  final Map<Uri, Uint8List> sourceBytes = <Uri, Uint8List>{};

  ClassHierarchyBuilder? _hierarchyBuilder;

  ClassMembersBuilder? _membersBuilder;

  ReferenceFromIndex? referenceFromIndex;

  /// Used when building directly to kernel.
  ClassHierarchy? _hierarchy;
  CoreTypes? _coreTypes;
  TypeEnvironment? _typeEnvironment;

  final ReferenceMap referenceMap = new ReferenceMap();

  /// Used when checking whether a return type of an async function is valid.
  ///
  /// The said return type is valid if it's a subtype of [futureOfBottom].
  DartType? _futureOfBottom;

  DartType get futureOfBottom => _futureOfBottom!;

  /// Used when checking whether a return type of a sync* function is valid.
  ///
  /// The said return type is valid if it's a subtype of [iterableOfBottom].
  DartType? _iterableOfBottom;

  DartType get iterableOfBottom => _iterableOfBottom!;

  /// Used when checking whether a return type of an async* function is valid.
  ///
  /// The said return type is valid if it's a subtype of [streamOfBottom].
  DartType? _streamOfBottom;

  DartType get streamOfBottom => _streamOfBottom!;

  TypeInferenceEngineImpl? _typeInferenceEngine;

  final SourceLoaderDataForTesting? dataForTesting;

  final Map<Uri, CompilationUnit> _compilationUnits = {};

  Map<Uri, LibraryBuilder> _loadedLibraryBuilders = <Uri, LibraryBuilder>{};

  List<SourceLibraryBuilder>? _sourceLibraryBuilders;

  final Queue<SourceCompilationUnit> _unparsedLibraries =
      new Queue<SourceCompilationUnit>();

  final List<Library> libraries = <Library>[];

  final KernelTarget target;

  /// List of all handled compile-time errors seen so far by libraries loaded
  /// by this loader.
  ///
  /// A handled error is an error that has been added to the generated AST
  /// already, for example, as a throw expression.
  final List<LocatedMessage> handledErrors = <LocatedMessage>[];

  /// List of all unhandled compile-time errors seen so far by libraries loaded
  /// by this loader.
  ///
  /// An unhandled error is an error that hasn't been handled, see
  /// [handledErrors].
  final List<LocatedMessage> unhandledErrors = <LocatedMessage>[];

  /// List of all problems seen so far by libraries loaded by this loader that
  /// does not belong directly to a library.
  final List<FormattedMessage> allComponentProblems = <FormattedMessage>[];

  /// The text of the messages that have been reported.
  ///
  /// This is used filter messages so that we don't report the same error twice.
  final Set<String> seenMessages = new Set<String>();

  /// Set to `true` if one of the reported errors had severity `Severity.error`.
  ///
  /// This is used for [hasSeenError].
  bool _hasSeenError = false;

  // Coverage-ignore(suite): Not run.
  /// Clears the [seenMessages] and [hasSeenError] state.
  void resetSeenMessages() {
    seenMessages.clear();
    _hasSeenError = false;
  }

  /// Returns `true` if a compile time error has been reported.
  bool get hasSeenError => _hasSeenError;

  LibraryBuilder? _coreLibrary;
  CompilationUnit? _coreLibraryCompilationUnit;
  CompilationUnit? _typedDataLibraryCompilationUnit;

  LibraryBuilder? get typedDataLibrary =>
      _typedDataLibraryCompilationUnit?.libraryBuilder;

  final Set<Uri> roots = {};

  // TODO(johnniwinther): Replace with a `singleRoot`.
  // See also https://dart-review.googlesource.com/c/sdk/+/273381.
  LibraryBuilder? get rootLibrary {
    for (Uri uri in roots) {
      LibraryBuilder? builder = lookupLoadedLibraryBuilder(uri);
      if (builder != null) return builder;
    }
    return null;
  }

  CompilationUnit? get rootCompilationUnit {
    for (Uri uri in roots) {
      CompilationUnit? builder = _compilationUnits[uri];
      if (builder != null) return builder;
    }
    return null;
  }

  int byteCount = 0;

  UriOffset? currentUriForCrashReporting;

  final List<String> _expectedOutlineFutureProblems = [];
  final List<String> _expectedBodyBuildingFutureProblems = [];

  SourceLoader(this.fileSystem, this.includeComments, this.target)
    : dataForTesting = retainDataForTesting
          ?
            // Coverage-ignore(suite): Not run.
            new SourceLoaderDataForTesting()
          : null;

  void installAllProblemsIntoComponent(
    Component component, {
    required CompilationPhaseForProblemReporting currentPhase,
  }) {
    List<String> expectedFutureProblemsForCurrentPhase = switch (currentPhase) {
      CompilationPhaseForProblemReporting.outline =>
        _expectedOutlineFutureProblems,
      CompilationPhaseForProblemReporting.bodyBuilding =>
        _expectedBodyBuildingFutureProblems,
    };
    assert(
      expectedFutureProblemsForCurrentPhase.isEmpty || hasSeenError,
      "Expected problems to be reported, but there were none.\n"
      "Current compilation phase: ${currentPhase}\n"
      "Expected at these locations:\n"
      "  * ${expectedFutureProblemsForCurrentPhase.join("\n  * ")}",
    );
    if (allComponentProblems.isNotEmpty) {
      component.problemsAsJson ??= <String>[];
    }
    for (int i = 0; i < allComponentProblems.length; i++) {
      FormattedMessage formattedMessage = allComponentProblems[i];
      component.problemsAsJson!.add(formattedMessage.toJsonString());
    }
    allComponentProblems.clear();
  }

  @override
  bool assertProblemReportedElsewhere(
    String location, {
    required CompilationPhaseForProblemReporting expectedPhase,
  }) {
    if (hasSeenError) return true;
    List<String> expectedFutureProblemsForCurrentPhase =
        switch (expectedPhase) {
          CompilationPhaseForProblemReporting.outline =>
            _expectedOutlineFutureProblems,
          CompilationPhaseForProblemReporting.bodyBuilding =>
            _expectedBodyBuildingFutureProblems,
        };
    expectedFutureProblemsForCurrentPhase.add(
      "${location}\n${StackTrace.current}\n",
    );
    return true;
  }

  bool containsLoadedLibraryBuilder(Uri importUri) =>
      lookupLoadedLibraryBuilder(importUri) != null;

  LibraryBuilder? lookupLoadedLibraryBuilder(Uri importUri) {
    return _loadedLibraryBuilders[importUri];
  }

  CompilationUnit? lookupCompilationUnit(Uri importUri) =>
      _compilationUnits[importUri];

  CompilationUnit? lookupCompilationUnitByFileUri(Uri fileUri) {
    // TODO(johnniwinther): Store compilation units in a map by file URI?
    for (CompilationUnit compilationUnit in _compilationUnits.values) {
      if (compilationUnit.fileUri == fileUri) {
        return compilationUnit;
      }
    }
    return null;
  }

  Iterable<CompilationUnit> get compilationUnits => _compilationUnits.values;

  Iterable<LibraryBuilder> get loadedLibraryBuilders {
    return _loadedLibraryBuilders.values;
  }

  /// The [SourceLibraryBuilder]s for the libraries built from source by this
  /// source loader.
  ///
  /// This is available after [resolveParts] have been called and doesn't
  /// include parts or augmentations. Orphaned parts _are_ included.
  List<SourceLibraryBuilder> get sourceLibraryBuilders {
    assert(
      _sourceLibraryBuilders != null,
      "Source library builder hasn't been computed yet. "
      "The source libraries are in SourceLoader.resolveParts.",
    );
    return _sourceLibraryBuilders!;
  }

  void clearSourceLibraryBuilders() {
    assert(
      _sourceLibraryBuilders != null,
      "Source library builder hasn't been computed yet. "
      "The source libraries are in SourceLoader.resolveParts.",
    );
    _sourceLibraryBuilders!.clear();
  }

  // Coverage-ignore(suite): Not run.
  Iterable<Uri> get loadedLibraryImportUris => _loadedLibraryBuilders.keys;

  void registerLoadedDillLibraryBuilder(DillLibraryBuilder libraryBuilder) {
    assert(!libraryBuilder.isPart, "Unexpected part $libraryBuilder.");
    Uri uri = libraryBuilder.importUri;
    _markDartLibraries(uri, libraryBuilder.mainCompilationUnit);
    _compilationUnits[uri] = libraryBuilder.mainCompilationUnit;
    _loadedLibraryBuilders[uri] = libraryBuilder;
  }

  LibraryBuilder? deregisterLoadedLibraryBuilder(Uri importUri) {
    LibraryBuilder? libraryBuilder = _loadedLibraryBuilders.remove(importUri);
    if (libraryBuilder != null) {
      _compilationUnits.remove(importUri);
    }
    return libraryBuilder;
  }

  // Coverage-ignore(suite): Not run.
  void clearLibraryBuilders() {
    _compilationUnits.clear();
    _loadedLibraryBuilders.clear();
  }

  /// Run [f] with [uri] and [fileOffset] as the current uri/offset used for
  /// reporting crashes.
  T withUriForCrashReporting<T>(Uri uri, int fileOffset, T Function() f) {
    UriOffset? oldUriForCrashReporting = currentUriForCrashReporting;
    currentUriForCrashReporting = new UriOffset(uri, fileOffset);
    T result = f();
    currentUriForCrashReporting = oldUriForCrashReporting;
    return result;
  }

  @override
  LibraryBuilder get coreLibrary =>
      _coreLibrary ??= _coreLibraryCompilationUnit!.libraryBuilder;

  @override
  CompilationUnit get coreLibraryCompilationUnit =>
      _coreLibraryCompilationUnit!;

  Ticker get ticker => target.ticker;

  /// Creates a [SourceLibraryBuilder] corresponding to [importUri], if one
  /// doesn't exist already.
  ///
  /// [fileUri] must not be null and is a URI that can be passed to FileSystem
  /// to locate the corresponding file.
  ///
  /// [origin] is non-null if the created library is an augmentation of
  /// [origin].
  ///
  /// [packageUri] is the base uri for the package which the library belongs to.
  /// For instance 'package:foo'.
  ///
  /// This is used to associate libraries in for instance the 'bin' and 'test'
  /// folders of a package source with the package uri of the 'lib' folder.
  ///
  /// If the [packageUri] is `null` the package association of this library is
  /// based on its [importUri].
  ///
  /// For libraries with a 'package:' [importUri], the package path must match
  /// the path in the [importUri]. For libraries with a 'dart:' [importUri] the
  /// [packageUri] must be `null`.
  ///
  /// [packageLanguageVersion] is the language version defined by the package
  /// which the library belongs to, or the current sdk version if the library
  /// doesn't belong to a package.

  SourceCompilationUnit createSourceCompilationUnit({
    required Uri importUri,
    required Uri fileUri,
    Uri? packageUri,
    required Uri originImportUri,
    required LanguageVersion packageLanguageVersion,
    SourceCompilationUnit? origin,
    IndexedLibrary? referencesFromIndex,
    bool? referenceIsPartOwner,
    bool isAugmentation = false,
    bool isPatch = false,
    required bool mayImplementRestrictedTypes,
  }) {
    final bool isDartLib = importUri.isScheme('dart');
    return new SourceCompilationUnitImpl(
      importUri: importUri,
      fileUri: fileUri,
      packageUri: packageUri,
      originImportUri: originImportUri,
      packageLanguageVersion: packageLanguageVersion,
      loader: this,
      augmentationRoot: origin,
      resolveInLibrary: null,
      indexedLibrary: referencesFromIndex,
      referenceIsPartOwner: referenceIsPartOwner,
      conditionalImportSupported:
          origin?.conditionalImportSupported ??
          isDartLib && target.uriTranslator.isLibrarySupported(importUri.path),
      importability:
          origin?.importability ??
          (isDartLib
              ? target.uriTranslator.isLibraryImportable(importUri.path)
              : Importability.always),
      isAugmenting: origin != null,
      forAugmentationLibrary: isAugmentation,
      forPatchLibrary: isPatch,
      mayImplementRestrictedTypes: mayImplementRestrictedTypes,
    );
  }

  /// Return `"true"` if the [dottedName] is a 'dart.library.*' qualifier for a
  /// supported dart:* library, and `null` otherwise.
  ///
  /// This is used to determine conditional imports and `bool.fromEnvironment`
  /// constant values for "dart.library.[libraryName]" values.
  ///
  /// The `null` value will not be equal to the tested string value of
  /// a configurable URI, which is always non-`null`. This prevents
  /// the configurable URI from matching an absent entry,
  /// even for an `if (dart.library.nonLibrary == "")` test.
  String? getLibrarySupportValue(String dottedName) {
    if (!DartLibrarySupport.isDartLibraryQualifier(dottedName)) {
      return "";
    }
    String libraryName = DartLibrarySupport.getDartLibraryName(dottedName);
    Uri uri = new Uri(scheme: "dart", path: libraryName);
    // TODO(johnniwinther): This should really be libraries only.
    CompilationUnit? compilationUnit = lookupCompilationUnit(uri);
    // TODO(johnniwinther): Why is the dill target sometimes not loaded at this
    // point? And does it matter?
    compilationUnit ??= target.dillTarget.loader
        .lookupLibraryBuilder(uri)
        // Coverage-ignore(suite): Not run.
        ?.mainCompilationUnit;
    return DartLibrarySupport.isDartLibrarySupported(
          libraryName,
          libraryExists: compilationUnit != null,
          isSynthetic: compilationUnit?.isSynthetic ?? true,
          conditionalImportSupported:
              compilationUnit?.conditionalImportSupported ?? false,
          dartLibrarySupport: target.backendTarget.dartLibrarySupport,
        )
        ? "true"
        : null;
  }

  SourceCompilationUnit _createSourceCompilationUnit({
    required Uri uri,
    required Uri? fileUri,
    required Uri? originImportUri,
    required SourceCompilationUnit? origin,
    required IndexedLibrary? referencesFromIndex,
    required bool? referenceIsPartOwner,
    required bool isAugmentation,
    required bool isPatch,
    required bool addAsRoot,
  }) {
    if (fileUri != null &&
        (fileUri.isScheme("dart") ||
            fileUri.isScheme("package") ||
            fileUri.isScheme("dart-ext"))) {
      fileUri = null;
    }
    package_config.Package? packageForLanguageVersion;
    if (fileUri == null) {
      switch (uri.scheme) {
        case "package":
        case "dart":
          fileUri =
              target.translateUri(uri) ??
              new Uri(
                scheme: untranslatableUriScheme,
                path: Uri.encodeComponent("$uri"),
              );
          if (uri.isScheme("package")) {
            packageForLanguageVersion = target.uriTranslator.getPackage(uri);
          } else {
            packageForLanguageVersion = target.uriTranslator.packages.packageOf(
              fileUri,
            );
          }
          break;

        default:
          fileUri = uri;
          packageForLanguageVersion = target.uriTranslator.packages.packageOf(
            fileUri,
          );
          break;
      }
    } else {
      packageForLanguageVersion = target.uriTranslator.packages.packageOf(
        fileUri,
      );
    }
    LanguageVersion? packageLanguageVersion;
    Uri? packageUri;
    Message? packageLanguageVersionProblem;
    if (packageForLanguageVersion != null) {
      Uri importUri = origin?.importUri ?? uri;
      if (!importUri.isScheme('dart') && !importUri.isScheme('package')) {
        packageUri = new Uri(
          scheme: 'package',
          path: packageForLanguageVersion.name,
        );
      }
      if (packageForLanguageVersion.languageVersion != null) {
        if (packageForLanguageVersion.languageVersion
            is package_config.InvalidLanguageVersion) {
          packageLanguageVersionProblem =
              diag.languageVersionInvalidInDotPackages;
          packageLanguageVersion = new InvalidLanguageVersion(
            fileUri,
            0,
            noLength,
            target.currentSdkVersion,
            false,
          );
        } else {
          Version version = new Version(
            packageForLanguageVersion.languageVersion!.major,
            packageForLanguageVersion.languageVersion!.minor,
          );
          if (version > target.currentSdkVersion) {
            packageLanguageVersionProblem = diag.languageVersionTooHighPackage
                .withArguments(
                  specifiedMajor: version.major,
                  specifiedMinor: version.minor,
                  packageName: packageForLanguageVersion.name,
                  highestSupportedMajor: target.currentSdkVersion.major,
                  highestSupportedMinor: target.currentSdkVersion.minor,
                );
            packageLanguageVersion = new InvalidLanguageVersion(
              fileUri,
              0,
              noLength,
              target.currentSdkVersion,
              false,
            );
          } else if (version < target.leastSupportedVersion) {
            packageLanguageVersionProblem = diag.languageVersionTooLowPackage
                .withArguments(
                  specifiedMajor: version.major,
                  specifiedMinor: version.minor,
                  packageName: packageForLanguageVersion.name,
                  lowestSupportedMajor: target.leastSupportedVersion.major,
                  lowestSupportedMinor: target.leastSupportedVersion.minor,
                );
            packageLanguageVersion = new InvalidLanguageVersion(
              fileUri,
              0,
              noLength,
              target.leastSupportedVersion,
              false,
            );
          } else {
            packageLanguageVersion = new ImplicitLanguageVersion(version);
          }
        }
      }
    }
    packageLanguageVersion ??= new ImplicitLanguageVersion(
      target.currentSdkVersion,
    );

    originImportUri ??= uri;
    SourceCompilationUnit compilationUnit = createSourceCompilationUnit(
      importUri: uri,
      fileUri: fileUri,
      packageUri: packageUri,
      originImportUri: originImportUri,
      packageLanguageVersion: packageLanguageVersion,
      origin: origin,
      referencesFromIndex: referencesFromIndex,
      referenceIsPartOwner: referenceIsPartOwner,
      isAugmentation: isAugmentation,
      isPatch: isPatch,
      mayImplementRestrictedTypes: target.backendTarget.mayDefineRestrictedType(
        originImportUri,
      ),
    );
    if (packageLanguageVersionProblem != null) {
      compilationUnit.addPostponedProblem(
        packageLanguageVersionProblem,
        0,
        noLength,
        compilationUnit.fileUri,
      );
    }

    if (addAsRoot) {
      roots.add(uri);
    }

    _checkForDartCore(uri, compilationUnit);

    if (uri.isScheme("dart") && originImportUri.isScheme("dart")) {
      // We only read the patch files if the [compilationUnit] is loaded as a
      // dart: library (through [uri]) and is considered a dart: library
      // (through [originImportUri]).
      //
      // This is to avoid reading patches and when reading dart: parts, and to
      // avoid reading patches of non-dart: libraries that claim to be a part of
      // a dart: library.
      target.readPatchFiles(compilationUnit, originImportUri);
    }
    _unparsedLibraries.addLast(compilationUnit);

    return compilationUnit;
  }

  DillLibraryBuilder? _lookupDillLibraryBuilder(Uri uri) {
    DillLibraryBuilder? libraryBuilder = target.dillTarget.loader
        .lookupLibraryBuilder(uri);
    if (libraryBuilder != null) {
      _checkForDartCore(uri, libraryBuilder.mainCompilationUnit);
    }
    return libraryBuilder;
  }

  void _markDartLibraries(Uri uri, CompilationUnit compilationUnit) {
    if (uri.isScheme("dart")) {
      if (uri.path == "core") {
        _coreLibraryCompilationUnit = compilationUnit;
      } else if (uri.path == "typed_data") {
        _typedDataLibraryCompilationUnit = compilationUnit;
      }
    }
  }

  void _checkForDartCore(Uri uri, CompilationUnit compilationUnit) {
    _markDartLibraries(uri, compilationUnit);

    // TODO(johnniwinther): If we save the created library in [_builders]
    // here, i.e. before calling `target.loadExtraRequiredLibraries` below,
    // the order of the libraries change, making `dart:core` come before the
    // required arguments. Currently [DillLoader.appendLibrary] one works
    // when this is not the case.
    if (_coreLibraryCompilationUnit == compilationUnit) {
      target.loadExtraRequiredLibraries(this);
    }
  }

  /// Look up a library builder by the [uri], or if such doesn't exist, create
  /// one. The canonical URI of the library is [uri], and its actual location is
  /// [fileUri].
  ///
  /// Canonical URIs have schemes like "dart", or "package", and the actual
  /// location is often a file URI.
  ///
  /// The [accessor] is the library that's trying to import, export, or include
  /// as part [uri], and [charOffset] is the location of the corresponding
  /// directive. If [accessor] isn't allowed to access [uri], it's a
  /// compile-time error.
  CompilationUnit read(
    Uri uri,
    int charOffset, {
    Uri? fileUri,
    required CompilationUnit accessor,
    Uri? originImportUri,
    SourceCompilationUnit? origin,
    IndexedLibrary? referencesFromIndex,
    bool? referenceIsPartOwner,
    bool isAugmentation = false,
    bool isPatch = false,
  }) {
    CompilationUnit libraryBuilder = _read(
      uri,
      fileUri: fileUri,
      originImportUri: originImportUri,
      origin: origin,
      referencesFromIndex: referencesFromIndex,
      referenceIsPartOwner: referenceIsPartOwner,
      isAugmentation: isAugmentation,
      isPatch: isPatch,
      addAsRoot: false,
    );
    libraryBuilder.recordAccess(
      accessor,
      charOffset,
      noLength,
      accessor.fileUri,
    );
    if (!_hasLibraryAccess(imported: uri, importer: accessor.importUri) &&
        !accessor.isAugmenting) {
      accessor.addProblem(
        diag.platformPrivateLibraryAccess,
        charOffset,
        noLength,
        accessor.fileUri,
      );
    }
    _issueErrorsOnUnsupportedDartColonImports(
      libraryBuilder,
      uri,
      accessor,
      charOffset,
      noLength,
    );
    return libraryBuilder;
  }

  void _issueErrorsOnUnsupportedDartColonImports(
    CompilationUnit libraryBuilder,
    Uri uri,
    CompilationUnit accessor,
    int charOffset,
    int length,
  ) {
    final Uri importUri = libraryBuilder.importUri;
    // Only check for imports of unsupported dart:* libraries.
    if (!importUri.isScheme('dart')) {
      return;
    }
    // Untranslatable dart uris are handled in [tokenize].
    if (libraryBuilder.fileUri.isScheme(untranslatableUriScheme)) {
      return;
    }

    // dart:* libraries (and their patch files) are not restricted from
    // importing other dart:* libraries.
    if (accessor.importUri.isScheme('dart') ||
        (accessor is SourceCompilationUnit &&
            accessor.originImportUri.isScheme('dart'))) {
      return;
    }

    final TargetFlags flags = target.backendTarget.flags;
    final DartLibrarySupport dartLibrarySupport =
        target.backendTarget.dartLibrarySupport;

    Message? diagnostic;
    final Importability importability = libraryBuilder.importability;
    final bool importableWithFlag =
        (importability == Importability.withFlag &&
        // Coverage-ignore(suite): Not run.
        flags.includeUnsupportedPlatformLibraryStubs);
    if (!dartLibrarySupport.computeDartLibrarySupport(
      importUri.path,
      isSupportedBySpec:
          (importability == Importability.always || importableWithFlag),
    )) {
      diagnostic = diag.unavailableDartLibrary.withArguments(uri: importUri);
    }
    // Coverage-ignore(suite): Not run.
    else if (importableWithFlag) {
      // Display a warning for each import of an unsupported library.
      diagnostic = diag.unsupportedPlatformDartLibraryImport.withArguments(
        uri: importUri,
      );
    }

    if (diagnostic == null) {
      return;
    }

    accessor.addProblem(diagnostic, charOffset, length, accessor.fileUri);
  }

  /// Reads the library [uri] as an entry point. This is used for reading the
  /// entry point library of a script or the explicitly mention libraries of
  /// a modular or incremental compilation.
  ///
  /// This differs from [read] in that there is no accessor library, meaning
  /// that access to platform private libraries cannot be granted.
  CompilationUnit readAsEntryPoint(
    Uri uri, {
    Uri? fileUri,
    IndexedLibrary? referencesFromIndex,
  }) {
    CompilationUnit libraryBuilder = _read(
      uri,
      fileUri: fileUri,
      referencesFromIndex: referencesFromIndex,
      addAsRoot: true,
      isAugmentation: false,
      isPatch: false,
    );
    // TODO(johnniwinther): Avoid using the first library, if present, as the
    // accessor of [libraryBuilder]. Currently the incremental compiler doesn't
    // handle errors reported without an accessor, since the messages are not
    // associated with a library. This currently has the side effect that
    // the first library is the accessor of itself.
    CompilationUnit? firstLibrary = rootCompilationUnit;
    if (firstLibrary != null) {
      libraryBuilder.recordAccess(
        firstLibrary,
        -1,
        noLength,
        firstLibrary.fileUri,
      );
    }
    if (!_hasLibraryAccess(imported: uri, importer: firstLibrary?.importUri)) {
      // Coverage-ignore-block(suite): Not run.
      if (firstLibrary != null) {
        firstLibrary.addProblem(
          diag.platformPrivateLibraryAccess,
          -1,
          noLength,
          firstLibrary.importUri,
        );
      } else {
        addProblem(diag.platformPrivateLibraryAccess, -1, noLength, null);
      }
    }
    if (firstLibrary != null) {
      _issueErrorsOnUnsupportedDartColonImports(
        libraryBuilder,
        uri,
        firstLibrary,
        -1,
        noLength,
      );
    }
    return libraryBuilder;
  }

  bool _hasLibraryAccess({required Uri imported, required Uri? importer}) {
    if (imported.isScheme("dart") && imported.path.startsWith("_")) {
      if (importer == null) {
        return false;
      } else {
        return target.backendTarget.allowPlatformPrivateLibraryAccess(
          importer,
          imported,
        );
      }
    }
    return true;
  }

  CompilationUnit _read(
    Uri uri, {
    required Uri? fileUri,
    Uri? originImportUri,
    SourceCompilationUnit? origin,
    required IndexedLibrary? referencesFromIndex,
    bool? referenceIsPartOwner,
    required bool isAugmentation,
    required bool isPatch,
    required bool addAsRoot,
  }) {
    CompilationUnit? compilationUnit = _compilationUnits[uri];
    if (compilationUnit == null) {
      if (target.dillTarget.isLoaded) {
        compilationUnit = _lookupDillLibraryBuilder(uri)?.mainCompilationUnit;
      }
      if (compilationUnit == null) {
        compilationUnit = _createSourceCompilationUnit(
          uri: uri,
          fileUri: fileUri,
          originImportUri: originImportUri,
          origin: origin,
          referencesFromIndex: referencesFromIndex,
          referenceIsPartOwner: referenceIsPartOwner,
          isAugmentation: isAugmentation,
          isPatch: isPatch,
          addAsRoot: addAsRoot,
        );
      }
      _compilationUnits[uri] = compilationUnit;
    }
    return compilationUnit;
  }

  void _ensureCoreLibrary() {
    if (_coreLibraryCompilationUnit == null) {
      readAsEntryPoint(Uri.parse("dart:core"));
      // TODO(askesc): When all backends support set literals, we no longer
      // need to index dart:collection, as it is only needed for desugaring of
      // const sets. We can remove it from this list at that time.
      readAsEntryPoint(Uri.parse("dart:collection"));
      assert(_coreLibraryCompilationUnit != null);
    }
  }

  Future<Null> buildBodies(List<SourceLibraryBuilder> libraryBuilders) async {
    assert(_coreLibraryCompilationUnit != null);
    for (SourceLibraryBuilder library in libraryBuilders) {
      currentUriForCrashReporting = new UriOffset(
        library.importUri,
        TreeNode.noOffset,
      );
      await buildBody(library);
    }
    // Workaround: This will return right away but avoid a "semi leak"
    // where the latest library is saved in a context somewhere.
    await buildBody(null);
    currentUriForCrashReporting = null;
    logSummary(diag.sourceBodySummary);
  }

  void logSummary(Template<SummaryTemplate> template) {
    ticker.log(
      // Coverage-ignore(suite): Not run.
      (Duration elapsed, Duration sinceStart) {
        int libraryCount = 0;
        for (CompilationUnit library in compilationUnits) {
          if (library.loader == this) {
            libraryCount++;
          }
        }
        double ms =
            elapsed.inMicroseconds / Duration.microsecondsPerMillisecond;
        Message message = template.withArguments(
          count: libraryCount,
          bytes: byteCount,
          timeMs: ms,
          rateBytesPerMs: byteCount / ms,
          averageTimeMs: ms / libraryCount,
        );
        print("$sinceStart: ${message.problemMessage}");
      },
    );
  }

  /// Register [message] as a problem with a severity determined by the
  /// intrinsic severity of the message.
  @override
  FormattedMessage? addProblem(
    Message message,
    int charOffset,
    int length,
    Uri? fileUri, {
    bool wasHandled = false,
    List<LocatedMessage>? context,
    CfeSeverity? severity,
    bool problemOnLibrary = false,
    List<Uri>? involvedFiles,
  }) {
    return addMessage(
      message,
      charOffset,
      length,
      fileUri,
      severity,
      wasHandled: wasHandled,
      context: context,
      problemOnLibrary: problemOnLibrary,
      involvedFiles: involvedFiles,
    );
  }

  /// All messages reported by the compiler (errors, warnings, etc.) are routed
  /// through this method.
  ///
  /// Returns a FormattedMessage if the message is new, that is, not previously
  /// reported. This is important as some parser errors may be reported up to
  /// three times by `OutlineBuilder`, `DietListener`, and `BodyBuilder`.
  /// If the message is not new, [null] is reported.
  ///
  /// If [severity] is `Severity.error`, the message is added to
  /// [handledErrors] if [wasHandled] is true or to [unhandledErrors] if
  /// [wasHandled] is false.
  FormattedMessage? addMessage(
    Message message,
    int charOffset,
    int length,
    Uri? fileUri,
    CfeSeverity? severity, {
    bool wasHandled = false,
    List<LocatedMessage>? context,
    bool problemOnLibrary = false,
    List<Uri>? involvedFiles,
  }) {
    assert(
      fileUri != missingUri,
      "Message unexpectedly reported on missing uri.",
    );
    severity ??= message.code.severity;
    if (severity == CfeSeverity.ignored) return null;
    String trace =
        """
message: ${message.problemMessage}
charOffset: $charOffset
fileUri: $fileUri
severity: $severity
""";
    if (!seenMessages.add(trace)) return null;
    if (message.code.severity == CfeSeverity.error) {
      _hasSeenError = true;
    }
    if (message.code.severity == CfeSeverity.context) {
      internalProblem(
        diag.internalProblemContextSeverity.withArguments(
          messageCode: message.code.name,
        ),
        charOffset,
        fileUri,
      );
    }
    target.context.report(
      fileUri != null
          ? message.withLocation(fileUri, charOffset, length)
          :
            // Coverage-ignore(suite): Not run.
            message.withoutLocation(),
      severity,
      context: context,
      involvedFiles: involvedFiles,
    );
    if (severity == CfeSeverity.error) {
      (wasHandled ? handledErrors : unhandledErrors).add(
        fileUri != null
            ? message.withLocation(fileUri, charOffset, length)
            :
              // Coverage-ignore(suite): Not run.
              message.withoutLocation(),
      );
    }
    FormattedMessage formattedMessage = target.createFormattedMessage(
      message,
      charOffset,
      length,
      fileUri,
      context,
      severity,
      involvedFiles: involvedFiles,
    );
    if (!problemOnLibrary) {
      allComponentProblems.add(formattedMessage);
    }
    return formattedMessage;
  }

  MemberBuilder getNativeAnnotation() => target.getNativeAnnotation(this);

  void addNativeAnnotation(Annotatable annotatable, String nativeMethodName) {
    MemberBuilder constructor = getNativeAnnotation();
    Arguments arguments = new Arguments(<Expression>[
      new StringLiteral(nativeMethodName),
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

    annotatable.addAnnotation(annotation);
  }

  CoreTypes get coreTypes {
    assert(_coreTypes != null, "CoreTypes has not been computed.");
    return _coreTypes!;
  }

  ClassHierarchy get hierarchy => _hierarchy!;

  void set hierarchy(ClassHierarchy? value) {
    if (_hierarchy != value) {
      _hierarchy = value;
      _typeEnvironment = null;
    }
  }

  TypeEnvironment get typeEnvironment {
    return _typeEnvironment ??= new TypeEnvironment(coreTypes, hierarchy);
  }

  final InferableTypes inferableTypes = new InferableTypes();

  TypeInferenceEngineImpl get typeInferenceEngine => _typeInferenceEngine!;

  ClassHierarchyBuilder get hierarchyBuilder => _hierarchyBuilder!;

  ClassMembersBuilder get membersBuilder => _membersBuilder!;

  Template<SummaryTemplate> get outlineSummaryTemplate =>
      diag.sourceOutlineSummary;

  /// The [SourceCompilationUnit]s for the `dart:` libraries that are not
  /// available.
  ///
  /// We special-case the errors for accessing these libraries and report
  /// it at the end of [buildOutlines] to ensure that all import paths are
  /// part of the error message.
  Set<SourceCompilationUnit> _unavailableDartLibraries = {};

  Future<Token> tokenize(
    SourceCompilationUnit compilationUnit, {
    bool suppressLexicalErrors = false,
    bool allowLazyStrings = true,
  }) async {
    target.benchmarker
    // Coverage-ignore(suite): Not run.
    ?.beginSubdivide(BenchmarkSubdivides.tokenize);
    Uri fileUri = compilationUnit.fileUri;

    // Lookup the file URI in the cache.
    Uint8List? bytes = sourceBytes[fileUri];

    if (bytes == null) {
      // Error recovery.
      if (fileUri.isScheme(untranslatableUriScheme)) {
        Uri importUri = compilationUnit.importUri;
        if (importUri.isScheme('dart')) {
          // We report this error later in [buildOutlines].
          _unavailableDartLibraries.add(compilationUnit);
        } else {
          compilationUnit.addProblemAtAccessors(
            diag.untranslatableUri.withArguments(uri: importUri),
          );
        }
        bytes = synthesizeSourceForMissingFile(importUri, null);
      } else if (!fileUri.hasScheme) {
        // Coverage-ignore-block(suite): Not run.
        target.benchmarker?.endSubdivide();
        return internalProblem(
          diag.internalProblemUriMissingScheme.withArguments(uri: fileUri),
          -1,
          compilationUnit.importUri,
        );
      } else if (fileUri.isScheme(MALFORMED_URI_SCHEME)) {
        compilationUnit.addProblemAtAccessors(diag.expectedUri);
        bytes = synthesizeSourceForMissingFile(compilationUnit.importUri, null);
      }
      if (bytes != null) {
        sourceBytes[fileUri] = bytes;
      }
    }

    if (bytes == null) {
      // If it isn't found in the cache, read the file read from the file
      // system.
      Uint8List rawBytes;
      try {
        rawBytes = await fileSystem.entityForUri(fileUri).readAsBytes();
      } on FileSystemException catch (e) {
        Message message = diag.cantReadFile.withArguments(
          uri: fileUri,
          details: target.context.options.osErrorMessage(e.message),
        );
        compilationUnit.addProblemAtAccessors(message);
        rawBytes = synthesizeSourceForMissingFile(
          compilationUnit.importUri,
          message,
        );
      }
      bytes = rawBytes;
      sourceBytes[fileUri] = bytes;
      byteCount += rawBytes.length;
    }

    ScannerResult result = scan(
      bytes,
      includeComments: includeComments,
      configuration: new ScannerConfiguration(
        enableTripleShift: target.isExperimentEnabledInLibraryByVersion(
          ExperimentalFlag.tripleShift,
          compilationUnit.importUri,
          compilationUnit.packageLanguageVersion.version,
        ),
        forAugmentationLibrary: compilationUnit.forAugmentationLibrary,
      ),
      languageVersionChanged: (Scanner scanner, LanguageVersionToken version) {
        if (!suppressLexicalErrors) {
          compilationUnit.registerExplicitLanguageVersion(
            new Version(version.major, version.minor),
            offset: version.offset,
            length: version.length,
          );
        }
        scanner.configuration = new ScannerConfiguration(
          enableTripleShift:
              compilationUnit.libraryFeatures.tripleShift.isEnabled,
        );
      },
      allowLazyStrings: allowLazyStrings,
    );
    Token token = result.tokens;
    if (!suppressLexicalErrors) {
      /// We use the [importUri] of the created [Library] and not the
      /// [importUri] of the [LibraryBuilder] since it might be an augmentation
      /// library which is not directly part of the output.
      Uri importUri = compilationUnit.importUri;
      if (compilationUnit.isAugmenting) {
        // For patch libraries we create a "fake" import uri.
        // We cannot use the import uri from the augmented library because
        // several different files would then have the same import uri,
        // and the VM does not support that. Also, what would, for instance,
        // setting a breakpoint on line 42 of some import uri mean, if the uri
        // represented several files?
        if (compilationUnit.forPatchLibrary) {
          // TODO(johnniwinther): Use augmentation-like solution for patching.
          List<String> newPathSegments = new List<String>.of(
            compilationUnit.originImportUri.pathSegments,
          );
          newPathSegments.add(compilationUnit.fileUri.pathSegments.last);
          newPathSegments[0] = "${newPathSegments[0]}-patch";
          importUri = compilationUnit.originImportUri.replace(
            pathSegments: newPathSegments,
          );
        }
      }
      target.addSourceInformation(
        importUri,
        compilationUnit.fileUri,
        result.lineStarts,
        bytes,
      );
    }
    compilationUnit.issuePostponedProblems();
    compilationUnit.markLanguageVersionFinal();
    while (token is ErrorToken) {
      if (!suppressLexicalErrors) {
        ErrorToken error = token;
        compilationUnit.addProblem(
          error.assertionMessage,
          offsetForToken(token),
          lengthForToken(token),
          fileUri,
        );
      }
      token = token.next!;
    }
    target.benchmarker
        // Coverage-ignore(suite): Not run.
        ?.endSubdivide();
    return token;
  }

  Uint8List synthesizeSourceForMissingFile(Uri uri, Message? message) {
    return utf8.encode(switch ("$uri") {
      "dart:core" => defaultDartCoreSource,
      "dart:async" => defaultDartAsyncSource,
      "dart:collection" => defaultDartCollectionSource,
      "dart:_compact_hash" => defaultDartCompactHashSource,
      "dart:_internal" => defaultDartInternalSource,
      "dart:typed_data" => defaultDartTypedDataSource,
      _ => message == null ? "" : "/* ${message.problemMessage} */",
    });
  }

  void registerConstructorToBeInferred(InferableMember inferableMember) {
    _typeInferenceEngine!.toBeInferred[inferableMember.member] =
        inferableMember;
  }

  void registerTypeDependency(Member member, TypeDependency typeDependency) {
    _typeInferenceEngine!.typeDependencies[member] = typeDependency;
  }

  // Coverage-ignore(suite): Not run.
  /// Registers the [compilationUnit] as unparsed with the given [source] code.
  ///
  /// This is used for creating synthesized augmentation libraries.
  void registerUnparsedLibrarySource(
    SourceCompilationUnit compilationUnit,
    Uint8List source,
  ) {
    sourceBytes[compilationUnit.fileUri] = source;
    _unparsedLibraries.addLast(compilationUnit);
  }

  /// Runs the [OutlineBuilder] on the source of all [_unparsedLibraries].
  Future<void> buildOutlines() async {
    _ensureCoreLibrary();
    while (_unparsedLibraries.isNotEmpty) {
      SourceCompilationUnit compilationUnit = _unparsedLibraries.removeFirst();
      currentUriForCrashReporting = new UriOffset(
        compilationUnit.importUri,
        TreeNode.noOffset,
      );
      await buildOutline(compilationUnit);
    }
    currentUriForCrashReporting = null;
    logSummary(outlineSummaryTemplate);
    if (_unavailableDartLibraries.isNotEmpty) {
      CompilationUnit? rootLibrary = rootCompilationUnit;
      LoadedLibraries? loadedLibraries;
      for (SourceCompilationUnit compilationUnit in _unavailableDartLibraries) {
        List<LocatedMessage>? context;
        Uri importUri = compilationUnit.importUri;
        Message message = diag.unavailableDartLibrary.withArguments(
          uri: importUri,
        );
        if (rootLibrary != null) {
          loadedLibraries ??= new LoadedLibrariesImpl([
            rootLibrary,
          ], compilationUnits);
          Set<String> importChain = computeImportChainsFor(
            rootLibrary.importUri,
            loadedLibraries,
            importUri,
            verbose: false,
          );
          Set<String> verboseImportChain = computeImportChainsFor(
            rootLibrary.importUri,
            loadedLibraries,
            importUri,
            verbose: true,
          );
          if (importChain.isNotEmpty) {
            if (importChain.containsAll(verboseImportChain)) {
              context = [
                diag.importChainContextSimple
                    .withArguments(
                      uri: compilationUnit.importUri,
                      importChain: importChain
                          .map((part) => '    $part\n')
                          .join(),
                    )
                    .withoutLocation(),
              ];
            } else {
              context = [
                diag.importChainContext
                    .withArguments(
                      uri: compilationUnit.importUri,
                      importChain: importChain
                          .map((part) => '    $part\n')
                          .join(),
                      verboseImportChain: verboseImportChain
                          .map((part) => '    $part\n')
                          .join(),
                    )
                    .withoutLocation(),
              ];
            }
          }
        }
        // We only include the [context] on the first library access.
        if (compilationUnit.accessors.isEmpty) {
          // Coverage-ignore-block(suite): Not run.
          // This is the entry point library, and nobody access it directly. So
          // we need to report a problem.
          addProblem(message, -1, 1, null, context: context);
        } else {
          LibraryAccess access = compilationUnit.accessors.first;
          access.accessor.addProblem(
            message,
            access.charOffset,
            access.length,
            access.fileUri,
            context: context,
          );
        }
      }
      // All subsequent library accesses are reported here without the context
      // message.
      for (SourceCompilationUnit compilationUnit in _unavailableDartLibraries) {
        Uri importUri = compilationUnit.importUri;
        Message message = diag.unavailableDartLibrary.withArguments(
          uri: importUri,
        );

        if (compilationUnit.accessors.length > 1) {
          for (LibraryAccess access in compilationUnit.accessors) {
            access.accessor.addProblem(
              message,
              access.charOffset,
              access.length,
              access.fileUri,
            );
          }
        }
        // Mark the library with an access problem so that it will be marked
        // as synthetic and so that subsequent accesses will be reported.
        compilationUnit.accessProblem ??= message;
      }
      _unavailableDartLibraries.clear();
    }
  }

  Future<Null> buildOutline(SourceCompilationUnit compilationUnit) async {
    Token tokens = await tokenize(compilationUnit);
    compilationUnit.buildOutline(tokens);
  }

  /// Builds all the method bodies found in the given [libraryBuilder].
  Future<Null> buildBody(SourceLibraryBuilder? libraryBuilder) async {
    // [library] is only nullable so we can call this a "dummy-time" to get rid
    // of a semi-leak.
    if (libraryBuilder == null) return;

    // We tokenize source files twice to keep memory usage low. This is the
    // second time, and the first time was in [buildOutline] above. So this
    // time we suppress lexical errors.
    SourceCompilationUnit compilationUnit = libraryBuilder.compilationUnit;
    Token tokens = await tokenize(
      compilationUnit,
      suppressLexicalErrors: true,
      allowLazyStrings: false,
    );

    if (target.benchmarker != null) {
      // When benchmarking we do extra parsing on it's own to get a timing of
      // how much time is spent on the actual parsing (as opposed to the
      // building of what's parsed).
      // NOTE: This runs the parser over the token stream meaning that any
      // parser recovery rewriting the token stream will have happened once
      // the "real" parsing is done. This in turn means that some errors
      // (e.g. missing semi-colon) will not be issued when benchmarking.
      {
        // Coverage-ignore-block(suite): Not run.
        target.benchmarker?.beginSubdivide(
          BenchmarkSubdivides.body_buildBody_benchmark_specific_diet_parser,
        );
        DietParser parser = new DietParser(
          new ForwardingListener(),
          experimentalFeatures: new LibraryExperimentalFeatures(
            libraryBuilder.libraryFeatures,
          ),
        );
        parser.parseUnit(tokens);
        target.benchmarker?.endSubdivide();
      }
      {
        // Coverage-ignore-block(suite): Not run.
        target.benchmarker?.beginSubdivide(
          BenchmarkSubdivides.body_buildBody_benchmark_specific_parser,
        );
        Parser parser = new Parser(
          new ForwardingListener(),
          experimentalFeatures: new LibraryExperimentalFeatures(
            libraryBuilder.libraryFeatures,
          ),
        );
        parser.parseUnit(tokens);
        target.benchmarker?.endSubdivide();
      }
    }

    DietListener listener = createDietListener(
      libraryBuilder: libraryBuilder,
      extensionScope: compilationUnit.extensionScope,
      compilationUnitScope: compilationUnit.compilationUnitScope,
      offsetMap: compilationUnit.offsetMap,
    );
    DietParser parser = new DietParser(
      listener,
      experimentalFeatures: new LibraryExperimentalFeatures(
        libraryBuilder.libraryFeatures,
      ),
    );
    parser.parseUnit(tokens);
    for (SourceCompilationUnit compilationUnit in libraryBuilder.parts) {
      Token tokens = await tokenize(
        compilationUnit,
        suppressLexicalErrors: true,
        allowLazyStrings: false,
      );
      DietListener listener = createDietListener(
        libraryBuilder: libraryBuilder,
        extensionScope: compilationUnit.extensionScope,
        compilationUnitScope: compilationUnit.compilationUnitScope,
        offsetMap: compilationUnit.offsetMap,
      );
      DietParser parser = new DietParser(
        listener,
        experimentalFeatures: new LibraryExperimentalFeatures(
          libraryBuilder.libraryFeatures,
        ),
      );
      parser.parseUnit(tokens);
    }
  }

  // Coverage-ignore(suite): Not run.
  Future<Expression> buildExpression(
    SourceLibraryBuilder libraryBuilder,
    String? enclosingClassOrExtension,
    bool isClassInstanceMember,
    Procedure procedure,
    VariableDeclaration? extensionThis,
    List<VariableDeclarationImpl> extraKnownVariables,
    ExpressionEvaluationHelper expressionEvaluationHelper,
  ) async {
    // TODO(johnniwinther): Support expression compilation in a specific
    //  compilation unit.
    ExtensionScope extensionScope =
        libraryBuilder.compilationUnit.extensionScope;
    LookupScope memberScope =
        libraryBuilder.compilationUnit.compilationUnitScope;

    DeclarationBuilder? declarationBuilder;
    if (enclosingClassOrExtension != null) {
      Builder? builder = memberScope.lookup(enclosingClassOrExtension)?.getable;
      if (builder is TypeDeclarationBuilder) {
        switch (builder) {
          case ClassBuilder():
            declarationBuilder = builder;
            // TODO(johnniwinther): This should be the body scope of the
            //  fragment in which we are compiling the expression.
            memberScope = new NameSpaceLookupScope(
              builder.nameSpace,
              parent: TypeParameterScope.fromList(
                memberScope,
                builder.typeParameters,
              ),
            );
          case ExtensionBuilder():
            declarationBuilder = builder;
            // TODO(johnniwinther): This should be the body scope of the
            //  fragment in which we are compiling the expression.
            memberScope = new NameSpaceLookupScope(
              builder.nameSpace,
              // TODO(johnniwinther): Shouldn't type parameters be in scope?
              parent: memberScope,
            );
          case ExtensionTypeDeclarationBuilder():
          // TODO(johnniwinther): Handle this case.
          case TypeAliasBuilder():
          case NominalParameterBuilder():
          case StructuralParameterBuilder():
          case InvalidBuilder():
          case BuiltinTypeDeclarationBuilder():
        }
      }
    }

    Token token = await tokenize(
      libraryBuilder.compilationUnit,
      suppressLexicalErrors: false,
      allowLazyStrings: false,
    );

    return createResolver().buildSingleExpression(
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: new ExpressionCompilerProcedureBodyBuildContext(
        procedure,
        libraryBuilder,
        declarationBuilder,
        isDeclarationInstanceMember: isClassInstanceMember,
      ),
      fileUri: libraryBuilder.fileUri,
      extensionScope: extensionScope,
      scope: memberScope,
      token: token,
      procedure: procedure,
      extraKnownVariables: extraKnownVariables,
      expressionEvaluationHelper: expressionEvaluationHelper,
      extensionThis: extensionThis,
    );
  }

  DietListener createDietListener({
    required SourceLibraryBuilder libraryBuilder,
    required ExtensionScope extensionScope,
    required LookupScope compilationUnitScope,
    required OffsetMap offsetMap,
  }) {
    return new DietListener(
      libraryBuilder: libraryBuilder,
      extensionScope: extensionScope,
      outermostScope: compilationUnitScope,
      offsetMap: offsetMap,
    );
  }

  Resolver createResolver() {
    return new Resolver(
      classHierarchy: hierarchy,
      coreTypes: coreTypes,
      typeInferenceEngine: typeInferenceEngine,
      benchmarker: target.benchmarker,
    );
  }

  void resolveParts() {
    Map<Uri, SourceCompilationUnit> parts = {};
    List<SourceLibraryBuilder> sourceLibraries = [];
    List<SourceCompilationUnit> augmentationCompilationUnits = [];
    _compilationUnits.forEach((Uri uri, CompilationUnit compilationUnit) {
      switch (compilationUnit) {
        case SourceCompilationUnit():
          if (compilationUnit.isPart) {
            parts[uri] = compilationUnit;
          } else {
            if (compilationUnit.isAugmenting) {
              augmentationCompilationUnits.add(compilationUnit);
            } else {
              SourceLibraryBuilder sourceLibraryBuilder = compilationUnit
                  .createLibrary();
              sourceLibraries.add(sourceLibraryBuilder);
              _loadedLibraryBuilders[uri] = sourceLibraryBuilder;
            }
          }
        case DillCompilationUnit():
          _loadedLibraryBuilders[uri] = compilationUnit.libraryBuilder;
      }
    });

    Set<Uri> usedParts = new Set<Uri>();

    // Include parts in normal libraries.
    for (SourceLibraryBuilder library in sourceLibraries) {
      library.includeParts(usedParts);
    }

    for (MapEntry<Uri, SourceCompilationUnit> entry in parts.entries) {
      Uri uri = entry.key;
      SourceCompilationUnit part = entry.value;
      if (usedParts.contains(uri)) {
        _compilationUnits.remove(uri);
        if (roots.contains(uri)) {
          roots.remove(uri);
          roots.add(part.partOfLibrary!.importUri);
        }
      } else {
        SourceLibraryBuilder sourceLibraryBuilder = part.createLibrary();
        sourceLibraries.add(sourceLibraryBuilder);
        _loadedLibraryBuilders[uri] = sourceLibraryBuilder;
      }
    }
    ticker.logMs("Resolved parts");

    _sourceLibraryBuilders = sourceLibraries;
    assert(
      _compilationUnits.values.every(
        (compilationUnit) =>
            compilationUnit.loader != this ||
            sourceLibraries.contains(compilationUnit.libraryBuilder),
      ),
      "Source library not found in sourceLibraryBuilders:" +
          _compilationUnits.values
              .where(
                (compilationUnit) =>
                    compilationUnit.loader == this &&
                    !sourceLibraries.contains(compilationUnit.libraryBuilder),
              )
              .join(', ') +
          ".",
    );
    ticker.logMs("Applied augmentations");
  }

  void buildNameSpaces(Iterable<SourceLibraryBuilder> sourceLibraryBuilders) {
    for (SourceLibraryBuilder sourceLibraryBuilder in sourceLibraryBuilders) {
      sourceLibraryBuilder.buildNameSpace();
    }
    ticker.logMs("Built name spaces");
  }

  void buildScopes(Iterable<SourceLibraryBuilder> sourceLibraryBuilders) {
    for (SourceLibraryBuilder sourceLibraryBuilder in sourceLibraryBuilders) {
      sourceLibraryBuilder.buildScopes(coreLibrary);
    }
    ticker.logMs("Resolved scopes");
  }

  /// Compute library scopes for [libraryBuilders].
  void computeLibraryScopes(Iterable<LibraryBuilder> libraryBuilders) {
    Set<LibraryBuilder> exporters = new Set<LibraryBuilder>();
    Set<LibraryBuilder> exportees = new Set<LibraryBuilder>();
    for (LibraryBuilder library in libraryBuilders) {
      if (library is SourceLibraryBuilder) {
        library.buildInitialScopes();
      }
      if (library.exporters.isNotEmpty) {
        exportees.add(library);
        for (Export exporter in library.exporters) {
          exporters.add(exporter.exporter.libraryBuilder);
        }
      }
    }
    Set<SourceLibraryBuilder> both = new Set<SourceLibraryBuilder>();
    for (LibraryBuilder exported in exportees) {
      if (exporters.contains(exported)) {
        both.add(exported as SourceLibraryBuilder);
      }
      for (Export export in exported.exporters) {
        Iterator<NamedBuilder> iterator = exported.exportNameSpace
            .filteredIterator();
        while (iterator.moveNext()) {
          NamedBuilder builder = iterator.current;
          export.addToExportScope(builder.name, builder);
        }
      }
    }
    bool wasChanged = false;
    do {
      wasChanged = false;
      for (SourceLibraryBuilder exported in both) {
        for (Export export in exported.exporters) {
          Iterator<NamedBuilder> iterator = exported.exportNameSpace
              .filteredIterator();
          while (iterator.moveNext()) {
            NamedBuilder builder = iterator.current;
            if (export.addToExportScope(builder.name, builder)) {
              wasChanged = true;
            }
          }
        }
      }
    } while (wasChanged);
    for (LibraryBuilder library in libraryBuilders) {
      if (library is SourceLibraryBuilder) {
        library.addImportsToScope();
      }
    }
    for (LibraryBuilder exportee in exportees) {
      // TODO(ahe): Change how we track exporters. Currently, when a library
      // (exporter) exports another library (exportee) we add a reference to
      // exporter to exportee. This creates a reference in the wrong direction
      // and can lead to memory leaks.
      exportee.exporters.clear();
    }
    ticker.logMs("Computed library scopes");
  }

  /// Resolve [NamedTypeBuilder]s in [libraryBuilders].
  void resolveTypes(Iterable<SourceLibraryBuilder> libraryBuilders) {
    int typeCount = 0;
    for (SourceLibraryBuilder library in libraryBuilders) {
      typeCount += library.resolveTypes();
    }
    ticker.logMs("Resolved $typeCount types");
  }

  void finishDeferredLoadTearoffs() {
    int count = 0;
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      count += library.finishDeferredLoadTearOffs();
    }
    ticker.logMs("Finished deferred load tearoffs $count");
  }

  void finishNoSuchMethodForwarders() {
    int count = 0;
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      count += library.finishForwarders();
    }
    ticker.logMs("Finished forwarders for $count procedures");
  }

  void resolveConstructors(List<SourceLibraryBuilder> libraryBuilders) {
    int count = 0;
    for (SourceLibraryBuilder library in libraryBuilders) {
      count += library.resolveConstructors();
    }
    ticker.logMs("Resolved $count constructors");
  }

  List<DelayedDefaultValueCloner>? installTypedefTearOffs() {
    List<DelayedDefaultValueCloner>? delayedDefaultValueCloners;
    if (target.backendTarget.isTypedefTearOffLoweringEnabled) {
      for (SourceLibraryBuilder library in sourceLibraryBuilders) {
        List<DelayedDefaultValueCloner>? libraryDelayedDefaultValueCloners =
            library.installTypedefTearOffs();
        if (libraryDelayedDefaultValueCloners != null) {
          (delayedDefaultValueCloners ??= []).addAll(
            libraryDelayedDefaultValueCloners,
          );
        }
      }
    }
    return delayedDefaultValueCloners;
  }

  void finishTypeParameters(
    Iterable<SourceLibraryBuilder> libraryBuilders,
    ClassBuilder object,
    TypeBuilder dynamicType,
  ) {
    Map<TypeParameterBuilder, SourceLibraryBuilder>
    unboundTypeParameterBuilders = {};
    for (SourceLibraryBuilder library in libraryBuilders) {
      library.collectUnboundTypeParameters(unboundTypeParameterBuilders);
    }

    // Ensure that type parameters are built after their dependencies by sorting
    // them topologically using references in bounds.
    List<TypeParameterBuilder> sortedTypeParameters =
        sortAllTypeParametersTopologically(unboundTypeParameterBuilders.keys);

    for (TypeParameterBuilder builder in sortedTypeParameters) {
      checkTypeParameterDependencies(unboundTypeParameterBuilders[builder]!, [
        builder,
      ]);
    }

    for (TypeParameterBuilder builder in sortedTypeParameters) {
      builder.finish(
        unboundTypeParameterBuilders[builder]!,
        object,
        dynamicType,
      );
    }

    ticker.logMs(
      "Resolved ${sortedTypeParameters.length} type-variable bounds",
    );
  }

  /// Computes variances of type parameters on typedefs in [libraryBuilders].
  void computeVariances(Iterable<SourceLibraryBuilder> libraryBuilders) {
    int count = 0;
    for (SourceLibraryBuilder library in libraryBuilders) {
      count += library.computeVariances();
    }
    ticker.logMs("Computed variances of $count type parameters");
  }

  void computeDefaultTypes(
    Iterable<SourceLibraryBuilder> libraryBuilders,
    TypeBuilder dynamicType,
    TypeBuilder nullType,
    TypeBuilder bottomType,
    ClassBuilder objectClass,
  ) {
    int count = 0;
    for (SourceLibraryBuilder library in libraryBuilders) {
      count += library.computeDefaultTypes(
        dynamicType,
        nullType,
        bottomType,
        objectClass,
      );
    }
    ticker.logMs("Computed default types for $count type parameters");
  }

  void finishNativeMethods() {
    int count = 0;
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      count += library.finishNativeMethods(this);
    }
    ticker.logMs("Finished $count native methods");
  }

  void buildBodyNodes() {
    int count = 0;
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      count += library.buildBodyNodes();
    }
    ticker.logMs("Finished $count augmentation methods");
  }

  /// Check that [objectClass] has no supertypes. Recover by removing any
  /// found.
  void checkObjectClassHierarchy(ClassBuilder objectClass) {
    if (objectClass is SourceClassBuilder) {
      // Coverage-ignore-block(suite): Not run.
      objectClass.checkObjectSupertypes();
    }
  }

  /// Add classes and extension types defined in libraries in this
  /// [SourceLoader] to [sourceClasses] and [sourceExtensionTypes].
  void collectSourceClasses(
    List<SourceClassBuilder> sourceClasses,
    List<SourceExtensionTypeDeclarationBuilder> sourceExtensionTypes,
  ) {
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      library.collectSourceClassesAndExtensionTypes(
        sourceClasses,
        sourceExtensionTypes,
      );
    }
  }

  /// Returns lists of all class builders and of all extension type builders
  /// declared in this loader. The classes and extension type are sorted
  /// topologically, any cycles in the hierarchy are reported as errors, cycles
  /// are broken. This means that the rest of the pipeline (including backends)
  /// can assume that there are no hierarchy cycles.
  (List<SourceClassBuilder>, List<SourceExtensionTypeDeclarationBuilder>)
  handleHierarchyCycles(ClassBuilder objectClass) {
    Set<ClassBuilder> denyListedClasses = new Set<ClassBuilder>();
    for (int i = 0; i < denylistedCoreClasses.length; i++) {
      denyListedClasses.add(
        coreLibrary.lookupRequiredLocalMember(denylistedCoreClasses[i])
            as ClassBuilder,
      );
    }
    ClassBuilder enumClass =
        coreLibrary.lookupRequiredLocalMember("Enum") as ClassBuilder;
    if (typedDataLibrary != null) {
      for (int i = 0; i < denylistedTypedDataClasses.length; i++) {
        // Allow the member to not exist. If it doesn't, nobody can extend it.
        Builder? member = typedDataLibrary!
            .lookupLocalMember(denylistedTypedDataClasses[i])
            ?.getable;
        if (member != null) denyListedClasses.add(member as ClassBuilder);
      }
    }

    // Sort the classes topologically.
    List<SourceClassBuilder> sourceClasses = [];
    List<SourceExtensionTypeDeclarationBuilder> sourceExtensionTypes = [];
    collectSourceClasses(sourceClasses, sourceExtensionTypes);

    _SourceClassGraph classGraph = new _SourceClassGraph(
      sourceClasses,
      objectClass,
    );
    TopologicalSortResult<SourceClassBuilder> classResult = topologicalSort(
      classGraph,
    );
    List<SourceClassBuilder> classes = classResult.sortedVertices;

    Map<ClassBuilder, ClassBuilder> classToBaseOrFinalSuperClass = {};
    for (SourceClassBuilder cls in classes) {
      checkClassSupertypes(
        cls,
        classGraph.directSupertypeMap[cls]!,
        denyListedClasses,
        enumClass,
      );
      _checkSupertypeClassModifiers(cls, classToBaseOrFinalSuperClass);
    }

    List<SourceClassBuilder> classesWithCycles = classResult.cyclicVertices;
    if (classesWithCycles.isNotEmpty) {
      // Sort the classes to ensure consistent output.
      classesWithCycles.sort();
      for (int i = 0; i < classesWithCycles.length; i++) {
        SourceClassBuilder classBuilder = classesWithCycles[i];
        classBuilder.markAsCyclic(objectClass);
        classes.add(classBuilder);
      }
    }

    _SourceExtensionTypeGraph extensionTypeGraph =
        new _SourceExtensionTypeGraph(sourceExtensionTypes);
    TopologicalSortResult<SourceExtensionTypeDeclarationBuilder>
    extensionTypeResult = topologicalSort(extensionTypeGraph);
    List<SourceExtensionTypeDeclarationBuilder> extensionsTypes =
        extensionTypeResult.sortedVertices;

    List<SourceExtensionTypeDeclarationBuilder> extensionTypesWithCycles =
        extensionTypeResult.cyclicVertices;
    if (extensionTypesWithCycles.isNotEmpty) {
      // Sort the classes to ensure consistent output.
      extensionTypesWithCycles.sort();
      for (int i = 0; i < extensionTypesWithCycles.length; i++) {
        SourceExtensionTypeDeclarationBuilder extensionTypeBuilder =
            extensionTypesWithCycles[i];

        /// Ensure that the cycle is broken by removing implemented interfaces.
        ExtensionTypeDeclaration extensionType =
            extensionTypeBuilder.extensionTypeDeclaration;
        extensionType.implements.clear();
        extensionTypeBuilder.interfaceBuilders = null;
        extensionsTypes.add(extensionTypeBuilder);
        // TODO(johnniwinther): Update the message for when an extension type
        //  depends on a cycle but does not depend on itself.
        extensionTypeBuilder.libraryBuilder.addProblem(
          diag.cyclicClassHierarchy.withArguments(
            typeName: extensionTypeBuilder.fullNameForErrors,
          ),
          extensionTypeBuilder.fileOffset,
          noLength,
          extensionTypeBuilder.fileUri,
        );
      }
    }

    ticker.logMs("Checked class hierarchy");
    return (classes, extensionsTypes);
  }

  void _checkConstructorsForMixin(
    SourceClassBuilder classBuilder,
    ClassBuilder mixinClassBuilder,
  ) {
    Iterator<ConstructorBuilder> iterator = mixinClassBuilder
        .filteredConstructorsIterator(includeDuplicates: false);
    while (iterator.moveNext()) {
      ConstructorBuilder constructorBuilder = iterator.current;
      if (!constructorBuilder.isSynthetic) {
        classBuilder.libraryBuilder.addProblem(
          diag.illegalMixinDueToConstructors.withArguments(
            className: mixinClassBuilder.fullNameForErrors,
          ),
          classBuilder.fileOffset,
          noLength,
          classBuilder.fileUri,
          context: [
            diag.illegalMixinDueToConstructorsCause
                .withArguments(className: mixinClassBuilder.fullNameForErrors)
                .withLocation(
                  constructorBuilder.fileUri!,
                  constructorBuilder.fileOffset,
                  noLength,
                ),
          ],
        );
      }
    }
  }

  bool checkEnumSupertypeIsDenylisted(SourceClassBuilder classBuilder) {
    if (!classBuilder.libraryBuilder.libraryFeatures.enhancedEnums.isEnabled) {
      // Coverage-ignore-block(suite): Not run.
      classBuilder.libraryBuilder.addProblem(
        diag.enumSupertypeOfNonAbstractClass.withArguments(
          className: classBuilder.name,
        ),
        classBuilder.fileOffset,
        noLength,
        classBuilder.fileUri,
      );
      return true;
    }
    return false;
  }

  void checkClassSupertypes(
    SourceClassBuilder classBuilder,
    Map<TypeDeclarationBuilder?, TypeAliasBuilder?> directSupertypeMap,
    Set<ClassBuilder> denyListedClasses,
    ClassBuilder enumClass,
  ) {
    // Check that the direct supertypes aren't deny-listed or enums.
    List<TypeDeclarationBuilder?> directSupertypes = directSupertypeMap.keys
        .toList();
    for (int i = 0; i < directSupertypes.length; i++) {
      TypeDeclarationBuilder? supertype = directSupertypes[i];
      if (supertype is SourceEnumBuilder) {
        classBuilder.libraryBuilder.addProblem(
          diag.extendingEnum.withArguments(enumName: supertype.name),
          classBuilder.fileOffset,
          noLength,
          classBuilder.fileUri,
        );
      } else if (!classBuilder.libraryBuilder.mayImplementRestrictedTypes &&
          (denyListedClasses.contains(supertype) ||
              identical(supertype, enumClass) &&
                  checkEnumSupertypeIsDenylisted(classBuilder))) {
        TypeAliasBuilder? aliasBuilder = directSupertypeMap[supertype];
        if (aliasBuilder != null) {
          classBuilder.libraryBuilder.addProblem(
            diag.extendingRestricted.withArguments(
              restrictedName: supertype!.fullNameForErrors,
            ),
            classBuilder.fileOffset,
            noLength,
            classBuilder.fileUri,
            context: [
              diag.typedefCause.withLocation(
                aliasBuilder.fileUri,
                aliasBuilder.fileOffset,
                noLength,
              ),
            ],
          );
        } else {
          classBuilder.libraryBuilder.addProblem(
            diag.extendingRestricted.withArguments(
              restrictedName: supertype!.fullNameForErrors,
            ),
            classBuilder.fileOffset,
            noLength,
            classBuilder.fileUri,
          );
        }
      }
    }

    // Check that the mixed-in type can be used as a mixin.
    final TypeBuilder? mixedInTypeBuilder = classBuilder.mixedInTypeBuilder;
    if (mixedInTypeBuilder != null) {
      TypeDeclarationBuilder? declaration = mixedInTypeBuilder.declaration;
      TypeDeclarationBuilder? unaliasedDeclaration = mixedInTypeBuilder
          .computeUnaliasedDeclaration(isUsedAsClass: true);

      switch (unaliasedDeclaration) {
        case ClassBuilder():
          if (!classBuilder.libraryBuilder.mayImplementRestrictedTypes &&
              denyListedClasses.contains(unaliasedDeclaration)) {
            classBuilder.libraryBuilder.addProblem(
              diag.extendingRestricted.withArguments(
                restrictedName: mixedInTypeBuilder.fullNameForErrors,
              ),
              classBuilder.fileOffset,
              noLength,
              classBuilder.fileUri,
              context: declaration is TypeAliasBuilder
                  ? [
                      diag.typedefUnaliasedTypeCause.withLocation(
                        unaliasedDeclaration.fileUri,
                        unaliasedDeclaration.fileOffset,
                        noLength,
                      ),
                    ]
                  : null,
            );
          } else {
            // Assume that mixin classes fulfill their contract of having no
            // generative constructors.
            if (!unaliasedDeclaration.isMixinClass) {
              _checkConstructorsForMixin(classBuilder, unaliasedDeclaration);
            }
          }
        case null:
        case BuiltinTypeDeclarationBuilder():
        case TypeAliasBuilder():
        case ExtensionBuilder():
        case ExtensionTypeDeclarationBuilder():
        case NominalParameterBuilder():
        case StructuralParameterBuilder():
          // TODO(ahe): Either we need to check this for superclass and
          // interfaces, or this shouldn't be necessary (or handled elsewhere).
          classBuilder.libraryBuilder.addProblem(
            diag.illegalMixin.withArguments(
              typeName: mixedInTypeBuilder.fullNameForErrors,
            ),
            classBuilder.fileOffset,
            noLength,
            classBuilder.fileUri,
            context: declaration is TypeAliasBuilder
                ? [
                    diag.typedefCause.withLocation(
                      declaration.fileUri,
                      declaration.fileOffset,
                      noLength,
                    ),
                  ]
                : null,
          );
        case InvalidBuilder():
          if (!unaliasedDeclaration.errorHasBeenReported) {
            // Coverage-ignore-block(suite): Not run.
            classBuilder.libraryBuilder.addProblem(
              diag.illegalMixin.withArguments(
                typeName: mixedInTypeBuilder.fullNameForErrors,
              ),
              classBuilder.fileOffset,
              noLength,
              classBuilder.fileUri,
              context: declaration is TypeAliasBuilder
                  ? [
                      diag.typedefCause.withLocation(
                        declaration.fileUri,
                        declaration.fileOffset,
                        noLength,
                      ),
                    ]
                  : null,
            );
          }
      }
    }
  }

  /// Checks that there are no cycles in the class hierarchy, and if so break
  /// these cycles by removing supertypes.
  ///
  /// Returns list of all source classes and extension types in topological
  /// order.
  (List<SourceClassBuilder>, List<SourceExtensionTypeDeclarationBuilder>)
  checkClassCycles(ClassBuilder objectClass) {
    checkObjectClassHierarchy(objectClass);
    return handleHierarchyCycles(objectClass);
  }

  /// Reports errors for 'base', 'interface', 'final', 'mixin' and 'sealed'
  /// class modifiers.
  // TODO(johnniwinther): Merge supertype checking with class hierarchy
  //  computation to better support transitive checking.
  void _checkSupertypeClassModifiers(
    SourceClassBuilder cls,
    Map<ClassBuilder, ClassBuilder> classToBaseOrFinalSuperClass,
  ) {
    bool isClassModifiersEnabled(ClassBuilder typeBuilder) =>
        typeBuilder.libraryBuilder.languageVersion >=
        ExperimentalFlag.classModifiers.experimentEnabledVersion;

    bool isSealedClassEnabled(ClassBuilder typeBuilder) =>
        typeBuilder.libraryBuilder.languageVersion >=
        ExperimentalFlag.sealedClass.experimentEnabledVersion;

    /// Set when we know whether this library can ignore class modifiers.
    ///
    /// The same decision applies to all declarations in the library,
    /// so the value only needs to be computed once.
    bool? isExempt;

    /// Whether the [cls] declaration can ignore (some) class modifiers.
    ///
    /// Checks whether the [cls] can ignore modifiers
    /// from the [supertypeDeclaration].
    /// This is only possible if the supertype declaration comes
    /// from a platform library (`dart:` URI scheme),
    /// and then only if the library is another platform library which is
    /// exempt from restrictions on extending otherwise sealed platform types,
    /// or if the library is a pre-class-modifiers-feature language version
    /// library.
    ///
    /// [checkingBaseOrFinalSubtypeError] indicates that we are checking whether
    /// to emit a base or final subtype error, see
    /// [checkForBaseFinalRestriction]. We ignore these in `dart:` libraries no
    /// matter what, otherwise pre-feature libraries can't use base types with
    /// modifiers at all.
    bool mayIgnoreClassModifiers(
      ClassBuilder supertypeDeclaration, {
      bool checkingBaseOrFinalSubtypeError = false,
    }) {
      // Only use this to ignore `final`, `base`, `interface`, and `mixin`.
      // Nobody can ignore `abstract` or `sealed`.

      // We already know the library cannot ignore modifiers.
      if (isExempt == false) return false;

      // Exception only applies to platform libraries.
      final LibraryBuilder superLibrary = supertypeDeclaration.libraryBuilder;
      if (!superLibrary.importUri.isScheme("dart")) return false;

      // Modifiers in certain libraries like 'dart:ffi' can't be ignored in
      // pre-feature code.
      if (superLibrary.importUri.path == 'ffi' &&
          !checkingBaseOrFinalSubtypeError) {
        return false;
      }

      // Remaining tests depend on the source library only,
      // and the result can be cached.
      if (isExempt == true) return true;

      final LibraryBuilder subLibrary = cls.libraryBuilder;

      // Some platform libraries may implement types like `int`,
      // even if they are final.
      if (subLibrary.mayImplementRestrictedTypes) {
        isExempt = true;
        return true;
      }
      // "Legacy" libraries may ignore `final`, `base` and `interface`
      // from platform libraries. (But still cannot implement `int`.)
      if (subLibrary.languageVersion <
          ExperimentalFlag.classModifiers.experimentEnabledVersion) {
        isExempt = true;
        return true;
      }
      isExempt = false;
      return false;
    }

    // All subtypes of a base or final class or mixin must also be base,
    // final, or sealed. Report an error otherwise.
    void checkForBaseFinalRestriction(
      ClassBuilder superclass, {
      TypeBuilder? implementsBuilder,
    }) {
      if (classToBaseOrFinalSuperClass.containsKey(cls)) {
        // We've already visited this class. Don't check it again.
        return;
      } else if (cls.isEnum) {
        // Don't report any errors on enums. They should all be considered
        // final.
        return;
      }

      final ClassBuilder? cachedBaseOrFinalSuperClass =
          classToBaseOrFinalSuperClass[superclass];
      final bool hasCachedBaseOrFinalSuperClass =
          cachedBaseOrFinalSuperClass != null;
      ClassBuilder baseOrFinalSuperClass;
      if (!superclass.cls.isAnonymousMixin &&
          (superclass.isBase || superclass.isFinal)) {
        // Prefer the direct base or final superclass
        baseOrFinalSuperClass = superclass;
      } else if (hasCachedBaseOrFinalSuperClass) {
        // There's a base or final class higher up in the class hierarchy.
        // The superclass is a sealed element or an anonymous class.
        baseOrFinalSuperClass = cachedBaseOrFinalSuperClass;
      } else {
        return;
      }

      classToBaseOrFinalSuperClass[cls] = baseOrFinalSuperClass;

      if (implementsBuilder != null &&
          superclass.isSealed &&
          baseOrFinalSuperClass.libraryBuilder != cls.libraryBuilder) {
        // This error is reported at the call site.
        // TODO(johnniwinther): Merge supertype checking with class hierarchy
        //  computation to better support transitive checking.
        // It's an error to implement a class if it has a supertype from a
        // different library which is marked base.
        /*if (baseOrFinalSuperClass.isBase) {
          cls.addProblem(
              codeBaseClassImplementedOutsideOfLibrary
                  .withArguments(baseOrFinalSuperClass.fullNameForErrors),
              implementsBuilder.charOffset ?? TreeNode.noOffset,
              noLength,
              context: [
                codeBaseClassImplementedOutsideOfLibraryCause
                    .withArguments(superclass.fullNameForErrors,
                        baseOrFinalSuperClass.fullNameForErrors)
                    .withLocation(baseOrFinalSuperClass.fileUri,
                        baseOrFinalSuperClass.charOffset, noLength)
              ]);
        }*/
      } else if (!cls.isBase &&
          !cls.isFinal &&
          !cls.isSealed &&
          !cls.cls.isAnonymousMixin &&
          !mayIgnoreClassModifiers(
            baseOrFinalSuperClass,
            checkingBaseOrFinalSubtypeError: true,
          )) {
        if (!superclass.isBase &&
            !superclass.isFinal &&
            !superclass.isSealed &&
            !superclass.cls.isAnonymousMixin &&
            superclass.libraryBuilder.languageVersion >=
                ExperimentalFlag.classModifiers.experimentEnabledVersion) {
          // Only report an error on the nearest subtype that does not fulfill
          // the base or final subtype restriction.
          return;
        }

        if (baseOrFinalSuperClass.isFinal) {
          // Don't check base and final subtyping restriction if the supertype
          // is a final type used outside of its library.
          if (cls.libraryBuilder != baseOrFinalSuperClass.libraryBuilder) {
            // In the special case where the 'baseOrFinalSuperClass' is a core
            // library class and we are indirectly subtyping from a superclass
            // that's from a pre-feature library, we want to produce a final
            // transitivity error.
            //
            // For implements clauses with the above scenario, we avoid
            // over-reporting since there will already be a
            // [FinalClassImplementedOutsideOfLibrary] error.
            //
            // TODO(kallentu): Avoid over-reporting for with clauses.
            if (baseOrFinalSuperClass.libraryBuilder ==
                    superclass.libraryBuilder ||
                !baseOrFinalSuperClass.libraryBuilder.importUri.isScheme(
                  "dart",
                ) ||
                implementsBuilder != null) {
              return;
            }
          }
          final Template<
            Message Function({
              required String typeName,
              required String supertypeName,
            })
          >
          template = cls.isMixinDeclaration
              ? diag.mixinSubtypeOfFinalIsNotBase
              : diag.subtypeOfFinalIsNotBaseFinalOrSealed;
          cls.libraryBuilder.addProblem(
            template.withArguments(
              typeName: cls.fullNameForErrors,
              supertypeName: baseOrFinalSuperClass.fullNameForErrors,
            ),
            cls.fileOffset,
            noLength,
            cls.fileUri,
          );
        } else if (baseOrFinalSuperClass.isBase) {
          final Template<
            Message Function({
              required String className,
              required String superclassName,
            })
          >
          template = cls.isMixinDeclaration
              ? diag.mixinSubtypeOfBaseIsNotBase
              : diag.subtypeOfBaseIsNotBaseFinalOrSealed;
          cls.libraryBuilder.addProblem(
            template.withArguments(
              className: cls.fullNameForErrors,
              superclassName: baseOrFinalSuperClass.fullNameForErrors,
            ),
            cls.fileOffset,
            noLength,
            cls.fileUri,
          );
        }
      }
    }

    final TypeBuilder? supertypeBuilder = cls.supertypeBuilder;
    if (supertypeBuilder != null) {
      final TypeDeclarationBuilder? supertypeDeclaration = supertypeBuilder
          .computeUnaliasedDeclaration(isUsedAsClass: true);
      if (supertypeDeclaration is ClassBuilder) {
        checkForBaseFinalRestriction(supertypeDeclaration);

        if (isClassModifiersEnabled(supertypeDeclaration)) {
          if (cls.libraryBuilder != supertypeDeclaration.libraryBuilder &&
              !mayIgnoreClassModifiers(supertypeDeclaration)) {
            if (supertypeDeclaration.isInterface && !cls.isMixinDeclaration) {
              cls.libraryBuilder.addProblem(
                diag.interfaceClassExtendedOutsideOfLibrary.withArguments(
                  interfaceClassName: supertypeDeclaration.fullNameForErrors,
                ),
                supertypeBuilder.charOffset ?? TreeNode.noOffset,
                noLength,
                supertypeBuilder.fileUri ?? // Coverage-ignore(suite): Not run.
                    cls.fileUri,
              );
            } else if (supertypeDeclaration.isFinal) {
              if (cls.isMixinDeclaration) {
                cls.libraryBuilder.addProblem(
                  diag.finalClassUsedAsMixinConstraintOutsideOfLibrary
                      .withArguments(
                        className: supertypeDeclaration.fullNameForErrors,
                      ),
                  supertypeBuilder.charOffset ?? TreeNode.noOffset,
                  noLength,
                  supertypeBuilder
                          .fileUri ?? // Coverage-ignore(suite): Not run.
                      cls.fileUri,
                );
              } else {
                cls.libraryBuilder.addProblem(
                  diag.finalClassExtendedOutsideOfLibrary.withArguments(
                    className: supertypeDeclaration.fullNameForErrors,
                  ),
                  supertypeBuilder.charOffset ?? TreeNode.noOffset,
                  noLength,
                  supertypeBuilder
                          .fileUri ?? // Coverage-ignore(suite): Not run.
                      cls.fileUri,
                );
              }
            }
          }
        }

        // Report error for extending a sealed class outside of its library.
        if (isSealedClassEnabled(supertypeDeclaration) &&
            supertypeDeclaration.isSealed &&
            cls.libraryBuilder != supertypeDeclaration.libraryBuilder) {
          cls.libraryBuilder.addProblem(
            diag.sealedClassSubtypeOutsideOfLibrary.withArguments(
              sealedClassName: supertypeDeclaration.fullNameForErrors,
            ),
            supertypeBuilder.charOffset ?? TreeNode.noOffset,
            noLength,
            supertypeBuilder.fileUri ?? // Coverage-ignore(suite): Not run.
                cls.fileUri,
          );
        }
      }
    }

    final TypeBuilder? mixedInTypeBuilder = cls.mixedInTypeBuilder;
    if (mixedInTypeBuilder != null) {
      final TypeDeclarationBuilder? mixedInTypeDeclaration = mixedInTypeBuilder
          .computeUnaliasedDeclaration(isUsedAsClass: true);
      if (mixedInTypeDeclaration is ClassBuilder) {
        checkForBaseFinalRestriction(mixedInTypeDeclaration);

        if (isClassModifiersEnabled(mixedInTypeDeclaration)) {
          // Check for classes being used as mixins. Only classes declared with
          // a 'mixin' modifier are allowed to be mixed in.
          if (cls.isMixinApplication &&
              !mixedInTypeDeclaration.isMixinDeclaration &&
              !mixedInTypeDeclaration.isMixinClass &&
              !mayIgnoreClassModifiers(mixedInTypeDeclaration)) {
            cls.libraryBuilder.addProblem(
              diag.cantUseClassAsMixin.withArguments(
                className: mixedInTypeDeclaration.fullNameForErrors,
              ),
              mixedInTypeBuilder.charOffset ?? TreeNode.noOffset,
              noLength,
              mixedInTypeBuilder.fileUri ?? // Coverage-ignore(suite): Not run.
                  cls.fileUri,
            );
          }
        }

        // Report error for mixing in a sealed mixin outside of its library.
        if (isSealedClassEnabled(mixedInTypeDeclaration) &&
            mixedInTypeDeclaration.isSealed &&
            cls.libraryBuilder != mixedInTypeDeclaration.libraryBuilder) {
          cls.libraryBuilder.addProblem(
            diag.sealedClassSubtypeOutsideOfLibrary.withArguments(
              sealedClassName: mixedInTypeDeclaration.fullNameForErrors,
            ),
            mixedInTypeBuilder.charOffset ?? TreeNode.noOffset,
            noLength,
            mixedInTypeBuilder.fileUri ?? // Coverage-ignore(suite): Not run.
                cls.fileUri,
          );
        }
      }
    }

    final List<TypeBuilder>? interfaceBuilders = cls.interfaceBuilders;
    if (interfaceBuilders != null) {
      for (TypeBuilder interfaceBuilder in interfaceBuilders) {
        final TypeDeclarationBuilder? interfaceDeclaration = interfaceBuilder
            .computeUnaliasedDeclaration(isUsedAsClass: true);
        if (interfaceDeclaration is ClassBuilder) {
          checkForBaseFinalRestriction(
            interfaceDeclaration,
            implementsBuilder: interfaceBuilder,
          );

          ClassBuilder? checkedClass = interfaceDeclaration;
          while (checkedClass != null) {
            if (cls.libraryBuilder != checkedClass.libraryBuilder &&
                !mayIgnoreClassModifiers(checkedClass)) {
              final List<LocatedMessage> context = [
                if (checkedClass != interfaceDeclaration)
                  diag.baseOrFinalClassImplementedOutsideOfLibraryCause
                      .withArguments(
                        subtypeName: interfaceDeclaration.fullNameForErrors,
                        causeName: checkedClass.fullNameForErrors,
                      )
                      .withLocation(
                        checkedClass.fileUri,
                        checkedClass.fileOffset,
                        noLength,
                      ),
              ];

              if (checkedClass.isBase && !cls.cls.isAnonymousMixin) {
                // Report an error for a class implementing a base class outside
                // of its library.
                final Template<Message Function({required String typeName})>
                template = checkedClass.isMixinDeclaration
                    ? diag.baseMixinImplementedOutsideOfLibrary
                    : diag.baseClassImplementedOutsideOfLibrary;
                cls.libraryBuilder.addProblem(
                  template.withArguments(
                    typeName: checkedClass.fullNameForErrors,
                  ),
                  interfaceBuilder.charOffset ?? TreeNode.noOffset,
                  noLength,
                  interfaceBuilder
                          .fileUri ?? // Coverage-ignore(suite): Not run.
                      cls.fileUri,
                  context: context,
                );
                // Break to only report one error.
                break;
              } else if (checkedClass.isFinal) {
                // Report an error for a class implementing a final class
                // outside of its library.
                final Template<Message Function({required String className})>
                template =
                    cls.cls.isAnonymousMixin &&
                        checkedClass == interfaceDeclaration
                    ? diag.finalClassUsedAsMixinConstraintOutsideOfLibrary
                    : diag.finalClassImplementedOutsideOfLibrary;
                cls.libraryBuilder.addProblem(
                  template.withArguments(
                    className: checkedClass.fullNameForErrors,
                  ),
                  interfaceBuilder.charOffset ?? TreeNode.noOffset,
                  noLength,
                  interfaceBuilder
                          .fileUri ?? // Coverage-ignore(suite): Not run.
                      cls.fileUri,
                  context: context,
                );
                // Break to only report one error.
                break;
              }
            }
            checkedClass = classToBaseOrFinalSuperClass[checkedClass];
          }

          // Report error for implementing a sealed class or a sealed mixin
          // outside of its library.
          if (isSealedClassEnabled(interfaceDeclaration) &&
              interfaceDeclaration.isSealed &&
              cls.libraryBuilder != interfaceDeclaration.libraryBuilder) {
            cls.libraryBuilder.addProblem(
              diag.sealedClassSubtypeOutsideOfLibrary.withArguments(
                sealedClassName: interfaceDeclaration.fullNameForErrors,
              ),
              interfaceBuilder.charOffset ?? TreeNode.noOffset,
              noLength,
              interfaceBuilder.fileUri ?? // Coverage-ignore(suite): Not run.
                  cls.fileUri,
            );
          }
        }
      }
    }
  }

  /// Computes the direct super type for all source classes.
  void computeSupertypes(Iterable<SourceLibraryBuilder> sourceLibraryBuilders) {
    for (SourceLibraryBuilder libraryBuilder in sourceLibraryBuilders) {
      libraryBuilder.computeSupertypes();
    }
  }

  /// Builds the core AST structure needed for the outline of the component.
  void buildOutlineNodes() {
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      Library target = library.buildOutlineNodes(coreLibrary);
      if (library.indexedLibrary != null) {
        referenceFromIndex ??= new ReferenceFromIndex();
        referenceFromIndex!.addIndexedLibrary(target, library.indexedLibrary!);
      }
      libraries.add(target);
    }
    ticker.logMs("Built component");
  }

  Component computeFullComponent() {
    Set<Library> libraries = new Set<Library>();
    List<Library> workList = <Library>[];
    for (LibraryBuilder libraryBuilder in loadedLibraryBuilders) {
      if ((libraryBuilder.loader == this ||
          libraryBuilder.importUri.isScheme("dart") ||
          roots.contains(libraryBuilder.importUri))) {
        if (libraries.add(libraryBuilder.library)) {
          workList.add(libraryBuilder.library);
        }
      }
    }
    while (workList.isNotEmpty) {
      Library library = workList.removeLast();
      for (LibraryDependency dependency in library.dependencies) {
        if (libraries.add(dependency.targetLibrary)) {
          workList.add(dependency.targetLibrary);
        }
      }
    }
    return new Component()..libraries.addAll(libraries);
  }

  void computeHierarchy() {
    if (_hierarchy == null) {
      hierarchy = new ClassHierarchy(
        computeFullComponent(),
        coreTypes,
        onAmbiguousSupertypes: (Class cls, Supertype a, Supertype b) {
          // Ignore errors. These have already been reported by the class
          // hierarchy builder.
        },
      );
    } else {
      Component component = computeFullComponent();
      hierarchy.coreTypes = coreTypes;
      hierarchy.applyTreeChanges(
        const [],
        component.libraries,
        const [],
        reissueAmbiguousSupertypesFor: component,
      );
    }
    ticker.logMs("Computed class hierarchy");
  }

  /// Creates an [InterfaceType] for the `dart:core` type by the given [name].
  ///
  /// This method can be called before [coreTypes] has been computed and only
  /// required [coreLibrary] to have been set.
  InterfaceType createCoreType(
    String name,
    Nullability nullability, [
    List<DartType>? typeArguments,
  ]) {
    assert(
      _coreLibraryCompilationUnit != null,
      "Core library has not been computed yet.",
    );
    ClassBuilder classBuilder =
        coreLibrary.lookupRequiredLocalMember(name) as ClassBuilder;
    return new InterfaceType(classBuilder.cls, nullability, typeArguments);
  }

  void computeCoreTypes(Component component) {
    assert(_coreTypes == null, "CoreTypes has already been computed");
    _coreTypes = new CoreTypes(component);

    // These types are used on the left-hand side of the is-subtype-of relation
    // to check if the return types of functions with async, sync*, and async*
    // bodies are correct.  It's valid to use the non-nullable types on the
    // left-hand side in both opt-in and opt-out code.
    _futureOfBottom = new InterfaceType(
      coreTypes.futureClass,
      Nullability.nonNullable,
      <DartType>[const NeverType.nonNullable()],
    );
    _iterableOfBottom = new InterfaceType(
      coreTypes.iterableClass,
      Nullability.nonNullable,
      <DartType>[const NeverType.nonNullable()],
    );
    _streamOfBottom = new InterfaceType(
      coreTypes.streamClass,
      Nullability.nonNullable,
      <DartType>[const NeverType.nonNullable()],
    );

    ticker.logMs("Computed core types");
  }

  void checkSupertypes(
    List<SourceClassBuilder> sourceClasses,
    List<SourceExtensionTypeDeclarationBuilder> sourceExtensionTypeDeclarations,
    Class objectClass,
    Class enumClass,
    Class underscoreEnumClass,
  ) {
    for (SourceClassBuilder builder in sourceClasses) {
      assert(builder.libraryBuilder.loader == this);
      builder.checkSupertypes(
        coreTypes,
        hierarchyBuilder,
        objectClass,
        enumClass,
        underscoreEnumClass,
      );
    }
    for (SourceExtensionTypeDeclarationBuilder builder
        in sourceExtensionTypeDeclarations) {
      assert(builder.libraryBuilder.loader == this);
      builder.checkSupertypes(coreTypes, hierarchyBuilder);
    }
    ticker.logMs("Checked supertypes");
  }

  void checkTypes() {
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      library.checkTypesInOutline(typeInferenceEngine.typeSchemaEnvironment);
    }
    ticker.logMs("Checked type arguments of supers against the bounds");
  }

  void checkOverrides(List<SourceClassBuilder> sourceClasses) {
    List<DelayedCheck> overrideChecks = membersBuilder.takeDelayedChecks();
    for (int i = 0; i < overrideChecks.length; i++) {
      overrideChecks[i].check(membersBuilder);
    }
    ticker.logMs("Checked ${overrideChecks.length} overrides");

    List<Name> restrictedMemberNames = <Name>[
      new Name("index"),
      new Name("hashCode"),
      new Name("=="),
      new Name("values"),
    ];
    List<Class?> restrictedMemberDeclarers = <Class?>[
      (target.underscoreEnumType.declaration as ClassBuilder).cls,
      coreTypes.objectClass,
      coreTypes.objectClass,
      null,
    ];
    for (SourceClassBuilder classBuilder in sourceClasses) {
      if (classBuilder.isEnum) {
        for (int i = 0; i < restrictedMemberNames.length; ++i) {
          Name name = restrictedMemberNames[i];
          Class? declarer = restrictedMemberDeclarers[i];

          ClassMember? classMember = membersBuilder.getDispatchClassMember(
            classBuilder.cls,
            name,
          );
          if (classMember != null) {
            Member member = classMember.getMember(membersBuilder);
            if (member.enclosingClass != declarer &&
                member.enclosingClass != classBuilder.cls &&
                member.isAbstract == false) {
              classBuilder.libraryBuilder.addProblem(
                diag.enumInheritsRestricted.withArguments(
                  memberName: name.text,
                ),
                classBuilder.fileOffset,
                classBuilder.name.length,
                classBuilder.fileUri,
                context: <LocatedMessage>[
                  diag.enumInheritsRestrictedMember.withLocation2(
                    classMember.uriOffset,
                  ),
                ],
              );
            }
          }
        }
      }
    }
    ticker.logMs("Checked for restricted members inheritance in enums.");

    typeInferenceEngine.finishTopLevelInitializingFormals();
    ticker.logMs("Finished initializing formals");
  }

  void checkAbstractMembers(List<SourceClassBuilder> sourceClasses) {
    List<ClassMember> delayedMemberChecks = membersBuilder
        .takeDelayedMemberComputations();
    Set<Class> changedClasses = new Set<Class>();
    for (int i = 0; i < delayedMemberChecks.length; i++) {
      delayedMemberChecks[i].getMember(membersBuilder);
      DeclarationBuilder declarationBuilder =
          delayedMemberChecks[i].declarationBuilder;
      switch (declarationBuilder) {
        case ClassBuilder():
          // TODO(johnniwinther): Only invalidate class if a member was added.
          changedClasses.add(declarationBuilder.cls);
        case ExtensionTypeDeclarationBuilder():
          // TODO(johnniwinther): Should the member be added to the extension
          //  type declaration?
          break;
        // Coverage-ignore(suite): Not run.
        case ExtensionBuilder():
          throw new UnsupportedError(
            "Unexpected declaration ${declarationBuilder}.",
          );
      }
    }
    ticker.logMs(
      "Computed ${delayedMemberChecks.length} combined member signatures",
    );

    hierarchy.applyMemberChanges(changedClasses, findDescendants: false);
    ticker.logMs(
      "Updated ${changedClasses.length} classes in kernel hierarchy",
    );
  }

  void checkRedirectingFactories(
    List<SourceClassBuilder> sourceClasses,
    List<SourceExtensionTypeDeclarationBuilder>
    sourceExtensionTypeDeclarationBuilders,
  ) {
    // TODO(ahe): Move this to [ClassHierarchyBuilder].
    for (SourceClassBuilder builder in sourceClasses) {
      if (builder.libraryBuilder.loader == this) {
        builder.checkRedirectingFactories(
          typeInferenceEngine.typeSchemaEnvironment,
        );
      }
    }
    for (SourceExtensionTypeDeclarationBuilder builder
        in sourceExtensionTypeDeclarationBuilders) {
      if (builder.libraryBuilder.loader == this) {
        builder.checkRedirectingFactories(
          typeInferenceEngine.typeSchemaEnvironment,
        );
      }
    }
    ticker.logMs("Checked redirecting factories");
  }

  /// Sets [SourceLibraryBuilder.unpromotablePrivateFieldNames] for any
  /// libraries in which field promotion is enabled.
  void computeFieldPromotability() {
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      // TODO(paulberry): what should we do for augmentation libraries?
      if (library.loader == this) {
        library.computeFieldPromotability();
      }
    }
    ticker.logMs("Computed unpromotable private field names");
  }

  void checkMixins(List<SourceClassBuilder> sourceClasses) {
    for (SourceClassBuilder builder in sourceClasses) {
      Class? mixedInClass = builder.cls.mixedInClass;
      if (mixedInClass != null && mixedInClass.isMixinDeclaration) {
        builder.checkMixinApplication(hierarchy, coreTypes);
      }
    }
    ticker.logMs("Checked mixin declaration applications");
  }

  /// Checks that super member access from mixin declarations mixed into
  /// the classes in the [sourceLibraryBuilders] have a concrete target
  // TODO(johnniwinther): Make this work for when the mixin declaration is from
  //  an outline library.
  void checkMixinSuperAccesses() {
    _SuperMemberCache superMemberCache = new _SuperMemberCache();
    for (SourceLibraryBuilder libraryBuilder in sourceLibraryBuilders) {
      Map<SourceClassBuilder, TypeBuilder> mixinApplications = {};
      libraryBuilder.takeMixinApplications(mixinApplications);
      for (MapEntry<SourceClassBuilder, TypeBuilder> entry
          in mixinApplications.entries) {
        SourceClassBuilder mixinApplication = entry.key;
        ClassHierarchyNode node = hierarchyBuilder.getNodeFromClassBuilder(
          mixinApplication,
        );
        ClassHierarchyNode? mixedInNode = node.mixedInNode;
        if (mixedInNode != null) {
          Class mixedInClass = mixedInNode.classBuilder.cls;
          List<Supertype> onClause = mixedInClass.onClause;
          if (onClause.isNotEmpty) {
            for (Procedure procedure in mixedInClass.procedures) {
              if (procedure.containsSuperCalls) {
                procedure.function.body?.accept(
                  new _CheckSuperAccess(
                    libraryBuilder,
                    mixinApplication.cls,
                    entry.value,
                    procedure,
                    superMemberCache,
                  ),
                );
              }
            }
            for (Field field in mixedInClass.fields) {
              if (field.containsSuperCalls) {
                field.initializer?.accept(
                  new _CheckSuperAccess(
                    libraryBuilder,
                    mixinApplication.cls,
                    entry.value,
                    field,
                    superMemberCache,
                  ),
                );
              }
            }
          }
        }
      }
    }
    ticker.logMs("Checked mixin application super-accesses");
  }

  void buildOutlineExpressions(
    ClassHierarchy classHierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      library.buildOutlineExpressions(
        classHierarchy,
        delayedDefaultValueCloners,
      );
    }
  }

  void buildClassHierarchy(
    List<SourceClassBuilder> sourceClasses,
    List<SourceExtensionTypeDeclarationBuilder> sourceExtensionTypes,
    ClassBuilder objectClass,
  ) {
    ClassHierarchyBuilder hierarchyBuilder = _hierarchyBuilder =
        ClassHierarchyBuilder.build(
          objectClass,
          sourceClasses,
          sourceExtensionTypes,
          this,
          coreTypes,
        );
    typeInferenceEngine.hierarchyBuilder = hierarchyBuilder;
    ticker.logMs("Built class hierarchy");
  }

  void buildClassHierarchyMembers(
    List<SourceClassBuilder> sourceClasses,
    List<SourceExtensionTypeDeclarationBuilder> sourceExtensionTypes,
  ) {
    ClassMembersBuilder membersBuilder = _membersBuilder =
        ClassMembersBuilder.build(
          hierarchyBuilder,
          sourceClasses,
          sourceExtensionTypes,
        );
    typeInferenceEngine.membersBuilder = membersBuilder;
    ticker.logMs("Built class hierarchy members");
  }

  void createTypeInferenceEngine() {
    _typeInferenceEngine = new TypeInferenceEngineImpl(
      benchmarker: target.benchmarker,
    );
  }

  void prepareTopLevelInference() {
    /// Inferring redirecting factories partially overlaps with top-level
    /// inference, since the formal parameters of the redirection targets should
    /// be inferred, and they can be formal initializing parameters requiring
    /// inference. [RedirectingFactoryBuilder.buildOutlineExpressions] can
    /// invoke inference on those formal parameters. Therefore, the top-level
    /// inference should be prepared before we can infer redirecting factories.

    /// The first phase of top level initializer inference, which consists of
    /// creating kernel objects for all fields and top level variables that
    /// might be subject to type inference, and records dependencies between
    /// them.
    typeInferenceEngine.prepareTopLevel(coreTypes, hierarchy);

    ticker.logMs("Prepared for top level inference");
  }

  void inferRedirectingFactories(
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    assert(
      typeInferenceEngine.isTypeInferencePrepared,
      "Top level inference has not been prepared.",
    );

    for (SourceLibraryBuilder library in sourceLibraryBuilders) {
      List<SourceFactoryBuilder>? redirectingFactoryBuilders =
          library.redirectingFactoryBuilders;
      if (redirectingFactoryBuilders != null) {
        for (SourceFactoryBuilder redirectingFactoryBuilder
            in redirectingFactoryBuilders) {
          registerConstructorToBeInferred(
            new InferableRedirectingFactory(
              redirectingFactoryBuilder,
              hierarchy,
              delayedDefaultValueCloners,
            ),
          );
        }
      }
    }

    ticker.logMs("Performed redirecting factory inference");
  }

  void computeMemberTypes() {
    assert(
      typeInferenceEngine.isTypeInferencePrepared,
      "Top level inference has not been prepared.",
    );
    membersBuilder.computeTypes();

    ticker.logMs("Computed member types");
  }

  void performTopLevelInference(List<SourceClassBuilder> sourceClasses) {
    assert(
      typeInferenceEngine.isTypeInferencePrepared,
      "Top level inference has not been prepared.",
    );
    inferableTypes.inferTypes(typeInferenceEngine.hierarchyBuilder);

    ticker.logMs("Performed top level inference");
  }

  void _checkMainMethods(
    SourceLibraryBuilder libraryBuilder,
    DartType listOfString,
  ) {
    LookupResult? result = libraryBuilder.exportNameSpace.lookup('main');
    Builder? mainBuilder = result?.getable;
    mainBuilder ??= result?.setable;
    if (mainBuilder is MemberBuilder) {
      if (mainBuilder is InvalidBuilder) {
        // This is an ambiguous export, skip the check.
        return;
      }
      if (mainBuilder.isProperty) {
        if (mainBuilder.libraryBuilder != libraryBuilder) {
          libraryBuilder.addProblem(
            diag.mainNotFunctionDeclarationExported,
            libraryBuilder.fileOffset,
            noLength,
            libraryBuilder.fileUri,
            context: [
              diag.exportedMain.withLocation(
                mainBuilder.fileUri!,
                mainBuilder.fileOffset,
                mainBuilder.name.length,
              ),
            ],
          );
        } else {
          libraryBuilder.addProblem(
            diag.mainNotFunctionDeclaration,
            mainBuilder.fileOffset,
            mainBuilder.name.length,
            mainBuilder.fileUri,
          );
        }
      } else {
        Procedure procedure = mainBuilder.invokeTarget as Procedure;
        if (procedure.function.requiredParameterCount > 2) {
          if (mainBuilder.libraryBuilder != libraryBuilder) {
            libraryBuilder.addProblem(
              diag.mainTooManyRequiredParametersExported,
              libraryBuilder.fileOffset,
              noLength,
              libraryBuilder.fileUri,
              context: [
                diag.exportedMain.withLocation(
                  mainBuilder.fileUri!,
                  mainBuilder.fileOffset,
                  mainBuilder.name.length,
                ),
              ],
            );
          } else {
            libraryBuilder.addProblem(
              diag.mainTooManyRequiredParameters,
              mainBuilder.fileOffset,
              mainBuilder.name.length,
              mainBuilder.fileUri,
            );
          }
        } else if (procedure.function.namedParameters.any(
          (parameter) => parameter.isRequired,
        )) {
          if (mainBuilder.libraryBuilder != libraryBuilder) {
            libraryBuilder.addProblem(
              diag.mainRequiredNamedParametersExported,
              libraryBuilder.fileOffset,
              noLength,
              libraryBuilder.fileUri,
              context: [
                diag.exportedMain.withLocation(
                  mainBuilder.fileUri!,
                  mainBuilder.fileOffset,
                  mainBuilder.name.length,
                ),
              ],
            );
          } else {
            libraryBuilder.addProblem(
              diag.mainRequiredNamedParameters,
              mainBuilder.fileOffset,
              mainBuilder.name.length,
              mainBuilder.fileUri,
            );
          }
        } else if (procedure.function.positionalParameters.length > 0) {
          DartType parameterType =
              procedure.function.positionalParameters.first.type;

          if (!typeEnvironment.isSubtypeOf(listOfString, parameterType)) {
            if (mainBuilder.libraryBuilder != libraryBuilder) {
              libraryBuilder.addProblem(
                diag.mainWrongParameterTypeExported.withArguments(
                  actualType: parameterType,
                  expectedType: listOfString,
                ),
                libraryBuilder.fileOffset,
                noLength,
                libraryBuilder.fileUri,
                context: [
                  diag.exportedMain.withLocation(
                    mainBuilder.fileUri!,
                    mainBuilder.fileOffset,
                    mainBuilder.name.length,
                  ),
                ],
              );
            } else {
              libraryBuilder.addProblem(
                diag.mainWrongParameterType.withArguments(
                  actualType: parameterType,
                  expectedType: listOfString,
                ),
                mainBuilder.fileOffset,
                mainBuilder.name.length,
                mainBuilder.fileUri,
              );
            }
          }
        }
      }
    } else if (mainBuilder != null) {
      if (mainBuilder.parent != libraryBuilder) {
        libraryBuilder.addProblem(
          diag.mainNotFunctionDeclarationExported,
          libraryBuilder.fileOffset,
          noLength,
          libraryBuilder.fileUri,
          context: [
            diag.exportedMain.withLocation(
              mainBuilder.fileUri!,
              mainBuilder.fileOffset,
              noLength,
            ),
          ],
        );
      } else {
        libraryBuilder.addProblem(
          diag.mainNotFunctionDeclaration,
          mainBuilder.fileOffset,
          noLength,
          mainBuilder.fileUri,
        );
      }
    }
  }

  void checkMainMethods() {
    DartType listOfString = new InterfaceType(
      coreTypes.listClass,
      Nullability.nonNullable,
      [coreTypes.stringNonNullableRawType],
    );

    for (SourceLibraryBuilder libraryBuilder in sourceLibraryBuilders) {
      _checkMainMethods(libraryBuilder, listOfString);
    }
  }

  void releaseAncillaryResources() {
    hierarchy = null;
    _hierarchyBuilder = null;
    _membersBuilder = null;
    _typeInferenceEngine = null;
    _compilationUnits.clear();
    libraries.clear();
    sourceBytes.clear();
    target.releaseAncillaryResources();
    _coreTypes = null;
  }

  @override
  ClassBuilder computeClassBuilderFromTargetClass(Class cls) {
    ClassBuilder? classBuilder = referenceMap.lookupClassBuilder(cls.reference);
    if (classBuilder != null) {
      return classBuilder;
    }
    Library library = cls.enclosingLibrary;
    LibraryBuilder? libraryBuilder = lookupLoadedLibraryBuilder(
      library.importUri,
    );
    if (libraryBuilder == null) {
      return target.dillTarget.loader.computeClassBuilderFromTargetClass(cls);
    }
    return libraryBuilder.lookupRequiredLocalMember(cls.name) as ClassBuilder;
  }

  @override
  ExtensionTypeDeclarationBuilder
  computeExtensionTypeBuilderFromTargetExtensionType(
    ExtensionTypeDeclaration extensionType,
  ) {
    ExtensionTypeDeclarationBuilder? extensionTypeDeclarationBuilder =
        referenceMap.lookupExtensionTypeDeclarationBuilder(
          extensionType.reference,
        );
    if (extensionTypeDeclarationBuilder != null) {
      return extensionTypeDeclarationBuilder;
    }
    Library kernelLibrary = extensionType.enclosingLibrary;
    LibraryBuilder? library = lookupLoadedLibraryBuilder(
      kernelLibrary.importUri,
    );
    if (library == null) {
      // Coverage-ignore-block(suite): Not run.
      return target.dillTarget.loader
          .computeExtensionTypeBuilderFromTargetExtensionType(extensionType);
    }
    return library.lookupRequiredLocalMember(extensionType.name)
        as ExtensionTypeDeclarationBuilder;
  }

  late TypeBuilderComputer _typeBuilderComputer = new TypeBuilderComputer(this);

  @override
  TypeBuilder computeTypeBuilder(DartType type) {
    return _typeBuilderComputer.visit(type);
  }
}

/// A minimal implementation of dart:core that is sufficient to create an
/// instance of [CoreTypes] and compile a program.
const String defaultDartCoreSource = """
import 'dart:_internal';
import 'dart:async';

export 'dart:async' show Future, Stream;

print(object) {}

bool identical(a, b) => false;

class Iterator<E> {
  bool moveNext() => null;
  E get current => null;
}

class Iterable<E> {
  Iterator<E> get iterator => null;
}

class List<E> extends Iterable<E> {
  factory List.unmodifiable(elements) => null;
  factory List.empty({bool growable = false}) => null;
  factory List.filled(int length, E fill, {bool growable = false}) => null;
  factory List.generate(int length, E generator(int index),
      {bool growable = true}) => null;
  factory List.of() => null;
  void add(E element) {}
  void addAll(Iterable<E> iterable) {}
  E operator [](int index) => null;
  int get length => 0;
  List<E> sublist(int start, [int? end]) => this;
}

class _GrowableList<E> implements List<E> {
  factory _GrowableList(int length) => null;
  factory _GrowableList.empty() => null;
  factory _GrowableList.filled() => null;
  factory _GrowableList.generate(int length, E generator(int index)) => null;
  factory _GrowableList._literal1(E e0) => null;
  factory _GrowableList._literal2(E e0, E e1) => null;
  factory _GrowableList._literal3(E e0, E e1, E e2) => null;
  factory _GrowableList._literal4(E e0, E e1, E e2, E e3) => null;
  factory _GrowableList._literal5(E e0, E e1, E e2, E e3, E e4) => null;
  factory _GrowableList._literal6(E e0, E e1, E e2, E e3, E e4, E e5) => null;
  factory _GrowableList._literal7(E e0, E e1, E e2, E e3, E e4, E e5, E e6) => null;
  factory _GrowableList._literal8(E e0, E e1, E e2, E e3, E e4, E e5, E e6, E e7) => null;
  void add(E element) {}
  void addAll(Iterable<E> iterable) {}
  Iterator<E> get iterator => null;
  E operator [](int index) => null;
}

class _List<E> {
  factory _List() => null;
  factory _List.empty() => null;
  factory _List.filled() => null;
  factory _List.generate(int length, E generator(int index)) => null;
}

class MapEntry<K, V> {
  K key;
  V value;
}

abstract class Map<K, V> extends Iterable {
  factory Map.unmodifiable(other) => null;
  factory Map.of(o) = Map<K, V>._of;
  external factory Map._of(o);
  Iterable<MapEntry<K, V>> get entries;
  void operator []=(K key, V value) {}
  void addAll(Map<K, V> other) {}
  V? operator [](Object key);
  bool containsKey(Object key);
}

abstract class pragma {
  String name;
  Object options;
}

class NoSuchMethodError {
  factory NoSuchMethodError.withInvocation(receiver, invocation) => throw '';
}

class StackTrace {}

class Null {}

class Object {
  const Object();
  noSuchMethod(invocation) => null;
  bool operator==(dynamic) {}
}

abstract class Enum {
  String get _name;
}

abstract class _Enum {
  final int index;
  final String _name;

  const _Enum(this.index, this._name);
}

class String {}

class Symbol {}

class Set<E> {
  factory Set() = Set<E>._;
  external factory Set._();
  factory Set.of(o) = Set<E>._of;
  external factory Set._of(o);
  bool add(E element) {}
  void addAll(Iterable<E> iterable) {}
}

class Type {}

class _InvocationMirror {
  _InvocationMirror._withType(_memberName, _type, _typeArguments,
      _positionalArguments, _namedArguments);
}

class bool {}

class double extends num {}

class int extends num {
  int operator -() => this;
}

class num {
  num operator -() => this;
  num operator -(num other) => this;
  bool operator >=(num other) => false;
}

class Function {}

class Record {}

class StateError {
  StateError(String message);
}
""";

/// A minimal implementation of dart:async that is sufficient to create an
/// instance of [CoreTypes] and compile program.
const String defaultDartAsyncSource = """
void _asyncStarMoveNextHelper(var stream) {}

abstract class Completer {
  factory Completer.sync() => null;

  get future;

  complete([value]);

  completeError(error, [stackTrace]);
}

class Future<T> {
  factory Future.microtask(computation) => null;
}

class FutureOr {
}

class _Future {
  void _completeError(Object error, StackTrace stackTrace) {}

  void _asyncCompleteError(Object error, StackTrace stackTrace) {}
}

class Stream {}

class _StreamIterator {
  get current => null;

  moveNext() {}

  cancel() {}
}
""";

/// A minimal implementation of dart:collection that is sufficient to create an
/// instance of [CoreTypes] and compile program.
const String defaultDartCollectionSource = """
abstract class LinkedHashMap<K, V> implements Map<K, V> {
  factory LinkedHashMap(
      {bool Function(K, K)? equals,
      int Function(K)? hashCode,
      bool Function(dynamic)? isValidKey}) => null;
}

abstract class LinkedHashSet<E> implements Set<E> {
  factory LinkedHashSet(
      {bool Function(E, E)? equals,
      int Function(E)? hashCode,
      bool Function(dynamic)? isValidKey}) => null;
}

class _UnmodifiableSet {
  final Map _map;
  const _UnmodifiableSet(this._map);
}
""";

/// A minimal implementation of dart:collection that is sufficient to create an
/// instance of [CoreTypes] and compile program.
const String defaultDartCompactHashSource = """
class _Map<K, V> {
}

class _Set<E> {
}
""";

/// A minimal implementation of dart:_internal that is sufficient to create an
/// instance of [CoreTypes] and compile program.
const String defaultDartInternalSource = """
class Symbol {
  const Symbol(String name);
}

T unsafeCast<T>(Object v) {}
class ReachabilityError {
  ReachabilityError([message]);
}
""";

/// A minimal implementation of dart:typed_data that is sufficient to create an
/// instance of [CoreTypes] and compile program.
const String defaultDartTypedDataSource = """
class Endian {
  static const Endian little = null;
  static const Endian big = null;
  static final Endian host = null;
}
""";

// Coverage-ignore(suite): Not run.
class SourceLoaderDataForTesting {
  final Map<TreeNode, TreeNode> _aliasMap = {};

  /// Registers that [original] has been replaced by [alias] in the generated
  /// AST.
  void registerAlias(TreeNode original, TreeNode alias) {
    _aliasMap[alias] = original;
  }

  /// Returns the original node for [alias] or [alias] if it was not registered
  /// as an alias.
  TreeNode toOriginal(TreeNode alias) {
    return _aliasMap[alias] ?? alias;
  }

  final ExhaustivenessDataForTesting exhaustivenessData =
      new ExhaustivenessDataForTesting();
}

class _SourceClassGraph implements Graph<SourceClassBuilder> {
  @override
  final List<SourceClassBuilder> vertices;
  final ClassBuilder _objectClass;
  final Map<SourceClassBuilder, Map<TypeDeclarationBuilder?, TypeAliasBuilder?>>
  directSupertypeMap = {};
  final Map<SourceClassBuilder, List<SourceClassBuilder>> _supertypeMap = {};

  _SourceClassGraph(this.vertices, this._objectClass);

  List<SourceClassBuilder> computeSuperClasses(SourceClassBuilder cls) {
    Map<TypeDeclarationBuilder?, TypeAliasBuilder?> directSupertypes =
        directSupertypeMap[cls] = cls.computeDirectSupertypes(_objectClass);
    List<SourceClassBuilder> superClasses = [];
    for (TypeDeclarationBuilder? directSupertype in directSupertypes.keys) {
      if (directSupertype is SourceClassBuilder) {
        superClasses.add(directSupertype);
      }
    }
    return superClasses;
  }

  @override
  Iterable<SourceClassBuilder> neighborsOf(SourceClassBuilder vertex) {
    return _supertypeMap[vertex] ??= computeSuperClasses(vertex);
  }
}

class _SourceExtensionTypeGraph
    implements Graph<SourceExtensionTypeDeclarationBuilder> {
  @override
  final List<SourceExtensionTypeDeclarationBuilder> vertices;
  final Map<
    SourceExtensionTypeDeclarationBuilder,
    Map<TypeDeclarationBuilder?, TypeAliasBuilder?>
  >
  directSupertypeMap = {};
  final Map<
    SourceExtensionTypeDeclarationBuilder,
    List<SourceExtensionTypeDeclarationBuilder>
  >
  _supertypeMap = {};

  _SourceExtensionTypeGraph(this.vertices);

  List<SourceExtensionTypeDeclarationBuilder> computeSuperClasses(
    SourceExtensionTypeDeclarationBuilder extensionTypeBuilder,
  ) {
    Map<TypeDeclarationBuilder?, TypeAliasBuilder?> directSupertypes =
        directSupertypeMap[extensionTypeBuilder] = extensionTypeBuilder
            .computeDirectSupertypes();
    List<SourceExtensionTypeDeclarationBuilder> superClasses = [];
    for (TypeDeclarationBuilder? directSupertype in directSupertypes.keys) {
      if (directSupertype is SourceExtensionTypeDeclarationBuilder) {
        superClasses.add(directSupertype);
      }
    }
    return superClasses;
  }

  @override
  Iterable<SourceExtensionTypeDeclarationBuilder> neighborsOf(
    SourceExtensionTypeDeclarationBuilder vertex,
  ) {
    return _supertypeMap[vertex] ??= computeSuperClasses(vertex);
  }
}

/// Visitor that checks that super accesses have a concrete target.
// TODO(johnniwinther): Update this to perform member cloning when needed by
// the backend.
class _CheckSuperAccess extends RecursiveVisitor {
  final SourceLibraryBuilder _sourceLibraryBuilder;
  final Class _mixinApplicationClass;
  final TypeBuilder _typeBuilder;
  final Member _enclosingMember;
  final _SuperMemberCache cache;

  _CheckSuperAccess(
    this._sourceLibraryBuilder,
    this._mixinApplicationClass,
    this._typeBuilder,
    this._enclosingMember,
    this.cache,
  );

  void _checkMember(
    Name name, {
    required Template<Message Function({required String memberName})> template,
    required bool isSetter,
    required int accessFileOffset,
  }) {
    Member? member = cache.findSuperMember(
      _mixinApplicationClass.superclass,
      name,
      isSetter: isSetter,
    );
    if (member == null) {
      _sourceLibraryBuilder.addProblem(
        template.withArguments(memberName: name.text),
        _typeBuilder.charOffset!,
        noLength,
        _typeBuilder.fileUri!,
        context: [
          diag.mixinApplicationNoConcreteMemberContext.withLocation(
            _enclosingMember.fileUri,
            accessFileOffset,
            noLength,
          ),
        ],
      );
    }
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    super.visitSuperMethodInvocation(node);
    _checkMember(
      node.interfaceTarget.name,
      isSetter: false,
      template: diag.mixinApplicationNoConcreteMethod,
      accessFileOffset: node.fileOffset,
    );
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    super.visitSuperPropertyGet(node);
    _checkMember(
      node.interfaceTarget.name,
      isSetter: false,
      template: diag.mixinApplicationNoConcreteGetter,
      accessFileOffset: node.fileOffset,
    );
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    super.visitSuperPropertySet(node);
    _checkMember(
      node.interfaceTarget.name,
      isSetter: true,
      template: diag.mixinApplicationNoConcreteSetter,
      accessFileOffset: node.fileOffset,
    );
  }
}

/// Cache of concrete members, used by [_CheckSuperAccess] to check that super
/// accesses have a concrete target.
class _SuperMemberCache {
  Map<Class, Map<Name, Member>> _getterMaps = {};
  Map<Class, Map<Name, Member>> _setterMaps = {};

  Map<Name, Member> _computeGetters(Class cls) {
    Map<Name, Member> cache = {};
    for (Procedure procedure in cls.procedures) {
      if (procedure.kind != ProcedureKind.Setter && !procedure.isAbstract) {
        cache[procedure.name] = procedure;
      }
    }
    for (Field field in cls.fields) {
      cache[field.name] = field;
    }
    return cache;
  }

  Map<Name, Member> _computeSetters(Class cls) {
    Map<Name, Member> cache = {};
    for (Procedure procedure in cls.procedures) {
      if (procedure.kind == ProcedureKind.Setter && !procedure.isAbstract) {
        cache[procedure.name] = procedure;
      }
    }
    for (Field field in cls.fields) {
      if (field.hasSetter) {
        cache[field.name] = field;
      }
    }
    return cache;
  }

  Map<Name, Member> _getConcreteMembers(Class cls, {required bool isSetter}) {
    if (isSetter) {
      return _setterMaps[cls] ??= _computeSetters(cls);
    } else {
      return _getterMaps[cls] ??= _computeGetters(cls);
    }
  }

  Member? findSuperMember(
    Class? superClass,
    Name name, {
    required bool isSetter,
  }) {
    while (superClass != null) {
      Map<Name, Member> cache = _getConcreteMembers(
        superClass,
        isSetter: isSetter,
      );
      Member? member = cache[name];
      if (member != null) {
        return member;
      }
      superClass = superClass.superclass;
    }
    return null;
  }
}

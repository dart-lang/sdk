// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/reference_from_index.dart' show IndexedContainer;
import 'package:kernel/target/changed_structure_notifier.dart'
    show ChangedStructureNotifier;
import 'package:kernel/target/targets.dart' show DiagnosticReporter, Target;
import 'package:kernel/type_algebra.dart' show Substitution;
import 'package:kernel/type_environment.dart' show TypeEnvironment;
import 'package:kernel/verifier.dart' show VerificationStage;
import 'package:package_config/package_config.dart' hide LanguageVersion;

import '../api_prototype/experimental_flags.dart'
    show ExperimentalFlag, GlobalFeatures;
import '../api_prototype/file_system.dart' show FileSystem;
import '../base/compiler_context.dart' show CompilerContext;
import '../base/crash.dart' show withCrashReporting;
import '../base/loader.dart' show Loader;
import '../base/messages.dart'
    show
        FormattedMessage,
        LocatedMessage,
        Message,
        messageConstConstructorLateFinalFieldCause,
        messageConstConstructorLateFinalFieldError,
        messageConstConstructorNonFinalField,
        messageConstConstructorNonFinalFieldCause,
        messageConstConstructorRedirectionToNonConst,
        noLength,
        templateFieldNonNullableNotInitializedByConstructorError,
        templateFieldNonNullableWithoutInitializerError,
        templateFinalFieldNotInitialized,
        templateFinalFieldNotInitializedByConstructor,
        templateMissingImplementationCause,
        templateSuperclassHasNoDefaultConstructor;
import '../base/nnbd_mode.dart';
import '../base/processed_options.dart' show ProcessedOptions;
import '../base/scope.dart' show AmbiguousBuilder;
import '../base/ticker.dart' show Ticker;
import '../base/uri_translator.dart' show UriTranslator;
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/property_builder.dart';
import '../builder/type_builder.dart';
import '../dill/dill_target.dart' show DillTarget;
import '../source/class_declaration.dart';
import '../source/constructor_declaration.dart';
import '../source/name_scheme.dart';
import '../source/source_class_builder.dart' show SourceClassBuilder;
import '../source/source_constructor_builder.dart';
import '../source/source_extension_type_declaration_builder.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../source/source_loader.dart'
    show CompilationPhaseForProblemReporting, SourceLoader;
import '../source/source_method_builder.dart';
import '../type_inference/type_schema.dart';
import 'benchmarker.dart' show BenchmarkPhases, Benchmarker;
import 'cfe_verifier.dart' show verifyComponent, verifyGetStaticType;
import 'constant_evaluator.dart' as constants
    show
        EvaluationMode,
        transformLibraries,
        transformProcedure,
        ConstantCoverage,
        ConstantEvaluationData;
import 'constructor_tearoff_lowering.dart';
import 'dynamic_module_validator.dart' as dynamic_module_validator;
import 'kernel_constants.dart' show KernelConstantErrorReporter;
import 'kernel_helper.dart';
import 'macro/macro.dart';

class KernelTarget {
  final Ticker ticker;

  /// The [FileSystem] which should be used to access files.
  final FileSystem fileSystem;

  /// Whether comments should be scanned and parsed.
  final bool includeComments;

  final DillTarget dillTarget;

  late final SourceLoader loader;

  Component? component;

  // 'dynamic' is always nullable.
  // TODO(johnniwinther): Why isn't this using a FixedTypeBuilder?
  final NamedTypeBuilder dynamicType = new NamedTypeBuilderImpl(
      const PredefinedTypeName("dynamic"), const NullabilityBuilder.inherent(),
      instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected);

  final NamedTypeBuilder objectType = new NamedTypeBuilderImpl(
      const PredefinedTypeName("Object"), const NullabilityBuilder.omitted(),
      instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected);

  // Null is always nullable.
  // TODO(johnniwinther): This could (maybe) use a FixedTypeBuilder when we
  //  have NullType?
  final NamedTypeBuilder nullType = new NamedTypeBuilderImpl(
      const PredefinedTypeName("Null"), const NullabilityBuilder.inherent(),
      instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected);

  // TODO(johnniwinther): Why isn't this using a FixedTypeBuilder?
  final NamedTypeBuilder bottomType = new NamedTypeBuilderImpl(
      const PredefinedTypeName("Never"), const NullabilityBuilder.omitted(),
      instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected);

  final NamedTypeBuilder enumType = new NamedTypeBuilderImpl(
      const PredefinedTypeName("Enum"), const NullabilityBuilder.omitted(),
      instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected);

  final NamedTypeBuilder underscoreEnumType = new NamedTypeBuilderImpl(
      const PredefinedTypeName("_Enum"), const NullabilityBuilder.omitted(),
      instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected);

  bool get excludeSource => !context.options.embedSourceText;

  Map<String, String>? get environmentDefines =>
      context.options.environmentDefines;

  bool get errorOnUnevaluatedConstant =>
      context.options.errorOnUnevaluatedConstant;

  final Map<Member, DelayedDefaultValueCloner> _delayedDefaultValueCloners = {};

  final UriTranslator uriTranslator;

  final Target backendTarget;

  final CompilerContext context;

  /// Shared with [CompilerContext].
  Map<Uri, Source> get uriToSource => context.uriToSource;

  MemberBuilder? _cachedDuplicatedFieldInitializerError;
  MemberBuilder? _cachedNativeAnnotation;

  final ProcessedOptions _options;

  final Benchmarker? benchmarker;

  KernelTarget(this.context, this.fileSystem, this.includeComments,
      DillTarget dillTarget, this.uriTranslator)
      : dillTarget = dillTarget,
        backendTarget = dillTarget.backendTarget,
        _options = context.options,
        ticker = dillTarget.ticker,
        benchmarker = dillTarget.benchmarker {
    assert(_options.haveBeenValidated, "Options have not been validated");
    loader = createLoader();
  }

  GlobalFeatures get globalFeatures => _options.globalFeatures;

  bool isExperimentEnabledInLibraryByVersion(
      ExperimentalFlag flag, Uri importUri, Version version) {
    return _options.isExperimentEnabledInLibraryByVersion(
        flag, importUri, version);
  }

  Uri? translateUri(Uri uri) => uriTranslator.translate(uri);

  /// Returns a reference to the constructor used for creating a runtime error
  /// when a final field is initialized twice. The constructor is expected to
  /// accept a single argument which is the name of the field.
  MemberBuilder getDuplicatedFieldInitializerError(Loader loader) {
    return _cachedDuplicatedFieldInitializerError ??= loader.coreLibrary
        .getConstructor("_DuplicatedFieldInitializerError",
            bypassLibraryPrivacy: true);
  }

  /// Returns a reference to the constructor used for creating `native`
  /// annotations. The constructor is expected to accept a single argument of
  /// type String, which is the name of the native method.
  MemberBuilder getNativeAnnotation(SourceLoader loader) {
    if (_cachedNativeAnnotation != null) return _cachedNativeAnnotation!;
    LibraryBuilder internal =
        loader.lookupLoadedLibraryBuilder(Uri.parse("dart:_internal"))!;
    return _cachedNativeAnnotation = internal.getConstructor("ExternalName");
  }

  void loadExtraRequiredLibraries(SourceLoader loader) {
    for (String uri in backendTarget.extraRequiredLibraries) {
      loader.read(Uri.parse(uri), 0,
          accessor: loader.coreLibraryCompilationUnit);
    }
    if (context.compilingPlatform) {
      // Coverage-ignore-block(suite): Not run.
      for (String uri in backendTarget.extraRequiredLibrariesPlatform) {
        loader.read(Uri.parse(uri), 0,
            accessor: loader.coreLibraryCompilationUnit);
      }
    }
  }

  FormattedMessage createFormattedMessage(
      Message message,
      int charOffset,
      int length,
      Uri? fileUri,
      List<LocatedMessage>? messageContext,
      Severity severity,
      {List<Uri>? involvedFiles}) {
    ProcessedOptions processedOptions = context.options;
    return processedOptions.format(
        context,
        fileUri != null
            ? message.withLocation(fileUri, charOffset, length)
            :
            // Coverage-ignore(suite): Not run.
            message.withoutLocation(),
        severity,
        messageContext,
        involvedFiles: involvedFiles);
  }

  String get currentSdkVersionString {
    return context.options.currentSdkVersion;
  }

  Version get leastSupportedVersion => const Version(2, 12);

  Version? _currentSdkVersion;

  Version get currentSdkVersion {
    if (_currentSdkVersion == null) {
      _parseCurrentSdkVersion();
    }
    return _currentSdkVersion!;
  }

  void _parseCurrentSdkVersion() {
    bool good = false;
    List<String> dotSeparatedParts = currentSdkVersionString.split(".");
    if (dotSeparatedParts.length >= 2) {
      _currentSdkVersion = new Version(int.tryParse(dotSeparatedParts[0])!,
          int.tryParse(dotSeparatedParts[1])!);
      good = true;
    }
    if (!good) {
      throw new StateError(
          "Unparsable sdk version given: $currentSdkVersionString");
    }
  }

  SourceLoader createLoader() =>
      new SourceLoader(fileSystem, includeComments, this);

  bool _hasAddedSources = false;

  void addSourceInformation(
      Uri importUri, Uri fileUri, List<int> lineStarts, Uint8List sourceCode) {
    Source source = new Source(lineStarts, sourceCode, importUri, fileUri);
    uriToSource[fileUri] = source;
    if (_hasAddedSources) {
      // Coverage-ignore-block(suite): Not run.
      // The sources have already been added to the component in [link] so we
      // have to add source directly here to create a consistent component.
      component?.uriToSource[fileUri] = excludeSource
          ? new Source.emptySource(
              source.lineStarts, source.importUri, source.fileUri)
          : source;
    }
  }

  // Coverage-ignore(suite): Not run.
  void removeSourceInformation(Uri fileUri) {
    uriToSource.remove(fileUri);
    if (_hasAddedSources) {
      // The sources have already been added to the component in [link] so we
      // have to remove source directly here to create a consistent component.
      component?.uriToSource.remove(fileUri);
    }
  }

  /// Return list of same size as input with possibly translated uris.
  List<Uri> setEntryPoints(List<Uri> entryPoints) {
    List<Uri> result = <Uri>[];
    for (Uri entryPoint in entryPoints) {
      Uri translatedEntryPoint = getEntryPointUri(entryPoint);
      result.add(translatedEntryPoint);
      loader.readAsEntryPoint(translatedEntryPoint,
          fileUri: translatedEntryPoint != entryPoint ? entryPoint : null);
    }
    return result;
  }

  /// Return list of same size as input with possibly translated uris.
  Uri getEntryPointUri(Uri entryPoint) {
    String scheme = entryPoint.scheme;
    switch (scheme) {
      case "package":
      case "dart":
      case "data":
        break;
      default:
        // Attempt to reverse-lookup [entryPoint] in package config.
        String asString = "$entryPoint";
        Package? package = uriTranslator.packages.packageOf(entryPoint);
        if (package != null) {
          String packageName = package.name;
          Uri packageUri = package.packageUriRoot;
          if (packageUri.hasFragment == true) {
            // Coverage-ignore-block(suite): Not run.
            packageUri = packageUri.removeFragment();
          }
          String prefix = "${packageUri}";
          if (asString.startsWith(prefix)) {
            // Coverage-ignore-block(suite): Not run.
            Uri reversed = Uri.parse(
                "package:$packageName/${asString.substring(prefix.length)}");
            if (entryPoint == uriTranslator.translate(reversed)) {
              entryPoint = reversed;
              break;
            }
          }
        }
    }
    return entryPoint;
  }

  bool _hasComputedNeededPrecompilations = false;

  Future<NeededPrecompilations?> computeNeededPrecompilations() async {
    assert(!_hasComputedNeededPrecompilations,
        "Needed precompilations have already been computed.");
    _hasComputedNeededPrecompilations = true;
    if (loader.roots.isEmpty) return null;
    return await withCrashReporting<NeededPrecompilations?>(() async {
      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_kernelBuildOutlines);
      await loader.buildOutlines();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_resolveParts);
      loader.resolveParts();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_buildNameSpaces);
      loader.buildNameSpaces(loader.sourceLibraryBuilders);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_becomeCoreLibrary);
      loader.coreLibrary.becomeCoreLibrary();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_buildScopes);
      loader.buildScopes(loader.sourceLibraryBuilders);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_computeMacroDeclarations);
      NeededPrecompilations? result =
          context.options.globalFeatures.macros.isEnabled
              ? loader.computeMacroDeclarations()
              : null;

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.unknownComputeNeededPrecompilations);
      return result;
    }, () => loader.currentUriForCrashReporting);
  }

  // Coverage-ignore(suite): Not run.
  /// Builds [libraryBuilders] to the state expected after
  /// [SourceLoader.buildScopes].
  void buildSyntheticLibrariesUntilBuildScopes(
      Iterable<SourceLibraryBuilder> libraryBuilders) {
    loader.buildNameSpaces(libraryBuilders);
    loader.buildScopes(libraryBuilders);
  }

  // Coverage-ignore(suite): Not run.
  /// Builds [libraryBuilders] to the state expected after default types have
  /// been computed.
  ///
  /// This assumes that [libraryBuilders] are in the state after
  /// [SourceLoader.buildScopes].
  void buildSyntheticLibrariesUntilComputeDefaultTypes(
      Iterable<SourceLibraryBuilder> libraryBuilders) {
    loader.computeLibraryScopes(libraryBuilders);
    loader.resolveTypes(libraryBuilders);
    loader.computeDefaultTypes(
        libraryBuilders, dynamicType, nullType, bottomType, objectClassBuilder);
  }

  // Coverage-ignore(suite): Not run.
  /// Builds [augmentationLibraries] to the state expected after applying phase
  /// 1 macros.
  Future<void> _buildForPhase1(MacroApplications macroApplications,
      Iterable<SourceLibraryBuilder> augmentationLibraries) async {
    await loader.buildOutlines();
    if (augmentationLibraries.isNotEmpty) {
      buildSyntheticLibrariesUntilBuildScopes(augmentationLibraries);
      // Normally augmentation libraries are applied in
      // [SourceLoader.resolveParts]. For macro-generated augmentation libraries
      // we instead apply them directly here.
      for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
        augmentationLibrary.applyAugmentations();
      }
      buildSyntheticLibrariesUntilComputeDefaultTypes(augmentationLibraries);

      await loader.computeAdditionalMacroApplications(
          macroApplications, augmentationLibraries);
    }
  }

  // Coverage-ignore(suite): Not run.
  /// Builds [augmentationLibraries] to the state expected after applying phase
  /// 2 macros.
  void _buildForPhase2(List<SourceLibraryBuilder> augmentationLibraries) {
    benchmarker?.enterPhase(BenchmarkPhases.outline_computeVariances);
    loader.computeVariances(augmentationLibraries);

    loader.finishTypeParameters(
        augmentationLibraries, objectClassBuilder, dynamicType);
    for (SourceLibraryBuilder augmentationLibrary in augmentationLibraries) {
      augmentationLibrary.buildOutlineNodes(loader.coreLibrary);
    }
    loader.resolveConstructors(augmentationLibraries);
  }

  // Coverage-ignore(suite): Not run.
  Future<void> _applyMacroPhase2(
      MacroApplications macroApplications,
      List<SourceClassBuilder> sortedSourceClassBuilders,
      List<SourceExtensionTypeDeclarationBuilder>
          sortedSourceExtensionTypeBuilders) async {
    benchmarker?.enterPhase(BenchmarkPhases.outline_applyDeclarationMacros);
    macroApplications.enterDeclarationsMacroPhase(loader.hierarchyBuilder);

    Future<void> applyDeclarationMacros() async {
      await macroApplications.applyDeclarationsMacros(
          sortedSourceClassBuilders, sortedSourceExtensionTypeBuilders,
          (SourceLibraryBuilder augmentationLibrary) async {
        List<SourceLibraryBuilder> augmentationLibraries = [
          augmentationLibrary
        ];
        // TODO(johnniwinther): How should we use the benchmarker here?
        benchmarker?.enterPhase(
            BenchmarkPhases.outline_buildMacroDeclarationsForPhase1);
        await _buildForPhase1(macroApplications, augmentationLibraries);
        benchmarker?.enterPhase(
            BenchmarkPhases.outline_buildMacroDeclarationsForPhase2);
        _buildForPhase2(augmentationLibraries);

        await applyDeclarationMacros();
      });
    }

    await applyDeclarationMacros();
  }

  // Coverage-ignore(suite): Not run.
  /// Builds [augmentationLibraries] to the state expected after applying phase
  /// 3 macros.
  void _buildForPhase3(List<SourceLibraryBuilder> augmentationLibraries) {
    // Currently there nothing to do here. The method is left in for symmetry.
  }

  Future<BuildResult> buildOutlines({CanonicalName? nameRoot}) async {
    if (loader.roots.isEmpty) {
      // Coverage-ignore-block(suite): Not run.
      return new BuildResult();
    }
    return await withCrashReporting<BuildResult>(() async {
      if (!_hasComputedNeededPrecompilations) {
        // Coverage-ignore-block(suite): Not run.
        NeededPrecompilations? neededPrecompilations =
            await computeNeededPrecompilations();
        // To support macros, the needed macro libraries must be compiled be
        // they are applied. Any supporting pipeline must therefore call
        // [computeNeededPrecompilations] before calling [buildOutlines] in
        // order to perform any need compilation in advance.
        //
        // If [neededPrecompilations] is non-null here, it means that macro
        // compilation was needed but not performed.
        if (neededPrecompilations != null) {
          throw new UnsupportedError('Macro precompilation is not supported.');
        }
      }

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_computeLibraryScopes);
      loader.computeLibraryScopes(loader.loadedLibraryBuilders);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_setupTopAndBottomTypes);
      setupTopAndBottomTypes();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_resolveTypes);
      loader.resolveTypes(loader.sourceLibraryBuilders);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_computeMacroApplications);
      MacroApplications? macroApplications =
          await loader.computeMacroApplications();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_computeVariances);
      loader.computeVariances(loader.sourceLibraryBuilders);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_computeDefaultTypes);
      loader.computeDefaultTypes(loader.sourceLibraryBuilders, dynamicType,
          nullType, bottomType, objectClassBuilder);

      if (macroApplications != null) {
        // Coverage-ignore-block(suite): Not run.
        benchmarker?.enterPhase(BenchmarkPhases.outline_applyTypeMacros);
        macroApplications.enterTypeMacroPhase();
        List<SourceLibraryBuilder> augmentationLibraries =
            await macroApplications.applyTypeMacros();
        benchmarker
            ?.enterPhase(BenchmarkPhases.outline_buildMacroTypesForPhase1);
        await _buildForPhase1(macroApplications, augmentationLibraries);
      }

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_checkSemantics);
      List<SourceClassBuilder>? sortedSourceClassBuilders;
      List<SourceExtensionTypeDeclarationBuilder>?
          sortedSourceExtensionTypeBuilders;
      (sortedSourceClassBuilders, sortedSourceExtensionTypeBuilders) =
          loader.checkClassCycles(objectClassBuilder);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_finishTypeParameters);
      loader.finishTypeParameters(
          loader.sourceLibraryBuilders, objectClassBuilder, dynamicType);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_createTypeInferenceEngine);
      loader.createTypeInferenceEngine();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_buildComponent);
      loader.buildOutlineNodes();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_installDefaultSupertypes);
      installDefaultSupertypes();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_link);
      component =
          link(new List<Library>.of(loader.libraries), nameRoot: nameRoot);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_computeCoreTypes);
      computeCoreTypes();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_buildClassHierarchy);
      loader.buildClassHierarchy(sortedSourceClassBuilders,
          sortedSourceExtensionTypeBuilders, objectClassBuilder);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_checkSupertypes);
      loader.checkSupertypes(
          sortedSourceClassBuilders,
          sortedSourceExtensionTypeBuilders,
          objectClass,
          enumClass,
          underscoreEnumClass);

      if (macroApplications != null) {
        // Coverage-ignore-block(suite): Not run.
        await _applyMacroPhase2(macroApplications, sortedSourceClassBuilders,
            sortedSourceExtensionTypeBuilders);
      }

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_installSyntheticConstructors);
      installSyntheticConstructors(sortedSourceClassBuilders);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_resolveConstructors);
      loader.resolveConstructors(loader.sourceLibraryBuilders);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_buildClassHierarchyMembers);
      loader.buildClassHierarchyMembers(
          sortedSourceClassBuilders, sortedSourceExtensionTypeBuilders);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_computeHierarchy);
      loader.computeHierarchy();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_installTypedefTearOffs);
      List<DelayedDefaultValueCloner>?
          typedefTearOffsDelayedDefaultValueCloners =
          loader.installTypedefTearOffs();
      typedefTearOffsDelayedDefaultValueCloners
          ?.forEach(registerDelayedDefaultValueCloner);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_computeFieldPromotability);
      loader.computeFieldPromotability();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(
              BenchmarkPhases.outline_performRedirectingFactoryInference);
      // TODO(johnniwinther): Add an interface for registering delayed actions.
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners = [];
      loader.inferRedirectingFactories(
          loader.hierarchy, delayedDefaultValueCloners);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_performTopLevelInference);
      loader.performTopLevelInference(sortedSourceClassBuilders);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_checkOverrides);
      loader.checkOverrides(sortedSourceClassBuilders);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_checkAbstractMembers);
      loader.checkAbstractMembers(sortedSourceClassBuilders);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_checkMixins);
      loader.checkMixins(sortedSourceClassBuilders);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_buildOutlineExpressions);
      loader.buildOutlineExpressions(
          loader.hierarchy, delayedDefaultValueCloners);
      delayedDefaultValueCloners.forEach(registerDelayedDefaultValueCloner);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_checkTypes);
      loader.checkTypes();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_checkRedirectingFactories);
      loader.checkRedirectingFactories(
          sortedSourceClassBuilders, sortedSourceExtensionTypeBuilders);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_finishSynthesizedParameters);
      finishSynthesizedParameters(forOutline: true);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_checkMainMethods);
      loader.checkMainMethods();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.outline_installAllComponentProblems);
      loader.installAllProblemsIntoComponent(component!,
          currentPhase: CompilationPhaseForProblemReporting.outline);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.unknownBuildOutlines);

      // For whatever reason sourceClassBuilders is kept alive for some amount
      // of time, meaning that all source library builders will be kept alive
      // (for whatever amount of time) even though we convert them to dill
      // library builders. To avoid it we null it out here.
      sortedSourceClassBuilders = null;

      return new BuildResult(
          component: component, macroApplications: macroApplications);
    }, () => loader.currentUriForCrashReporting);
  }

  /// Build the kernel representation of the component loaded by this
  /// target. The component will contain full bodies for the code loaded from
  /// sources, and only references to the code loaded by the [DillTarget],
  /// which may or may not include method bodies (depending on what was loaded
  /// into that target, an outline or a full kernel component).
  ///
  /// If [verify], run the default kernel verification on the resulting
  /// component.
  Future<BuildResult> buildComponent(
      {required MacroApplications? macroApplications,
      bool verify = false,
      bool allowVerificationErrorForTesting = false}) async {
    if (loader.roots.isEmpty) {
      // Coverage-ignore-block(suite): Not run.
      return new BuildResult(macroApplications: macroApplications);
    }
    return await withCrashReporting<BuildResult>(() async {
      ticker.logMs("Building component");

      if (macroApplications != null) {
        // Coverage-ignore-block(suite): Not run.
        benchmarker?.enterPhase(BenchmarkPhases.body_applyDefinitionMacros);
        macroApplications.enterDefinitionMacroPhase();
        List<SourceLibraryBuilder> augmentationLibraries =
            await macroApplications.applyDefinitionMacros();
        benchmarker
            ?.enterPhase(BenchmarkPhases.body_buildMacroDefinitionsForPhase1);
        await _buildForPhase1(macroApplications, augmentationLibraries);
        benchmarker
            ?.enterPhase(BenchmarkPhases.body_buildMacroDefinitionsForPhase2);
        _buildForPhase2(augmentationLibraries);
        benchmarker
            ?.enterPhase(BenchmarkPhases.body_buildMacroDefinitionsForPhase3);
        _buildForPhase3(augmentationLibraries);
      }

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.body_buildBodies);
      await loader.buildBodies(loader.sourceLibraryBuilders);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.body_checkMixinSuperAccesses);
      loader.checkMixinSuperAccesses();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.body_finishSynthesizedParameters);
      finishSynthesizedParameters();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.body_finishDeferredLoadTearoffs);
      loader.finishDeferredLoadTearoffs();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.body_finishNoSuchMethodForwarders);
      loader.finishNoSuchMethodForwarders();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.body_collectSourceClasses);
      List<SourceClassBuilder>? sourceClasses = [];
      List<SourceExtensionTypeDeclarationBuilder>? extensionTypeDeclarations =
          [];
      loader.collectSourceClasses(sourceClasses, extensionTypeDeclarations);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.body_finishNativeMethods);
      loader.finishNativeMethods();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.body_finishAugmentationMethods);
      loader.buildBodyNodes();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.body_finishAllConstructors);
      finishAllConstructors(sourceClasses, extensionTypeDeclarations);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.body_validateDynamicModule);
      await validateDynamicModule();

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.body_runBuildTransformations);
      runBuildTransformations();

      if (loader.macroClass != null) {
        // Coverage-ignore-block(suite): Not run.
        checkMacroApplications(loader.hierarchy, loader.macroClass!,
            loader.sourceLibraryBuilders, macroApplications);
      }
      if (macroApplications != null) {
        // Coverage-ignore-block(suite): Not run.
        macroApplications.buildMergedAugmentationLibraries(component!);
      }

      if (verify) {
        benchmarker
            // Coverage-ignore(suite): Not run.
            ?.enterPhase(BenchmarkPhases.body_verify);
        _verify(
            allowVerificationErrorForTesting: allowVerificationErrorForTesting);
      }

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.body_installAllComponentProblems);
      loader.installAllProblemsIntoComponent(component!,
          currentPhase: CompilationPhaseForProblemReporting.bodyBuilding);

      benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.unknownBuildComponent);

      // For whatever reason sourceClasses is kept alive for some amount
      // of time, meaning that all source library builders will be kept alive
      // (for whatever amount of time) even though we convert them to dill
      // library builders. To avoid it we null it out here.
      sourceClasses = null;
      extensionTypeDeclarations = null;

      context.options.hooksForTesting
          // Coverage-ignore(suite): Not run.
          ?.onBuildComponentComplete(component!);

      return new BuildResult(
          component: component, macroApplications: macroApplications);
    }, () => loader.currentUriForCrashReporting);
  }

  /// Creates a component by combining [libraries] with the libraries of
  /// `dillTarget.loader.component`.
  Component link(List<Library> libraries, {CanonicalName? nameRoot}) {
    libraries.addAll(dillTarget.loader.libraries);

    // Copy source data from the map in [CompilerContext] into a new map that is
    // put on the component.

    Map<Uri, Source> uriToSource = new Map<Uri, Source>();
    void copySource(Uri uri, Source source) {
      uriToSource[uri] = excludeSource
          ?
          // Coverage-ignore(suite): Not run.
          new Source.emptySource(
              source.lineStarts, source.importUri, source.fileUri)
          : source;
    }

    this.uriToSource.forEach(copySource);
    _hasAddedSources = true;

    Component component = backendTarget.configureComponent(new Component(
        nameRoot: nameRoot, libraries: libraries, uriToSource: uriToSource));

    NonNullableByDefaultCompiledMode? compiledMode = null;
    if (globalFeatures.nonNullable.isEnabled) {
      switch (loader.nnbdMode) {
        case NnbdMode.Weak:
          compiledMode = NonNullableByDefaultCompiledMode.Weak;
          break;
        case NnbdMode.Strong:
          compiledMode = NonNullableByDefaultCompiledMode.Strong;
          break;
      }
    } else {
      compiledMode = NonNullableByDefaultCompiledMode.Weak;
    }
    if (loader.hasInvalidNnbdModeLibrary) {
      compiledMode = NonNullableByDefaultCompiledMode.Invalid;
    }

    Reference? mainReference;

    LibraryBuilder? firstRoot = loader.rootLibrary;
    if (firstRoot != null) {
      // TODO(sigmund): do only for full program
      Builder? declaration =
          firstRoot.exportNameSpace.lookupLocalMember("main", setter: false);
      if (declaration is AmbiguousBuilder) {
        // Coverage-ignore-block(suite): Not run.
        AmbiguousBuilder problem = declaration;
        declaration = problem.getFirstDeclaration();
      }
      // TODO(johnniwinther): Add a [MethodBuilder] interface to handle this.
      if (declaration is ProcedureBuilder) {
        mainReference = declaration.procedure.reference;
      } else if (declaration is SourceMethodBuilder) {
        mainReference = declaration.invokeTarget.reference;
      }
    }
    component.setMainMethodAndMode(mainReference, true, compiledMode);

    assert(_getLibraryNnbdModeError(component) == null,
        "Got error: ${_getLibraryNnbdModeError(component)}");

    ticker.logMs("Linked component");
    return component;
  }

  String? _getLibraryNnbdModeError(Component component) {
    if (loader.hasInvalidNnbdModeLibrary) {
      // At least 1 library should be invalid or there should be a mix of strong
      // and weak. For libraries we've just compiled it will be marked as
      // invalid, but for libraries loaded from dill they have their original
      // value (i.e. either strong or weak).
      bool foundInvalid = false;
      bool foundStrong = false;
      bool foundWeak = false;
      for (Library library in component.libraries) {
        if (library.nonNullableByDefaultCompiledMode ==
            NonNullableByDefaultCompiledMode.Invalid) {
          foundInvalid = true;
          break;
        } else if (!foundWeak &&
            library.nonNullableByDefaultCompiledMode ==
                NonNullableByDefaultCompiledMode.Weak) {
          foundWeak = true;
          if (foundStrong) break;
        } else if (!foundStrong &&
            library.nonNullableByDefaultCompiledMode ==
                NonNullableByDefaultCompiledMode.Strong) {
          foundStrong = true;
          if (foundWeak) break;
        }
      }
      if (!foundInvalid && !(foundStrong && foundWeak)) {
        return "hasInvalidNnbdModeLibrary is true, but no library was invalid "
            "and there was no weak/strong mix.";
      }
      if (component.mode != NonNullableByDefaultCompiledMode.Invalid) {
        return "Component mode is not invalid as expected";
      }
    } else {
      // No libraries are allowed to be invalid, and should all be compatible
      // with the component nnbd mode setting.
      if (component.mode == NonNullableByDefaultCompiledMode.Invalid) {
        return "Component mode is invalid which was not expected";
      }
      if (component.modeRaw == null) {
        return "Component mode not set at all";
      }
      for (Library library in component.libraries) {
        if (component.mode == NonNullableByDefaultCompiledMode.Strong) {
          if (library.nonNullableByDefaultCompiledMode !=
              NonNullableByDefaultCompiledMode.Strong) {
            // Coverage-ignore-block(suite): Not run.
            return "Expected library ${library.importUri} to be strong, "
                "but was ${library.nonNullableByDefaultCompiledMode}";
          }
        }
        // Coverage-ignore(suite): Not run.
        else if (component.mode == NonNullableByDefaultCompiledMode.Weak) {
          if (library.nonNullableByDefaultCompiledMode !=
              NonNullableByDefaultCompiledMode.Weak) {
            return "Expected library ${library.importUri} to be weak, "
                "but was ${library.nonNullableByDefaultCompiledMode}";
          }
        } else {
          return "Expected component mode to be either strong, "
              "weak or agnostic but was ${component.mode}";
        }
      }
    }
    return null;
  }

  void installDefaultSupertypes() {
    Class objectClass = this.objectClass;
    for (SourceLibraryBuilder library in loader.sourceLibraryBuilders) {
      library.installDefaultSupertypes(objectClassBuilder, objectClass);
    }
    ticker.logMs("Installed Object as implicit superclass");
  }

  void installSyntheticConstructors(List<SourceClassBuilder> builders) {
    Class objectClass = this.objectClass;
    for (SourceClassBuilder builder in builders) {
      if (builder.cls != objectClass && !builder.isAugmenting) {
        if (builder.isAugmenting ||
            builder.isMixinDeclaration ||
            builder.isExtension) {
          continue;
        }
        if (builder.isMixinApplication) {
          installForwardingConstructors(builder);
        } else {
          installDefaultConstructor(builder);
        }
      }
    }
    ticker.logMs("Installed synthetic constructors");
  }

  ClassBuilder get objectClassBuilder => objectType.declaration as ClassBuilder;

  Class get objectClass => objectClassBuilder.cls;

  ClassBuilder get enumClassBuilder => enumType.declaration as ClassBuilder;

  Class get enumClass => enumClassBuilder.cls;

  ClassBuilder get underscoreEnumBuilder =>
      underscoreEnumType.declaration as ClassBuilder;

  Class get underscoreEnumClass => underscoreEnumBuilder.cls;

  /// If [builder] doesn't have a constructors, install the defaults.
  void installDefaultConstructor(SourceClassBuilder builder) {
    assert(!builder.isMixinApplication);
    assert(!builder.isExtension);
    // TODO(askesc): Make this check light-weight in the absence of
    //  augmentations.
    if (builder.cls.constructors.isNotEmpty) return;
    for (Procedure proc in builder.cls.procedures) {
      if (proc.isFactory) return;
    }

    IndexedContainer? indexedClass = builder.indexedClass;
    Reference? constructorReference;
    Reference? tearOffReference;
    if (indexedClass != null) {
      constructorReference =
          indexedClass.lookupConstructorReference(new Name(""));
      tearOffReference = indexedClass.lookupGetterReference(
          new Name(constructorTearOffName(""), indexedClass.library));
    }

    /// From [Dart Programming Language Specification, 4th Edition](
    /// https://ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf):
    /// >Iff no constructor is specified for a class C, it implicitly has a
    /// >default constructor C() : super() {}, unless C is class Object.
    // The superinitializer is installed below in [finishConstructors].
    builder.addSyntheticConstructor(_makeDefaultConstructor(
        builder, constructorReference, tearOffReference));
  }

  void installForwardingConstructors(SourceClassBuilder builder) {
    assert(builder.isMixinApplication);
    if (builder.libraryBuilder.loader != loader) return;
    if (builder.cls.constructors.isNotEmpty) {
      // These were installed by a subclass in the recursive call below.
      return;
    }

    /// From [Dart Programming Language Specification, 4th Edition](
    /// https://ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf):
    /// >A mixin application of the form S with M; defines a class C with
    /// >superclass S.
    /// >...

    /// >Let LM be the library in which M is declared. For each generative
    /// >constructor named qi(Ti1 ai1, . . . , Tiki aiki), i in 1..n of S
    /// >that is accessible to LM , C has an implicitly declared constructor
    /// >named q'i = [C/S]qi of the form q'i(ai1,...,aiki) :
    /// >super(ai1,...,aiki);.
    TypeBuilder? type = builder.supertypeBuilder;
    TypeDeclarationBuilder? supertype =
        type?.computeUnaliasedDeclaration(isUsedAsClass: true);
    if (supertype is SourceClassBuilder && supertype.isMixinApplication) {
      installForwardingConstructors(supertype);
    }

    IndexedContainer? indexedClass = builder.indexedClass;
    Reference? constructorReference;
    Reference? tearOffReference;
    if (indexedClass != null) {
      constructorReference =
          indexedClass.lookupConstructorReference(new Name(""));
      tearOffReference = indexedClass.lookupGetterReference(
          new Name(constructorTearOffName(""), indexedClass.library));
    }

    switch (supertype) {
      case ClassBuilder():
        ClassBuilder superclassBuilder = supertype;
        bool isConstructorAdded = false;
        Map<TypeParameter, DartType>? substitutionMap;

        NameIterator<MemberBuilder> iterator =
            superclassBuilder.fullConstructorNameIterator();
        while (iterator.moveNext()) {
          String name = iterator.name;
          MemberBuilder memberBuilder = iterator.current;
          if (memberBuilder.invokeTarget is Constructor) {
            substitutionMap ??=
                builder.getSubstitutionMap(superclassBuilder.cls);
            Reference? constructorReference;
            Reference? tearOffReference;
            if (indexedClass != null) {
              constructorReference = indexedClass
                  // We use the name of the member builder here since it refers
                  // to the library of the original declaration when private.
                  // For instance:
                  //
                  //     // lib1:
                  //     class Super { Super._() }
                  //     class Subclass extends Class {
                  //       Subclass() : super._();
                  //     }
                  //     // lib2:
                  //     class Mixin {}
                  //     class Class = Super with Mixin;
                  //
                  // Here `super._()` in `Subclass` targets the forwarding stub
                  // added to `Class` whose name is `_` private to `lib1`.
                  .lookupConstructorReference(memberBuilder.invokeTarget!.name);
              tearOffReference = indexedClass.lookupGetterReference(
                  new Name(constructorTearOffName(name), indexedClass.library));
            }
            builder.addSyntheticConstructor(_makeMixinApplicationConstructor(
                builder,
                builder.cls.mixin,
                memberBuilder as MemberBuilderImpl,
                substitutionMap,
                constructorReference,
                tearOffReference));
            isConstructorAdded = true;
          }
        }

        if (!isConstructorAdded) {
          // Coverage-ignore-block(suite): Not run.
          builder.addSyntheticConstructor(_makeDefaultConstructor(
              builder, constructorReference, tearOffReference));
        }
      case TypeAliasBuilder():
      case NominalParameterBuilder():
      case StructuralParameterBuilder():
      case ExtensionBuilder():
      case ExtensionTypeDeclarationBuilder():
      case InvalidTypeDeclarationBuilder():
      case BuiltinTypeDeclarationBuilder():
      // Coverage-ignore(suite): Not run.
      // TODO(johnniwinther): How should we handle this case?
      case OmittedTypeDeclarationBuilder():
      case null:
        builder.addSyntheticConstructor(_makeDefaultConstructor(
            builder, constructorReference, tearOffReference));
    }
  }

  SyntheticSourceConstructorBuilder _makeMixinApplicationConstructor(
      SourceClassBuilder classBuilder,
      Class mixin,
      MemberBuilder superConstructorBuilder,
      Map<TypeParameter, DartType> substitutionMap,
      Reference? constructorReference,
      Reference? tearOffReference) {
    bool hasTypeDependency = false;
    Substitution substitution = Substitution.fromMap(substitutionMap);

    VariableDeclaration copyFormal(VariableDeclaration formal) {
      VariableDeclaration copy = new VariableDeclaration(formal.name,
          isFinal: formal.isFinal,
          isConst: formal.isConst,
          isRequired: formal.isRequired,
          hasDeclaredInitializer: formal.hasDeclaredInitializer,
          type: const UnknownType());
      if (!hasTypeDependency && formal.type is! UnknownType) {
        copy.type = substitution.substituteType(formal.type);
      } else {
        hasTypeDependency = true;
      }
      return copy;
    }

    SourceLibraryBuilder libraryBuilder = classBuilder.libraryBuilder;
    Class cls = classBuilder.cls;
    Constructor superConstructor =
        superConstructorBuilder.invokeTarget as Constructor;
    bool isConst = superConstructor.isConst;
    if (isConst && mixin.fields.isNotEmpty) {
      for (Field field in mixin.fields) {
        if (!field.isStatic) {
          isConst = false;
          break;
        }
      }
    }
    List<VariableDeclaration> positionalParameters = <VariableDeclaration>[];
    List<VariableDeclaration> namedParameters = <VariableDeclaration>[];
    List<Expression> positional = <Expression>[];
    List<NamedExpression> named = <NamedExpression>[];

    for (VariableDeclaration formal
        in superConstructor.function.positionalParameters) {
      positionalParameters.add(copyFormal(formal));
      positional.add(new VariableGet(positionalParameters.last));
    }
    for (VariableDeclaration formal
        in superConstructor.function.namedParameters) {
      VariableDeclaration clone = copyFormal(formal);
      namedParameters.add(clone);
      named.add(new NamedExpression(
          formal.name!, new VariableGet(namedParameters.last)));
    }
    FunctionNode function = new FunctionNode(new EmptyStatement(),
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount:
            superConstructor.function.requiredParameterCount,
        returnType: makeConstructorReturnType(cls));
    SuperInitializer initializer = new SuperInitializer(
        superConstructor, new Arguments(positional, named: named));
    Constructor constructor = new Constructor(function,
            name: superConstructor.name,
            initializers: <Initializer>[initializer],
            isSynthetic: true,
            isConst: isConst,
            reference: constructorReference,
            fileUri: cls.fileUri)
          ..fileOffset = cls.fileOffset
        // TODO(johnniwinther): Should we add file end offset to synthesized
        //  constructors?
        //..fileEndOffset = cls.fileOffset
        ;
    DelayedDefaultValueCloner delayedDefaultValueCloner =
        new DelayedDefaultValueCloner(superConstructor, constructor,
            libraryBuilder: libraryBuilder);

    TypeDependency? typeDependency;
    if (hasTypeDependency) {
      typeDependency = new TypeDependency(
          constructor, superConstructor, substitution,
          copyReturnType: false);
    }

    Procedure? constructorTearOff = createConstructorTearOffProcedure(
        new MemberName(libraryBuilder.libraryName,
            constructorTearOffName(superConstructor.name.text)),
        libraryBuilder,
        cls.fileUri,
        cls.fileOffset,
        tearOffReference,
        forAbstractClassOrEnumOrMixin: classBuilder.isAbstract);

    if (constructorTearOff != null) {
      DelayedDefaultValueCloner delayedDefaultValueCloner =
          buildConstructorTearOffProcedure(
              tearOff: constructorTearOff,
              declarationConstructor: constructor,
              implementationConstructor: constructor,
              enclosingDeclarationTypeParameters:
                  classBuilder.cls.typeParameters,
              libraryBuilder: libraryBuilder);
      registerDelayedDefaultValueCloner(delayedDefaultValueCloner);
    }
    SyntheticSourceConstructorBuilder constructorBuilder =
        new SyntheticSourceConstructorBuilder(
            libraryBuilder, classBuilder, constructor, constructorTearOff,
            // We pass on the original constructor and the cloned function nodes
            // to ensure that the default values are computed and cloned for the
            // outline. It is needed to make the default values a part of the
            // outline for const constructors, and additionally it is required
            // for a potential subclass using super initializing parameters that
            // will required the cloning of the default values.
            definingConstructor: superConstructorBuilder,
            delayedDefaultValueCloner: delayedDefaultValueCloner,
            typeDependency: typeDependency);
    loader.registerConstructorToBeInferred(constructor, constructorBuilder);
    return constructorBuilder;
  }

  void registerDelayedDefaultValueCloner(DelayedDefaultValueCloner cloner) {
    // TODO(cstefantsova): Investigate the reason for the assumption breakage
    // and uncomment the following line.
    // assert(!_delayedDefaultValueCloners.containsKey(cloner.synthesized));
    _delayedDefaultValueCloners[cloner.synthesized] ??= cloner;
  }

  void finishSynthesizedParameters({bool forOutline = false}) {
    void cloneDefaultValues(
        DelayedDefaultValueCloner delayedDefaultValueCloner) {
      DelayedDefaultValueCloner? originalCloner =
          _delayedDefaultValueCloners[delayedDefaultValueCloner.original];
      if (originalCloner != null) {
        cloneDefaultValues(originalCloner);
      }
      delayedDefaultValueCloner.cloneDefaultValues(loader.typeEnvironment);
    }

    for (DelayedDefaultValueCloner delayedDefaultValueCloner
        in _delayedDefaultValueCloners.values) {
      if (!forOutline || delayedDefaultValueCloner.isOutlineNode) {
        cloneDefaultValues(delayedDefaultValueCloner);
      }
    }
    if (!forOutline) {
      _delayedDefaultValueCloners.clear();
    }
    ticker.logMs("Cloned default values of formals");
  }

  SyntheticSourceConstructorBuilder _makeDefaultConstructor(
      SourceClassBuilder classBuilder,
      Reference? constructorReference,
      Reference? tearOffReference) {
    SourceLibraryBuilder libraryBuilder = classBuilder.libraryBuilder;
    Class enclosingClass = classBuilder.cls;
    Constructor constructor = new Constructor(
            new FunctionNode(new EmptyStatement(),
                returnType: makeConstructorReturnType(enclosingClass)),
            name: new Name(""),
            isSynthetic: true,
            reference: constructorReference,
            fileUri: enclosingClass.fileUri)
          ..fileOffset = enclosingClass.fileOffset
        // TODO(johnniwinther): Should we add file end offsets to synthesized
        //  constructors?
        //..fileEndOffset = enclosingClass.fileOffset
        ;
    Procedure? constructorTearOff = createConstructorTearOffProcedure(
        new MemberName(libraryBuilder.libraryName, constructorTearOffName('')),
        libraryBuilder,
        enclosingClass.fileUri,
        enclosingClass.fileOffset,
        tearOffReference,
        forAbstractClassOrEnumOrMixin:
            enclosingClass.isAbstract || enclosingClass.isEnum);
    if (constructorTearOff != null) {
      DelayedDefaultValueCloner delayedDefaultValueCloner =
          buildConstructorTearOffProcedure(
              tearOff: constructorTearOff,
              declarationConstructor: constructor,
              implementationConstructor: constructor,
              enclosingDeclarationTypeParameters:
                  classBuilder.cls.typeParameters,
              libraryBuilder: libraryBuilder);
      registerDelayedDefaultValueCloner(delayedDefaultValueCloner);
    }
    return new SyntheticSourceConstructorBuilder(
        libraryBuilder, classBuilder, constructor, constructorTearOff);
  }

  DartType makeConstructorReturnType(Class enclosingClass) {
    List<DartType> typeParameterTypes = <DartType>[];
    for (int i = 0; i < enclosingClass.typeParameters.length; i++) {
      TypeParameter typeParameter = enclosingClass.typeParameters[i];
      typeParameterTypes
          .add(new TypeParameterType.withDefaultNullability(typeParameter));
    }
    return new InterfaceType(enclosingClass,
        enclosingClass.enclosingLibrary.nonNullable, typeParameterTypes);
  }

  void setupTopAndBottomTypes() {
    objectType.bind(
        loader.coreLibrary,
        loader.coreLibrary.lookupLocalMember("Object", required: true)
            as TypeDeclarationBuilder);
    dynamicType.bind(
        loader.coreLibrary,
        loader.coreLibrary.lookupLocalMember("dynamic", required: true)
            as TypeDeclarationBuilder);
    ClassBuilder nullClassBuilder = loader.coreLibrary
        .lookupLocalMember("Null", required: true) as ClassBuilder;
    nullType.bind(loader.coreLibrary, nullClassBuilder..isNullClass = true);
    bottomType.bind(
        loader.coreLibrary,
        loader.coreLibrary.lookupLocalMember("Never", required: true)
            as TypeDeclarationBuilder);
    enumType.bind(
        loader.coreLibrary,
        loader.coreLibrary.lookupLocalMember("Enum", required: true)
            as TypeDeclarationBuilder);
    underscoreEnumType.bind(
        loader.coreLibrary,
        loader.coreLibrary.lookupLocalMember("_Enum", required: true)
            as TypeDeclarationBuilder);
  }

  void computeCoreTypes() {
    List<Library> libraries = <Library>[];
    for (String platformLibrary in [
      "dart:_internal",
      "dart:async",
      "dart:core",
      "dart:mirrors",
      ...backendTarget.extraIndexedLibraries
    ]) {
      Uri uri = Uri.parse(platformLibrary);
      LibraryBuilder? libraryBuilder = loader.lookupLoadedLibraryBuilder(uri);
      if (libraryBuilder == null) {
        // TODO(ahe): This is working around a bug in kernel_driver_test or
        // kernel_driver.
        bool found = false;
        for (Library target in dillTarget.loader.libraries) {
          if (target.importUri == uri) {
            libraries.add(target);
            found = true;
            break;
          }
        }
        if (!found && uri.path != "mirrors") {
          // Coverage-ignore-block(suite): Not run.
          // dart:mirrors is optional.
          throw "Can't find $uri";
        }
      } else {
        libraries.add(libraryBuilder.library);
      }
    }
    Component platformLibraries =
        backendTarget.configureComponent(new Component());
    // Add libraries directly to prevent that their parents are changed.
    platformLibraries.libraries.addAll(libraries);
    loader.computeCoreTypes(platformLibraries);
  }

  void finishAllConstructors(
      List<SourceClassBuilder> sourceClassBuilders,
      List<SourceExtensionTypeDeclarationBuilder>
          sourceExtensionTypeDeclarationBuilders) {
    Class objectClass = this.objectClass;
    for (SourceClassBuilder builder in sourceClassBuilders) {
      Class cls = builder.cls;
      if (cls != objectClass) {
        finishConstructors(builder);
      }
    }
    for (SourceExtensionTypeDeclarationBuilder builder
        in sourceExtensionTypeDeclarationBuilders) {
      finishExtensionTypeConstructors(builder);
    }

    ticker.logMs("Finished constructors");
  }

  /// Ensure constructors of [classBuilder] have the correct initializers and
  /// other requirements.
  void finishConstructors(SourceClassBuilder classBuilder) {
    if (classBuilder.isAugmenting) return;
    Class cls = classBuilder.cls;

    Constructor? superTarget;
    for (Constructor constructor in cls.constructors) {
      if (constructor.isExternal) {
        continue;
      }
      bool isRedirecting = false;
      for (Initializer initializer in constructor.initializers) {
        if (initializer is RedirectingInitializer) {
          if (constructor.isConst && !initializer.target.isConst) {
            classBuilder.addProblem(
                messageConstConstructorRedirectionToNonConst,
                initializer.fileOffset,
                initializer.target.name.text.length);
          }
          isRedirecting = true;
          break;
        }
      }
      if (!isRedirecting) {
        /// >If no superinitializer is provided, an implicit superinitializer
        /// >of the form super() is added at the end of k’s initializer list,
        /// >unless the enclosing class is class Object.
        if (constructor.initializers.isEmpty) {
          superTarget ??= defaultSuperConstructor(cls);
          Initializer initializer;
          if (superTarget == null) {
            int offset = constructor.fileOffset;
            if (offset == -1 &&
                // Coverage-ignore(suite): Not run.
                constructor.isSynthetic) {
              // Coverage-ignore-block(suite): Not run.
              offset = cls.fileOffset;
            }
            classBuilder.addProblem(
                templateSuperclassHasNoDefaultConstructor
                    .withArguments(cls.superclass!.name),
                offset,
                noLength);
            initializer = new InvalidInitializer();
          } else {
            initializer =
                new SuperInitializer(superTarget, new Arguments.empty())
                  ..isSynthetic = true;
          }
          constructor.initializers.add(initializer);
          initializer.parent = constructor;
        }
        if (constructor.function.body == null) {
          // Coverage-ignore-block(suite): Not run.
          /// >If a generative constructor c is not a redirecting constructor
          /// >and no body is provided, then c implicitly has an empty body {}.
          /// We use an empty statement instead.
          constructor.function.body = new EmptyStatement()
            ..parent = constructor.function;
        }
      }
    }

    _finishConstructors(classBuilder);
  }

  void finishExtensionTypeConstructors(
      SourceExtensionTypeDeclarationBuilder extensionTypeDeclaration) {
    _finishConstructors(extensionTypeDeclaration);
  }

  void _finishConstructors(ClassDeclaration classDeclaration) {
    SourceLibraryBuilder libraryBuilder = classDeclaration.libraryBuilder;

    /// Quotes below are from [Dart Programming Language Specification, 4th
    /// Edition](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf):
    List<PropertyBuilder> uninitializedFields = [];
    List<PropertyBuilder> nonFinalFields = [];
    List<PropertyBuilder> lateFinalFields = [];

    Iterator<PropertyBuilder> fieldIterator =
        classDeclaration.fullMemberIterator<PropertyBuilder>();
    while (fieldIterator.moveNext()) {
      PropertyBuilder fieldBuilder = fieldIterator.current;
      if (!fieldBuilder.isField) {
        continue;
      }
      if (fieldBuilder.isAbstract || fieldBuilder.isExternal) {
        // Skip abstract and external fields. These are abstract/external
        // getters/setters and have no initialization.
        continue;
      }
      if (fieldBuilder.isDeclarationInstanceMember && !fieldBuilder.isFinal) {
        nonFinalFields.add(fieldBuilder);
      }
      if (fieldBuilder.isDeclarationInstanceMember &&
          fieldBuilder.isLate &&
          fieldBuilder.isFinal) {
        lateFinalFields.add(fieldBuilder);
      }
      if (!fieldBuilder.hasInitializer) {
        uninitializedFields.add(fieldBuilder);
      }
    }

    Map<ConstructorDeclaration, Set<PropertyBuilder>>
        constructorInitializedFields = new Map.identity();
    Set<PropertyBuilder>? initializedFieldBuilders = null;
    Set<PropertyBuilder>? uninitializedInstanceFields;

    Iterator<ConstructorDeclaration> constructorIterator =
        classDeclaration.fullConstructorIterator<ConstructorDeclaration>();
    while (constructorIterator.moveNext()) {
      ConstructorDeclaration constructor = constructorIterator.current;
      if (constructor.isEffectivelyRedirecting) continue;
      if (constructor.isConst && nonFinalFields.isNotEmpty) {
        classDeclaration.addProblem(messageConstConstructorNonFinalField,
            constructor.fileOffset, noLength,
            context: nonFinalFields
                .map((field) => messageConstConstructorNonFinalFieldCause
                    .withLocation(field.fileUri, field.fileOffset, noLength))
                .toList());
        nonFinalFields.clear();
      }
      if (constructor.isConst && lateFinalFields.isNotEmpty) {
        for (PropertyBuilder field in lateFinalFields) {
          classDeclaration.addProblem(
              messageConstConstructorLateFinalFieldError,
              field.fileOffset,
              noLength,
              context: [
                messageConstConstructorLateFinalFieldCause.withLocation(
                    constructor.fileUri, constructor.fileOffset, noLength)
              ]);
        }
        lateFinalFields.clear();
      }
      if (constructor.isEffectivelyExternal) {
        // Assume that an external constructor initializes all uninitialized
        // instance fields.
        uninitializedInstanceFields ??= uninitializedFields
            .where((PropertyBuilder fieldBuilder) => !fieldBuilder.isStatic)
            .toSet();
        constructorInitializedFields[constructor] = uninitializedInstanceFields;
        (initializedFieldBuilders ??= new Set<PropertyBuilder>.identity())
            .addAll(uninitializedInstanceFields);
      } else {
        Set<PropertyBuilder> fields =
            constructor.takeInitializedFields() ?? const {};
        constructorInitializedFields[constructor] = fields;
        (initializedFieldBuilders ??= new Set<PropertyBuilder>.identity())
            .addAll(fields);
      }
    }

    // Run through all fields that aren't initialized by any constructor, and
    // set their initializer to `null`.
    for (PropertyBuilder fieldBuilder in uninitializedFields) {
      if (fieldBuilder.isExtensionTypeDeclaredInstanceField) continue;
      if (initializedFieldBuilders == null ||
          !initializedFieldBuilders.contains(fieldBuilder)) {
        if (!fieldBuilder.isLate) {
          if (fieldBuilder.isFinal) {
            String uri = '${libraryBuilder.importUri}';
            String file = fieldBuilder.fileUri.pathSegments.last;
            if (uri == 'dart:html' ||
                uri == 'dart:svg' ||
                uri == 'dart:_native_typed_data' ||
                uri == 'dart:_interceptors' &&
                    // Coverage-ignore(suite): Not run.
                    file == 'js_string.dart') {
              // TODO(johnniwinther): Use external getters instead of final
              // fields. See https://github.com/dart-lang/sdk/issues/33762
            } else {
              libraryBuilder.addProblem(
                  templateFinalFieldNotInitialized
                      .withArguments(fieldBuilder.name),
                  fieldBuilder.fileOffset,
                  fieldBuilder.name.length,
                  fieldBuilder.fileUri);
            }
          } else if (fieldBuilder.fieldType is! InvalidType &&
              fieldBuilder.fieldType.isPotentiallyNonNullable) {
            libraryBuilder.addProblem(
                templateFieldNonNullableWithoutInitializerError.withArguments(
                    fieldBuilder.name, fieldBuilder.fieldType),
                fieldBuilder.fileOffset,
                fieldBuilder.name.length,
                fieldBuilder.fileUri);
          }
          fieldBuilder.buildImplicitDefaultValue();
        }
      }
    }

    // Run through all fields that are initialized by some constructor, and
    // make sure that all other constructors also initialize them.
    for (MapEntry<ConstructorDeclaration, Set<PropertyBuilder>> entry
        in constructorInitializedFields.entries) {
      ConstructorDeclaration constructorBuilder = entry.key;
      Set<PropertyBuilder> fieldBuilders = entry.value;
      for (PropertyBuilder fieldBuilder
          in initializedFieldBuilders!.difference(fieldBuilders)) {
        if (fieldBuilder.isExtensionTypeDeclaredInstanceField) continue;
        if (!fieldBuilder.hasInitializer && !fieldBuilder.isLate) {
          Initializer initializer = fieldBuilder.buildImplicitInitializer();
          constructorBuilder.prependInitializer(initializer);
          if (fieldBuilder.isFinal) {
            libraryBuilder.addProblem(
                templateFinalFieldNotInitializedByConstructor
                    .withArguments(fieldBuilder.name),
                constructorBuilder.fileOffset,
                constructorBuilder.name.length,
                constructorBuilder.fileUri,
                context: [
                  templateMissingImplementationCause
                      .withArguments(fieldBuilder.name)
                      .withLocation(fieldBuilder.fileUri,
                          fieldBuilder.fileOffset, fieldBuilder.name.length)
                ]);
          } else if (fieldBuilder.fieldType is! InvalidType &&
              !fieldBuilder.isLate &&
              fieldBuilder.fieldType.isPotentiallyNonNullable) {
            libraryBuilder.addProblem(
                templateFieldNonNullableNotInitializedByConstructorError
                    .withArguments(fieldBuilder.name, fieldBuilder.fieldType),
                constructorBuilder.fileOffset,
                noLength,
                constructorBuilder.fileUri,
                context: [
                  templateMissingImplementationCause
                      .withArguments(fieldBuilder.name)
                      .withLocation(fieldBuilder.fileUri,
                          fieldBuilder.fileOffset, fieldBuilder.name.length)
                ]);
          }
        }
      }
    }
  }

  Future<void> validateDynamicModule() async {
    final Uri? dynamicInterfaceSpecificationUri =
        _options.dynamicInterfaceSpecificationUri;
    if (dynamicInterfaceSpecificationUri != null) {
      final String? dynamicInterfaceSpecification =
          await _options.loadDynamicInterfaceSpecification();
      if (dynamicInterfaceSpecification != null) {
        dynamic_module_validator.validateDynamicModule(
            dynamicInterfaceSpecification,
            dynamicInterfaceSpecificationUri,
            component!,
            loader.hierarchy,
            loader.libraries,
            loader);
      }
    }
  }

  /// Run all transformations that are needed when building a bundle of
  /// libraries for the first time.
  void runBuildTransformations() {
    backendTarget.performPreConstantEvaluationTransformations(
        component!,
        loader.coreTypes,
        loader.libraries,
        new KernelDiagnosticReporter(loader),
        logger:
            // Coverage-ignore(suite): Not run.
            (String msg) => ticker.logMs(msg),
        changedStructureNotifier: changedStructureNotifier);

    TypeEnvironment environment =
        new TypeEnvironment(loader.coreTypes, loader.hierarchy);
    constants.EvaluationMode evaluationMode = _getConstantEvaluationMode();

    constants.ConstantEvaluationData constantEvaluationData =
        constants.transformLibraries(
            component!,
            loader.libraries,
            backendTarget,
            environmentDefines,
            environment,
            new KernelConstantErrorReporter(loader),
            evaluationMode,
            evaluateAnnotations: true,
            enableTripleShift: globalFeatures.tripleShift.isEnabled,
            enableConstFunctions: globalFeatures.constFunctions.isEnabled,
            enableConstructorTearOff:
                globalFeatures.constructorTearoffs.isEnabled,
            errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
            exhaustivenessDataForTesting: loader
                .dataForTesting
                // Coverage-ignore(suite): Not run.
                ?.exhaustivenessData);
    ticker.logMs("Evaluated constants");

    markLibrariesUsed(constantEvaluationData.visitedLibraries);

    constants.ConstantCoverage coverage = constantEvaluationData.coverage;
    coverage.constructorCoverage.forEach((Uri fileUri, Set<Reference> value) {
      Source? source = uriToSource[fileUri];
      if (source != null) {
        source.constantCoverageConstructors ??= new Set<Reference>();
        source.constantCoverageConstructors!.addAll(value);
      }
    });
    ticker.logMs("Added constant coverage");

    backendTarget.performModularTransformationsOnLibraries(
        component!,
        loader.coreTypes,
        loader.hierarchy,
        loader.libraries,
        environmentDefines,
        new KernelDiagnosticReporter(loader),
        loader.referenceFromIndex,
        logger: (String msg) => ticker.logMs(msg),
        changedStructureNotifier: changedStructureNotifier);
  }

  ChangedStructureNotifier? get changedStructureNotifier => null;

  // Coverage-ignore(suite): Not run.
  void runProcedureTransformations(Procedure procedure) {
    TypeEnvironment environment =
        new TypeEnvironment(loader.coreTypes, loader.hierarchy);
    constants.EvaluationMode evaluationMode = _getConstantEvaluationMode();

    constants.transformProcedure(
      procedure,
      backendTarget,
      component!,
      environmentDefines,
      environment,
      new KernelConstantErrorReporter(loader),
      evaluationMode,
      evaluateAnnotations: true,
      enableTripleShift: globalFeatures.tripleShift.isEnabled,
      enableConstFunctions: globalFeatures.constFunctions.isEnabled,
      enableConstructorTearOff: globalFeatures.constructorTearoffs.isEnabled,
      errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
    );
    ticker.logMs("Evaluated constants");

    backendTarget.performTransformationsOnProcedure(
        loader.coreTypes, loader.hierarchy, procedure, environmentDefines,
        logger: (String msg) => ticker.logMs(msg));
  }

  constants.EvaluationMode getConstantEvaluationModeForTesting() =>
      _getConstantEvaluationMode();

  constants.EvaluationMode _getConstantEvaluationMode() {
    // If nnbd is not enabled we will use weak evaluation mode. This is needed
    // because the SDK might be agnostic and therefore needs to be weakened
    // for legacy mode.
    assert(
        globalFeatures.nonNullable.isEnabled ||
            // Coverage-ignore(suite): Not run.
            loader.nnbdMode == NnbdMode.Weak,
        "Non-weak nnbd mode found without experiment enabled: "
        "${loader.nnbdMode}.");
    return constants.EvaluationMode.fromNnbdMode(loader.nnbdMode);
  }

  void _verify({required bool allowVerificationErrorForTesting}) {
    // TODO(ahe): How to handle errors.
    List<LocatedMessage> errors = verifyComponent(
        context, VerificationStage.afterModularTransformations, component!,
        skipPlatform: context.options.skipPlatformVerification);
    assert(
        allowVerificationErrorForTesting ||
            // Coverage-ignore(suite): Not run.
            errors.isEmpty,
        "Verification errors found: $errors");
    ClassHierarchy hierarchy =
        new ClassHierarchy(component!, new CoreTypes(component!),
            onAmbiguousSupertypes: (Class cls, Supertype a, Supertype b) {
      // An error has already been reported.
    });
    verifyGetStaticType(
        new TypeEnvironment(loader.coreTypes, hierarchy), component!,
        skipPlatform: context.options.skipPlatformVerification);
    ticker.logMs("Verified component");
  }

  // Coverage-ignore(suite): Not run.
  /// Return `true` if the given [library] was built by this [KernelTarget]
  /// from sources, and not loaded from a [DillTarget].
  /// Note that this is meant for debugging etc and that it is slow, each
  /// call takes O(# libraries).
  bool isSourceLibraryForDebugging(Library library) {
    return loader.libraries.contains(library);
  }

  void readPatchFiles(
      SourceCompilationUnit compilationUnit, Uri originImportUri) {
    assert(originImportUri.isScheme("dart"),
        "Unexpected origin import uri: $originImportUri");
    List<Uri>? patches = uriTranslator.getDartPatches(originImportUri.path);
    if (patches != null) {
      for (Uri patch in patches) {
        loader.read(patch, -1,
            fileUri: patch,
            originImportUri: originImportUri,
            origin: compilationUnit,
            accessor: compilationUnit,
            isPatch: true);
      }
    }
  }

  void releaseAncillaryResources() {
    component = null;
  }

  void markLibrariesUsed(Set<Library> visitedLibraries) {
    // Default implementation does nothing.
  }
}

/// Looks for a constructor call that matches `super()` from a constructor in
/// [cls]. Such a constructor may have optional arguments, but no required
/// arguments.
Constructor? defaultSuperConstructor(Class cls) {
  Class? superclass = cls.superclass;
  if (superclass != null) {
    for (Constructor constructor in superclass.constructors) {
      if (constructor.name.text.isEmpty) {
        return constructor.function.requiredParameterCount == 0
            ? constructor
            : null;
      }
    }
  }
  return null;
}

class KernelDiagnosticReporter
    extends DiagnosticReporter<Message, LocatedMessage> {
  final SourceLoader loader;

  KernelDiagnosticReporter(this.loader);

  @override
  void report(Message message, int charOffset, int length, Uri? fileUri,
      {List<LocatedMessage>? context}) {
    loader.addProblem(message, charOffset, noLength, fileUri, context: context);
  }
}

class BuildResult {
  final Component? component;
  final NeededPrecompilations? neededPrecompilations;
  final MacroApplications? macroApplications;

  BuildResult(
      {this.component, this.macroApplications, this.neededPrecompilations});
}

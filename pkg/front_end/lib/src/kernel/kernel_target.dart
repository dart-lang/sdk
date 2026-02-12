// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/messages/severity.dart'
    show CfeSeverity;
import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/reference_from_index.dart'
    show IndexedContainer, IndexedClass;
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
import '../base/messages.dart'
    show
        FormattedMessage,
        LocatedMessage,
        Message,
        noLength,
        CompilationPhaseForProblemReporting;
import '../base/processed_options.dart' show ProcessedOptions;
import '../base/ticker.dart' show Ticker;
import '../base/uri_offset.dart';
import '../base/uri_translator.dart' show UriTranslator;
import '../builder/builder.dart';
import '../builder/compilation_unit.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/method_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/property_builder.dart';
import '../builder/type_builder.dart';
import '../dill/dill_target.dart' show DillTarget;
import '../fragment/constructor/declaration.dart';
import '../source/name_scheme.dart';
import '../source/source_class_builder.dart' show SourceClassBuilder;
import '../source/source_constructor_builder.dart';
import '../source/source_declaration_builder.dart';
import '../source/source_extension_type_declaration_builder.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../source/source_loader.dart' show SourceLoader;
import '../source/source_property_builder.dart';
import '../type_inference/type_schema.dart';
import 'benchmarker.dart' show BenchmarkPhases, Benchmarker;
import 'cfe_verifier.dart' show verifyComponent, verifyGetStaticType;
import 'constant_evaluator.dart'
    as constants
    show
        transformLibraries,
        transformProcedure,
        ConstantCoverage,
        ConstantEvaluationData;
import 'constructor_tearoff_lowering.dart';
import 'dynamic_module_validator.dart' as dynamic_module_validator;
import 'kernel_constants.dart' show KernelConstantErrorReporter;
import 'kernel_helper.dart';
import 'utils.dart';

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
    const PredefinedTypeName("dynamic"),
    const NullabilityBuilder.inherent(),
    instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected,
  );

  final NamedTypeBuilder intType = new NamedTypeBuilderImpl(
    const PredefinedTypeName("int"),
    const NullabilityBuilder.omitted(),
    instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected,
  );

  final NamedTypeBuilder stringType = new NamedTypeBuilderImpl(
    const PredefinedTypeName("String"),
    const NullabilityBuilder.omitted(),
    instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected,
  );

  final NamedTypeBuilder objectType = new NamedTypeBuilderImpl(
    const PredefinedTypeName("Object"),
    const NullabilityBuilder.omitted(),
    instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected,
  );

  // Null is always nullable.
  // TODO(johnniwinther): This could (maybe) use a FixedTypeBuilder when we
  //  have NullType?
  final NamedTypeBuilder nullType = new NamedTypeBuilderImpl(
    const PredefinedTypeName("Null"),
    const NullabilityBuilder.inherent(),
    instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected,
  );

  // TODO(johnniwinther): Why isn't this using a FixedTypeBuilder?
  final NamedTypeBuilder bottomType = new NamedTypeBuilderImpl(
    const PredefinedTypeName("Never"),
    const NullabilityBuilder.omitted(),
    instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected,
  );

  final NamedTypeBuilder enumType = new NamedTypeBuilderImpl(
    const PredefinedTypeName("Enum"),
    const NullabilityBuilder.omitted(),
    instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected,
  );

  final NamedTypeBuilder underscoreEnumType = new NamedTypeBuilderImpl(
    const PredefinedTypeName("_Enum"),
    const NullabilityBuilder.omitted(),
    instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected,
  );

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

  MemberBuilder? _cachedNativeAnnotation;

  final ProcessedOptions _options;

  final Benchmarker? benchmarker;

  KernelTarget(
    this.context,
    this.fileSystem,
    this.includeComments,
    DillTarget dillTarget,
    this.uriTranslator,
  ) : dillTarget = dillTarget,
      backendTarget = dillTarget.backendTarget,
      _options = context.options,
      ticker = dillTarget.ticker,
      benchmarker = dillTarget.benchmarker {
    assert(_options.haveBeenValidated, "Options have not been validated");
    loader = createLoader();
  }

  GlobalFeatures get globalFeatures => _options.globalFeatures;

  bool isExperimentEnabledInLibraryByVersion(
    ExperimentalFlag flag,
    Uri importUri,
    Version version,
  ) {
    return _options.isExperimentEnabledInLibraryByVersion(
      flag,
      importUri,
      version,
    );
  }

  Uri? translateUri(Uri uri) => uriTranslator.translate(uri);

  /// Returns a reference to the constructor used for creating `native`
  /// annotations. The constructor is expected to accept a single argument of
  /// type String, which is the name of the native method.
  MemberBuilder getNativeAnnotation(SourceLoader loader) {
    if (_cachedNativeAnnotation != null) return _cachedNativeAnnotation!;
    LibraryBuilder internal = loader.lookupLoadedLibraryBuilder(
      Uri.parse("dart:_internal"),
    )!;
    return _cachedNativeAnnotation = internal.getConstructor("ExternalName");
  }

  void loadExtraRequiredLibraries(SourceLoader loader) {
    for (String uri in backendTarget.extraRequiredLibraries) {
      loader.read(
        Uri.parse(uri),
        0,
        accessor: loader.coreLibraryCompilationUnit,
      );
    }
    if (context.compilingPlatform) {
      // Coverage-ignore-block(suite): Not run.
      for (String uri in backendTarget.extraRequiredLibrariesPlatform) {
        loader.read(
          Uri.parse(uri),
          0,
          accessor: loader.coreLibraryCompilationUnit,
        );
      }
    }
  }

  FormattedMessage createFormattedMessage(
    Message message,
    int charOffset,
    int length,
    Uri? fileUri,
    List<LocatedMessage>? messageContext,
    CfeSeverity severity, {
    List<Uri>? involvedFiles,
  }) {
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
      involvedFiles: involvedFiles,
    );
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
      _currentSdkVersion = new Version(
        int.tryParse(dotSeparatedParts[0])!,
        int.tryParse(dotSeparatedParts[1])!,
      );
      good = true;
    }
    if (!good) {
      throw new StateError(
        "Unparsable sdk version given: $currentSdkVersionString",
      );
    }
  }

  SourceLoader createLoader() =>
      new SourceLoader(fileSystem, includeComments, this);

  bool _hasAddedSources = false;

  void addSourceInformation(
    Uri importUri,
    Uri fileUri,
    List<int> lineStarts,
    Uint8List sourceCode,
  ) {
    Source source = new Source(lineStarts, sourceCode, importUri, fileUri);
    uriToSource[fileUri] = source;
    if (_hasAddedSources) {
      // Coverage-ignore-block(suite): Not run.
      // The sources have already been added to the component in [link] so we
      // have to add source directly here to create a consistent component.
      component?.uriToSource[fileUri] = excludeSource
          ? new Source.emptySource(
              source.lineStarts,
              source.importUri,
              source.fileUri,
            )
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
      loader.readAsEntryPoint(
        translatedEntryPoint,
        fileUri: translatedEntryPoint != entryPoint ? entryPoint : null,
      );
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
              "package:$packageName/${asString.substring(prefix.length)}",
            );
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

  // TODO(johnniwinther): Remove this.
  Future<void> computeNeededPrecompilations() async {
    assert(
      !_hasComputedNeededPrecompilations,
      "Needed precompilations have already been computed.",
    );
    _hasComputedNeededPrecompilations = true;
    if (loader.roots.isEmpty) return null;
    return await withCrashReporting<void>(() async {
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
      ?.enterPhase(BenchmarkPhases.unknownComputeNeededPrecompilations);
    }, () => loader.currentUriForCrashReporting);
  }

  // Coverage-ignore(suite): Not run.
  /// Builds [libraryBuilders] to the state expected after
  /// [SourceLoader.buildScopes].
  void buildSyntheticLibrariesUntilBuildScopes(
    Iterable<SourceLibraryBuilder> libraryBuilders,
  ) {
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
    Iterable<SourceLibraryBuilder> libraryBuilders,
  ) {
    loader.computeLibraryScopes(libraryBuilders);
    loader.resolveTypes(libraryBuilders);
    loader.computeSupertypes(libraryBuilders);
    loader.computeDefaultTypes(
      libraryBuilders,
      dynamicType,
      nullType,
      bottomType,
      objectClassBuilder,
    );
  }

  Future<BuildResult> buildOutlines({CanonicalName? nameRoot}) async {
    if (loader.roots.isEmpty) {
      // Coverage-ignore-block(suite): Not run.
      return new BuildResult();
    }
    return await withCrashReporting<BuildResult>(
      () async {
        if (!_hasComputedNeededPrecompilations) {
          // Coverage-ignore-block(suite): Not run.
          await computeNeededPrecompilations();
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
        ?.enterPhase(BenchmarkPhases.outline_computeSupertypes);
        loader.computeSupertypes(loader.sourceLibraryBuilders);

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_computeMacroApplications);

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_computeVariances);
        loader.computeVariances(loader.sourceLibraryBuilders);

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_computeDefaultTypes);
        loader.computeDefaultTypes(
          loader.sourceLibraryBuilders,
          dynamicType,
          nullType,
          bottomType,
          objectClassBuilder,
        );

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_checkSemantics);
        List<SourceClassBuilder>? sortedSourceClassBuilders;
        List<SourceExtensionTypeDeclarationBuilder>?
        sortedSourceExtensionTypeBuilders;
        (sortedSourceClassBuilders, sortedSourceExtensionTypeBuilders) = loader
            .checkClassCycles(objectClassBuilder);

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_finishTypeParameters);
        loader.finishTypeParameters(
          loader.sourceLibraryBuilders,
          objectClassBuilder,
          dynamicType,
        );

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
        component = link(
          new List<Library>.of(loader.libraries),
          nameRoot: nameRoot,
        );

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_computeCoreTypes);
        computeCoreTypes();

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_buildClassHierarchy);
        loader.buildClassHierarchy(
          sortedSourceClassBuilders,
          sortedSourceExtensionTypeBuilders,
          objectClassBuilder,
        );

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_checkSupertypes);
        loader.checkSupertypes(
          sortedSourceClassBuilders,
          sortedSourceExtensionTypeBuilders,
          objectClass,
          enumClass,
          underscoreEnumClass,
        );

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
          sortedSourceClassBuilders,
          sortedSourceExtensionTypeBuilders,
        );

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_computeHierarchy);
        loader.computeHierarchy();

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_installTypedefTearOffs);
        List<DelayedDefaultValueCloner>?
        typedefTearOffsDelayedDefaultValueCloners = loader
            .installTypedefTearOffs();
        typedefTearOffsDelayedDefaultValueCloners?.forEach(
          registerDelayedDefaultValueCloner,
        );

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_computeFieldPromotability);
        loader.computeFieldPromotability();

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_prepareTopLevelInference);
        loader.prepareTopLevelInference();

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(
          BenchmarkPhases.outline_performRedirectingFactoryInference,
        );
        // TODO(johnniwinther): Add an interface for registering delayed
        // actions.
        List<DelayedDefaultValueCloner> delayedDefaultValueCloners = [];
        loader.inferRedirectingFactories(delayedDefaultValueCloners);

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_computeMemberTypes);
        loader.computeMemberTypes();

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
          loader.hierarchy,
          delayedDefaultValueCloners,
        );
        delayedDefaultValueCloners.forEach(registerDelayedDefaultValueCloner);

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_checkTypes);
        loader.checkTypes();

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.outline_checkRedirectingFactories);
        loader.checkRedirectingFactories(
          sortedSourceClassBuilders,
          sortedSourceExtensionTypeBuilders,
        );

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
        loader.installAllProblemsIntoComponent(
          component!,
          currentPhase: CompilationPhaseForProblemReporting.outline,
        );

        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.unknownBuildOutlines);

        // For whatever reason sourceClassBuilders is kept alive for some amount
        // of time, meaning that all source library builders will be kept alive
        // (for whatever amount of time) even though we convert them to dill
        // library builders. To avoid it we null it out here.
        sortedSourceClassBuilders = null;

        return new BuildResult(component: component);
      }, // Coverage-ignore(suite): Not run.
      () => loader.currentUriForCrashReporting,
    );
  }

  /// Build the kernel representation of the component loaded by this
  /// target. The component will contain full bodies for the code loaded from
  /// sources, and only references to the code loaded by the [DillTarget],
  /// which may or may not include method bodies (depending on what was loaded
  /// into that target, an outline or a full kernel component).
  ///
  /// If [verify], run the default kernel verification on the resulting
  /// component.
  Future<BuildResult> buildComponent({
    bool verify = false,
    bool allowVerificationErrorForTesting = false,
  }) async {
    if (loader.roots.isEmpty) {
      // Coverage-ignore-block(suite): Not run.
      return new BuildResult();
    }
    return await withCrashReporting<BuildResult>(() async {
      ticker.logMs("Building component");

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

      if (verify) {
        benchmarker
        // Coverage-ignore(suite): Not run.
        ?.enterPhase(BenchmarkPhases.body_verify);
        _verify(
          allowVerificationErrorForTesting: allowVerificationErrorForTesting,
        );
      }

      benchmarker
      // Coverage-ignore(suite): Not run.
      ?.enterPhase(BenchmarkPhases.body_installAllComponentProblems);
      loader.installAllProblemsIntoComponent(
        component!,
        currentPhase: CompilationPhaseForProblemReporting.bodyBuilding,
      );

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

      return new BuildResult(component: component);
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
              source.lineStarts,
              source.importUri,
              source.fileUri,
            )
          : source;
    }

    this.uriToSource.forEach(copySource);
    _hasAddedSources = true;

    Component component = backendTarget.configureComponent(
      new Component(
        nameRoot: nameRoot,
        libraries: libraries,
        uriToSource: uriToSource,
      ),
    );

    Reference? mainReference;

    LibraryBuilder? firstRoot = loader.rootLibrary;
    if (firstRoot != null) {
      // TODO(sigmund): do only for full program
      Builder? declaration = firstRoot.exportNameSpace.lookup("main")?.getable;
      if (declaration is MethodBuilder) {
        mainReference = declaration.invokeTargetReference;
      }
    }
    component.setMainMethodAndMode(mainReference, true);

    ticker.logMs("Linked component");
    return component;
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
      if (builder.cls != objectClass) {
        if (builder.isMixinDeclaration) {
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
      constructorReference = indexedClass.lookupConstructorReference(
        new Name(""),
      );
      tearOffReference = indexedClass.lookupGetterReference(
        new Name(constructorTearOffName(""), indexedClass.library),
      );
    }

    /// From [Dart Programming Language Specification, 4th Edition](
    /// https://ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf):
    /// >Iff no constructor is specified for a class C, it implicitly has a
    /// >default constructor C() : super() {}, unless C is class Object.
    // The superinitializer is installed below in [finishConstructors].
    builder.addSyntheticConstructor(
      _makeDefaultConstructor(builder, constructorReference, tearOffReference),
    );
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
    TypeDeclarationBuilder? supertype = type?.computeUnaliasedDeclaration(
      isUsedAsClass: true,
    );
    if (supertype is SourceClassBuilder && supertype.isMixinApplication) {
      installForwardingConstructors(supertype);
    }

    IndexedContainer? indexedClass = builder.indexedClass;
    Reference? constructorReference;
    Reference? tearOffReference;
    if (indexedClass != null) {
      constructorReference = indexedClass.lookupConstructorReference(
        new Name(""),
      );
      tearOffReference = indexedClass.lookupGetterReference(
        new Name(constructorTearOffName(""), indexedClass.library),
      );
    }

    switch (supertype) {
      case ClassBuilder():
        ClassBuilder superclassBuilder = supertype;
        bool isConstructorAdded = false;
        Map<TypeParameter, DartType>? substitutionMap;

        Iterator<MemberBuilder> iterator = superclassBuilder
            .filteredConstructorsIterator(includeDuplicates: false);
        while (iterator.moveNext()) {
          MemberBuilder memberBuilder = iterator.current;
          String name = memberBuilder.name;
          if (memberBuilder.invokeTarget is Constructor) {
            substitutionMap ??= builder.getSubstitutionMap(
              superclassBuilder.cls,
            );
            if (indexedClass != null) {
              constructorReference = indexedClass.lookupConstructorReference(
                memberBuilder.invokeTarget!.name,
              );
              tearOffReference = indexedClass.lookupGetterReference(
                new Name(constructorTearOffName(name), indexedClass.library),
              );
            }
            builder.addSyntheticConstructor(
              _makeMixinApplicationConstructor(
                builder,
                builder.cls.mixin,
                memberBuilder,
                substitutionMap,
              ),
            );
            isConstructorAdded = true;
          }
        }

        if (!isConstructorAdded) {
          builder.addSyntheticConstructor(
            _makeDefaultConstructor(
              builder,
              constructorReference,
              tearOffReference,
            ),
          );
        }
      case TypeAliasBuilder():
      case NominalParameterBuilder():
      case StructuralParameterBuilder():
      case ExtensionBuilder():
      case ExtensionTypeDeclarationBuilder():
      case InvalidBuilder():
      case BuiltinTypeDeclarationBuilder():
      case null:
        builder.addSyntheticConstructor(
          _makeDefaultConstructor(
            builder,
            constructorReference,
            tearOffReference,
          ),
        );
    }
  }

  SourceConstructorBuilder _makeMixinApplicationConstructor(
    SourceClassBuilder classBuilder,
    Class mixin,
    MemberBuilder superConstructorBuilder,
    Map<TypeParameter, DartType> substitutionMap,
  ) {
    SourceLibraryBuilder libraryBuilder = classBuilder.libraryBuilder;
    Constructor superConstructor =
        superConstructorBuilder.invokeTarget as Constructor;
    Name name = superConstructor.name;

    IndexedClass? indexedClass = classBuilder.indexedClass;

    // If the name of the super constructor is private, we use the library name
    // of its enclosing library to ensure that both constructor and tear-off
    // are private wrt to the original library. Otherwise we use the library
    // name of the [libraryBuilder], since only the tear-off should be private.
    //
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
    LibraryName libraryName = name.isPrivate
        ? superConstructorBuilder.libraryBuilder.libraryName
        : libraryBuilder.libraryName;

    NameScheme nameScheme = new NameScheme(
      isInstanceMember: false,
      containerName: new ClassName(classBuilder.name),
      containerType: ContainerType.Class,
      libraryName: libraryName,
    );

    ConstructorReferences constructorReferences = new ConstructorReferences(
      name: superConstructorBuilder.name,
      nameScheme: nameScheme,
      indexedContainer: indexedClass,
      loader: loader,
      declarationBuilder: classBuilder,
    );

    bool hasTypeDependency = false;
    Substitution substitution = Substitution.fromMap(substitutionMap);

    VariableDeclaration copyFormal(VariableDeclaration formal) {
      VariableDeclaration copy = new VariableDeclaration(
        formal.name,
        isFinal: formal.isFinal,
        isConst: formal.isConst,
        isRequired: formal.isRequired,
        hasDeclaredInitializer: formal.hasDeclaredInitializer,
        type: const UnknownType(),
      );
      if (!hasTypeDependency && formal.type is! UnknownType) {
        copy.type = substitution.substituteType(formal.type);
      } else {
        hasTypeDependency = true;
      }
      return copy;
    }

    Class cls = classBuilder.cls;
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
      named.add(
        new NamedExpression(
          formal.name!,
          new VariableGet(namedParameters.last),
        ),
      );
    }
    FunctionNode function = new FunctionNode(
      new EmptyStatement(),
      positionalParameters: positionalParameters,
      namedParameters: namedParameters,
      requiredParameterCount: superConstructor.function.requiredParameterCount,
      returnType: makeConstructorReturnType(cls),
    );
    SuperInitializer initializer = new SuperInitializer(
      superConstructor,
      new Arguments(positional, named: named),
    );
    Constructor constructor = new Constructor(
      function,
      name: name,
      initializers: <Initializer>[initializer],
      isSynthetic: true,
      isConst: isConst,
      reference: constructorReferences.constructorReference,
      fileUri: cls.fileUri,
    )..fileOffset = cls.fileOffset
    // TODO(johnniwinther): Should we add file end offset to synthesized
    //  constructors?
    //..fileEndOffset = cls.fileOffset
    ;
    DelayedDefaultValueCloner delayedDefaultValueCloner =
        new DelayedDefaultValueCloner(
          superConstructor,
          constructor,
          libraryBuilder: libraryBuilder,
        );

    TypeDependency? typeDependency;
    if (hasTypeDependency) {
      typeDependency = new TypeDependency(
        constructor,
        superConstructor,
        substitution,
        copyReturnType: false,
      );
    }

    Procedure? constructorTearOff = createConstructorTearOffProcedure(
      new MemberName(libraryName, constructorTearOffName(name.text)),
      libraryBuilder,
      cls.fileUri,
      cls.fileOffset,
      constructorReferences.tearOffReference,
      forAbstractClassOrEnumOrMixin: classBuilder.isAbstract,
    );

    if (constructorTearOff != null) {
      DelayedDefaultValueCloner delayedDefaultValueCloner =
          buildConstructorTearOffProcedure(
            tearOff: constructorTearOff,
            declarationConstructor: constructor,
            implementationConstructor: constructor,
            enclosingDeclarationTypeParameters: classBuilder.cls.typeParameters,
            libraryBuilder: libraryBuilder,
          );
      registerDelayedDefaultValueCloner(delayedDefaultValueCloner);
    }
    ConstructorDeclaration declaration = new ForwardingConstructorDeclaration(
      constructor: constructor,
      constructorTearOff: constructorTearOff,
      // We pass on the original constructor and the cloned function nodes
      // to ensure that the default values are computed and cloned for the
      // outline. It is needed to make the default values a part of the
      // outline for const constructors, and additionally it is required
      // for a potential subclass using super initializing parameters that
      // will required the cloning of the default values.
      definingConstructor: superConstructorBuilder,
      delayedDefaultValueCloner: delayedDefaultValueCloner,
      typeDependency: typeDependency,
    );

    SourceConstructorBuilder constructorBuilder = new SourceConstructorBuilder(
      name: superConstructorBuilder.name,
      libraryBuilder: libraryBuilder,
      declarationBuilder: classBuilder,
      fileOffset: classBuilder.fileOffset,
      fileUri: classBuilder.fileUri,
      constructorReferences: constructorReferences,
      nameScheme: nameScheme,
      introductory: declaration,
      isConst: isConst,
    );

    loader.registerConstructorToBeInferred(
      new InferableConstructor(constructor, constructorBuilder),
    );
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
      DelayedDefaultValueCloner delayedDefaultValueCloner,
    ) {
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

  SourceConstructorBuilder _makeDefaultConstructor(
    SourceClassBuilder classBuilder,
    Reference? constructorReference,
    Reference? tearOffReference,
  ) {
    SourceLibraryBuilder libraryBuilder = classBuilder.libraryBuilder;

    IndexedClass? indexedClass = classBuilder.indexedClass;
    LibraryName libraryName = indexedClass != null
        ? new LibraryName(indexedClass.library.reference)
        : libraryBuilder.libraryName;

    Name name = new Name('');

    NameScheme nameScheme = new NameScheme(
      isInstanceMember: false,
      containerName: new ClassName(classBuilder.name),
      containerType: ContainerType.Class,
      libraryName: libraryName,
    );

    ConstructorReferences constructorReferences = new ConstructorReferences(
      name: name.text,
      nameScheme: nameScheme,
      indexedContainer: indexedClass,
      loader: loader,
      declarationBuilder: classBuilder,
    );

    Class enclosingClass = classBuilder.cls;
    Constructor constructor = new Constructor(
      new FunctionNode(
        new EmptyStatement(),
        returnType: makeConstructorReturnType(enclosingClass),
      ),
      name: name,
      isSynthetic: true,
      reference: constructorReferences.constructorReference,
      fileUri: enclosingClass.fileUri,
    )..fileOffset = enclosingClass.fileOffset
    // TODO(johnniwinther): Should we add file end offsets to synthesized
    //  constructors?
    //..fileEndOffset = enclosingClass.fileOffset
    ;
    Procedure? constructorTearOff = createConstructorTearOffProcedure(
      new MemberName(libraryBuilder.libraryName, constructorTearOffName('')),
      libraryBuilder,
      enclosingClass.fileUri,
      enclosingClass.fileOffset,
      constructorReferences.tearOffReference,
      forAbstractClassOrEnumOrMixin:
          enclosingClass.isAbstract || enclosingClass.isEnum,
    );
    if (constructorTearOff != null) {
      DelayedDefaultValueCloner delayedDefaultValueCloner =
          buildConstructorTearOffProcedure(
            tearOff: constructorTearOff,
            declarationConstructor: constructor,
            implementationConstructor: constructor,
            enclosingDeclarationTypeParameters: classBuilder.cls.typeParameters,
            libraryBuilder: libraryBuilder,
          );
      registerDelayedDefaultValueCloner(delayedDefaultValueCloner);
    }
    ConstructorDeclaration declaration = new DefaultConstructorDeclaration(
      constructor: constructor,
      constructorTearOff: constructorTearOff,
    );

    return new SourceConstructorBuilder(
      name: '',
      libraryBuilder: libraryBuilder,
      declarationBuilder: classBuilder,
      fileOffset: classBuilder.fileOffset,
      fileUri: classBuilder.fileUri,
      constructorReferences: constructorReferences,
      nameScheme: nameScheme,
      introductory: declaration,
      isConst: false,
    );
  }

  DartType makeConstructorReturnType(Class enclosingClass) {
    List<DartType> typeParameterTypes = <DartType>[];
    for (int i = 0; i < enclosingClass.typeParameters.length; i++) {
      TypeParameter typeParameter = enclosingClass.typeParameters[i];
      typeParameterTypes.add(
        new TypeParameterType.withDefaultNullability(typeParameter),
      );
    }
    return new InterfaceType(
      enclosingClass,
      enclosingClass.enclosingLibrary.nonNullable,
      typeParameterTypes,
    );
  }

  void setupTopAndBottomTypes() {
    LibraryBuilder coreLibrary = loader.coreLibrary;
    bindCoreType(coreLibrary, objectType);
    bindCoreType(coreLibrary, stringType);
    bindCoreType(coreLibrary, intType);
    bindCoreType(coreLibrary, dynamicType);
    bindCoreType(coreLibrary, nullType, isNullClass: true);
    bindCoreType(coreLibrary, bottomType);
    bindCoreType(coreLibrary, enumType);
    bindCoreType(coreLibrary, underscoreEnumType);
  }

  void computeCoreTypes() {
    List<Library> libraries = <Library>[];
    for (String platformLibrary in [
      "dart:_internal",
      "dart:async",
      "dart:core",
      "dart:mirrors",
      ...backendTarget.extraIndexedLibraries,
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
    Component platformLibraries = backendTarget.configureComponent(
      new Component(),
    );
    // Add libraries directly to prevent that their parents are changed.
    platformLibraries.libraries.addAll(libraries);
    loader.computeCoreTypes(platformLibraries);
  }

  void finishAllConstructors(
    List<SourceClassBuilder> sourceClassBuilders,
    List<SourceExtensionTypeDeclarationBuilder>
    sourceExtensionTypeDeclarationBuilders,
  ) {
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
    Class cls = classBuilder.cls;

    Constructor? superTarget;
    for (Constructor constructor in cls.constructors) {
      if (constructor.isExternal) {
        continue;
      }
      bool isRedirecting = false;
      for (Initializer initializer in constructor.initializers) {
        assert(
          initializer is! AuxiliaryInitializer,
          "Unexpected auxiliary initializer $initializer.",
        );
        if (initializer is RedirectingInitializer) {
          if (constructor.isConst && !initializer.target.isConst) {
            classBuilder.libraryBuilder.addProblem(
              diag.constConstructorRedirectionToNonConst,
              initializer.fileOffset,
              initializer.target.name.text.length,
              constructor.fileUri,
            );
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
            Uri fileUri = constructor.fileUri;
            if (offset == -1 &&
                // Coverage-ignore(suite): Not run.
                constructor.isSynthetic) {
              // Coverage-ignore-block(suite): Not run.
              offset = cls.fileOffset;
              fileUri = cls.fileUri;
            }
            Message message = diag.superclassHasNoDefaultConstructor
                .withArguments(className: cls.superclass!.name);
            classBuilder.libraryBuilder.addProblem(
              message,
              offset,
              noLength,
              fileUri,
            );
            String text = context
                .format(
                  message.withLocation(fileUri, offset, noLength),
                  CfeSeverity.error,
                )
                .plain;
            initializer = new InvalidInitializer(text);
          } else {
            initializer = new SuperInitializer(
              superTarget,
              new Arguments.empty(),
            )..isSynthetic = true;
          }
          constructor.initializers.add(initializer);
          initializer.parent = constructor;
        }
        if (constructor.function.body == null) {
          // Coverage-ignore-block(suite): Not run.
          /// >If a generative constructor c is not a redirecting constructor
          /// >and no body is provided, then c implicitly has an empty body {}.
          /// We use an empty statement instead.
          constructor.function.registerFunctionBody(new EmptyStatement());
        }
      }
    }

    _finishConstructors(classBuilder);
  }

  void finishExtensionTypeConstructors(
    SourceExtensionTypeDeclarationBuilder extensionTypeDeclaration,
  ) {
    _finishConstructors(extensionTypeDeclaration);
  }

  void _finishConstructors(SourceDeclarationBuilder classDeclaration) {
    SourceLibraryBuilder libraryBuilder = classDeclaration.libraryBuilder;

    /// Quotes below are from [Dart Programming Language Specification, 4th
    /// Edition](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf):
    List<SourcePropertyBuilder> uninitializedFields = [];
    List<SourcePropertyBuilder> nonFinalFields = [];
    List<SourcePropertyBuilder> lateFinalFields = [];
    List<SourcePropertyBuilder> nonLateClassInstanceFieldsWithInitializers = [];

    Iterator<SourcePropertyBuilder> fieldIterator = classDeclaration
        .filteredMembersIterator(includeDuplicates: false);
    while (fieldIterator.moveNext()) {
      SourcePropertyBuilder fieldBuilder = fieldIterator.current;
      if (!fieldBuilder.hasConcreteField) {
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
      if (classDeclaration is SourceClassBuilder &&
          fieldBuilder.isDeclarationInstanceMember &&
          !fieldBuilder.isLate &&
          fieldBuilder.hasInitializer) {
        nonLateClassInstanceFieldsWithInitializers.add(fieldBuilder);
      }
    }

    Map<SourceConstructorBuilder, Set<SourcePropertyBuilder>>
    constructorInitializedFields = new Map.identity();
    Set<SourcePropertyBuilder>? initializedFieldBuilders = null;
    Set<SourcePropertyBuilder>? uninitializedInstanceFields;

    Iterator<SourceConstructorBuilder> constructorIterator = classDeclaration
        .filteredConstructorsIterator(includeDuplicates: false);
    while (constructorIterator.moveNext()) {
      SourceConstructorBuilder constructor = constructorIterator.current;
      if (constructor.isEffectivelyRedirecting) continue;
      if (constructor.isConst && nonFinalFields.isNotEmpty) {
        classDeclaration.libraryBuilder.addProblem(
          classDeclaration.isEnum
              ? diag.enumConstructorNonFinalField
              : diag.constConstructorNonFinalField,
          constructor.fileOffset,
          noLength,
          constructor.fileUri,
          context: nonFinalFields
              .map(
                (field) => diag.constConstructorNonFinalFieldCause.withLocation(
                  field.fileUri,
                  field.fileOffset,
                  noLength,
                ),
              )
              .toList(),
        );
        nonFinalFields.clear();
      }
      if (constructor.isConst && lateFinalFields.isNotEmpty) {
        for (SourcePropertyBuilder field in lateFinalFields) {
          classDeclaration.libraryBuilder.addProblem2(
            diag.constConstructorLateFinalFieldError,
            field.fieldUriOffset!,
            context: [
              diag.constConstructorLateFinalFieldCause.withLocation(
                constructor.fileUri,
                constructor.fileOffset,
                noLength,
              ),
            ],
          );
        }
        lateFinalFields.clear();
      }
      if (constructor.isEffectivelyExternal) {
        // Assume that an external constructor initializes all uninitialized
        // instance fields.
        uninitializedInstanceFields ??= uninitializedFields
            .where(
              (SourcePropertyBuilder fieldBuilder) => !fieldBuilder.isStatic,
            )
            .toSet();
        constructorInitializedFields[constructor] = uninitializedInstanceFields;
        (initializedFieldBuilders ??= new Set<SourcePropertyBuilder>.identity())
            .addAll(uninitializedInstanceFields);
      } else {
        Set<SourcePropertyBuilder> fields =
            constructor.takeInitializedFields() ?? const {};
        constructorInitializedFields[constructor] = fields;
        (initializedFieldBuilders ??= new Set<SourcePropertyBuilder>.identity())
            .addAll(fields);
      }
      if (constructor.isPrimaryConstructor) {
        // We prepend the initializers in reversed order to preserve normal
        // field initializer evaluation order.
        for (SourcePropertyBuilder field
            in nonLateClassInstanceFieldsWithInitializers.reversed) {
          constructor.prependInitializer(
            field.takePrimaryConstructorFieldInitializer(),
          );
        }
        if (classDeclaration is SourceClassBuilder) {
          Iterator<SourceConstructorBuilder> otherConstructorIterator =
              classDeclaration.filteredConstructorsIterator(
                includeDuplicates: false,
              );
          while (otherConstructorIterator.moveNext()) {
            SourceConstructorBuilder otherConstructor =
                otherConstructorIterator.current;
            if (constructor != otherConstructor &&
                !otherConstructor.isEffectivelyRedirecting) {
              classDeclaration.libraryBuilder.addProblem(
                diag.nonRedirectingGenerativeConstructorWithPrimary,
                otherConstructor.fileOffset,
                noLength,
                otherConstructor.fileUri,
              );
            }
          }
        }
      }
    }

    // Run through all fields that aren't initialized by any constructor, and
    // set their initializer to `null`.
    for (SourcePropertyBuilder fieldBuilder in uninitializedFields) {
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
                diag.finalFieldNotInitialized.withArguments(
                  fieldName: fieldBuilder.name,
                ),
                fieldBuilder.fileOffset,
                fieldBuilder.name.length,
                fieldBuilder.fileUri,
              );
            }
          } else if (fieldBuilder.fieldType is! InvalidType &&
              fieldBuilder.fieldType.isPotentiallyNonNullable) {
            libraryBuilder.addProblem(
              diag.fieldNonNullableWithoutInitializerError.withArguments(
                fieldName: fieldBuilder.name,
                fieldType: fieldBuilder.fieldType,
              ),
              fieldBuilder.fileOffset,
              fieldBuilder.name.length,
              fieldBuilder.fileUri,
            );
          }
          fieldBuilder.buildImplicitDefaultValue();
        }
      }
    }

    // Run through all fields that are initialized by some constructor, and
    // make sure that all other constructors also initialize them.
    for (MapEntry<SourceConstructorBuilder, Set<SourcePropertyBuilder>> entry
        in constructorInitializedFields.entries) {
      SourceConstructorBuilder constructorBuilder = entry.key;
      Set<SourcePropertyBuilder> fieldBuilders = entry.value;
      bool hasReportedErrors = false;
      for (SourcePropertyBuilder fieldBuilder
          in initializedFieldBuilders!.difference(fieldBuilders)) {
        if (fieldBuilder.isExtensionTypeDeclaredInstanceField) continue;
        if (!fieldBuilder.hasInitializer && !fieldBuilder.isLate) {
          Initializer initializer = fieldBuilder.buildImplicitInitializer();
          constructorBuilder.prependInitializer(initializer);
          if (fieldBuilder.isFinal) {
            // Avoid cascading error if the constructor is known to be
            // erroneous: such constructors don't initialize the final fields
            // properly.
            if (!constructorBuilder.invokeTarget.isErroneous) {
              libraryBuilder.addProblem(
                diag.finalFieldNotInitializedByConstructor.withArguments(
                  fieldName: fieldBuilder.name,
                ),
                constructorBuilder.fileOffset,
                constructorBuilder.name.length,
                constructorBuilder.fileUri,
                context: [
                  diag.missingImplementationCause
                      .withArguments(name: fieldBuilder.name)
                      .withLocation(
                        fieldBuilder.fileUri,
                        fieldBuilder.fileOffset,
                        fieldBuilder.name.length,
                      ),
                ],
              );
              hasReportedErrors = true;
            }
          } else if (fieldBuilder.fieldType is! InvalidType &&
              !fieldBuilder.isLate &&
              fieldBuilder.fieldType.isPotentiallyNonNullable) {
            libraryBuilder.addProblem(
              diag.fieldNonNullableNotInitializedByConstructorError
                  .withArguments(
                    fieldName: fieldBuilder.name,
                    fieldType: fieldBuilder.fieldType,
                  ),
              constructorBuilder.fileOffset,
              noLength,
              constructorBuilder.fileUri,
              context: [
                diag.missingImplementationCause
                    .withArguments(name: fieldBuilder.name)
                    .withLocation(
                      fieldBuilder.fileUri,
                      fieldBuilder.fileOffset,
                      fieldBuilder.name.length,
                    ),
              ],
            );
            hasReportedErrors = true;
          }
        }
      }

      if (hasReportedErrors) {
        constructorBuilder.markAsErroneous();
      }
    }
  }

  Future<void> validateDynamicModule() async {
    final Uri? dynamicInterfaceSpecificationUri =
        _options.dynamicInterfaceSpecificationUri;
    if (dynamicInterfaceSpecificationUri != null) {
      final String? dynamicInterfaceSpecification = await _options
          .loadDynamicInterfaceSpecification();
      if (dynamicInterfaceSpecification != null) {
        dynamic_module_validator.validateDynamicModule(
          dynamicInterfaceSpecification,
          dynamicInterfaceSpecificationUri,
          component!,
          loader.coreTypes,
          loader.hierarchy,
          loader.libraries,
          loader,
        );
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
      changedStructureNotifier: changedStructureNotifier,
    );

    TypeEnvironment environment = new TypeEnvironment(
      loader.coreTypes,
      loader.hierarchy,
    );

    constants.ConstantEvaluationData constantEvaluationData = constants
        .transformLibraries(
          component!,
          loader.libraries,
          backendTarget,
          environmentDefines,
          environment,
          new KernelConstantErrorReporter(loader),
          evaluateAnnotations: true,
          enableTripleShift: globalFeatures.tripleShift.isEnabled,
          enableConstFunctions: globalFeatures.constFunctions.isEnabled,
          enableConstructorTearOff:
              globalFeatures.constructorTearoffs.isEnabled,
          errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
          exhaustivenessDataForTesting: loader
              .dataForTesting
              // Coverage-ignore(suite): Not run.
              ?.exhaustivenessData,
        );
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
      changedStructureNotifier: changedStructureNotifier,
    );
  }

  ChangedStructureNotifier? get changedStructureNotifier => null;

  // Coverage-ignore(suite): Not run.
  void runProcedureTransformations(Procedure procedure) {
    TypeEnvironment environment = new TypeEnvironment(
      loader.coreTypes,
      loader.hierarchy,
    );
    constants.transformProcedure(
      procedure,
      backendTarget,
      component!,
      environmentDefines,
      environment,
      new KernelConstantErrorReporter(loader),
      evaluateAnnotations: true,
      enableTripleShift: globalFeatures.tripleShift.isEnabled,
      enableConstFunctions: globalFeatures.constFunctions.isEnabled,
      enableConstructorTearOff: globalFeatures.constructorTearoffs.isEnabled,
      errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
    );
    ticker.logMs("Evaluated constants");

    backendTarget.performTransformationsOnProcedure(
      loader.coreTypes,
      loader.hierarchy,
      procedure,
      environmentDefines,
      logger: (String msg) => ticker.logMs(msg),
    );
  }

  void _verify({required bool allowVerificationErrorForTesting}) {
    // TODO(ahe): How to handle errors.
    List<LocatedMessage> errors = verifyComponent(
      context,
      VerificationStage.afterModularTransformations,
      component!,
      skipPlatform: context.options.skipPlatformVerification,
    );
    assert(
      allowVerificationErrorForTesting ||
          // Coverage-ignore(suite): Not run.
          errors.isEmpty,
      "Verification errors found: $errors",
    );
    ClassHierarchy hierarchy = new ClassHierarchy(
      component!,
      new CoreTypes(component!),
      onAmbiguousSupertypes: (Class cls, Supertype a, Supertype b) {
        // An error has already been reported.
      },
    );
    verifyGetStaticType(
      new TypeEnvironment(loader.coreTypes, hierarchy),
      component!,
      skipPlatform: context.options.skipPlatformVerification,
    );
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
    SourceCompilationUnit compilationUnit,
    Uri originImportUri,
  ) {
    assert(
      originImportUri.isScheme("dart"),
      "Unexpected origin import uri: $originImportUri",
    );
    List<Uri>? patches = uriTranslator.getDartPatches(originImportUri.path);
    if (patches != null) {
      for (Uri patch in patches) {
        compilationUnit.registerAugmentation(
          loader.read(
            patch,
            -1,
            fileUri: patch,
            originImportUri: originImportUri,
            origin: compilationUnit,
            accessor: compilationUnit,
            isPatch: true,
          ),
        );
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
  void report(
    Message message,
    int charOffset,
    int length,
    Uri? fileUri, {
    List<LocatedMessage>? context,
  }) {
    loader.addProblem(message, charOffset, noLength, fileUri, context: context);
  }
}

class BuildResult {
  final Component? component;

  BuildResult({this.component});
}

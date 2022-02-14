// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_target;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/reference_from_index.dart' show IndexedClass;
import 'package:kernel/target/changed_structure_notifier.dart'
    show ChangedStructureNotifier;
import 'package:kernel/target/targets.dart' show DiagnosticReporter, Target;
import 'package:kernel/transformations/value_class.dart' as valueClass;
import 'package:kernel/type_algebra.dart' show Substitution;
import 'package:kernel/type_environment.dart' show TypeEnvironment;
import 'package:package_config/package_config.dart' hide LanguageVersion;

import '../../api_prototype/experimental_flags.dart' show ExperimentalFlag;
import '../../api_prototype/file_system.dart' show FileSystem;
import '../../base/nnbd_mode.dart';
import '../../base/processed_options.dart' show ProcessedOptions;
import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/dynamic_type_declaration_builder.dart';
import '../builder/field_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/never_type_declaration_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/type_variable_builder.dart';
import '../builder/void_type_declaration_builder.dart';
import '../compiler_context.dart' show CompilerContext;
import '../crash.dart' show withCrashReporting;
import '../dill/dill_target.dart' show DillTarget;
import '../kernel/constructor_tearoff_lowering.dart';
import '../loader.dart' show Loader;
import '../messages.dart'
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
import '../problems.dart' show unhandled;
import '../scope.dart' show AmbiguousBuilder;
import '../source/name_scheme.dart';
import '../source/source_class_builder.dart' show SourceClassBuilder;
import '../source/source_constructor_builder.dart';
import '../source/source_field_builder.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../source/source_loader.dart' show SourceLoader;
import '../target_implementation.dart' show TargetImplementation;
import '../ticker.dart' show Ticker;
import '../type_inference/type_schema.dart';
import '../uri_translator.dart' show UriTranslator;
import 'benchmarker.dart' show BenchmarkPhases, Benchmarker;
import 'constant_evaluator.dart' as constants
    show
        EvaluationMode,
        transformLibraries,
        transformProcedure,
        ConstantCoverage,
        ConstantEvaluationData;
import 'kernel_constants.dart' show KernelConstantErrorReporter;
import 'kernel_helper.dart';
import 'macro.dart';
import 'verifier.dart' show verifyComponent, verifyGetStaticType;

class KernelTarget extends TargetImplementation {
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
  final TypeBuilder dynamicType = new NamedTypeBuilder(
      "dynamic",
      const NullabilityBuilder.inherent(),
      /* arguments = */ null,
      /* fileUri = */ null,
      /* charOffset = */ null,
      instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);

  final NamedTypeBuilder objectType = new NamedTypeBuilder(
      "Object",
      const NullabilityBuilder.omitted(),
      /* arguments = */ null,
      /* fileUri = */ null,
      /* charOffset = */ null,
      instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);

  // Null is always nullable.
  // TODO(johnniwinther): This could (maybe) use a FixedTypeBuilder when we
  //  have NullType?
  final TypeBuilder nullType = new NamedTypeBuilder(
      "Null",
      const NullabilityBuilder.inherent(),
      /* arguments = */ null,
      /* fileUri = */ null,
      /* charOffset = */ null,
      instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);

  // TODO(johnniwinther): Why isn't this using a FixedTypeBuilder?
  final TypeBuilder bottomType = new NamedTypeBuilder(
      "Never",
      const NullabilityBuilder.omitted(),
      /* arguments = */ null,
      /* fileUri = */ null,
      /* charOffset = */ null,
      instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);

  final NamedTypeBuilder enumType = new NamedTypeBuilder(
      "Enum",
      const NullabilityBuilder.omitted(),
      /* arguments = */ null,
      /* fileUri = */ null,
      /* charOffset = */ null,
      instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);

  final NamedTypeBuilder underscoreEnumType = new NamedTypeBuilder(
      "_Enum",
      const NullabilityBuilder.omitted(),
      /* arguments = */ null,
      /* fileUri = */ null,
      /* charOffset = */ null,
      instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);

  final bool excludeSource = !CompilerContext.current.options.embedSourceText;

  final Map<String, String>? environmentDefines =
      CompilerContext.current.options.environmentDefines;

  final bool errorOnUnevaluatedConstant =
      CompilerContext.current.options.errorOnUnevaluatedConstant;

  final List<SynthesizedFunctionNode> synthesizedFunctionNodes =
      <SynthesizedFunctionNode>[];

  final UriTranslator uriTranslator;

  @override
  final Target backendTarget;

  @override
  final CompilerContext context = CompilerContext.current;

  /// Shared with [CompilerContext].
  final Map<Uri, Source> uriToSource = CompilerContext.current.uriToSource;

  MemberBuilder? _cachedAbstractClassInstantiationError;
  MemberBuilder? _cachedCompileTimeError;
  MemberBuilder? _cachedDuplicatedFieldInitializerError;
  MemberBuilder? _cachedNativeAnnotation;

  final ProcessedOptions _options;

  final Benchmarker? benchmarker;

  KernelTarget(this.fileSystem, this.includeComments, DillTarget dillTarget,
      this.uriTranslator)
      : dillTarget = dillTarget,
        backendTarget = dillTarget.backendTarget,
        _options = CompilerContext.current.options,
        ticker = dillTarget.ticker,
        benchmarker = dillTarget.benchmarker {
    loader = createLoader();
  }

  bool isExperimentEnabledInLibrary(ExperimentalFlag flag, Uri importUri) {
    return _options.isExperimentEnabledInLibrary(flag, importUri);
  }

  Version getExperimentEnabledVersionInLibrary(
      ExperimentalFlag flag, Uri importUri) {
    return _options.getExperimentEnabledVersionInLibrary(flag, importUri);
  }

  bool isExperimentEnabledInLibraryByVersion(
      ExperimentalFlag flag, Uri importUri, Version version) {
    return _options.isExperimentEnabledInLibraryByVersion(
        flag, importUri, version);
  }

  /// Returns `true` if the [flag] is enabled by default.
  bool isExperimentEnabledByDefault(ExperimentalFlag flag) {
    return _options.isExperimentEnabledByDefault(flag);
  }

  /// Returns `true` if the [flag] is enabled globally.
  ///
  /// This is `true` either if the [flag] is passed through an explicit
  /// `--enable-experiment` option or if the [flag] is expired and on by
  /// default.
  bool isExperimentEnabledGlobally(ExperimentalFlag flag) {
    return _options.isExperimentEnabledGlobally(flag);
  }

  Uri? translateUri(Uri uri) => uriTranslator.translate(uri);

  /// Returns a reference to the constructor of
  /// `AbstractClassInstantiationError` error.  The constructor is expected to
  /// accept a single argument of type String, which is the name of the
  /// abstract class.
  // TODO: Use some other error before `AbstractClassInstantiationError`
  // is removed.
  MemberBuilder getAbstractClassInstantiationError(Loader loader) {
    return _cachedAbstractClassInstantiationError ??=
        loader.coreLibrary.getConstructor("AbstractClassInstantiationError");
  }

  /// Returns a reference to the constructor used for creating a compile-time
  /// error. The constructor is expected to accept a single argument of type
  /// String, which is the compile-time error message.
  MemberBuilder getCompileTimeError(Loader loader) {
    return _cachedCompileTimeError ??= loader.coreLibrary
        .getConstructor("_CompileTimeError", bypassLibraryPrivacy: true);
  }

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
    LibraryBuilder internal = loader.read(Uri.parse("dart:_internal"), -1,
        accessor: loader.coreLibrary);
    return _cachedNativeAnnotation = internal.getConstructor("ExternalName");
  }

  void loadExtraRequiredLibraries(SourceLoader loader) {
    for (String uri in backendTarget.extraRequiredLibraries) {
      loader.read(Uri.parse(uri), 0, accessor: loader.coreLibrary);
    }
    if (context.compilingPlatform) {
      for (String uri in backendTarget.extraRequiredLibrariesPlatform) {
        loader.read(Uri.parse(uri), 0, accessor: loader.coreLibrary);
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
        fileUri != null
            ? message.withLocation(fileUri, charOffset, length)
            : message.withoutLocation(),
        severity,
        messageContext,
        involvedFiles: involvedFiles);
  }

  String get currentSdkVersionString {
    return CompilerContext.current.options.currentSdkVersion;
  }

  Version? _currentSdkVersion;

  Version get currentSdkVersion {
    if (_currentSdkVersion == null) {
      _parseCurrentSdkVersion();
    }
    return _currentSdkVersion!;
  }

  void _parseCurrentSdkVersion() {
    bool good = false;
    // ignore: unnecessary_null_comparison
    if (currentSdkVersionString != null) {
      List<String> dotSeparatedParts = currentSdkVersionString.split(".");
      if (dotSeparatedParts.length >= 2) {
        _currentSdkVersion = new Version(int.tryParse(dotSeparatedParts[0])!,
            int.tryParse(dotSeparatedParts[1])!);
        good = true;
      }
    }
    if (!good) {
      throw new StateError(
          "Unparsable sdk version given: $currentSdkVersionString");
    }
  }

  SourceLoader createLoader() =>
      new SourceLoader(fileSystem, includeComments, this);

  void addSourceInformation(
      Uri importUri, Uri fileUri, List<int> lineStarts, List<int> sourceCode) {
    uriToSource[fileUri] =
        new Source(lineStarts, sourceCode, importUri, fileUri);
  }

  /// Return list of same size as input with possibly translated uris.
  List<Uri> setEntryPoints(List<Uri> entryPoints) {
    List<Uri> result = <Uri>[];
    for (Uri entryPoint in entryPoints) {
      Uri translatedEntryPoint =
          getEntryPointUri(entryPoint, issueProblem: true);
      result.add(translatedEntryPoint);
      loader.readAsEntryPoint(translatedEntryPoint,
          fileUri: translatedEntryPoint != entryPoint ? entryPoint : null);
    }
    return result;
  }

  /// Return list of same size as input with possibly translated uris.
  Uri getEntryPointUri(Uri entryPoint, {bool issueProblem: false}) {
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
            packageUri = packageUri.removeFragment();
          }
          String prefix = "${packageUri}";
          if (asString.startsWith(prefix)) {
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

  /// The class [cls] is involved in a cyclic definition. This method should
  /// ensure that the cycle is broken, for example, by removing superclass and
  /// implemented interfaces.
  void breakCycle(ClassBuilder builder) {
    Class cls = builder.cls;
    cls.implementedTypes.clear();
    cls.supertype = null;
    cls.mixedInType = null;
    builder.supertypeBuilder = new NamedTypeBuilder(
        "Object",
        const NullabilityBuilder.omitted(),
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null,
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected)
      ..bind(objectClassBuilder);
    builder.interfaceBuilders = null;
    builder.mixedInTypeBuilder = null;
  }

  bool _hasComputedNeededPrecompilations = false;

  Future<NeededPrecompilations?> computeNeededPrecompilations() async {
    assert(!_hasComputedNeededPrecompilations,
        "Needed precompilations have already been computed.");
    _hasComputedNeededPrecompilations = true;
    if (loader.first == null) return null;
    return withCrashReporting<NeededPrecompilations?>(() async {
      benchmarker?.enterPhase(BenchmarkPhases.outline_kernelBuildOutlines);
      await loader.buildOutlines();

      benchmarker?.enterPhase(BenchmarkPhases.outline_becomeCoreLibrary);
      loader.coreLibrary.becomeCoreLibrary();

      benchmarker?.enterPhase(BenchmarkPhases.outline_resolveParts);
      loader.resolveParts();

      benchmarker?.enterPhase(BenchmarkPhases.outline_computeMacroDeclarations);
      NeededPrecompilations? result = loader.computeMacroDeclarations();

      benchmarker?.enterPhase(BenchmarkPhases.unknown);
      return result;
    }, () => loader.currentUriForCrashReporting);
  }

  Future<BuildResult> buildOutlines({CanonicalName? nameRoot}) async {
    if (loader.first == null) return new BuildResult();
    return withCrashReporting<BuildResult>(() async {
      if (!_hasComputedNeededPrecompilations) {
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

      benchmarker?.enterPhase(BenchmarkPhases.outline_computeLibraryScopes);
      loader.computeLibraryScopes();

      benchmarker?.enterPhase(BenchmarkPhases.outline_computeMacroApplications);
      MacroApplications? macroApplications =
          await loader.computeMacroApplications();

      benchmarker?.enterPhase(BenchmarkPhases.outline_setupTopAndBottomTypes);
      setupTopAndBottomTypes();

      benchmarker?.enterPhase(BenchmarkPhases.outline_resolveTypes);
      loader.resolveTypes();

      benchmarker?.enterPhase(BenchmarkPhases.outline_computeVariances);
      loader.computeVariances();

      benchmarker?.enterPhase(BenchmarkPhases.outline_computeDefaultTypes);
      loader.computeDefaultTypes(
          dynamicType, nullType, bottomType, objectClassBuilder);

      if (macroApplications != null) {
        benchmarker?.enterPhase(BenchmarkPhases.outline_applyTypeMacros);
        await macroApplications.applyTypeMacros();
      }

      benchmarker?.enterPhase(BenchmarkPhases.outline_checkSemantics);
      List<SourceClassBuilder>? sourceClassBuilders =
          loader.checkSemantics(objectClassBuilder);

      benchmarker?.enterPhase(BenchmarkPhases.outline_finishTypeVariables);
      loader.finishTypeVariables(objectClassBuilder, dynamicType);

      benchmarker
          ?.enterPhase(BenchmarkPhases.outline_createTypeInferenceEngine);
      loader.createTypeInferenceEngine();

      benchmarker?.enterPhase(BenchmarkPhases.outline_buildComponent);
      loader.buildComponent();

      benchmarker?.enterPhase(BenchmarkPhases.outline_installDefaultSupertypes);
      installDefaultSupertypes();

      benchmarker
          ?.enterPhase(BenchmarkPhases.outline_installSyntheticConstructors);
      installSyntheticConstructors(sourceClassBuilders);

      benchmarker?.enterPhase(BenchmarkPhases.outline_resolveConstructors);
      loader.resolveConstructors();

      benchmarker?.enterPhase(BenchmarkPhases.outline_link);
      component =
          link(new List<Library>.of(loader.libraries), nameRoot: nameRoot);

      benchmarker?.enterPhase(BenchmarkPhases.outline_computeCoreTypes);
      computeCoreTypes();

      benchmarker?.enterPhase(BenchmarkPhases.outline_buildClassHierarchy);
      loader.buildClassHierarchy(sourceClassBuilders, objectClassBuilder);

      benchmarker?.enterPhase(BenchmarkPhases.outline_checkSupertypes);
      loader.checkSupertypes(sourceClassBuilders, enumClass);

      if (macroApplications != null) {
        benchmarker?.enterPhase(BenchmarkPhases.outline_applyDeclarationMacros);
        await macroApplications
            .applyDeclarationsMacros(loader.hierarchyBuilder);
      }

      benchmarker
          ?.enterPhase(BenchmarkPhases.outline_buildClassHierarchyMembers);
      loader.buildClassHierarchyMembers(sourceClassBuilders);

      benchmarker?.enterPhase(BenchmarkPhases.outline_computeHierarchy);
      loader.computeHierarchy();

      benchmarker?.enterPhase(BenchmarkPhases.outline_computeShowHideElements);
      loader.computeShowHideElements();

      benchmarker?.enterPhase(BenchmarkPhases.outline_installTypedefTearOffs);
      loader.installTypedefTearOffs();

      benchmarker?.enterPhase(BenchmarkPhases.outline_performTopLevelInference);
      loader.performTopLevelInference(sourceClassBuilders);

      benchmarker?.enterPhase(BenchmarkPhases.outline_checkOverrides);
      loader.checkOverrides(sourceClassBuilders);

      benchmarker?.enterPhase(BenchmarkPhases.outline_checkAbstractMembers);
      loader.checkAbstractMembers(sourceClassBuilders);

      benchmarker
          ?.enterPhase(BenchmarkPhases.outline_addNoSuchMethodForwarders);
      loader.addNoSuchMethodForwarders(sourceClassBuilders);

      benchmarker?.enterPhase(BenchmarkPhases.outline_checkMixins);
      loader.checkMixins(sourceClassBuilders);

      benchmarker?.enterPhase(BenchmarkPhases.outline_buildOutlineExpressions);
      loader.buildOutlineExpressions(
          loader.hierarchy, synthesizedFunctionNodes);

      benchmarker?.enterPhase(BenchmarkPhases.outline_checkTypes);
      loader.checkTypes();

      benchmarker
          ?.enterPhase(BenchmarkPhases.outline_checkRedirectingFactories);
      loader.checkRedirectingFactories(sourceClassBuilders);

      benchmarker
          ?.enterPhase(BenchmarkPhases.outline_finishSynthesizedParameters);
      finishSynthesizedParameters(forOutline: true);

      benchmarker?.enterPhase(BenchmarkPhases.outline_checkMainMethods);
      loader.checkMainMethods();

      benchmarker
          ?.enterPhase(BenchmarkPhases.outline_installAllComponentProblems);
      installAllComponentProblems(loader.allComponentProblems);
      loader.allComponentProblems.clear();

      benchmarker?.enterPhase(BenchmarkPhases.unknown);

      // For whatever reason sourceClassBuilders is kept alive for some amount
      // of time, meaning that all source library builders will be kept alive
      // (for whatever amount of time) even though we convert them to dill
      // library builders. To avoid it we null it out here.
      sourceClassBuilders = null;

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
      bool verify: false}) async {
    if (loader.first == null) {
      return new BuildResult(macroApplications: macroApplications);
    }
    return withCrashReporting<BuildResult>(() async {
      ticker.logMs("Building component");

      benchmarker?.enterPhase(BenchmarkPhases.body_buildBodies);
      await loader.buildBodies();

      benchmarker?.enterPhase(BenchmarkPhases.body_finishSynthesizedParameters);
      finishSynthesizedParameters();

      benchmarker?.enterPhase(BenchmarkPhases.body_finishDeferredLoadTearoffs);
      loader.finishDeferredLoadTearoffs();

      benchmarker
          ?.enterPhase(BenchmarkPhases.body_finishNoSuchMethodForwarders);
      loader.finishNoSuchMethodForwarders();

      benchmarker?.enterPhase(BenchmarkPhases.body_collectSourceClasses);
      List<SourceClassBuilder>? sourceClasses = loader.collectSourceClasses();

      if (macroApplications != null) {
        benchmarker?.enterPhase(BenchmarkPhases.body_applyDefinitionMacros);
        await macroApplications.applyDefinitionMacros();
      }

      benchmarker?.enterPhase(BenchmarkPhases.body_finishNativeMethods);
      loader.finishNativeMethods();

      benchmarker?.enterPhase(BenchmarkPhases.body_finishPatchMethods);
      loader.finishPatchMethods();

      benchmarker?.enterPhase(BenchmarkPhases.body_finishAllConstructors);
      finishAllConstructors(sourceClasses);

      benchmarker?.enterPhase(BenchmarkPhases.body_runBuildTransformations);
      runBuildTransformations();

      if (verify) {
        benchmarker?.enterPhase(BenchmarkPhases.body_verify);
        this.verify();
      }

      benchmarker?.enterPhase(BenchmarkPhases.body_installAllComponentProblems);
      installAllComponentProblems(loader.allComponentProblems);

      benchmarker?.enterPhase(BenchmarkPhases.unknown);

      // For whatever reason sourceClasses is kept alive for some amount
      // of time, meaning that all source library builders will be kept alive
      // (for whatever amount of time) even though we convert them to dill
      // library builders. To avoid it we null it out here.
      sourceClasses = null;
      return new BuildResult(
          component: component, macroApplications: macroApplications);
    }, () => loader.currentUriForCrashReporting);
  }

  void installAllComponentProblems(
      List<FormattedMessage> allComponentProblems) {
    if (allComponentProblems.isNotEmpty) {
      component!.problemsAsJson ??= <String>[];
    }
    for (int i = 0; i < allComponentProblems.length; i++) {
      FormattedMessage formattedMessage = allComponentProblems[i];
      component!.problemsAsJson!.add(formattedMessage.toJsonString());
    }
  }

  /// Creates a component by combining [libraries] with the libraries of
  /// `dillTarget.loader.component`.
  Component link(List<Library> libraries, {CanonicalName? nameRoot}) {
    libraries.addAll(dillTarget.loader.libraries);

    Map<Uri, Source> uriToSource = new Map<Uri, Source>();
    void copySource(Uri uri, Source source) {
      uriToSource[uri] = excludeSource
          ? new Source(source.lineStarts, const <int>[], source.importUri,
              source.fileUri)
          : source;
    }

    this.uriToSource.forEach(copySource);

    Component component = backendTarget.configureComponent(new Component(
        nameRoot: nameRoot, libraries: libraries, uriToSource: uriToSource));

    NonNullableByDefaultCompiledMode? compiledMode = null;
    if (isExperimentEnabledGlobally(ExperimentalFlag.nonNullable)) {
      switch (loader.nnbdMode) {
        case NnbdMode.Weak:
          compiledMode = NonNullableByDefaultCompiledMode.Weak;
          break;
        case NnbdMode.Strong:
          compiledMode = NonNullableByDefaultCompiledMode.Strong;
          break;
        case NnbdMode.Agnostic:
          compiledMode = NonNullableByDefaultCompiledMode.Agnostic;
          break;
      }
    } else {
      compiledMode = NonNullableByDefaultCompiledMode.Weak;
    }
    if (loader.hasInvalidNnbdModeLibrary) {
      compiledMode = NonNullableByDefaultCompiledMode.Invalid;
    }

    Reference? mainReference;

    if (loader.first != null) {
      // TODO(sigmund): do only for full program
      Builder? declaration =
          loader.first!.exportScope.lookup("main", -1, loader.first!.fileUri);
      if (declaration is AmbiguousBuilder) {
        AmbiguousBuilder problem = declaration;
        declaration = problem.getFirstDeclaration();
      }
      if (declaration is ProcedureBuilder) {
        mainReference = declaration.procedure.reference;
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
                  NonNullableByDefaultCompiledMode.Strong &&
              library.nonNullableByDefaultCompiledMode !=
                  NonNullableByDefaultCompiledMode.Agnostic) {
            return "Expected library ${library.importUri} to be strong or "
                "agnostic, but was ${library.nonNullableByDefaultCompiledMode}";
          }
        } else if (component.mode == NonNullableByDefaultCompiledMode.Weak) {
          if (library.nonNullableByDefaultCompiledMode !=
                  NonNullableByDefaultCompiledMode.Weak &&
              library.nonNullableByDefaultCompiledMode !=
                  NonNullableByDefaultCompiledMode.Agnostic) {
            return "Expected library ${library.importUri} to be weak or "
                "agnostic, but was ${library.nonNullableByDefaultCompiledMode}";
          }
        } else if (component.mode ==
            NonNullableByDefaultCompiledMode.Agnostic) {
          if (library.nonNullableByDefaultCompiledMode !=
              NonNullableByDefaultCompiledMode.Agnostic) {
            return "Expected library ${library.importUri} to be agnostic, "
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
      if (builder.cls != objectClass && !builder.isPatch) {
        if (builder.isPatch ||
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

  /// If [builder] doesn't have a constructors, install the defaults.
  void installDefaultConstructor(SourceClassBuilder builder) {
    assert(!builder.isMixinApplication);
    assert(!builder.isExtension);
    // TODO(askesc): Make this check light-weight in the absence of patches.
    if (builder.cls.constructors.isNotEmpty) return;
    if (builder.cls.redirectingFactories.isNotEmpty) return;
    for (Procedure proc in builder.cls.procedures) {
      if (proc.isFactory) return;
    }

    IndexedClass? indexedClass = builder.referencesFromIndexed;
    Reference? constructorReference;
    Reference? tearOffReference;
    if (indexedClass != null) {
      constructorReference =
          indexedClass.lookupConstructorReference(new Name(""));
      tearOffReference = indexedClass.lookupGetterReference(
          constructorTearOffName("", indexedClass.library));
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
    if (builder.library.loader != loader) return;
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
    TypeDeclarationBuilder? supertype;
    if (type is NamedTypeBuilder) {
      supertype = type.declaration;
    } else {
      unhandled("${type.runtimeType}", "installForwardingConstructors",
          builder.charOffset, builder.fileUri);
    }
    if (supertype is TypeAliasBuilder) {
      TypeAliasBuilder aliasBuilder = supertype;
      NamedTypeBuilder namedBuilder = type;
      supertype = aliasBuilder.unaliasDeclaration(namedBuilder.arguments,
          isUsedAsClass: true,
          usedAsClassCharOffset: namedBuilder.charOffset,
          usedAsClassFileUri: namedBuilder.fileUri);
    }
    if (supertype is SourceClassBuilder && supertype.isMixinApplication) {
      installForwardingConstructors(supertype);
    }

    IndexedClass? indexedClass = builder.referencesFromIndexed;
    Reference? constructorReference;
    Reference? tearOffReference;
    if (indexedClass != null) {
      constructorReference =
          indexedClass.lookupConstructorReference(new Name(""));
      tearOffReference = indexedClass.lookupGetterReference(
          constructorTearOffName("", indexedClass.library));
    }

    if (supertype is ClassBuilder) {
      ClassBuilder superclassBuilder = supertype;
      bool isConstructorAdded = false;
      Map<TypeParameter, DartType>? substitutionMap;

      void addSyntheticConstructor(String name, MemberBuilder memberBuilder) {
        if (memberBuilder.member is Constructor) {
          substitutionMap ??= builder.getSubstitutionMap(superclassBuilder.cls);
          Reference? constructorReference;
          Reference? tearOffReference;
          if (indexedClass != null) {
            constructorReference = indexedClass
                // We use the name of the member builder here since it refers to
                // the library of the original declaration when private. For
                // instance:
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
                .lookupConstructorReference(memberBuilder.member.name);
            tearOffReference = indexedClass.lookupGetterReference(
                constructorTearOffName(name, indexedClass.library));
          }
          builder.addSyntheticConstructor(_makeMixinApplicationConstructor(
              builder,
              builder.cls.mixin,
              memberBuilder as MemberBuilderImpl,
              substitutionMap!,
              constructorReference,
              tearOffReference));
          isConstructorAdded = true;
        }
      }

      superclassBuilder.forEachConstructor(addSyntheticConstructor,
          includeInjectedConstructors: true);

      if (!isConstructorAdded) {
        builder.addSyntheticConstructor(_makeDefaultConstructor(
            builder, constructorReference, tearOffReference));
      }
    } else if (supertype is InvalidTypeDeclarationBuilder ||
        supertype is TypeVariableBuilder ||
        supertype is DynamicTypeDeclarationBuilder ||
        supertype is VoidTypeDeclarationBuilder ||
        supertype is NeverTypeDeclarationBuilder ||
        supertype is TypeAliasBuilder) {
      builder.addSyntheticConstructor(_makeDefaultConstructor(
          builder, constructorReference, tearOffReference));
    } else {
      unhandled("${supertype.runtimeType}", "installForwardingConstructors",
          builder.charOffset, builder.fileUri);
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
          type: const UnknownType());
      if (!hasTypeDependency && formal.type is! UnknownType) {
        copy.type = substitution.substituteType(formal.type);
      } else {
        hasTypeDependency = true;
      }
      return copy;
    }

    Class cls = classBuilder.cls;
    Constructor superConstructor =
        superConstructorBuilder.member as Constructor;
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
    SynthesizedFunctionNode synthesizedFunctionNode =
        new SynthesizedFunctionNode(
            substitutionMap, superConstructor.function, function);
    if (!isConst) {
      // For constant constructors default values are computed and cloned part
      // of the outline expression and therefore passed to the
      // [SyntheticConstructorBuilder] below.
      //
      // For non-constant constructors default values are cloned as part of the
      // full compilation using [synthesizedFunctionNodes].
      synthesizedFunctionNodes.add(synthesizedFunctionNode);
    }
    Constructor constructor = new Constructor(function,
        name: superConstructor.name,
        initializers: <Initializer>[initializer],
        isSynthetic: true,
        isConst: isConst,
        reference: constructorReference,
        fileUri: cls.fileUri)
      // TODO(johnniwinther): Should we add file offsets to synthesized
      //  constructors?
      //..fileOffset = cls.fileOffset
      //..fileEndOffset = cls.fileOffset
      ..isNonNullableByDefault = cls.enclosingLibrary.isNonNullableByDefault;

    if (hasTypeDependency) {
      loader.registerTypeDependency(
          constructor,
          new TypeDependency(constructor, superConstructor, substitution,
              copyReturnType: false));
    }

    Procedure? constructorTearOff = createConstructorTearOffProcedure(
        superConstructor.name.text,
        classBuilder.library,
        cls.fileUri,
        cls.fileOffset,
        tearOffReference,
        forAbstractClassOrEnum: classBuilder.isAbstract);

    if (constructorTearOff != null) {
      buildConstructorTearOffProcedure(constructorTearOff, constructor,
          classBuilder.cls, classBuilder.library);
    }
    return new SyntheticSourceConstructorBuilder(
        classBuilder, constructor, constructorTearOff,
        // We pass on the original constructor and the cloned function nodes to
        // ensure that the default values are computed and cloned for the
        // outline. It is needed to make the default values a part of the
        // outline for const constructors, and additionally it is required for
        // a potential subclass using super initializing parameters that will
        // required the cloning of the default values.
        origin: superConstructorBuilder,
        synthesizedFunctionNode: synthesizedFunctionNode);
  }

  void finishSynthesizedParameters({bool forOutline = false}) {
    for (SynthesizedFunctionNode synthesizedFunctionNode
        in synthesizedFunctionNodes) {
      if (!forOutline || synthesizedFunctionNode.isOutlineNode) {
        synthesizedFunctionNode.cloneDefaultValues();
      }
    }
    if (!forOutline) {
      synthesizedFunctionNodes.clear();
    }
    ticker.logMs("Cloned default values of formals");
  }

  SyntheticSourceConstructorBuilder _makeDefaultConstructor(
      SourceClassBuilder classBuilder,
      Reference? constructorReference,
      Reference? tearOffReference) {
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
      ..isNonNullableByDefault =
          enclosingClass.enclosingLibrary.isNonNullableByDefault;
    Procedure? constructorTearOff = createConstructorTearOffProcedure(
        '',
        classBuilder.library,
        enclosingClass.fileUri,
        enclosingClass.fileOffset,
        tearOffReference,
        forAbstractClassOrEnum:
            enclosingClass.isAbstract || enclosingClass.isEnum);
    if (constructorTearOff != null) {
      buildConstructorTearOffProcedure(constructorTearOff, constructor,
          classBuilder.cls, classBuilder.library);
    }
    return new SyntheticSourceConstructorBuilder(
        classBuilder, constructor, constructorTearOff);
  }

  DartType makeConstructorReturnType(Class enclosingClass) {
    List<DartType> typeParameterTypes = <DartType>[];
    for (int i = 0; i < enclosingClass.typeParameters.length; i++) {
      TypeParameter typeParameter = enclosingClass.typeParameters[i];
      typeParameterTypes.add(
          new TypeParameterType.withDefaultNullabilityForLibrary(
              typeParameter, enclosingClass.enclosingLibrary));
    }
    return new InterfaceType(enclosingClass,
        enclosingClass.enclosingLibrary.nonNullable, typeParameterTypes);
  }

  void setupTopAndBottomTypes() {
    objectType.bind(loader.coreLibrary
        .lookupLocalMember("Object", required: true) as TypeDeclarationBuilder);
    dynamicType.bind(
        loader.coreLibrary.lookupLocalMember("dynamic", required: true)
            as TypeDeclarationBuilder);
    ClassBuilder nullClassBuilder = loader.coreLibrary
        .lookupLocalMember("Null", required: true) as ClassBuilder;
    nullType.bind(nullClassBuilder..isNullClass = true);
    bottomType.bind(loader.coreLibrary
        .lookupLocalMember("Never", required: true) as TypeDeclarationBuilder);
    enumType.bind(loader.coreLibrary.lookupLocalMember("Enum", required: true)
        as TypeDeclarationBuilder);
    underscoreEnumType.bind(loader.coreLibrary
        .lookupLocalMember("_Enum", required: true) as TypeDeclarationBuilder);
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
      LibraryBuilder? libraryBuilder = loader.lookupLibraryBuilder(uri);
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

  void finishAllConstructors(List<SourceClassBuilder> builders) {
    Class objectClass = this.objectClass;
    for (SourceClassBuilder builder in builders) {
      Class cls = builder.cls;
      if (cls != objectClass) {
        finishConstructors(builder);
      }
    }
    ticker.logMs("Finished constructors");
  }

  /// Ensure constructors of [builder] have the correct initializers and other
  /// requirements.
  void finishConstructors(SourceClassBuilder builder) {
    if (builder.isPatch) return;
    Class cls = builder.cls;

    /// Quotes below are from [Dart Programming Language Specification, 4th
    /// Edition](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf):
    List<SourceFieldBuilder> uninitializedFields = [];
    List<SourceFieldBuilder> nonFinalFields = [];
    List<SourceFieldBuilder> lateFinalFields = [];

    builder
        .forEachDeclaredField((String name, SourceFieldBuilder fieldBuilder) {
      if (fieldBuilder.isAbstract || fieldBuilder.isExternal) {
        // Skip abstract and external fields. These are abstract/external
        // getters/setters and have no initialization.
        return;
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
        // In case of duplicating fields the earliest ones (those that
        // declared towards the beginning of the file) come last in the list.
        // To report errors on the first definition of a field, we need to
        // iterate until that last element.
        SourceFieldBuilder earliest = fieldBuilder;
        Builder current = fieldBuilder;
        while (current.next != null) {
          current = current.next!;
          if (current is SourceFieldBuilder && !fieldBuilder.hasInitializer) {
            earliest = current;
          }
        }
        uninitializedFields.add(earliest);
      }
    });

    Constructor? superTarget;
    // In the underlying Kernel IR the patches are already applied, so
    // cls.constructors should contain both constructors from the original
    // declaration and the constructors from the patch.  The assert checks that
    // it's so.
    assert(() {
      Set<String> patchConstructorNames = {};
      builder.forEachDeclaredConstructor(
          (String name, ConstructorBuilder constructorBuilder) {
        // Don't add the default constructor's name.
        if (name.isNotEmpty) {
          patchConstructorNames.add(name);
        }
      });
      builder.constructors.forEach((String name, Builder builder) {
        if (builder is ConstructorBuilder) {
          patchConstructorNames.remove(name);
        }
      });
      Set<String> kernelConstructorNames =
          cls.constructors.map((c) => c.name.text).toSet().difference({""});
      return kernelConstructorNames.containsAll(patchConstructorNames);
    }(),
        "Constructors of class '${builder.fullNameForErrors}' "
        "aren't fully patched.");
    for (Constructor constructor in cls.constructors) {
      bool isRedirecting = false;
      for (Initializer initializer in constructor.initializers) {
        if (initializer is RedirectingInitializer) {
          if (constructor.isConst && !initializer.target.isConst) {
            builder.addProblem(messageConstConstructorRedirectionToNonConst,
                initializer.fileOffset, initializer.target.name.text.length);
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
            if (offset == -1 && constructor.isSynthetic) {
              offset = cls.fileOffset;
            }
            builder.addProblem(
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
          /// >If a generative constructor c is not a redirecting constructor
          /// >and no body is provided, then c implicitly has an empty body {}.
          /// We use an empty statement instead.
          constructor.function.body = new EmptyStatement()
            ..parent = constructor.function;
        }

        if (constructor.isConst && nonFinalFields.isNotEmpty) {
          builder.addProblem(messageConstConstructorNonFinalField,
              constructor.fileOffset, noLength,
              context: nonFinalFields
                  .map((field) => messageConstConstructorNonFinalFieldCause
                      .withLocation(field.fileUri, field.charOffset, noLength))
                  .toList());
          nonFinalFields.clear();
        }
        SourceLibraryBuilder library = builder.library;
        if (library.isNonNullableByDefault) {
          if (constructor.isConst && lateFinalFields.isNotEmpty) {
            for (FieldBuilder field in lateFinalFields) {
              builder.addProblem(messageConstConstructorLateFinalFieldError,
                  field.charOffset, noLength,
                  context: [
                    messageConstConstructorLateFinalFieldCause.withLocation(
                        constructor.fileUri, constructor.fileOffset, noLength)
                  ]);
            }
            lateFinalFields.clear();
          }
        }
      }
    }

    Map<ConstructorBuilder, Set<SourceFieldBuilder>>
        constructorInitializedFields = new Map.identity();
    Set<SourceFieldBuilder>? initializedFields = null;

    builder.forEachDeclaredConstructor(
        (String name, DeclaredSourceConstructorBuilder constructorBuilder) {
      if (constructorBuilder.isExternal) return;
      // In case of duplicating constructors the earliest ones (those that
      // declared towards the beginning of the file) come last in the list.
      // To report errors on the first definition of a constructor, we need to
      // iterate until that last element.
      DeclaredSourceConstructorBuilder earliest = constructorBuilder;
      Builder earliestBuilder = constructorBuilder;
      while (earliestBuilder.next != null) {
        earliestBuilder = earliestBuilder.next!;
        if (earliestBuilder is DeclaredSourceConstructorBuilder) {
          earliest = earliestBuilder;
        }
      }

      bool isRedirecting = false;
      for (Initializer initializer in earliest.constructor.initializers) {
        if (initializer is RedirectingInitializer) {
          isRedirecting = true;
        }
      }
      if (!isRedirecting) {
        Set<SourceFieldBuilder> fields =
            earliest.takeInitializedFields() ?? const {};
        constructorInitializedFields[earliest] = fields;
        (initializedFields ??= new Set<SourceFieldBuilder>.identity())
            .addAll(fields);
      }
    });

    // Run through all fields that aren't initialized by any constructor, and
    // set their initializer to `null`.
    for (SourceFieldBuilder fieldBuilder in uninitializedFields) {
      if (initializedFields == null ||
          !initializedFields!.contains(fieldBuilder)) {
        bool uninitializedFinalOrNonNullableFieldIsError =
            cls.enclosingLibrary.isNonNullableByDefault ||
                (cls.constructors.isNotEmpty || cls.isMixinDeclaration);
        if (!fieldBuilder.isLate) {
          if (fieldBuilder.isFinal &&
              uninitializedFinalOrNonNullableFieldIsError) {
            String uri = '${fieldBuilder.library.importUri}';
            String file = fieldBuilder.fileUri.pathSegments.last;
            if (uri == 'dart:html' ||
                uri == 'dart:svg' ||
                uri == 'dart:_native_typed_data' ||
                uri == 'dart:_interceptors' && file == 'js_string.dart') {
              // TODO(johnniwinther): Use external getters instead of final
              // fields. See https://github.com/dart-lang/sdk/issues/33762
            } else {
              builder.library.addProblem(
                  templateFinalFieldNotInitialized
                      .withArguments(fieldBuilder.name),
                  fieldBuilder.charOffset,
                  fieldBuilder.name.length,
                  fieldBuilder.fileUri);
            }
          } else if (fieldBuilder.fieldType is! InvalidType &&
              fieldBuilder.fieldType.isPotentiallyNonNullable &&
              uninitializedFinalOrNonNullableFieldIsError) {
            SourceLibraryBuilder library = builder.library;
            if (library.isNonNullableByDefault) {
              library.addProblem(
                  templateFieldNonNullableWithoutInitializerError.withArguments(
                      fieldBuilder.name,
                      fieldBuilder.fieldType,
                      library.isNonNullableByDefault),
                  fieldBuilder.charOffset,
                  fieldBuilder.name.length,
                  fieldBuilder.fileUri);
            }
          }
        }
      }
    }

    // Run through all fields that are initialized by some constructor, and
    // make sure that all other constructors also initialize them.
    constructorInitializedFields.forEach((ConstructorBuilder constructorBuilder,
        Set<FieldBuilder> fieldBuilders) {
      for (SourceFieldBuilder fieldBuilder
          in initializedFields!.difference(fieldBuilders)) {
        if (!fieldBuilder.hasInitializer && !fieldBuilder.isLate) {
          FieldInitializer initializer =
              new FieldInitializer(fieldBuilder.field, new NullLiteral())
                ..isSynthetic = true;
          initializer.parent = constructorBuilder.constructor;
          constructorBuilder.constructor.initializers.insert(0, initializer);
          if (fieldBuilder.isFinal) {
            builder.library.addProblem(
                templateFinalFieldNotInitializedByConstructor
                    .withArguments(fieldBuilder.name),
                constructorBuilder.charOffset,
                constructorBuilder.name.length,
                constructorBuilder.fileUri,
                context: [
                  templateMissingImplementationCause
                      .withArguments(fieldBuilder.name)
                      .withLocation(fieldBuilder.fileUri,
                          fieldBuilder.charOffset, fieldBuilder.name.length)
                ]);
          } else if (fieldBuilder.field.type is! InvalidType &&
              !fieldBuilder.isLate &&
              fieldBuilder.field.type.isPotentiallyNonNullable) {
            SourceLibraryBuilder library = builder.library;
            if (library.isNonNullableByDefault) {
              library.addProblem(
                  templateFieldNonNullableNotInitializedByConstructorError
                      .withArguments(fieldBuilder.name, fieldBuilder.field.type,
                          library.isNonNullableByDefault),
                  constructorBuilder.charOffset,
                  noLength,
                  constructorBuilder.fileUri,
                  context: [
                    templateMissingImplementationCause
                        .withArguments(fieldBuilder.name)
                        .withLocation(fieldBuilder.fileUri,
                            fieldBuilder.charOffset, fieldBuilder.name.length)
                  ]);
            }
          }
        }
      }
    });

    Set<Field>? initializedFieldsKernel = null;
    if (initializedFields != null) {
      for (FieldBuilder fieldBuilder in initializedFields!) {
        (initializedFieldsKernel ??= new Set<Field>.identity())
            .add(fieldBuilder.field);
      }
    }
    // In the underlying Kernel IR the patches are already applied, so
    // cls.fields should contain both fields from the original
    // declaration and the fields from the patch.  The assert checks that
    // it's so.
    assert(() {
      Set<String> patchFieldNames = {};
      builder
          .forEachDeclaredField((String name, SourceFieldBuilder fieldBuilder) {
        patchFieldNames.add(NameScheme.createFieldName(
          FieldNameType.Field,
          name,
          isInstanceMember: fieldBuilder.isClassInstanceMember,
          className: builder.name,
          isSynthesized: fieldBuilder.isLateLowered,
        ));
      });
      builder.forEach((String name, Builder builder) {
        if (builder is FieldBuilder) {
          patchFieldNames.remove(name);
        }
      });
      Set<String> kernelFieldNames = cls.fields.map((f) => f.name.text).toSet();
      return kernelFieldNames.containsAll(patchFieldNames);
    }(),
        "Fields of class '${builder.fullNameForErrors}' "
        "aren't fully patched.");
    for (Field field in cls.fields) {
      if (field.initializer == null &&
          !field.isLate &&
          (initializedFieldsKernel == null ||
              !initializedFieldsKernel.contains(field))) {
        field.initializer = new NullLiteral()..parent = field;
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
        logger: (String msg) => ticker.logMs(msg),
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
            enableTripleShift:
                isExperimentEnabledGlobally(ExperimentalFlag.tripleShift),
            enableConstFunctions:
                isExperimentEnabledGlobally(ExperimentalFlag.constFunctions),
            enableConstructorTearOff: isExperimentEnabledGlobally(
                ExperimentalFlag.constructorTearoffs),
            errorOnUnevaluatedConstant: errorOnUnevaluatedConstant);
    ticker.logMs("Evaluated constants");

    markLibrariesUsed(constantEvaluationData.visitedLibraries);

    constants.ConstantCoverage coverage = constantEvaluationData.coverage;
    coverage.constructorCoverage.forEach((Uri fileUri, Set<Reference> value) {
      Source? source = uriToSource[fileUri];
      // ignore: unnecessary_null_comparison
      if (source != null && fileUri != null) {
        source.constantCoverageConstructors ??= new Set<Reference>();
        source.constantCoverageConstructors!.addAll(value);
      }
    });
    ticker.logMs("Added constant coverage");

    if (loader.target.context.options
        .isExperimentEnabledGlobally(ExperimentalFlag.valueClass)) {
      valueClass.transformComponent(component!, loader.coreTypes,
          loader.hierarchy, loader.referenceFromIndex, environment);
      ticker.logMs("Lowered value classes");
    }

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
      enableTripleShift:
          isExperimentEnabledGlobally(ExperimentalFlag.tripleShift),
      enableConstFunctions:
          isExperimentEnabledGlobally(ExperimentalFlag.constFunctions),
      enableConstructorTearOff:
          isExperimentEnabledGlobally(ExperimentalFlag.constructorTearoffs),
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
    constants.EvaluationMode evaluationMode;
    // If nnbd is not enabled we will use weak evaluation mode. This is needed
    // because the SDK might be agnostic and therefore needs to be weakened
    // for legacy mode.
    assert(
        isExperimentEnabledGlobally(ExperimentalFlag.nonNullable) ||
            loader.nnbdMode == NnbdMode.Weak,
        "Non-weak nnbd mode found without experiment enabled: "
        "${loader.nnbdMode}.");
    switch (loader.nnbdMode) {
      case NnbdMode.Weak:
        evaluationMode = constants.EvaluationMode.weak;
        break;
      case NnbdMode.Strong:
        evaluationMode = constants.EvaluationMode.strong;
        break;
      case NnbdMode.Agnostic:
        evaluationMode = constants.EvaluationMode.agnostic;
        break;
    }
    return evaluationMode;
  }

  void verify() {
    // TODO(ahe): How to handle errors.
    verifyComponent(component!, context.options.target,
        skipPlatform: context.options.skipPlatformVerification);
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

  /// Return `true` if the given [library] was built by this [KernelTarget]
  /// from sources, and not loaded from a [DillTarget].
  /// Note that this is meant for debugging etc and that it is slow, each
  /// call takes O(# libraries).
  bool isSourceLibraryForDebugging(Library library) {
    return loader.libraries.contains(library);
  }

  void readPatchFiles(SourceLibraryBuilder library) {
    assert(library.importUri.isScheme("dart"));
    List<Uri>? patches = uriTranslator.getDartPatches(library.importUri.path);
    if (patches != null) {
      SourceLibraryBuilder? first;
      for (Uri patch in patches) {
        if (first == null) {
          first = library.loader.read(patch, -1,
              fileUri: patch,
              origin: library,
              accessor: library) as SourceLibraryBuilder;
        } else {
          // If there's more than one patch file, it's interpreted as a part of
          // the patch library.
          SourceLibraryBuilder part = library.loader.read(patch, -1,
              origin: library,
              fileUri: patch,
              accessor: library) as SourceLibraryBuilder;
          first.parts.add(part);
          first.partOffsets.add(-1);
          part.partOfUri = first.importUri;
        }
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

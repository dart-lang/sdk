// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the front-end API for converting source code to Dart Kernel objects.
library front_end.kernel_generator_impl;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/verifier.dart' show VerificationStage;
import 'package:macros/src/bootstrap.dart';
import 'package:macros/src/executor/kernel_executor.dart' as kernelExecutor;
import 'package:macros/src/executor/multi_executor.dart';
import 'package:macros/src/executor/serialization.dart';

import 'api_prototype/file_system.dart' show FileSystem;
import 'api_prototype/front_end.dart' show CompilerOptions, CompilerResult;
import 'api_prototype/kernel_generator.dart';
import 'api_prototype/memory_file_system.dart';
import 'base/compiler_context.dart' show CompilerContext;
import 'base/crash.dart' show withCrashReporting;
import 'base/hybrid_file_system.dart';
import 'base/instrumentation.dart';
import 'base/nnbd_mode.dart';
import 'base/processed_options.dart' show ProcessedOptions;
import 'base/uri_offset.dart';
import 'base/uri_translator.dart' show UriTranslator;
import 'codes/cfe_codes.dart' show LocatedMessage;
import 'dill/dill_target.dart' show DillTarget;
import 'kernel/benchmarker.dart' show BenchmarkPhases, Benchmarker;
import 'kernel/kernel_target.dart' show BuildResult, KernelTarget;
import 'kernel/macro/macro.dart';
import 'kernel/utils.dart' show printComponentText, serializeComponent;
import 'kernel/cfe_verifier.dart' show verifyComponent;
import 'macros/macro_target.dart'
    show MacroConfiguration, computeMacroConfiguration;
import 'source/source_loader.dart' show SourceLoader;

// Coverage-ignore(suite): Not run.
/// Implementation for the
/// `package:front_end/src/api_prototype/kernel_generator.dart` and
/// `package:front_end/src/api_prototype/summary_generator.dart` APIs.
Future<CompilerResult> generateKernel(ProcessedOptions options,
    {bool buildSummary = false,
    bool buildComponent = true,
    bool truncateSummary = false,
    bool includeOffsets = true,
    bool includeHierarchyAndCoreTypes = false}) async {
  return await CompilerContext.runWithOptions(options,
      (CompilerContext c) async {
    return await generateKernelInternal(c,
        buildSummary: buildSummary,
        buildComponent: buildComponent,
        truncateSummary: truncateSummary,
        includeOffsets: includeOffsets,
        includeHierarchyAndCoreTypes: includeHierarchyAndCoreTypes);
  });
}

/// Note that if [buildSummary] is true it will be default serialize the summary
/// but this can be disabled by setting [serializeIfBuildingSummary] to false.
Future<InternalCompilerResult> generateKernelInternal(
    CompilerContext compilerContext,
    {bool buildSummary = false,
    bool serializeIfBuildingSummary = true,
    bool buildComponent = true,
    bool truncateSummary = false,
    bool includeOffsets = true,
    bool includeHierarchyAndCoreTypes = false,
    bool retainDataForTesting = false,
    Benchmarker? benchmarker,
    Instrumentation? instrumentation,
    List<Component>? additionalDillsForTesting}) async {
  ProcessedOptions options = compilerContext.options;
  assert(options.haveBeenValidated, "Options have not been validated");

  options.reportNullSafetyCompilationModeInfo();
  FileSystem fs = options.fileSystem;

  SourceLoader? sourceLoader;
  return withCrashReporting<InternalCompilerResult>(() async {
    while (true) {
      // TODO(johnniwinther): How much can we reuse between iterations?
      UriTranslator uriTranslator = await options.getUriTranslator();

      DillTarget dillTarget = new DillTarget(
          compilerContext, options.ticker, uriTranslator, options.target,
          benchmarker: benchmarker);

      List<Component> loadedComponents = <Component>[];

      Component? sdkSummary = await options.loadSdkSummary(null);
      if (sdkSummary != null) {
        dillTarget.loader.appendLibraries(sdkSummary);
      }

      // By using the nameRoot of the summary, we enable sharing the
      // sdkSummary between multiple invocations.
      CanonicalName? nameRoot;
      if (additionalDillsForTesting != null) {
        for (Component additionalDill in additionalDillsForTesting) {
          loadedComponents.add(additionalDill);
          dillTarget.loader.appendLibraries(additionalDill);
        }
      } else if (options.hasAdditionalDills) {
        // Coverage-ignore-block(suite): Not run.
        nameRoot = sdkSummary?.root ?? new CanonicalName.root();
        for (Component additionalDill
            in await options.loadAdditionalDills(nameRoot)) {
          loadedComponents.add(additionalDill);
          dillTarget.loader.appendLibraries(additionalDill);
        }
      }

      dillTarget.buildOutlines();

      KernelTarget kernelTarget = new KernelTarget(
          compilerContext, fs, false, dillTarget, uriTranslator);
      sourceLoader = kernelTarget.loader;
      sourceLoader!.instrumentation = instrumentation;
      kernelTarget.setEntryPoints(options.inputs);
      NeededPrecompilations? neededPrecompilations =
          await kernelTarget.computeNeededPrecompilations();
      kernelTarget.benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.precompileMacros);
      Map<Uri, ExecutorFactoryToken>? precompiled =
          await precompileMacros(neededPrecompilations, options);
      if (precompiled != null) {
        // Coverage-ignore-block(suite): Not run.
        kernelTarget.benchmarker
            ?.enterPhase(BenchmarkPhases.unknownGenerateKernelInternal);
        continue;
      }
      kernelTarget.benchmarker
          // Coverage-ignore(suite): Not run.
          ?.enterPhase(BenchmarkPhases.unknownGenerateKernelInternal);
      return _buildInternal(compilerContext,
          options: options,
          kernelTarget: kernelTarget,
          nameRoot: nameRoot,
          sdkSummary: sdkSummary,
          loadedComponents: loadedComponents,
          buildSummary: buildSummary,
          serializeIfBuildingSummary: serializeIfBuildingSummary,
          truncateSummary: truncateSummary,
          buildComponent: buildComponent,
          includeOffsets: includeOffsets,
          includeHierarchyAndCoreTypes: includeHierarchyAndCoreTypes,
          retainDataForTesting: retainDataForTesting);
    }
  },
      // Coverage-ignore(suite): Not run.
      () =>
          sourceLoader?.currentUriForCrashReporting ??
          new UriOffset(options.inputs.first, TreeNode.noOffset));
}

Future<InternalCompilerResult> _buildInternal(CompilerContext compilerContext,
    {required ProcessedOptions options,
    required KernelTarget kernelTarget,
    required CanonicalName? nameRoot,
    required Component? sdkSummary,
    required List<Component> loadedComponents,
    required bool buildSummary,
    required bool serializeIfBuildingSummary,
    required bool truncateSummary,
    required bool buildComponent,
    required bool includeOffsets,
    required bool includeHierarchyAndCoreTypes,
    required bool retainDataForTesting}) async {
  BuildResult buildResult =
      await kernelTarget.buildOutlines(nameRoot: nameRoot);
  Component summaryComponent = buildResult.component!;
  List<int>? summary = null;
  if (buildSummary) {
    // Coverage-ignore-block(suite): Not run.
    if (options.verify) {
      List<LocatedMessage> errors = verifyComponent(
          compilerContext, VerificationStage.outline, summaryComponent);
      for (LocatedMessage error in errors) {
        options.report(compilerContext, error, Severity.error);
      }
      assert(errors.isEmpty, "Verification errors found.");
    }
    if (options.debugDump) {
      printComponentText(summaryComponent,
          libraryFilter: kernelTarget.isSourceLibraryForDebugging,
          showOffsets: options.debugDumpShowOffsets);
    }

    // Create the requested component ("truncating" or not).
    //
    // Note: we don't pass the library argument to the constructor to
    // preserve the libraries parent pointer (it should continue to point
    // to the component within KernelTarget).
    Component trimmedSummaryComponent =
        new Component(nameRoot: summaryComponent.root)
          ..libraries.addAll(truncateSummary
              ? kernelTarget.loader.libraries
              : summaryComponent.libraries);
    trimmedSummaryComponent.metadata.addAll(summaryComponent.metadata);
    trimmedSummaryComponent.uriToSource.addAll(summaryComponent.uriToSource);

    NonNullableByDefaultCompiledMode compiledMode =
        NonNullableByDefaultCompiledMode.Weak;
    switch (options.nnbdMode) {
      case NnbdMode.Weak:
        compiledMode = NonNullableByDefaultCompiledMode.Weak;
        break;
      case NnbdMode.Strong:
        compiledMode = NonNullableByDefaultCompiledMode.Strong;
        break;
    }
    if (kernelTarget.loader.hasInvalidNnbdModeLibrary) {
      compiledMode = NonNullableByDefaultCompiledMode.Invalid;
    }

    trimmedSummaryComponent.setMainMethodAndMode(
        trimmedSummaryComponent.mainMethodName, false, compiledMode);

    // As documented, we only run outline transformations when we are building
    // summaries without building a full component (at this time, that's
    // the only need we have for these transformations).
    if (!buildComponent) {
      options.target.performOutlineTransformations(trimmedSummaryComponent);
      options.ticker.logMs("Transformed outline");
    }
    if (serializeIfBuildingSummary) {
      // Don't include source (but do add it above to include importUris).
      summary = serializeComponent(trimmedSummaryComponent,
          includeSources: false, includeOffsets: includeOffsets);
    }
    options.ticker.logMs("Generated outline");
  }

  Component? component;
  if (buildComponent) {
    buildResult = await kernelTarget.buildComponent(
        macroApplications: buildResult.macroApplications,
        verify: options.verify);
    component = buildResult.component;
    if (options.debugDump) {
      // Coverage-ignore-block(suite): Not run.
      printComponentText(component,
          libraryFilter: kernelTarget.isSourceLibraryForDebugging,
          showOffsets: options.debugDumpShowOffsets);
    }
    options.ticker.logMs("Generated component");
  } else {
    component = summaryComponent;
  }
  // TODO(johnniwinther): Should we reuse the macro executor on subsequent
  // compilations where possible?
  buildResult.macroApplications
      // Coverage-ignore(suite): Not run.
      ?.close();

  return new InternalCompilerResult(
      summary: summary,
      component: component,
      sdkComponent: sdkSummary,
      loadedComponents: loadedComponents,
      classHierarchy:
          includeHierarchyAndCoreTypes ? kernelTarget.loader.hierarchy : null,
      coreTypes:
          includeHierarchyAndCoreTypes ? kernelTarget.loader.coreTypes : null,
      kernelTargetForTesting: retainDataForTesting ? kernelTarget : null);
}

/// Result object of [generateKernel].
class InternalCompilerResult implements CompilerResult {
  /// The generated summary bytes, if it was requested.
  @override
  final List<int>? summary;

  /// The generated component, if it was requested.
  @override
  final Component? component;

  @override
  final Component? sdkComponent;

  @override
  final List<Component> loadedComponents;

  @override
  final ClassHierarchy? classHierarchy;

  @override
  final CoreTypes? coreTypes;

  /// The [KernelTarget] used to generated the component.
  ///
  /// This is only provided for use in testing.
  final KernelTarget? kernelTargetForTesting;

  InternalCompilerResult(
      {this.summary,
      this.component,
      this.sdkComponent,
      required this.loadedComponents,
      this.classHierarchy,
      this.coreTypes,
      this.kernelTargetForTesting});
}

// Coverage-ignore(suite): Not run.
/// A fake absolute directory used as the root of a memory-file system in the
/// compilation below.
final Uri _defaultDir = Uri.parse('org-dartlang-macro:///a/b/c/');

/// Compiles the libraries for the macro classes in [neededPrecompilations].
///
/// Returns a map of library uri to [ExecutorFactoryToken] if macro classes were
/// compiled and added to the [CompilerOptions.macroExecutor] of the provided
/// [options].
///
/// Returns `null` if no macro classes needed precompilation or if macro
/// precompilation is not supported.
Future<Map<Uri, ExecutorFactoryToken>?> precompileMacros(
    NeededPrecompilations? neededPrecompilations,
    ProcessedOptions options) async {
  // Coverage-ignore-block(suite): Not run.
  if (neededPrecompilations != null) {
    if (options.globalFeatures.macros.isEnabled) {
      // TODO(johnniwinther): Avoid using [rawOptionsForTesting] to compute
      // the compiler options for the precompilation.
      // TODO(johnniwinther): Assert that some works has been done.
      // TODO(johnniwinther): Stop in case of compile-time errors.
      // Don't fail here for `requirePrebuiltMacros`: the build will fail later
      // if the macro missing a prebuild is actually applied.
      if (!options.rawOptionsForTesting.requirePrebuiltMacros) {
        return await _compileMacros(neededPrecompilations, options);
      }
    } else {
      throw new UnsupportedError('Macro precompilation is not supported');
    }
  }
  return null;
}

// Coverage-ignore(suite): Not run.
Future<Map<Uri, ExecutorFactoryToken>?> _compileMacros(
    NeededPrecompilations neededPrecompilations,
    ProcessedOptions options) async {
  CompilerOptions rawOptions = options.rawOptionsForTesting;
  CompilerOptions precompilationOptions = new CompilerOptions();
  MacroConfiguration macroConfiguration = computeMacroConfiguration(
    targetSdkSummary: options.sdkSummary,
  );
  precompilationOptions.target = macroConfiguration.target;
  precompilationOptions.explicitExperimentalFlags =
      rawOptions.explicitExperimentalFlags;
  // TODO(johnniwinther): What is the right environment when it isn't passed
  // by the caller? Dart2js calls the CFE without an environment, but it's
  // macros likely need them.
  precompilationOptions.environmentDefines = options.environmentDefines ?? {};
  precompilationOptions.packagesFileUri =
      await options.resolvePackagesFileUri();
  MultiMacroExecutor macroExecutor =
      precompilationOptions.macroExecutor = options.macroExecutor;
  // TODO(johnniwinther): What if sdk root isn't set? How do we then get the
  // right sdk?
  precompilationOptions.sdkRoot = options.sdkRoot;
  precompilationOptions.sdkSummary = macroConfiguration.sdkSummary;
  // TODO(johnniwinther): Strong mode should be the default option for the
  // `CompilerOptions.nnbdMode`.
  precompilationOptions.nnbdMode = NnbdMode.Strong;
  precompilationOptions.librariesSpecificationUri =
      options.librariesSpecificationUri;
  precompilationOptions.runningPrecompilations =
      neededPrecompilations.macroDeclarations.keys.toSet();

  Map<String, Map<String, List<String>>> macroDeclarations = {};
  neededPrecompilations.macroDeclarations
      .forEach((Uri uri, Map<String, List<String>> macroClasses) {
    macroDeclarations[uri.toString()] = macroClasses;
  });

  Uri uri = _defaultDir.resolve('main.dart');
  MemoryFileSystem fs = new MemoryFileSystem(_defaultDir);
  fs.entityForUri(uri).writeAsStringSync(
      bootstrapMacroIsolate(macroDeclarations, SerializationMode.byteData));
  precompilationOptions
    ..fileSystem = new HybridFileSystem(fs, options.fileSystem);

  // Surface diagnostics in the outer compile, failing the build if the macro
  // build fails.
  bool failed = false;
  precompilationOptions.onDiagnostic = (diagnostic) {
    options.rawOptionsForTesting.onDiagnostic!(diagnostic);
    if (diagnostic.severity == Severity.error) {
      failed = true;
    }
  };

  CompilerResult? compilerResult =
      await kernelForProgramInternal(uri, precompilationOptions);
  if (failed) return null;
  Uri precompiledUri = await options.macroSerializer
      .createUriForComponent(compilerResult!.component!);
  Set<Uri> macroLibraries =
      neededPrecompilations.macroDeclarations.keys.toSet();
  ExecutorFactoryToken executorToken = macroExecutor.registerExecutorFactory(
      () => kernelExecutor.start(SerializationMode.byteData, precompiledUri),
      macroLibraries);
  return <Uri, ExecutorFactoryToken>{
    for (Uri library in macroLibraries) library: executorToken,
  };
}

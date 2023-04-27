// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the front-end API for converting source code to Dart Kernel objects.
library front_end.kernel_generator_impl;

import 'package:_fe_analyzer_shared/src/macros/bootstrap.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/isolated_executor.dart'
    as isolatedExecutor;
import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart';
import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/verifier.dart' show VerificationStage;

import 'api_prototype/file_system.dart' show FileSystem;
import 'api_prototype/front_end.dart' show CompilerOptions, CompilerResult;
import 'api_prototype/kernel_generator.dart';
import 'api_prototype/memory_file_system.dart';
import 'base/nnbd_mode.dart';
import 'base/processed_options.dart' show ProcessedOptions;
import 'fasta/compiler_context.dart' show CompilerContext;
import 'fasta/crash.dart' show withCrashReporting;
import 'fasta/dill/dill_target.dart' show DillTarget;
import 'fasta/fasta_codes.dart' show LocatedMessage;
import 'fasta/hybrid_file_system.dart';
import 'fasta/kernel/benchmarker.dart' show BenchmarkPhases;
import 'fasta/kernel/kernel_target.dart' show BuildResult, KernelTarget;
import 'fasta/kernel/macro/macro.dart';
import 'fasta/kernel/utils.dart' show printComponentText, serializeComponent;
import 'fasta/kernel/verifier.dart' show verifyComponent;
import 'fasta/source/source_loader.dart' show SourceLoader;
import 'fasta/uri_offset.dart';
import 'fasta/uri_translator.dart' show UriTranslator;

/// Implementation for the
/// `package:front_end/src/api_prototype/kernel_generator.dart` and
/// `package:front_end/src/api_prototype/summary_generator.dart` APIs.
Future<CompilerResult> generateKernel(ProcessedOptions options,
    {bool buildSummary = false,
    bool buildComponent = true,
    bool truncateSummary = false,
    bool includeOffsets = true,
    bool includeHierarchyAndCoreTypes = false}) async {
  return await CompilerContext.runWithOptions(options, (_) async {
    return await generateKernelInternal(
        buildSummary: buildSummary,
        buildComponent: buildComponent,
        truncateSummary: truncateSummary,
        includeOffsets: includeOffsets,
        includeHierarchyAndCoreTypes: includeHierarchyAndCoreTypes);
  });
}

Future<CompilerResult> generateKernelInternal(
    {bool buildSummary = false,
    bool buildComponent = true,
    bool truncateSummary = false,
    bool includeOffsets = true,
    bool retainDataForTesting = false,
    bool includeHierarchyAndCoreTypes = false}) async {
  ProcessedOptions options = CompilerContext.current.options;
  options.reportNullSafetyCompilationModeInfo();
  FileSystem fs = options.fileSystem;

  SourceLoader? sourceLoader;
  return withCrashReporting<CompilerResult>(() async {
    while (true) {
      // TODO(johnniwinther): How much can we reuse between iterations?
      UriTranslator uriTranslator = await options.getUriTranslator();

      DillTarget dillTarget =
          new DillTarget(options.ticker, uriTranslator, options.target);

      List<Component> loadedComponents = <Component>[];

      Component? sdkSummary = await options.loadSdkSummary(null);
      // By using the nameRoot of the summary, we enable sharing the
      // sdkSummary between multiple invocations.
      CanonicalName nameRoot = sdkSummary?.root ?? new CanonicalName.root();
      if (sdkSummary != null) {
        dillTarget.loader.appendLibraries(sdkSummary);
      }

      for (Component additionalDill
          in await options.loadAdditionalDills(nameRoot)) {
        loadedComponents.add(additionalDill);
        dillTarget.loader.appendLibraries(additionalDill);
      }

      dillTarget.buildOutlines();

      KernelTarget kernelTarget =
          new KernelTarget(fs, false, dillTarget, uriTranslator);
      sourceLoader = kernelTarget.loader;
      kernelTarget.setEntryPoints(options.inputs);
      NeededPrecompilations? neededPrecompilations =
          await kernelTarget.computeNeededPrecompilations();
      kernelTarget.benchmarker?.enterPhase(BenchmarkPhases.precompileMacros);
      Map<Uri, ExecutorFactoryToken>? precompiled =
          await precompileMacros(neededPrecompilations, options);
      if (precompiled != null) {
        kernelTarget.benchmarker
            ?.enterPhase(BenchmarkPhases.unknownGenerateKernelInternal);
        continue;
      }
      kernelTarget.benchmarker
          ?.enterPhase(BenchmarkPhases.unknownGenerateKernelInternal);
      return _buildInternal(
          options: options,
          kernelTarget: kernelTarget,
          nameRoot: nameRoot,
          sdkSummary: sdkSummary,
          loadedComponents: loadedComponents,
          buildSummary: buildSummary,
          truncateSummary: truncateSummary,
          buildComponent: buildComponent,
          includeOffsets: includeOffsets,
          includeHierarchyAndCoreTypes: includeHierarchyAndCoreTypes,
          retainDataForTesting: retainDataForTesting);
    }
  },
      () =>
          sourceLoader?.currentUriForCrashReporting ??
          new UriOffset(options.inputs.first, TreeNode.noOffset));
}

Future<CompilerResult> _buildInternal(
    {required ProcessedOptions options,
    required KernelTarget kernelTarget,
    required CanonicalName nameRoot,
    required Component? sdkSummary,
    required List<Component> loadedComponents,
    required bool buildSummary,
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
    if (options.verify) {
      for (LocatedMessage error in verifyComponent(
          options.target, VerificationStage.outline, summaryComponent)) {
        options.report(error, Severity.error);
      }
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
      case NnbdMode.Agnostic:
        compiledMode = NonNullableByDefaultCompiledMode.Agnostic;
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
    // Don't include source (but do add it above to include importUris).
    summary = serializeComponent(trimmedSummaryComponent,
        includeSources: false, includeOffsets: includeOffsets);
    options.ticker.logMs("Generated outline");
  }

  Component? component;
  if (buildComponent) {
    buildResult = await kernelTarget.buildComponent(
        macroApplications: buildResult.macroApplications,
        verify: options.verify);
    component = buildResult.component;
    if (options.debugDump) {
      printComponentText(component,
          libraryFilter: kernelTarget.isSourceLibraryForDebugging,
          showOffsets: options.debugDumpShowOffsets);
    }
    options.ticker.logMs("Generated component");
  }
  // TODO(johnniwinther): Should we reuse the macro executor on subsequent
  // compilations where possible?
  buildResult.macroApplications?.close();

  return new InternalCompilerResult(
      summary: summary,
      component: component,
      sdkComponent: sdkSummary,
      loadedComponents: loadedComponents,
      classHierarchy:
          includeHierarchyAndCoreTypes ? kernelTarget.loader.hierarchy : null,
      coreTypes:
          includeHierarchyAndCoreTypes ? kernelTarget.loader.coreTypes : null,
      deps: new List<Uri>.from(CompilerContext.current.dependencies),
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

  /// Dependencies traversed by the compiler. Used only for generating
  /// dependency .GN files in the dart-sdk build system.
  /// Note this might be removed when we switch to compute dependencies without
  /// using the compiler itself.
  @override
  final List<Uri> deps;

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
      required this.deps,
      this.classHierarchy,
      this.coreTypes,
      this.kernelTargetForTesting});
}

/// A fake absolute directory used as the root of a memory-file system in the
/// compilation below.
Uri _defaultDir = Uri.parse('org-dartlang-macro:///a/b/c/');

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
  if (neededPrecompilations != null) {
    if (enableMacros) {
      // TODO(johnniwinther): Avoid using [rawOptionsForTesting] to compute
      // the compiler options for the precompilation.
      if (options.rawOptionsForTesting.macroTarget != null) {
        // TODO(johnniwinther): Assert that some works has been done.
        // TODO(johnniwinther): Stop in case of compile-time errors.
        return await _compileMacros(
            neededPrecompilations, options.rawOptionsForTesting);
      }
    } else {
      throw new UnsupportedError('Macro precompilation is not supported');
    }
  }
  return null;
}

Future<Map<Uri, ExecutorFactoryToken>> _compileMacros(
    NeededPrecompilations neededPrecompilations,
    CompilerOptions options) async {
  assert(options.macroSerializer != null);
  CompilerOptions precompilationOptions = new CompilerOptions();
  precompilationOptions.target = options.macroTarget;
  precompilationOptions.explicitExperimentalFlags =
      options.explicitExperimentalFlags;
  // TODO(johnniwinther): What is the right environment when it isn't passed
  // by the caller? Dart2js calls the CFE without an environment, but it's
  // macros likely need them.
  precompilationOptions.environmentDefines = options.environmentDefines ?? {};
  precompilationOptions.packagesFileUri = options.packagesFileUri;
  MultiMacroExecutor macroExecutor = precompilationOptions.macroExecutor =
      options.macroExecutor ??= new MultiMacroExecutor();
  // TODO(johnniwinther): What if sdk root isn't set? How do we then get the
  // right sdk?
  precompilationOptions.sdkRoot = options.sdkRoot;

  Map<String, Map<String, List<String>>> macroDeclarations = {};
  neededPrecompilations.macroDeclarations
      .forEach((Uri uri, Map<String, List<String>> macroClasses) {
    macroDeclarations[uri.toString()] = macroClasses;
  });

  Uri uri = _defaultDir.resolve('main.dart');
  MemoryFileSystem fs = new MemoryFileSystem(_defaultDir);
  fs.entityForUri(uri).writeAsStringSync(bootstrapMacroIsolate(
      macroDeclarations, SerializationMode.byteDataClient));

  precompilationOptions
    ..fileSystem = new HybridFileSystem(fs, options.fileSystem);
  CompilerResult? compilerResult =
      await kernelForProgramInternal(uri, precompilationOptions);
  Uri precompiledUri = await options.macroSerializer!
      .createUriForComponent(compilerResult!.component!);
  Set<Uri> macroLibraries =
      neededPrecompilations.macroDeclarations.keys.toSet();
  ExecutorFactoryToken executorToken = macroExecutor.registerExecutorFactory(
      () => isolatedExecutor.start(
          SerializationMode.byteDataServer, precompiledUri),
      macroLibraries);
  return <Uri, ExecutorFactoryToken>{
    for (Uri library in macroLibraries) library: executorToken,
  };
}

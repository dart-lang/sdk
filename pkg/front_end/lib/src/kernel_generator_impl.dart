// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the front-end API for converting source code to Dart Kernel objects.
library front_end.kernel_generator_impl;

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/messages/severity.dart'
    show CfeSeverity;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/verifier.dart' show VerificationStage;

import 'api_prototype/file_system.dart' show FileSystem;
import 'api_prototype/front_end.dart' show CompilerResult;
import 'api_prototype/kernel_generator.dart';
import 'base/compiler_context.dart' show CompilerContext;
import 'base/crash.dart' show withCrashReporting;
import 'base/instrumentation.dart';
import 'base/processed_options.dart' show ProcessedOptions;
import 'base/uri_offset.dart';
import 'base/uri_translator.dart' show UriTranslator;
import 'codes/cfe_codes.dart' show LocatedMessage;
import 'dill/dill_target.dart' show DillTarget;
import 'kernel/benchmarker.dart' show BenchmarkPhases, Benchmarker;
import 'kernel/cfe_verifier.dart' show verifyComponent;
import 'kernel/kernel_target.dart' show BuildResult, KernelTarget;
import 'kernel/utils.dart' show printComponentText, serializeComponent;
import 'source/source_loader.dart' show SourceLoader;

// Coverage-ignore(suite): Not run.
/// Implementation for the
/// `package:front_end/src/api_prototype/kernel_generator.dart` and
/// `package:front_end/src/api_prototype/summary_generator.dart` APIs.
Future<CompilerResult> generateKernel(
  ProcessedOptions options, {
  bool buildSummary = false,
  bool buildComponent = true,
  bool truncateSummary = false,
  bool includeOffsets = true,
  bool includeHierarchyAndCoreTypes = false,
}) async {
  return await CompilerContext.runWithOptions(options, (
    CompilerContext c,
  ) async {
    return await generateKernelInternal(
      c,
      buildSummary: buildSummary,
      buildComponent: buildComponent,
      truncateSummary: truncateSummary,
      includeOffsets: includeOffsets,
      includeHierarchyAndCoreTypes: includeHierarchyAndCoreTypes,
    );
  });
}

/// Note that if [buildSummary] is true it will be default serialize the summary
/// but this can be disabled by setting [serializeIfBuildingSummary] to false.
Future<InternalCompilerResult> generateKernelInternal(
  CompilerContext compilerContext, {
  bool buildSummary = false,
  bool serializeIfBuildingSummary = true,
  bool buildComponent = true,
  bool truncateSummary = false,
  bool includeOffsets = true,
  bool includeHierarchyAndCoreTypes = false,
  bool retainDataForTesting = false,
  Benchmarker? benchmarker,
  Instrumentation? instrumentation,
  List<Component>? additionalDillsForTesting,
  bool allowVerificationErrorForTesting = false,
}) async {
  ProcessedOptions options = compilerContext.options;
  assert(options.haveBeenValidated, "Options have not been validated");

  FileSystem fs = options.fileSystem;

  SourceLoader? sourceLoader;
  return withCrashReporting<InternalCompilerResult>(
    () async {
      UriTranslator uriTranslator = await options.getUriTranslator();

      DillTarget dillTarget = new DillTarget(
        compilerContext,
        options.ticker,
        uriTranslator,
        options.target,
        benchmarker: benchmarker,
      );

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
        for (Component additionalDill in await options.loadAdditionalDills(
          nameRoot,
        )) {
          loadedComponents.add(additionalDill);
          dillTarget.loader.appendLibraries(additionalDill);
        }
      }

      dillTarget.buildOutlines();

      KernelTarget kernelTarget = new KernelTarget(
        compilerContext,
        fs,
        false,
        dillTarget,
        uriTranslator,
      );
      sourceLoader = kernelTarget.loader;
      sourceLoader!.instrumentation = instrumentation;
      kernelTarget.setEntryPoints(options.inputs);
      await kernelTarget.computeNeededPrecompilations();
      kernelTarget.benchmarker
      // Coverage-ignore(suite): Not run.
      ?.enterPhase(BenchmarkPhases.precompileMacros);
      kernelTarget.benchmarker
      // Coverage-ignore(suite): Not run.
      ?.enterPhase(BenchmarkPhases.unknownGenerateKernelInternal);
      return _buildInternal(
        compilerContext,
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
        retainDataForTesting: retainDataForTesting,
        allowVerificationErrorForTesting: allowVerificationErrorForTesting,
      );
    },
    // Coverage-ignore(suite): Not run.
    () =>
        sourceLoader?.currentUriForCrashReporting ??
        new UriOffset(options.inputs.first, TreeNode.noOffset),
  );
}

Future<InternalCompilerResult> _buildInternal(
  CompilerContext compilerContext, {
  required ProcessedOptions options,
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
  required bool retainDataForTesting,
  required bool allowVerificationErrorForTesting,
}) async {
  BuildResult buildResult = await kernelTarget.buildOutlines(
    nameRoot: nameRoot,
  );
  Component summaryComponent = buildResult.component!;
  Uint8List? summary = null;
  if (buildSummary) {
    // Coverage-ignore-block(suite): Not run.
    if (options.verify) {
      List<LocatedMessage> errors = verifyComponent(
        compilerContext,
        VerificationStage.outline,
        summaryComponent,
      );
      for (LocatedMessage error in errors) {
        options.report(compilerContext, error, CfeSeverity.error);
      }
      assert(errors.isEmpty, "Verification errors found.");
    }
    if (options.debugDump) {
      printComponentText(
        summaryComponent,
        libraryFilter: kernelTarget.isSourceLibraryForDebugging,
        showOffsets: options.debugDumpShowOffsets,
      );
    }

    // Create the requested component ("truncating" or not).
    //
    // Note: we don't pass the library argument to the constructor to
    // preserve the libraries parent pointer (it should continue to point
    // to the component within KernelTarget).
    Component trimmedSummaryComponent =
        new Component(nameRoot: summaryComponent.root)
          ..libraries.addAll(
            truncateSummary
                ? kernelTarget.loader.libraries
                : summaryComponent.libraries,
          );
    trimmedSummaryComponent.metadata.addAll(summaryComponent.metadata);
    trimmedSummaryComponent.uriToSource.addAll(summaryComponent.uriToSource);

    trimmedSummaryComponent.setMainMethodAndMode(
      trimmedSummaryComponent.mainMethodName,
      false,
    );

    // As documented, we only run outline transformations when we are building
    // summaries without building a full component (at this time, that's
    // the only need we have for these transformations).
    if (!buildComponent) {
      options.target.performOutlineTransformations(trimmedSummaryComponent);
      options.ticker.logMs("Transformed outline");
    }
    if (serializeIfBuildingSummary) {
      // Don't include source (but do add it above to include importUris).
      summary = serializeComponent(
        trimmedSummaryComponent,
        includeSources: false,
        includeOffsets: includeOffsets,
      );
    }
    options.ticker.logMs("Generated outline");
  }

  Component? component;
  if (buildComponent) {
    buildResult = await kernelTarget.buildComponent(
      verify: options.verify,
      allowVerificationErrorForTesting: allowVerificationErrorForTesting,
    );
    component = buildResult.component;
    if (options.debugDump) {
      // Coverage-ignore-block(suite): Not run.
      printComponentText(
        component,
        libraryFilter: kernelTarget.isSourceLibraryForDebugging,
        showOffsets: options.debugDumpShowOffsets,
      );
    }
    options.ticker.logMs("Generated component");
  } else {
    component = summaryComponent;
  }

  return new InternalCompilerResult(
    summary: summary,
    component: component,
    sdkComponent: sdkSummary,
    loadedComponents: loadedComponents,
    classHierarchy: includeHierarchyAndCoreTypes
        ? kernelTarget.loader.hierarchy
        : null,
    coreTypes: includeHierarchyAndCoreTypes
        ? kernelTarget.loader.coreTypes
        : null,
    kernelTargetForTesting: retainDataForTesting ? kernelTarget : null,
  );
}

/// Result object of [generateKernel].
class InternalCompilerResult implements CompilerResult {
  /// The generated summary bytes, if it was requested.
  @override
  final Uint8List? summary;

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

  InternalCompilerResult({
    this.summary,
    this.component,
    this.sdkComponent,
    required this.loadedComponents,
    this.classHierarchy,
    this.coreTypes,
    this.kernelTargetForTesting,
  });
}

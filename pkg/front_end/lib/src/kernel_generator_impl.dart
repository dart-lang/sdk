// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the front-end API for converting source code to Dart Kernel objects.
library front_end.kernel_generator_impl;

import 'dart:async' show Future;

import 'package:front_end/src/fasta/kernel/kernel_api.dart';
import 'package:kernel/kernel.dart' show Component, CanonicalName;

import 'base/processed_options.dart' show ProcessedOptions;

import 'fasta/compiler_context.dart' show CompilerContext;

import 'fasta/crash.dart' show withCrashReporting;

import 'fasta/dill/dill_target.dart' show DillTarget;

import 'fasta/fasta_codes.dart' show LocatedMessage;

import 'fasta/kernel/kernel_target.dart' show KernelTarget;

import 'fasta/kernel/utils.dart' show printComponentText, serializeComponent;

import 'fasta/kernel/verifier.dart' show verifyComponent;

import 'fasta/loader.dart' show Loader;

import 'fasta/severity.dart' show Severity;

import 'fasta/uri_translator.dart' show UriTranslator;

import 'api_prototype/front_end.dart' show CompilerResult;

import 'api_prototype/file_system.dart' show FileSystem;

/// Implementation for the
/// `package:front_end/src/api_prototype/kernel_generator.dart` and
/// `package:front_end/src/api_prototype/summary_generator.dart` APIs.
Future<CompilerResult> generateKernel(ProcessedOptions options,
    {bool buildSummary: false,
    bool buildComponent: true,
    bool truncateSummary: false,
    bool includeOffsets: true,
    bool includeHierarchyAndCoreTypes: false}) async {
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
    {bool buildSummary: false,
    bool buildComponent: true,
    bool truncateSummary: false,
    bool includeOffsets: true,
    bool retainDataForTesting: false,
    bool includeHierarchyAndCoreTypes: false}) async {
  ProcessedOptions options = CompilerContext.current.options;
  FileSystem fs = options.fileSystem;

  Loader sourceLoader;
  return withCrashReporting<CompilerResult>(() async {
    UriTranslator uriTranslator = await options.getUriTranslator();

    DillTarget dillTarget =
        new DillTarget(options.ticker, uriTranslator, options.target);

    Set<Uri> externalLibs(Component component) {
      return component.libraries
          .where((lib) => lib.isExternal)
          .map((lib) => lib.importUri)
          .toSet();
    }

    Component sdkSummary = await options.loadSdkSummary(null);
    // By using the nameRoot of the the summary, we enable sharing the
    // sdkSummary between multiple invocations.
    CanonicalName nameRoot = sdkSummary?.root ?? new CanonicalName.root();
    if (sdkSummary != null) {
      Set<Uri> excluded = externalLibs(sdkSummary);
      dillTarget.loader.appendLibraries(sdkSummary,
          filter: (uri) => !excluded.contains(uri));
    }

    // TODO(sigmund): provide better error reporting if input summaries or
    // linked dependencies were listed out of order (or provide mechanism to
    // sort them).
    for (Component inputSummary in await options.loadInputSummaries(nameRoot)) {
      Set<Uri> excluded = externalLibs(inputSummary);
      dillTarget.loader.appendLibraries(inputSummary,
          filter: (uri) => !excluded.contains(uri));
    }

    // All summaries are considered external and shouldn't include source-info.
    dillTarget.loader.libraries.forEach((lib) {
      // TODO(ahe): Don't do this, and remove [external_state_snapshot.dart].
      lib.isExternal = true;
    });

    // Linked dependencies are meant to be part of the component so they are not
    // marked external.
    for (Component dependency in await options.loadLinkDependencies(nameRoot)) {
      Set<Uri> excluded = externalLibs(dependency);
      dillTarget.loader.appendLibraries(dependency,
          filter: (uri) => !excluded.contains(uri));
    }

    await dillTarget.buildOutlines();

    KernelTarget kernelTarget =
        new KernelTarget(fs, false, dillTarget, uriTranslator);
    sourceLoader = kernelTarget.loader;
    kernelTarget.setEntryPoints(options.inputs);
    Component summaryComponent =
        await kernelTarget.buildOutlines(nameRoot: nameRoot);
    List<int> summary = null;
    if (buildSummary) {
      if (options.verify) {
        for (LocatedMessage error in verifyComponent(summaryComponent)) {
          options.report(error, Severity.error);
        }
      }
      if (options.debugDump) {
        printComponentText(summaryComponent,
            libraryFilter: kernelTarget.isSourceLibrary);
      }

      // Create the requested component ("truncating" or not).
      //
      // Note: we don't pass the library argument to the constructor to
      // preserve the the libraries parent pointer (it should continue to point
      // to the component within KernelTarget).
      Component trimmedSummaryComponent =
          new Component(nameRoot: summaryComponent.root)
            ..libraries.addAll(truncateSummary
                ? kernelTarget.loader.libraries
                : summaryComponent.libraries);
      trimmedSummaryComponent.metadata.addAll(summaryComponent.metadata);
      trimmedSummaryComponent.uriToSource.addAll(summaryComponent.uriToSource);

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

    Component component;
    if (buildComponent) {
      component = await kernelTarget.buildComponent(verify: options.verify);
      if (options.debugDump) {
        printComponentText(component,
            libraryFilter: kernelTarget.isSourceLibrary);
      }
      options.ticker.logMs("Generated component");
    }

    return new InternalCompilerResult(
        summary: summary,
        component: component,
        classHierarchy:
            includeHierarchyAndCoreTypes ? kernelTarget.loader.hierarchy : null,
        coreTypes:
            includeHierarchyAndCoreTypes ? kernelTarget.loader.coreTypes : null,
        deps: new List<Uri>.from(CompilerContext.current.dependencies),
        kernelTargetForTesting: retainDataForTesting ? kernelTarget : null);
  }, () => sourceLoader?.currentUriForCrashReporting ?? options.inputs.first);
}

/// Result object of [generateKernel].
class InternalCompilerResult implements CompilerResult {
  /// The generated summary bytes, if it was requested.
  final List<int> summary;

  /// The generated component, if it was requested.
  final Component component;

  /// Dependencies traversed by the compiler. Used only for generating
  /// dependency .GN files in the dart-sdk build system.
  /// Note this might be removed when we switch to compute dependencies without
  /// using the compiler itself.
  final List<Uri> deps;

  final ClassHierarchy classHierarchy;

  final CoreTypes coreTypes;

  /// The [KernelTarget] used to generated the component.
  ///
  /// This is only provided for use in testing.
  final KernelTarget kernelTargetForTesting;

  InternalCompilerResult(
      {this.summary,
      this.component,
      this.deps,
      this.classHierarchy,
      this.coreTypes,
      this.kernelTargetForTesting});
}

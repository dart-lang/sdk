// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the front-end API for converting source code to Dart Kernel objects.
library front_end.kernel_generator_impl;

import 'dart:async' show Future;
import 'dart:async';

import 'package:kernel/kernel.dart' show Program, CanonicalName;

import 'base/processed_options.dart';
import 'fasta/severity.dart' show Severity;
import 'fasta/compiler_context.dart' show CompilerContext;
import 'fasta/deprecated_problems.dart' show deprecated_InputError, reportCrash;
import 'fasta/dill/dill_target.dart' show DillTarget;
import 'fasta/kernel/kernel_outline_shaker.dart';
import 'fasta/kernel/kernel_target.dart' show KernelTarget;
import 'fasta/kernel/utils.dart';
import 'fasta/kernel/verifier.dart';
import 'fasta/uri_translator.dart' show UriTranslator;

/// Implementation for the `package:front_end/kernel_generator.dart` and
/// `package:front_end/summary_generator.dart` APIs.
Future<CompilerResult> generateKernel(ProcessedOptions options,
    {bool buildSummary: false,
    bool buildProgram: true,
    bool trimDependencies: false}) async {
  return await CompilerContext.runWithOptions(options, (_) async {
    return await generateKernelInternal(
        buildSummary: buildSummary,
        buildProgram: buildProgram,
        trimDependencies: trimDependencies);
  });
}

Future<CompilerResult> generateKernelInternal(
    {bool buildSummary: false,
    bool buildProgram: true,
    bool trimDependencies: false}) async {
  var options = CompilerContext.current.options;
  var fs = options.fileSystem;
  if (!await options.validateOptions()) return null;
  options.ticker.logMs("Validated arguments");

  try {
    UriTranslator uriTranslator = await options.getUriTranslator();

    var dillTarget =
        new DillTarget(options.ticker, uriTranslator, options.target);

    CanonicalName nameRoot = new CanonicalName.root();
    Set<Uri> externalLibs(Program program) {
      return program.libraries
          .where((lib) => lib.isExternal)
          .map((lib) => lib.importUri)
          .toSet();
    }

    var sdkSummary = await options.loadSdkSummary(nameRoot);
    if (sdkSummary != null) {
      var excluded = externalLibs(sdkSummary);
      dillTarget.loader
          .appendLibraries(sdkSummary, (uri) => !excluded.contains(uri));
    }

    // TODO(sigmund): provide better error reporting if input summaries or
    // linked dependencies were listed out of order (or provide mechanism to
    // sort them).
    for (var inputSummary in await options.loadInputSummaries(nameRoot)) {
      var excluded = externalLibs(inputSummary);
      dillTarget.loader
          .appendLibraries(inputSummary, (uri) => !excluded.contains(uri));
    }

    // All summaries are considered external and shouldn't include source-info.
    dillTarget.loader.libraries.forEach((lib) {
      lib.isExternal = true;
      lib.dependencies.clear();
    });

    // Linked dependencies are meant to be part of the program so they are not
    // marked external.
    for (var dependency in await options.loadLinkDependencies(nameRoot)) {
      var excluded = externalLibs(dependency);
      dillTarget.loader
          .appendLibraries(dependency, (uri) => !excluded.contains(uri));
    }

    await dillTarget.buildOutlines();

    var kernelTarget = new KernelTarget(fs, false, dillTarget, uriTranslator);
    options.inputs.forEach(kernelTarget.read);
    Program summaryProgram =
        await kernelTarget.buildOutlines(nameRoot: nameRoot);
    List<int> summary = null;
    if (buildSummary) {
      if (trimDependencies) {
        // TODO(sigmund): see if it is worth supporting this. Note: trimming the
        // program is destructive, so if we are emitting summaries and the
        // program in a single API call, we would need to clone the program here
        // to avoid deleting pieces that are needed by kernelTarget.buildProgram
        // below.
        assert(!buildProgram);
        var excluded =
            dillTarget.loader.libraries.map((lib) => lib.importUri).toSet();
        trimProgram(summaryProgram, (uri) => !excluded.contains(uri));
      }
      if (options.verify) {
        for (var error in verifyProgram(summaryProgram)) {
          options.report(error, Severity.error);
        }
      }
      if (options.debugDump) {
        printProgramText(summaryProgram,
            libraryFilter: kernelTarget.isSourceLibrary);
      }
      if (kernelTarget.errors.isEmpty) {
        summary = serializeProgram(summaryProgram, excludeUriToSource: true);
      }
      options.ticker.logMs("Generated outline");
    }

    Program program;
    if (buildProgram && kernelTarget.errors.isEmpty) {
      program = await kernelTarget.buildProgram(verify: options.verify);
      if (trimDependencies) {
        var excluded =
            dillTarget.loader.libraries.map((lib) => lib.importUri).toSet();
        trimProgram(program, (uri) => !excluded.contains(uri));
      }
      if (options.debugDump) {
        printProgramText(program, libraryFilter: kernelTarget.isSourceLibrary);
      }
      options.ticker.logMs("Generated program");
    }

    if (kernelTarget.errors.isNotEmpty) {
      // TODO(sigmund): remove duplicate error reporting. Currently
      // kernelTarget.errors contains recoverable and unrecoverable errors. We
      // are reporting unrecoverable errors twice.
      kernelTarget.errors.forEach((e) => options.report(e, Severity.error));
      return null;
    }

    return new CompilerResult(
        summary: summary,
        program: program,
        deps: kernelTarget.loader.getDependencies());
  } on deprecated_InputError catch (e) {
    options.report(
        deprecated_InputError.toMessage(e), Severity.internalProblem);
    return null;
  } catch (e, t) {
    return reportCrash(e, t);
  }
}

/// Result object of [generateKernel].
class CompilerResult {
  /// The generated summary bytes, if it was requested.
  final List<int> summary;

  /// The generated program, if it was requested.
  final Program program;

  /// Dependencies traversed by the compiler. Used only for generating
  /// dependency .GN files in the dart-sdk build system.
  /// Note this might be removed when we switch to compute depencencies without
  /// using the compiler itself.
  final List<Uri> deps;

  CompilerResult({this.summary, this.program, this.deps});
}

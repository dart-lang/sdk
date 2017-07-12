// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the front-end API for converting source code to Dart Kernel objects.
library front_end.kernel_generator_impl;

import 'dart:async' show Future;
import 'dart:async';

import 'package:kernel/kernel.dart' show Program, CanonicalName;

import 'base/processed_options.dart';
import 'fasta/compiler_command_line.dart' show CompilerCommandLine;
import 'fasta/compiler_context.dart' show CompilerContext;
import 'fasta/deprecated_problems.dart' show deprecated_InputError, reportCrash;
import 'fasta/dill/dill_target.dart' show DillTarget;
import 'fasta/kernel/kernel_outline_shaker.dart';
import 'fasta/kernel/kernel_target.dart' show KernelTarget;
import 'fasta/kernel/utils.dart';
import 'fasta/kernel/verifier.dart';
import 'fasta/translate_uri.dart' show TranslateUri;

/// Implementation for the `package:front_end/kernel_generator.dart` and
/// `package:front_end/summary_generator.dart` APIs.
Future<CompilerResult> generateKernel(ProcessedOptions options,
    {bool buildSummary: false,
    bool buildProgram: true,
    bool trimDependencies: false}) async {
  // TODO(sigmund): Replace CompilerCommandLine and instead simply use a
  // CompilerContext that directly uses the ProcessedOptions through the
  // system.
  String programName = "";
  List<String> arguments = <String>[programName, "--target=none"];
  if (options.strongMode) {
    arguments.add("--strong-mode");
  }
  if (options.verbose) {
    arguments.add("--verbose");
  }
  if (options.setExitCodeOnProblem) {
    arguments.add("--set-exit-code-on-problem");
  }
  return await CompilerCommandLine.withGlobalOptions(programName, arguments,
      (CompilerContext context) async {
    context.options.options["--target"] = options.target;
    return await generateKernelInternal(options,
        buildSummary: buildSummary,
        buildProgram: buildProgram,
        trimDependencies: trimDependencies);
  });
}

Future<CompilerResult> generateKernelInternal(ProcessedOptions options,
    {bool buildSummary: false,
    bool buildProgram: true,
    bool trimDependencies: false}) async {
  var fs = options.fileSystem;
  if (!await options.validateOptions()) return null;
  options.ticker.logMs("Validated arguments");

  try {
    TranslateUri uriTranslator = await options.getUriTranslator();

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
    dillTarget.loader.libraries.forEach((lib) => lib.isExternal = true);

    // Linked dependencies are meant to be part of the program so they are not
    // marked external.
    for (var dependency in await options.loadLinkDependencies(nameRoot)) {
      var excluded = externalLibs(dependency);
      dillTarget.loader
          .appendLibraries(dependency, (uri) => !excluded.contains(uri));
    }

    await dillTarget.buildOutlines();

    var kernelTarget = new KernelTarget(fs, dillTarget, uriTranslator);
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
        verifyProgram(summaryProgram).forEach((e) => options.reportError('$e'));
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
      kernelTarget.errors.forEach(options.reportError);
      return null;
    }

    return new CompilerResult(
        summary: summary,
        program: program,
        deps: kernelTarget.loader.getDependencies());
  } on deprecated_InputError catch (e) {
    options.reportError(e.deprecated_format());
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

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.tool.entry_points;

import 'dart:async' show Future;

import 'dart:convert' show JSON;

import 'dart:io' show File, exitCode;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/deprecated_problems.dart'
    show deprecated_InputError, deprecated_inputError;

import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;

import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;

import 'package:front_end/src/fasta/kernel/utils.dart'
    show printProgramText, writeProgramToFile;

import 'package:front_end/src/fasta/severity.dart' show Severity;

import 'package:front_end/src/fasta/ticker.dart' show Ticker;

import 'package:front_end/src/fasta/uri_translator.dart' show UriTranslator;

import 'package:kernel/kernel.dart' show Program, loadProgramFromBytes;

import 'command_line.dart' show withGlobalOptions;

const bool summary = const bool.fromEnvironment("summary", defaultValue: false);

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

compileEntryPoint(List<String> arguments) async {
  // Timing results for each iteration
  List<double> elapsedTimes = <double>[];

  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n\n=== Iteration ${i+1} of $iterations");
    }
    var stopwatch = new Stopwatch()..start();
    await compile(arguments);
    stopwatch.stop();

    elapsedTimes.add(stopwatch.elapsedMilliseconds.toDouble());
  }

  if (summary) {
    var json = JSON.encode(<String, dynamic>{'elapsedTimes': elapsedTimes});
    print('\nSummary: $json');
  }
}

outlineEntryPoint(List<String> arguments) async {
  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n");
    }
    await outline(arguments);
  }
}

Future<KernelTarget> outline(List<String> arguments) async {
  try {
    return await withGlobalOptions("outline", arguments, true,
        (CompilerContext c, _) async {
      if (c.options.verbose) {
        print("Building outlines for ${arguments.join(' ')}");
      }
      CompileTask task =
          new CompileTask(c, new Ticker(isVerbose: c.options.verbose));
      return await task.buildOutline(c.options.output);
    });
  } on deprecated_InputError catch (e) {
    exitCode = 1;
    CompilerContext.runWithDefaultOptions(
        (c) => c.report(deprecated_InputError.toMessage(e), Severity.error));
    return null;
  }
}

Future<Uri> compile(List<String> arguments) async {
  try {
    return await withGlobalOptions("compile", arguments, true,
        (CompilerContext c, _) async {
      if (c.options.verbose) {
        print("Compiling directly to Kernel: ${arguments.join(' ')}");
      }
      CompileTask task =
          new CompileTask(c, new Ticker(isVerbose: c.options.verbose));
      return await task.compile();
    });
  } on deprecated_InputError catch (e) {
    exitCode = 1;
    CompilerContext.runWithDefaultOptions(
        (c) => c.report(deprecated_InputError.toMessage(e), Severity.error));
    return null;
  }
}

class CompileTask {
  final CompilerContext c;
  final Ticker ticker;

  CompileTask(this.c, this.ticker);

  DillTarget createDillTarget(UriTranslator uriTranslator) {
    return new DillTarget(ticker, uriTranslator, c.options.target);
  }

  KernelTarget createKernelTarget(
      DillTarget dillTarget, UriTranslator uriTranslator, bool strongMode) {
    return new KernelTarget(c.fileSystem, false, dillTarget, uriTranslator,
        uriToSource: c.uriToSource);
  }

  Future<KernelTarget> buildOutline([Uri output]) async {
    UriTranslator uriTranslator = await c.options.getUriTranslator();
    ticker.logMs("Read packages file");
    DillTarget dillTarget = createDillTarget(uriTranslator);
    KernelTarget kernelTarget =
        createKernelTarget(dillTarget, uriTranslator, c.options.strongMode);
    if (c.options.strongMode) {
      print("Note: strong mode support is preliminary and may not work.");
    }
    Uri platform = c.options.sdkSummary;
    if (platform != null) {
      _appendDillForUri(dillTarget, platform);
    }
    Uri uri = c.options.inputs.first;
    String path = uriTranslator.translate(uri)?.path ?? uri.path;
    if (path.endsWith(".dart")) {
      kernelTarget.read(uri);
    } else {
      deprecated_inputError(uri, -1, "Unexpected input: $uri");
    }
    await dillTarget.buildOutlines();
    var outline = await kernelTarget.buildOutlines();
    if (c.options.debugDump && output != null) {
      printProgramText(outline, libraryFilter: kernelTarget.isSourceLibrary);
    }
    if (output != null) {
      await writeProgramToFile(outline, output);
      ticker.logMs("Wrote outline to ${output.toFilePath()}");
    }
    return kernelTarget;
  }

  Future<Uri> compile() async {
    KernelTarget kernelTarget = await buildOutline();
    if (exitCode != 0) return null;
    Uri uri = c.options.output;
    var program = await kernelTarget.buildProgram(verify: c.options.verify);
    if (c.options.debugDump) {
      printProgramText(program, libraryFilter: kernelTarget.isSourceLibrary);
    }
    await writeProgramToFile(program, uri);
    ticker.logMs("Wrote program to ${uri.toFilePath()}");
    return uri;
  }
}

/// Load the [Program] from the given [uri] and append its libraries
/// to the [dillTarget].
void _appendDillForUri(DillTarget dillTarget, Uri uri) {
  var bytes = new File.fromUri(uri).readAsBytesSync();
  var platformProgram = loadProgramFromBytes(bytes);
  dillTarget.loader.appendLibraries(platformProgram);
}

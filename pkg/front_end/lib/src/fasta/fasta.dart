// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta;

import 'dart:async' show Future;

import 'dart:convert' show JSON;

import 'dart:io' show BytesBuilder, File, exitCode;

import 'package:front_end/physical_file_system.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/fasta/uri_translator_impl.dart';

import 'package:kernel/kernel.dart' show Program, loadProgramFromBytes;

import 'compiler_command_line.dart' show CompilerCommandLine;

import 'compiler_context.dart' show CompilerContext;

import 'deprecated_problems.dart'
    show deprecated_InputError, deprecated_inputError;

import 'kernel/kernel_target.dart' show KernelTarget;

import 'dill/dill_target.dart' show DillTarget;

import 'compile_platform.dart' show compilePlatformInternal;

import 'severity.dart' show Severity;

import 'ticker.dart' show Ticker;

import 'uri_translator.dart' show UriTranslator;

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
    return await CompilerCommandLine.withGlobalOptions("outline", arguments,
        (CompilerContext c) async {
      if (c.options.verbose) {
        print("Building outlines for ${arguments.join(' ')}");
      }
      CompileTask task =
          new CompileTask(c, new Ticker(isVerbose: c.options.verbose));
      return await task.buildOutline(c.options.output);
    });
  } on deprecated_InputError catch (e) {
    exitCode = 1;
    CompilerContext.current
        .report(deprecated_InputError.toMessage(e), Severity.error);
    return null;
  }
}

Future<Uri> compile(List<String> arguments) async {
  try {
    return await CompilerCommandLine.withGlobalOptions("compile", arguments,
        (CompilerContext c) async {
      if (c.options.verbose) {
        print("Compiling directly to Kernel: ${arguments.join(' ')}");
      }
      CompileTask task =
          new CompileTask(c, new Ticker(isVerbose: c.options.verbose));
      return await task.compile();
    });
  } on deprecated_InputError catch (e) {
    exitCode = 1;
    CompilerContext.current
        .report(deprecated_InputError.toMessage(e), Severity.error);
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
    return new KernelTarget(
        c.fileSystem, dillTarget, uriTranslator, c.uriToSource);
  }

  Future<KernelTarget> buildOutline([Uri output]) async {
    UriTranslator uriTranslator = await UriTranslatorImpl
        .parse(c.fileSystem, c.options.sdk, packages: c.options.packages);
    ticker.logMs("Read packages file");
    DillTarget dillTarget = createDillTarget(uriTranslator);
    KernelTarget kernelTarget =
        createKernelTarget(dillTarget, uriTranslator, c.options.strongMode);
    if (c.options.strongMode) {
      print("Note: strong mode support is preliminary and may not work.");
    }
    Uri platform = c.options.platform;
    if (platform != null) {
      _appendDillForUri(dillTarget, platform);
    }
    String argument = c.options.arguments.first;
    Uri uri = Uri.base.resolve(argument);
    String path = uriTranslator.translate(uri)?.path ?? argument;
    if (path.endsWith(".dart")) {
      kernelTarget.read(uri);
    } else {
      deprecated_inputError(uri, -1, "Unexpected input: $uri");
    }
    await dillTarget.buildOutlines();
    var outline = await kernelTarget.buildOutlines();
    if (c.options.dumpIr && output != null) {
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
    if (c.options.dumpIr) {
      printProgramText(program, libraryFilter: kernelTarget.isSourceLibrary);
    }
    await writeProgramToFile(program, uri);
    ticker.logMs("Wrote program to ${uri.toFilePath()}");
    return uri;
  }
}

Future compilePlatform(Uri patchedSdk, Uri fullOutput,
    {Uri outlineOutput,
    Uri packages,
    bool verbose: false,
    String backendTarget}) async {
  backendTarget ??= "vm_fasta";
  Ticker ticker = new Ticker(isVerbose: verbose);
  await CompilerCommandLine.withGlobalOptions("", [""], (CompilerContext c) {
    c.options.options["--target"] = backendTarget;
    c.options.options["--packages"] = packages;
    if (verbose) {
      c.options.options["--verbose"] = true;
    }
    c.options.validate();
    return compilePlatformInternal(
        c, ticker, patchedSdk, fullOutput, outlineOutput);
  });
}

// TODO(sigmund): reimplement this API using the directive listener intead.
Future<List<Uri>> getDependencies(Uri script,
    {Uri sdk,
    Uri packages,
    Uri platform,
    bool verbose: false,
    String backendTarget}) async {
  backendTarget ??= "vm_fasta";
  Ticker ticker = new Ticker(isVerbose: verbose);
  return await CompilerCommandLine.withGlobalOptions("", [""],
      (CompilerContext c) async {
    c.options.options["--target"] = backendTarget;
    c.options.options["--strong-mode"] = false;
    c.options.options["--packages"] = packages;
    if (verbose) {
      c.options.options["--verbose"] = true;
    }
    c.options.validate();
    sdk ??= c.options.sdk;

    UriTranslator uriTranslator = await UriTranslatorImpl
        .parse(c.fileSystem, sdk, packages: c.options.packages);
    ticker.logMs("Read packages file");
    DillTarget dillTarget =
        new DillTarget(ticker, uriTranslator, c.options.target);
    if (platform != null) _appendDillForUri(dillTarget, platform);
    KernelTarget kernelTarget = new KernelTarget(
        PhysicalFileSystem.instance, dillTarget, uriTranslator, c.uriToSource);

    kernelTarget.read(script);
    await dillTarget.buildOutlines();
    await kernelTarget.loader.buildOutlines();
    return await kernelTarget.loader.getDependencies();
  });
}

/// Load the [Program] from the given [uri] and append its libraries
/// to the [dillTarget].
void _appendDillForUri(DillTarget dillTarget, Uri uri) {
  var bytes = new File.fromUri(uri).readAsBytesSync();
  var platformProgram = loadProgramFromBytes(bytes);
  platformProgram.unbindCanonicalNames();
  dillTarget.loader.appendLibraries(platformProgram);
}

// TODO(ahe): https://github.com/dart-lang/sdk/issues/28316
class ByteSink implements Sink<List<int>> {
  final BytesBuilder builder = new BytesBuilder();

  void add(List<int> data) {
    builder.add(data);
  }

  void close() {
    // Nothing to do.
  }
}

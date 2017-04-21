// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta;

import 'dart:async' show Future;

import 'dart:convert' show JSON;

import 'dart:io' show BytesBuilder, Directory, File, exitCode;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/kernel.dart' show Program;

import 'package:kernel/target/targets.dart' show Target, TargetFlags, getTarget;

import 'compiler_command_line.dart' show CompilerCommandLine;

import 'compiler_context.dart' show CompilerContext;

import 'errors.dart' show InputError, formatUnexpected, inputError, reportCrash;

import 'kernel/kernel_target.dart' show KernelTarget;

import 'dill/dill_target.dart' show DillTarget;

import 'compile_platform.dart' show compilePlatformInternal;

import 'ticker.dart' show Ticker;

import 'translate_uri.dart' show TranslateUri;

import 'vm.dart' show CompilationResult;

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
  } on InputError catch (e) {
    exitCode = 1;
    print(e.format());
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
  } on InputError catch (e) {
    exitCode = 1;
    print(e.format());
    return null;
  }
}

class CompileTask {
  final CompilerContext c;
  final Ticker ticker;

  CompileTask(this.c, this.ticker);

  KernelTarget createKernelTarget(
      DillTarget dillTarget, TranslateUri uriTranslator) {
    return new KernelTarget(dillTarget, uriTranslator, c.uriToSource);
  }

  Future<KernelTarget> buildOutline([Uri output]) async {
    TranslateUri uriTranslator =
        await TranslateUri.parse(c.options.sdk, c.options.packages);
    ticker.logMs("Read packages file");
    DillTarget dillTarget = new DillTarget(ticker, uriTranslator);
    KernelTarget kernelTarget = createKernelTarget(dillTarget, uriTranslator);
    Uri platform = c.options.platform;
    if (platform != null) {
      dillTarget.read(platform);
    }
    String argument = c.options.arguments.first;
    Uri uri = Uri.base.resolve(argument);
    String path = uriTranslator.translate(uri)?.path ?? argument;
    if (path.endsWith(".dart")) {
      kernelTarget.read(uri);
    } else {
      inputError(uri, -1, "Unexpected input: $uri");
    }
    await dillTarget.writeOutline(null);
    await kernelTarget.writeOutline(output);
    if (c.options.dumpIr && output != null) {
      kernelTarget.dumpIr();
    }
    return kernelTarget;
  }

  Future<Uri> compile() async {
    KernelTarget kernelTarget = await buildOutline();
    if (exitCode != 0) return null;
    Uri uri = c.options.output;
    await kernelTarget.writeProgram(uri,
        dumpIr: c.options.dumpIr, verify: c.options.verify);
    return uri;
  }
}

Future<CompilationResult> parseScript(
    Uri fileName, Uri packages, Uri patchedSdk, bool verbose) async {
  try {
    if (!await new File.fromUri(fileName).exists()) {
      return new CompilationResult.error(
          formatUnexpected(fileName, -1, "No such file."));
    }
    if (!await new Directory.fromUri(patchedSdk).exists()) {
      return new CompilationResult.error(
          formatUnexpected(patchedSdk, -1, "Patched sdk directory not found."));
    }

    Target target = getTarget("vm", new TargetFlags(strongMode: false));

    Program program;
    final uriTranslator = await TranslateUri.parse(null, packages);
    final Ticker ticker = new Ticker(isVerbose: verbose);
    final DillTarget dillTarget = new DillTarget(ticker, uriTranslator);
    dillTarget.read(patchedSdk.resolve('platform.dill'));
    final KernelTarget kernelTarget =
        new KernelTarget(dillTarget, uriTranslator);
    try {
      kernelTarget.read(fileName);
      await dillTarget.writeOutline(null);
      program = await kernelTarget.writeOutline(null);
      program = await kernelTarget.writeProgram(null);
      if (kernelTarget.errors.isNotEmpty) {
        return new CompilationResult.errors(kernelTarget.errors
            .map((err) => err.toString())
            .toList(growable: false));
      }
    } on InputError catch (e) {
      return new CompilationResult.error(e.format());
    }

    // Perform target-specific transformations.
    target.performModularTransformations(program);
    target.performGlobalTransformations(program);

    // Write the program to a list of bytes and return it.
    var sink = new ByteSink();
    new BinaryPrinter(sink).writeProgramFile(program);
    return new CompilationResult.ok(sink.builder.takeBytes());
  } catch (e, s) {
    return reportCrash(e, s, fileName);
  }
}

Future compilePlatform(Uri patchedSdk, Uri output,
    {Uri packages, bool verbose: false}) async {
  Ticker ticker = new Ticker(isVerbose: verbose);
  await CompilerCommandLine.withGlobalOptions("", [""], (CompilerContext c) {
    c.options.options["--packages"] = packages;
    if (verbose) {
      c.options.options["--verbose"] = true;
    }
    return compilePlatformInternal(c, ticker, patchedSdk, output);
  });
}

Future writeDepsFile(Uri script, Uri depsFile, Uri output,
    {Uri packages,
    Uri platform,
    Iterable<Uri> extraDependencies,
    bool verbose: false}) async {
  Ticker ticker = new Ticker(isVerbose: verbose);
  await CompilerCommandLine.withGlobalOptions("", [""],
      (CompilerContext c) async {
    c.options.options["--packages"] = packages;
    if (verbose) {
      c.options.options["--verbose"] = true;
    }

    TranslateUri uriTranslator =
        await TranslateUri.parse(c.options.sdk, c.options.packages);
    ticker.logMs("Read packages file");
    DillTarget dillTarget = new DillTarget(ticker, uriTranslator)
      ..read(platform);
    KernelTarget kernelTarget =
        new KernelTarget(dillTarget, uriTranslator, c.uriToSource);

    kernelTarget.read(script);
    await dillTarget.writeOutline(null);
    await kernelTarget.loader.buildOutlines();
    await kernelTarget.writeDepsFile(output, depsFile,
        extraDependencies: extraDependencies);
  });
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

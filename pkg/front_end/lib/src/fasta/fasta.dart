// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta;

import 'dart:async' show Future;

import 'dart:convert' show JSON;

import 'dart:io' show BytesBuilder, Directory, File, exitCode;

import 'package:front_end/file_system.dart';
import 'package:front_end/physical_file_system.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:kernel/binary/ast_to_binary.dart'
    show LibraryFilteringBinaryPrinter;

import 'package:kernel/kernel.dart' show Library, Program, loadProgramFromBytes;

import 'package:kernel/target/targets.dart' show getTarget, TargetFlags;

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

  DillTarget createDillTarget(TranslateUri uriTranslator) {
    return new DillTarget(
        ticker,
        uriTranslator,
        getTarget(c.options.target,
            new TargetFlags(strongMode: c.options.strongMode)));
  }

  KernelTarget createKernelTarget(
      DillTarget dillTarget, TranslateUri uriTranslator, bool strongMode) {
    return new KernelTarget(
        c.fileSystem, dillTarget, uriTranslator, c.uriToSource);
  }

  Future<KernelTarget> buildOutline([Uri output]) async {
    TranslateUri uriTranslator = await TranslateUri
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
      inputError(uri, -1, "Unexpected input: $uri");
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

Future<CompilationResult> parseScript(
    Uri fileName, Uri packages, Uri patchedSdk,
    {bool verbose: false, bool strongMode: false}) async {
  return parseScriptInFileSystem(
      fileName, PhysicalFileSystem.instance, packages, patchedSdk,
      verbose: verbose, strongMode: strongMode);
}

Future<CompilationResult> parseScriptInFileSystem(
    Uri fileName, FileSystem fileSystem, Uri packages, Uri patchedSdk,
    {bool verbose: false, bool strongMode: false, String backendTarget}) async {
  backendTarget ??= "vm_fasta";
  try {
    if (!await fileSystem.entityForUri(fileName).exists()) {
      return new CompilationResult.error(
          formatUnexpected(fileName, -1, "No such file."));
    }
    if (!await new Directory.fromUri(patchedSdk).exists()) {
      return new CompilationResult.error(
          formatUnexpected(patchedSdk, -1, "Patched sdk directory not found."));
    }

    Program program;
    try {
      TranslateUri uriTranslator =
          await TranslateUri.parse(fileSystem, patchedSdk, packages: packages);
      final Ticker ticker = new Ticker(isVerbose: verbose);
      final DillTarget dillTarget = new DillTarget(ticker, uriTranslator,
          getTarget(backendTarget, new TargetFlags(strongMode: strongMode)));
      _appendDillForUri(dillTarget, patchedSdk.resolve('platform.dill'));
      final KernelTarget kernelTarget =
          new KernelTarget(fileSystem, dillTarget, uriTranslator);
      kernelTarget.read(fileName);
      await dillTarget.buildOutlines();
      await kernelTarget.buildOutlines();
      program = await kernelTarget.buildProgram();
      if (kernelTarget.errors.isNotEmpty) {
        return new CompilationResult.errors(kernelTarget.errors);
      }
    } on InputError catch (e) {
      return new CompilationResult.error(e.format());
    }

    if (program.mainMethod == null) {
      return new CompilationResult.error("No 'main' method found.");
    }

    // Write the program to a list of bytes and return it.  Do not include
    // libraries that have a dart: import URI.
    //
    // TODO(kmillikin): This is intended to exclude platform libraries that are
    // included in the Kernel binary platform platform.dill.  It does not
    // necessarily exclude exactly the platform libraries.  Use a better
    // predicate that knows what is included in platform.dill.
    var sink = new ByteSink();
    bool predicate(Library library) => !library.importUri.isScheme('dart');
    new LibraryFilteringBinaryPrinter(sink, predicate)
        .writeProgramFile(program);
    return new CompilationResult.ok(sink.builder.takeBytes());
  } catch (e, s) {
    return reportCrash(e, s, fileName);
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
    return compilePlatformInternal(
        c, ticker, patchedSdk, fullOutput, outlineOutput);
  });
}

Future writeDepsFile(Uri script, Uri depsFile, Uri output,
    {Uri sdk,
    Uri packages,
    Uri platform,
    Iterable<Uri> extraDependencies,
    bool verbose: false,
    String backendTarget}) async {
  backendTarget ??= "vm_fasta";
  Ticker ticker = new Ticker(isVerbose: verbose);
  await CompilerCommandLine.withGlobalOptions("", [""],
      (CompilerContext c) async {
    c.options.options["--packages"] = packages;
    if (verbose) {
      c.options.options["--verbose"] = true;
    }
    sdk ??= c.options.sdk;

    TranslateUri uriTranslator = await TranslateUri.parse(c.fileSystem, sdk,
        packages: c.options.packages);
    ticker.logMs("Read packages file");
    DillTarget dillTarget = new DillTarget(ticker, uriTranslator,
        getTarget(backendTarget, new TargetFlags(strongMode: false)));
    _appendDillForUri(dillTarget, platform);
    KernelTarget kernelTarget = new KernelTarget(
        PhysicalFileSystem.instance, dillTarget, uriTranslator, c.uriToSource);

    kernelTarget.read(script);
    await dillTarget.buildOutlines();
    await kernelTarget.loader.buildOutlines();
    await kernelTarget.writeDepsFile(output, depsFile,
        extraDependencies: extraDependencies);
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

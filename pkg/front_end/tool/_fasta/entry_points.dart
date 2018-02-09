// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.tool.entry_points;

import 'dart:async' show Future, Stream;

import 'dart:convert' show JSON, LineSplitter, UTF8;

import 'dart:io' show File, exitCode, stderr, stdin, stdout;

import 'package:compiler/src/kernel/dart2js_target.dart' show Dart2jsTarget;

import 'package:kernel/kernel.dart'
    show CanonicalName, Library, Program, Source, loadProgramFromBytes;

import 'package:kernel/target/targets.dart' show TargetFlags, targets;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

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

import 'command_line.dart' show withGlobalOptions;

const bool summary = const bool.fromEnvironment("summary", defaultValue: false);

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

compileEntryPoint(List<String> arguments) async {
  targets["dart2js"] = (TargetFlags flags) => new Dart2jsTarget(flags);

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

batchEntryPoint(List<String> arguments) {
  return new BatchCompiler(
          stdin.transform(UTF8.decoder).transform(new LineSplitter()))
      .run();
}

class BatchCompiler {
  final Stream lines;

  Uri platformUri;

  Program platformComponent;

  BatchCompiler(this.lines);

  run() async {
    await for (String line in lines) {
      try {
        if (await batchCompile(line)) {
          stdout.writeln(">>> TEST OK");
        } else {
          stdout.writeln(">>> TEST FAIL");
        }
      } catch (e, trace) {
        stderr.writeln("Unhandled exception:\n  $e");
        stderr.writeln(trace);
        stdout.writeln(">>> TEST CRASH");
      }
      await stdout.flush();
      stderr.writeln(">>> EOF STDERR");
      await stderr.flush();
    }
  }

  Future<bool> batchCompile(String line) async {
    List<String> arguments = new List<String>.from(JSON.decode(line));
    try {
      return await withGlobalOptions("compile", arguments, true,
          (CompilerContext c, _) async {
        ProcessedOptions options = c.options;
        bool verbose = options.verbose;
        Ticker ticker = new Ticker(isVerbose: verbose);
        if (verbose) {
          print("Compiling directly to Kernel: $line");
        }
        if (platformComponent == null || platformUri != options.sdkSummary) {
          platformUri = options.sdkSummary;
          platformComponent = await options.loadSdkSummary(null);
        } else {
          options.sdkSummaryComponent = platformComponent;
        }
        CompileTask task = new CompileTask(c, ticker);
        await task.compile(sansPlatform: true);
        CanonicalName root = platformComponent.root;
        for (Library library in platformComponent.libraries) {
          library.parent = platformComponent;
          CanonicalName name = library.reference.canonicalName;
          if (name != null && name.parent != root) {
            root.adoptChild(name);
          }
        }
        root.unbindAll();
        return c.errors.isEmpty;
      });
    } on deprecated_InputError catch (e) {
      CompilerContext.runWithDefaultOptions(
          (c) => c.report(deprecated_InputError.toMessage(e), Severity.error));
      return false;
    }
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

  Future<Uri> compile({bool sansPlatform: false}) async {
    KernelTarget kernelTarget = await buildOutline();
    if (exitCode != 0) return null;
    Uri uri = c.options.output;
    Program program = await kernelTarget.buildProgram(verify: c.options.verify);
    if (c.options.debugDump) {
      printProgramText(program, libraryFilter: kernelTarget.isSourceLibrary);
    }
    if (sansPlatform) {
      program.computeCanonicalNames();
      Program userCode = new Program(
          nameRoot: program.root,
          uriToSource: new Map<Uri, Source>.from(program.uriToSource));
      userCode.mainMethodName = program.mainMethodName;
      for (Library library in program.libraries) {
        if (library.importUri.scheme != "dart") {
          userCode.libraries.add(library);
        }
      }
      program = userCode;
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
  dillTarget.loader.appendLibraries(platformProgram, byteCount: bytes.length);
}

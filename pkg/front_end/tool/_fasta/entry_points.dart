// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.tool.entry_points;

import 'dart:convert' show JsonEncoder, LineSplitter, jsonDecode, utf8;
import 'dart:io'
    show File, Platform, ProcessSignal, exit, exitCode, stderr, stdin, stdout;

import 'package:_fe_analyzer_shared/src/util/relativize.dart'
    show isWindows, relativizeUri;
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';
import 'package:front_end/src/api_prototype/kernel_generator.dart';
import 'package:front_end/src/base/command_line_options.dart';
import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;
import 'package:front_end/src/fasta/codes/fasta_codes.dart'
    show codeInternalProblemVerificationError;
import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;
import 'package:front_end/src/fasta/get_dependencies.dart' show getDependencies;
import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;
import 'package:front_end/src/fasta/kernel/benchmarker.dart'
    show BenchmarkPhases, Benchmarker;
import 'package:front_end/src/fasta/kernel/utils.dart'
    show writeComponentToFile;
import 'package:front_end/src/kernel_generator_impl.dart'
    show generateKernelInternal;
import 'package:front_end/src/linux_and_intel_specific_perf.dart';
import 'package:kernel/kernel.dart'
    show Component, Library, RecursiveVisitor, Source;
import 'package:kernel/src/types.dart' show Types;
import 'package:kernel/target/targets.dart' show Target, TargetFlags, getTarget;
import 'package:kernel/verifier.dart';

import '../../test/coverage_helper.dart';
import 'additional_targets.dart' show installAdditionalTargets;
import 'bench_maker.dart' show BenchMaker;
import 'command_line.dart' show runProtectedFromAbort, withGlobalOptions;

const bool benchmark =
    const bool.fromEnvironment("benchmark", defaultValue: false);

const bool summary =
    const bool.fromEnvironment("summary", defaultValue: false) || benchmark;

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

Future<void> compileEntryPoint(List<String> arguments) async {
  if (Platform.environment["dart_cfe_intel_pt"] == "true") {
    print("Notice: Locating perf for profiling using intel_pt events.");
    linuxAndIntelSpecificPerf(onlyInitialize: true);
  }
  installAdditionalTargets();

  // Timing results for each iteration
  List<double> elapsedTimes = <double>[];
  List<Benchmarker> benchmarkers = <Benchmarker>[];

  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n\n=== Iteration ${i + 1} of $iterations");
    }
    Stopwatch stopwatch = new Stopwatch()..start();
    Benchmarker? benchmarker;
    if (benchmark) {
      benchmarker = new Benchmarker();
      benchmarkers.add(benchmarker);
    }
    await compile(arguments, benchmarker: benchmarker);
    benchmarker?.stop();
    stopwatch.stop();

    elapsedTimes.add(stopwatch.elapsedMilliseconds.toDouble());
    List<Object>? typeChecks = Types.typeChecksForTesting;
    if (typeChecks?.isNotEmpty ?? false) {
      BenchMaker.writeTypeChecks("type_checks.json", typeChecks!);
    }
  }

  summarize(elapsedTimes, benchmarkers);
}

Future<void> outlineEntryPoint(List<String> arguments) async {
  installAdditionalTargets();

  // Timing results for each iteration
  List<double> elapsedTimes = <double>[];
  List<Benchmarker> benchmarkers = <Benchmarker>[];

  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n\n=== Iteration ${i + 1} of $iterations");
    }
    Stopwatch stopwatch = new Stopwatch()..start();
    Benchmarker? benchmarker;
    if (benchmark) {
      benchmarker = new Benchmarker();
      benchmarkers.add(benchmarker);
    }
    await outline(arguments, benchmarker: benchmarker);
    benchmarker?.stop();
    stopwatch.stop();

    elapsedTimes.add(stopwatch.elapsedMilliseconds.toDouble());
  }

  summarize(elapsedTimes, benchmarkers);
}

void summarize(List<double> elapsedTimes, List<Benchmarker> benchmarkers) {
  if (summary) {
    Map<String, dynamic> map = <String, dynamic>{
      'elapsedTimes': elapsedTimes,
      if (benchmarkers.isNotEmpty) 'benchmarkers': benchmarkers
    };
    JsonEncoder encoder = new JsonEncoder.withIndent("  ");
    String json = encoder.convert(map);
    print('\nSummary:\n\n$json\n');
  } else {
    assert(benchmarkers.isEmpty);
  }
}

Future<void> depsEntryPoint(List<String> arguments) async {
  installAdditionalTargets();

  for (int i = 0; i < iterations; i++) {
    if (i > 1) {
      print("\n");
    }
    await deps(arguments);
  }
}

Future<void> compilePlatformEntryPoint(List<String> arguments) async {
  installAdditionalTargets();
  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n");
    }
    await runProtectedFromAbort<void>(() => compilePlatform(arguments));
  }
}

Future<void> batchEntryPoint(List<String> arguments) async {
  if (shouldCollectCoverage()) {
    tryListenToSignal(ProcessSignal.sigterm,
        () => possiblyCollectCoverage("batch_compiler", doExit: true));
  }
  installAdditionalTargets();
  await new BatchCompiler(
          stdin.transform(utf8.decoder).transform(new LineSplitter()))
      .run();
}

void tryListenToSignal(ProcessSignal signal, void Function() callback) {
  try {
    signal.watch().listen(
      (_) => callback(),
      onError: (_) {
        // swallow.
      },
    );
  } catch (e) {
    // swallow.
  }
}

const String cfeCoverageEnvironmentVariable = "CFE_COVERAGE";

bool shouldCollectCoverage() {
  String? coverage = Platform.environment[cfeCoverageEnvironmentVariable];
  if (coverage != null) return true;
  return false;
}

Future<void> possiblyCollectCoverage(String displayNamePrefix,
    {required bool doExit}) async {
  String? coverage = Platform.environment[cfeCoverageEnvironmentVariable];

  if (coverage != null) {
    assert(shouldCollectCoverage());
    Uri coverageUri = Uri.base.resolveUri(Uri.file(coverage));
    String displayName =
        "${displayNamePrefix}_${DateTime.now().microsecondsSinceEpoch}";
    File f = new File.fromUri(coverageUri.resolve("$displayName.coverage"));
    // Force compiling seems to add something like 1 second to the collection
    // time, but we get rid of uncompiled functions so it seems to be worth it.
    (await collectCoverage(displayName: displayName, forceCompile: true))
        ?.writeToFile(f);
  }

  if (doExit) {
    exit(exitCode);
  }
}

class BatchCompiler {
  final Stream<String>? lines;

  Uri? platformUri;

  Component? platformComponent;

  bool hadVerifyError = false;

  IncrementalCompiler? _incrementalCompiler;

  List<DiagnosticMessage> _errors = [];

  void Function(DiagnosticMessage)? _originalOnDiagnostic;

  BatchCompiler(this.lines);

  Future<void> run() async {
    await for (String line in lines!) {
      try {
        if (await batchCompileArguments(
            new List<String>.from(jsonDecode(line)))) {
          stdout.writeln(">>> TEST OK");
        } else {
          stdout.writeln(">>> TEST FAIL");
        }
      } catch (e, trace) {
        stderr.writeln("Unhandled exception:\n  $e");
        stderr.writeln(trace);
        stdout.writeln(">>> TEST CRASH");
        _incrementalCompiler = null;
      }
      await stdout.flush();
      stderr.writeln(">>> EOF STDERR");
      await stderr.flush();
    }
  }

  Future<bool> batchCompileArguments(List<String> arguments) {
    return runProtectedFromAbort<bool>(
        () => withGlobalOptions<bool>(
            "compile",
            [Flags.omitPlatform, ...arguments],
            true,
            (CompilerContext c, _) => batchCompileImpl(c)),
        false);
  }

  Future<bool> batchCompile(CompilerOptions options, Uri input, Uri output) {
    return CompilerContext.runWithOptions(
        new ProcessedOptions(
            options: options, inputs: <Uri>[input], output: output),
        batchCompileImpl);
  }

  void _onDiagnostic(DiagnosticMessage message) {
    _errors.add(message);
    if (_originalOnDiagnostic != null) {
      _originalOnDiagnostic!(message);
    }
  }

  Future<bool> batchCompileImpl(CompilerContext context) async {
    _errors.clear();
    ProcessedOptions options = context.options;
    bool createNewCompiler = false;
    if (_incrementalCompiler == null ||
        !_incrementalCompiler!.context.options.equivalent(options)) {
      createNewCompiler = true;
    }

    if (platformComponent == null ||
        platformUri != options.sdkSummary ||
        hadVerifyError) {
      createNewCompiler = true;
      platformUri = options.sdkSummary;
      platformComponent = await options.loadSdkSummary(null);
      if (platformComponent == null) {
        throw "platformComponent is null";
      }
      hadVerifyError = false;
    }

    if (createNewCompiler) {
      platformComponent!.adoptChildren();
      _incrementalCompiler =
          new IncrementalCompiler.fromComponent(context, platformComponent);
    }

    ProcessedOptions incrementalCompilerOptions =
        _incrementalCompiler!.context.options;
    if (!identical(incrementalCompilerOptions.inputs, options.inputs)) {
      // Invalidating the packages uri causes it to recalculate which packages
      // file to use which is what we want.
      _incrementalCompiler!.invalidate(incrementalCompilerOptions.packagesUri);
      incrementalCompilerOptions.inputs.clear();
      incrementalCompilerOptions.inputs.addAll(options.inputs);
    }

    _originalOnDiagnostic = options.rawOptionsForTesting.onDiagnostic ??
        options.defaultDiagnosticMessageHandler;
    incrementalCompilerOptions.rawOptionsForTesting.onDiagnostic =
        _onDiagnostic;

    // This is a weird one, but apparently this is how it's done.
    incrementalCompilerOptions.reportNullSafetyCompilationModeInfo();

    assert(options.omitPlatform,
        "Platform must be omitted for the batch compiler.");
    assert(!options.hasAdditionalDills,
        "Additional dills are not supported for the batch compiler.");
    IncrementalCompilerResult compilerResult =
        await _incrementalCompiler!.computeDelta(fullComponent: true);
    await _emitComponent(options, compilerResult.component,
        message: "Wrote component to ");
    for (DiagnosticMessage error in _errors) {
      if (error.codeName == codeInternalProblemVerificationError.name) {
        hadVerifyError = true;
      }
    }
    return _errors.isEmpty;
  }
}

Future<void> incrementalEntryPoint(List<String> arguments) async {
  installAdditionalTargets();
  await withGlobalOptions("incremental", arguments, true,
      (CompilerContext c, _) {
    // TODO(ahe): Extend this entry point so it can replace
    // batchEntryPoint.
    new IncrementalCompiler(c);
    return Future<void>.value();
  });
}

Future<void> outline(List<String> arguments, {Benchmarker? benchmarker}) async {
  return await runProtectedFromAbort<void>(() async {
    return await withGlobalOptions("outline", arguments, true,
        (CompilerContext c, _) async {
      if (c.options.verbose) {
        print("Building outlines for ${arguments.join(' ')}");
      }
      CompilerResult compilerResult = await generateKernelInternal(
          buildSummary: true, benchmarker: benchmarker);
      Component component = compilerResult.component!;
      await _emitComponent(c.options, component,
          benchmarker: benchmarker, message: "Wrote outline to ");
    });
  });
}

Future<Uri> compile(List<String> arguments, {Benchmarker? benchmarker}) async {
  return await runProtectedFromAbort<Uri>(() async {
    return await withGlobalOptions("compile", arguments, true,
        (CompilerContext c, _) async {
      if (c.options.verbose) {
        print("Compiling directly to Kernel: ${arguments.join(' ')}");
      }
      CompilerResult compilerResult =
          await generateKernelInternal(benchmarker: benchmarker);
      Component component = compilerResult.component!;
      Uri uri = await _emitComponent(c.options, component,
          benchmarker: benchmarker, message: "Wrote component to ");
      _benchmarkAstVisitor(component, benchmarker);
      return uri;
    });
  });
}

Future<Uri?> deps(List<String> arguments) async {
  return await runProtectedFromAbort<Uri?>(() async {
    return await withGlobalOptions("deps", arguments, true,
        (CompilerContext c, _) async {
      if (c.options.verbose) {
        print("Computing deps: ${arguments.join(' ')}");
      }
      await generateKernelInternal(buildSummary: true);
      return await _emitDeps(c, c.options.output);
    });
  });
}

/// Writes the [component] to the URI specified in the compiler options.
Future<Uri> _emitComponent(ProcessedOptions options, Component component,
    {Benchmarker? benchmarker, required String message}) async {
  Uri uri = options.output!;
  if (options.omitPlatform) {
    benchmarker?.enterPhase(BenchmarkPhases.omitPlatform);
    component.computeCanonicalNames();
    Component userCode = new Component(
        nameRoot: component.root,
        uriToSource: new Map<Uri, Source>.from(component.uriToSource));
    userCode.setMainMethodAndMode(
        component.mainMethodName, true, component.mode);
    for (Library library in component.libraries) {
      if (!library.importUri.isScheme("dart")) {
        userCode.libraries.add(library);
      }
    }
    component = userCode;
  }
  if (uri.isScheme("file")) {
    benchmarker?.enterPhase(BenchmarkPhases.writeComponent);
    await writeComponentToFile(component, uri);
    options.ticker.logMs("${message}${uri.toFilePath()}");
  }
  return uri;
}

Future<Uri?> _emitDeps(CompilerContext context, [Uri? output]) async {
  Uri? dFile;
  if (output != null) {
    dFile = new File(new File.fromUri(output).path + ".d").uri;
    await writeDepsFile(output, dFile, context.dependencies);
  }
  return dFile;
}

/// Runs a visitor on [component] for benchmarking.
void _benchmarkAstVisitor(Component component, Benchmarker? benchmarker) {
  if (benchmarker != null) {
    // When benchmarking also do a recursive visit of the produced component
    // that does nothing other than visiting everything. Do this to produce
    // a reference point for comparing inference time and serialization time.
    benchmarker.enterPhase(BenchmarkPhases.benchmarkAstVisit);
    component.accept(new EmptyRecursiveVisitorForBenchmarking());
  }
  benchmarker?.enterPhase(BenchmarkPhases.unknown);
}

class EmptyRecursiveVisitorForBenchmarking extends RecursiveVisitor {}

Future<void> compilePlatform(List<String> arguments) async {
  await withGlobalOptions("compile_platform", arguments, false,
      (CompilerContext c, List<String> restArguments) {
    c.compilingPlatform = true;
    Uri hostPlatform = Uri.base.resolveUri(new Uri.file(restArguments[2]));
    Uri outlineOutput = Uri.base.resolveUri(new Uri.file(restArguments[4]));
    return compilePlatformInternal(
        c, c.options.output!, outlineOutput, hostPlatform);
  });
}

Future<void> compilePlatformInternal(CompilerContext c, Uri fullOutput,
    Uri outlineOutput, Uri hostPlatform) async {
  if (c.options.verbose) {
    print("Generating outline of ${c.options.sdkRoot} into $outlineOutput");
    print("Compiling ${c.options.sdkRoot} to $fullOutput");
  }

  CompilerResult result =
      await generateKernelInternal(buildSummary: true, buildComponent: true);
  new File.fromUri(outlineOutput).writeAsBytesSync(result.summary!);
  c.options.ticker.logMs("Wrote outline to ${outlineOutput.toFilePath()}");

  verifyComponent(c.options.target,
      VerificationStage.afterModularTransformations, result.component!);
  await writeComponentToFile(result.component!, fullOutput);

  c.options.ticker.logMs("Wrote component to ${fullOutput.toFilePath()}");

  if (c.options.emitDeps) {
    List<Uri> deps = result.deps.toList();
    for (Uri dependency in await computeHostDependencies(hostPlatform)) {
      // Add the dependencies of the compiler's own sources.
      if (dependency != outlineOutput) {
        // We're computing the dependencies for [outlineOutput], so we shouldn't
        // include it in the deps file.
        deps.add(dependency);
      }
    }
    await writeDepsFile(fullOutput,
        new File(new File.fromUri(fullOutput).path + ".d").uri, deps);
  }
}

Future<List<Uri>> computeHostDependencies(Uri hostPlatform) {
  // Returns a list of source files that make up the Fasta compiler (the files
  // the Dart VM reads to run Fasta). Until Fasta is self-hosting (in strong
  // mode), this is only an approximation, albeit accurate.  Once Fasta is
  // self-hosting, this isn't an approximation. Regardless, strong mode
  // shouldn't affect which files are read.
  Target? hostTarget = getTarget("vm", new TargetFlags());
  return getDependencies(Platform.script,
      platform: hostPlatform, target: hostTarget);
}

Future<void> writeDepsFile(
    Uri output, Uri depsFile, List<Uri> allDependencies) async {
  if (allDependencies.isEmpty) return;
  String toRelativeFilePath(Uri uri) {
    // Ninja expects to find file names relative to the current working
    // directory. We've tried making them relative to the deps file, but that
    // doesn't work for downstream projects. Making them absolute also
    // doesn't work.
    //
    // We can test if it works by running ninja twice, for example:
    //
    //     ninja -C xcodebuild/ReleaseX64 -d explain compile_platform
    //     ninja -C xcodebuild/ReleaseX64 -d explain compile_platform
    //
    // The second time, ninja should say:
    //
    //     ninja: Entering directory `xcodebuild/ReleaseX64'
    //     ninja: no work to do.
    //
    // It's broken if it says something like this:
    //
    //     ninja explain: expected depfile 'vm_platform.dill.d' to mention \
    //     'vm_platform.dill', got '/.../xcodebuild/ReleaseX64/vm_platform.dill'
    return Uri.parse(relativizeUri(Uri.base, uri, isWindows)).toFilePath();
  }

  StringBuffer sb = new StringBuffer();
  sb.write(toRelativeFilePath(output));
  sb.write(":");
  List<String> paths = new List<String>.generate(
      allDependencies.length, (int i) => toRelativeFilePath(allDependencies[i]),
      growable: false);
  // Sort the relative paths to ease analyzing future changes to this code.
  paths.sort();
  String? previous;
  for (String path in paths) {
    // Check for and omit duplicates.
    if (path != previous) {
      previous = path;
      sb.write(" \\\n  ");
      sb.write(path);
    }
  }
  sb.writeln();
  await new File.fromUri(depsFile).writeAsString("$sb");
}

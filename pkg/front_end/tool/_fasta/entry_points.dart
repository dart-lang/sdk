// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.tool.entry_points;

import 'dart:convert' show LineSplitter, jsonDecode, jsonEncode, utf8;

import 'dart:io' show File, Platform, exitCode, stderr, stdin, stdout;

import 'package:_fe_analyzer_shared/src/util/relativize.dart'
    show isWindows, relativizeUri;

import 'package:front_end/src/fasta/fasta_codes.dart'
    show LocatedMessage, codeInternalProblemVerificationError;

import 'package:kernel/kernel.dart'
    show CanonicalName, Library, Component, Source, loadComponentFromBytes;

import 'package:kernel/target/targets.dart' show Target, TargetFlags, getTarget;

import 'package:kernel/src/types.dart' show Types;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;

import 'package:front_end/src/fasta/get_dependencies.dart' show getDependencies;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;

import 'package:front_end/src/fasta/kernel/utils.dart'
    show printComponentText, writeComponentToFile;

import 'package:front_end/src/fasta/ticker.dart' show Ticker;

import 'package:front_end/src/fasta/uri_translator.dart' show UriTranslator;

import 'package:front_end/src/kernel_generator_impl.dart'
    show generateKernelInternal;

import 'additional_targets.dart' show installAdditionalTargets;

import 'bench_maker.dart' show BenchMaker;

import 'command_line.dart' show runProtectedFromAbort, withGlobalOptions;

const bool summary = const bool.fromEnvironment("summary", defaultValue: false);

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

compileEntryPoint(List<String> arguments) async {
  installAdditionalTargets();

  // Timing results for each iteration
  List<double> elapsedTimes = <double>[];

  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n\n=== Iteration ${i + 1} of $iterations");
    }
    var stopwatch = new Stopwatch()..start();
    await compile(arguments);
    stopwatch.stop();

    elapsedTimes.add(stopwatch.elapsedMilliseconds.toDouble());
    List<Object> typeChecks = Types.typeChecksForTesting;
    if (typeChecks?.isNotEmpty ?? false) {
      BenchMaker.writeTypeChecks("type_checks.json", typeChecks);
    }
  }

  if (summary) {
    var json = jsonEncode(<String, dynamic>{'elapsedTimes': elapsedTimes});
    print('\nSummary: $json');
  }
}

outlineEntryPoint(List<String> arguments) async {
  installAdditionalTargets();

  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n");
    }
    await outline(arguments);
  }
}

depsEntryPoint(List<String> arguments) async {
  installAdditionalTargets();

  for (int i = 0; i < iterations; i++) {
    if (i > 1) {
      print("\n");
    }
    await deps(arguments);
  }
}

compilePlatformEntryPoint(List<String> arguments) async {
  installAdditionalTargets();
  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n");
    }
    await runProtectedFromAbort<void>(() => compilePlatform(arguments));
  }
}

batchEntryPoint(List<String> arguments) {
  installAdditionalTargets();
  return new BatchCompiler(
          stdin.transform(utf8.decoder).transform(new LineSplitter()))
      .run();
}

class BatchCompiler {
  final Stream<String> lines;

  Uri platformUri;

  Component platformComponent;

  bool hadVerifyError = false;

  BatchCompiler(this.lines);

  run() async {
    await for (String line in lines) {
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
      }
      await stdout.flush();
      stderr.writeln(">>> EOF STDERR");
      await stderr.flush();
    }
  }

  Future<bool> batchCompileArguments(List<String> arguments) async {
    return runProtectedFromAbort<bool>(
        () => withGlobalOptions<bool>("compile", arguments, true,
            (CompilerContext c, _) => batchCompileImpl(c)),
        false);
  }

  Future<bool> batchCompile(CompilerOptions options, Uri input, Uri output) {
    return CompilerContext.runWithOptions(
        new ProcessedOptions(
            options: options, inputs: <Uri>[input], output: output),
        batchCompileImpl);
  }

  Future<bool> batchCompileImpl(CompilerContext c) async {
    ProcessedOptions options = c.options;
    bool verbose = options.verbose;
    Ticker ticker = new Ticker(isVerbose: verbose);
    if (platformComponent == null ||
        platformUri != options.sdkSummary ||
        hadVerifyError) {
      platformUri = options.sdkSummary;
      platformComponent = await options.loadSdkSummary(null);
      if (platformComponent == null) {
        throw "platformComponent is null";
      }
      hadVerifyError = false;
    } else {
      options.sdkSummaryComponent = platformComponent;
    }
    CompileTask task = new CompileTask(c, ticker);
    await task.compile(omitPlatform: true, supportAdditionalDills: false);
    CanonicalName root = platformComponent.root;
    for (Library library in platformComponent.libraries) {
      library.parent = platformComponent;
      CanonicalName name = library.reference.canonicalName;
      if (name != null && name.parent != root) {
        root.adoptChild(name);
      }
    }
    for (Object error in c.errors) {
      if (error is LocatedMessage) {
        if (error.messageObject.code == codeInternalProblemVerificationError) {
          hadVerifyError = true;
        }
      }
    }
    return c.errors.isEmpty;
  }
}

incrementalEntryPoint(List<String> arguments) async {
  installAdditionalTargets();
  await withGlobalOptions("incremental", arguments, true,
      (CompilerContext c, _) {
    // TODO(ahe): Extend this entry point so it can replace
    // batchEntryPoint.
    new IncrementalCompiler(c);
    return Future<void>.value();
  });
}

Future<KernelTarget> outline(List<String> arguments) async {
  return await runProtectedFromAbort<KernelTarget>(() async {
    return await withGlobalOptions("outline", arguments, true,
        (CompilerContext c, _) async {
      if (c.options.verbose) {
        print("Building outlines for ${arguments.join(' ')}");
      }
      CompileTask task =
          new CompileTask(c, new Ticker(isVerbose: c.options.verbose));
      return await task.buildOutline(
          output: c.options.output, omitPlatform: c.options.omitPlatform);
    });
  });
}

Future<Uri> compile(List<String> arguments) async {
  return await runProtectedFromAbort<Uri>(() async {
    return await withGlobalOptions("compile", arguments, true,
        (CompilerContext c, _) async {
      if (c.options.verbose) {
        print("Compiling directly to Kernel: ${arguments.join(' ')}");
      }
      CompileTask task =
          new CompileTask(c, new Ticker(isVerbose: c.options.verbose));
      return await task.compile(omitPlatform: c.options.omitPlatform);
    });
  });
}

Future<Uri> deps(List<String> arguments) async {
  return await runProtectedFromAbort<Uri>(() async {
    return await withGlobalOptions("deps", arguments, true,
        (CompilerContext c, _) async {
      if (c.options.verbose) {
        print("Computing deps: ${arguments.join(' ')}");
      }
      CompileTask task =
          new CompileTask(c, new Ticker(isVerbose: c.options.verbose));
      return await task.buildDeps(c.options.output);
    });
  });
}

class CompileTask {
  final CompilerContext c;
  final Ticker ticker;

  CompileTask(this.c, this.ticker);

  DillTarget createDillTarget(UriTranslator uriTranslator) {
    return new DillTarget(ticker, uriTranslator, c.options.target);
  }

  KernelTarget createKernelTarget(
      DillTarget dillTarget, UriTranslator uriTranslator) {
    return new KernelTarget(c.fileSystem, false, dillTarget, uriTranslator);
  }

  Future<Uri> buildDeps([Uri output]) async {
    UriTranslator uriTranslator = await c.options.getUriTranslator();
    ticker.logMs("Read packages file");
    DillTarget dillTarget = createDillTarget(uriTranslator);
    KernelTarget kernelTarget = createKernelTarget(dillTarget, uriTranslator);
    Uri platform = c.options.sdkSummary;
    if (platform != null) {
      // TODO(CFE-Team): Probably this should be read through the filesystem as
      // well and the recording would be automatic.
      _appendDillForUri(dillTarget, platform);
      CompilerContext.recordDependency(platform);
    }
    kernelTarget.setEntryPoints(c.options.inputs);
    await dillTarget.buildOutlines();
    await kernelTarget.loader.buildOutlines();

    Uri dFile;
    if (output != null) {
      dFile = new File(new File.fromUri(output).path + ".d").uri;
      await writeDepsFile(output, dFile, c.dependencies);
    }
    return dFile;
  }

  Future<KernelTarget> buildOutline(
      {Uri output,
      bool omitPlatform: false,
      bool supportAdditionalDills: true}) async {
    UriTranslator uriTranslator = await c.options.getUriTranslator();
    ticker.logMs("Read packages file");
    DillTarget dillTarget = createDillTarget(uriTranslator);
    KernelTarget kernelTarget = createKernelTarget(dillTarget, uriTranslator);

    if (supportAdditionalDills) {
      Component sdkSummary = await c.options.loadSdkSummary(null);
      if (sdkSummary != null) {
        dillTarget.loader.appendLibraries(sdkSummary);
      }

      CanonicalName nameRoot = sdkSummary?.root ?? new CanonicalName.root();
      for (Component additionalDill
          in await c.options.loadAdditionalDills(nameRoot)) {
        dillTarget.loader.appendLibraries(additionalDill);
      }
    } else {
      Component sdkSummary = await c.options.loadSdkSummary(null);
      if (sdkSummary != null) {
        dillTarget.loader.appendLibraries(sdkSummary);
      }
    }

    kernelTarget.setEntryPoints(c.options.inputs);
    await dillTarget.buildOutlines();
    var outline = await kernelTarget.buildOutlines();
    if (c.options.debugDump && output != null) {
      printComponentText(outline, libraryFilter: kernelTarget.isSourceLibrary);
    }
    if (output != null) {
      if (omitPlatform) {
        outline.computeCanonicalNames();
        Component userCode = new Component(
            nameRoot: outline.root,
            uriToSource: new Map<Uri, Source>.from(outline.uriToSource));
        userCode.setMainMethodAndMode(
            outline.mainMethodName, true, outline.mode);
        for (Library library in outline.libraries) {
          if (library.importUri.scheme != "dart") {
            userCode.libraries.add(library);
          }
        }
        outline = userCode;
      }

      await writeComponentToFile(outline, output);
      ticker.logMs("Wrote outline to ${output.toFilePath()}");
    }
    return kernelTarget;
  }

  Future<Uri> compile(
      {bool omitPlatform: false, bool supportAdditionalDills: true}) async {
    KernelTarget kernelTarget =
        await buildOutline(supportAdditionalDills: supportAdditionalDills);
    Uri uri = c.options.output;
    Component component =
        await kernelTarget.buildComponent(verify: c.options.verify);
    if (c.options.debugDump) {
      printComponentText(component,
          libraryFilter: kernelTarget.isSourceLibrary);
    }
    if (omitPlatform) {
      component.computeCanonicalNames();
      Component userCode = new Component(
          nameRoot: component.root,
          uriToSource: new Map<Uri, Source>.from(component.uriToSource));
      userCode.setMainMethodAndMode(
          component.mainMethodName, true, component.mode);
      for (Library library in component.libraries) {
        if (library.importUri.scheme != "dart") {
          userCode.libraries.add(library);
        }
      }
      component = userCode;
    }
    if (uri.scheme == "file") {
      await writeComponentToFile(component, uri);
      ticker.logMs("Wrote component to ${uri.toFilePath()}");
    }
    return uri;
  }
}

/// Load the [Component] from the given [uri] and append its libraries
/// to the [dillTarget].
Component _appendDillForUri(DillTarget dillTarget, Uri uri) {
  var bytes = new File.fromUri(uri).readAsBytesSync();
  var platformComponent = loadComponentFromBytes(bytes);
  dillTarget.loader.appendLibraries(platformComponent, byteCount: bytes.length);
  return platformComponent;
}

Future<void> compilePlatform(List<String> arguments) async {
  await withGlobalOptions("compile_platform", arguments, false,
      (CompilerContext c, List<String> restArguments) {
    c.compilingPlatform = true;
    Uri hostPlatform = Uri.base.resolveUri(new Uri.file(restArguments[2]));
    Uri outlineOutput = Uri.base.resolveUri(new Uri.file(restArguments[4]));
    return compilePlatformInternal(
        c, c.options.output, outlineOutput, hostPlatform);
  });
}

Future<void> compilePlatformInternal(CompilerContext c, Uri fullOutput,
    Uri outlineOutput, Uri hostPlatform) async {
  if (c.options.verbose) {
    print("Generating outline of ${c.options.sdkRoot} into $outlineOutput");
    print("Compiling ${c.options.sdkRoot} to $fullOutput");
  }

  var result =
      await generateKernelInternal(buildSummary: true, buildComponent: true);
  if (result == null) {
    exitCode = 1;
    // Note: an error should have been reported by now.
    print('The platform .dill files were not created.');
    return;
  }
  new File.fromUri(outlineOutput).writeAsBytesSync(result.summary);
  c.options.ticker.logMs("Wrote outline to ${outlineOutput.toFilePath()}");

  await writeComponentToFile(result.component, fullOutput);

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

Future<List<Uri>> computeHostDependencies(Uri hostPlatform) async {
  // Returns a list of source files that make up the Fasta compiler (the files
  // the Dart VM reads to run Fasta). Until Fasta is self-hosting (in strong
  // mode), this is only an approximation, albeit accurate.  Once Fasta is
  // self-hosting, this isn't an approximation. Regardless, strong mode
  // shouldn't affect which files are read.
  Target hostTarget = getTarget("vm", new TargetFlags());
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
  List<String> paths = new List<String>.filled(allDependencies.length, null);
  for (int i = 0; i < allDependencies.length; i++) {
    paths[i] = toRelativeFilePath(allDependencies[i]);
  }
  // Sort the relative paths to ease analyzing future changes to this code.
  paths.sort();
  String previous;
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

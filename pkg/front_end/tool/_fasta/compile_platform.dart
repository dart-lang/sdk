// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compile_platform;

import 'dart:async' show Future;

import 'dart:io' show File, Platform, exitCode;

import 'package:compiler/src/kernel/dart2js_target.dart' show Dart2jsTarget;

import 'package:vm/bytecode/gen_bytecode.dart'
    show generateBytecode, kEnableKernelBytecodeForPlatform;

import 'package:vm/target/dart_runner.dart' show DartRunnerTarget;

import 'package:vm/target/flutter_runner.dart' show FlutterRunnerTarget;

import 'package:kernel/target/targets.dart' show TargetFlags, targets;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/deprecated_problems.dart'
    show deprecated_InputError;

import 'package:front_end/src/fasta/kernel/utils.dart'
    show writeComponentToFile;

import 'package:front_end/src/fasta/severity.dart' show Severity;

import 'package:front_end/src/kernel_generator_impl.dart'
    show generateKernelInternal;

import 'package:front_end/src/fasta/util/relativize.dart' show relativizeUri;

import 'package:front_end/src/fasta/get_dependencies.dart' show getDependencies;

import 'command_line.dart' show withGlobalOptions;

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

Future main(List<String> arguments) async {
  targets["dart2js"] =
      (TargetFlags flags) => new Dart2jsTarget("dart2js", flags);
  targets["dart2js_server"] =
      (TargetFlags flags) => new Dart2jsTarget("dart2js_server", flags);
  targets["dart_runner"] = (TargetFlags flags) => new DartRunnerTarget(flags);
  targets["flutter_runner"] =
      (TargetFlags flags) => new FlutterRunnerTarget(flags);
  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n");
    }
    try {
      await compilePlatform(arguments);
    } on deprecated_InputError catch (e) {
      exitCode = 1;
      CompilerContext.runWithDefaultOptions(
          (c) => c.report(deprecated_InputError.toMessage(e), Severity.error));
      return null;
    }
  }
}

Future compilePlatform(List<String> arguments) async {
  await withGlobalOptions("compile_platform", arguments, false,
      (CompilerContext c, List<String> restArguments) {
    Uri outlineOutput = Uri.base.resolveUri(new Uri.file(restArguments.last));
    return compilePlatformInternal(c, c.options.output, outlineOutput);
  });
}

Future compilePlatformInternal(
    CompilerContext c, Uri fullOutput, Uri outlineOutput) async {
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

  if (kEnableKernelBytecodeForPlatform) {
    generateBytecode(result.component, strongMode: c.options.strongMode);
  }

  await writeComponentToFile(result.component, fullOutput,
      filter: (lib) => !lib.isExternal);

  c.options.ticker.logMs("Wrote component to ${fullOutput.toFilePath()}");

  List<Uri> deps = result.deps.toList();
  deps.addAll(await getDependencies(Platform.script,
      platform: outlineOutput, target: c.options.target));
  await writeDepsFile(
      fullOutput, new File(new File.fromUri(fullOutput).path + ".d").uri, deps);
}

Future writeDepsFile(
    Uri output, Uri depsFile, Iterable<Uri> allDependencies) async {
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
    //     ninja explain: expected depfile 'vm_platform.dill.d' to mention 'vm_platform.dill', got '/.../xcodebuild/ReleaseX64/vm_platform.dill'
    return Uri.parse(relativizeUri(uri, base: Uri.base)).toFilePath();
  }

  StringBuffer sb = new StringBuffer();
  sb.write(toRelativeFilePath(output));
  sb.write(":");
  for (Uri uri in allDependencies) {
    sb.write(" \\\n  ");
    sb.write(toRelativeFilePath(uri));
  }
  sb.writeln();
  await new File.fromUri(depsFile).writeAsString("$sb");
}

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compile_platform;

import 'dart:async' show Future;

import 'dart:io' show File, Platform, exitCode;

import 'package:kernel/target/targets.dart' show Target, TargetFlags, getTarget;

import 'package:vm/bytecode/gen_bytecode.dart'
    show generateBytecode, isKernelBytecodeEnabledForPlatform;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/deprecated_problems.dart'
    show deprecated_InputError;

import 'package:front_end/src/fasta/get_dependencies.dart' show getDependencies;

import 'package:front_end/src/fasta/kernel/utils.dart'
    show writeComponentToFile;

import 'package:front_end/src/fasta/severity.dart' show Severity;

import 'package:front_end/src/fasta/util/relativize.dart' show relativizeUri;

import 'package:front_end/src/kernel_generator_impl.dart'
    show generateKernelInternal;

import 'additional_targets.dart' show installAdditionalTargets;

import 'command_line.dart' show withGlobalOptions;

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

Future main(List<String> arguments) async {
  installAdditionalTargets();
  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n");
    }
    try {
      await compilePlatform(arguments);
    } on deprecated_InputError catch (e) {
      exitCode = 1;
      await CompilerContext.runWithDefaultOptions((c) => new Future<void>.sync(
          () => c.report(deprecated_InputError.toMessage(e), Severity.error)));
      return null;
    }
  }
}

Future compilePlatform(List<String> arguments) async {
  await withGlobalOptions("compile_platform", arguments, false,
      (CompilerContext c, List<String> restArguments) {
    Uri hostPlatform = Uri.base.resolveUri(new Uri.file(restArguments[2]));
    Uri outlineOutput = Uri.base.resolveUri(new Uri.file(restArguments[4]));
    return compilePlatformInternal(
        c, c.options.output, outlineOutput, hostPlatform);
  });
}

Future compilePlatformInternal(CompilerContext c, Uri fullOutput,
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

  if (isKernelBytecodeEnabledForPlatform) {
    generateBytecode(result.component, strongMode: c.options.strongMode);
  }

  await writeComponentToFile(result.component, fullOutput,
      filter: (lib) => !lib.isExternal);

  c.options.ticker.logMs("Wrote component to ${fullOutput.toFilePath()}");

  List<Uri> deps = result.deps.toList();
  for (Uri dependency in await computeHostDependencies(hostPlatform)) {
    // Add the dependencies of the compiler's own sources.
    if (dependency != outlineOutput) {
      // We're computing the dependencies for [outlineOutput], so we shouldn't
      // include it in the deps file.
      deps.add(dependency);
    }
  }
  await writeDepsFile(
      fullOutput, new File(new File.fromUri(fullOutput).path + ".d").uri, deps);
}

Future<List<Uri>> computeHostDependencies(Uri hostPlatform) async {
  // Returns a list of source files that make up the Fasta compiler (the files
  // the Dart VM reads to run Fasta). Until Fasta is self-hosting (in strong
  // mode), this is only an approximation, albeit accurate.  Once Fasta is
  // self-hosting, this isn't an approximation. Regardless, strong mode
  // shouldn't affect which files are read.
  Target hostTarget = getTarget("vm", new TargetFlags(strongMode: true));
  return getDependencies(Platform.script,
      platform: hostPlatform, target: hostTarget);
}

Future writeDepsFile(
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
    return Uri.parse(relativizeUri(uri, base: Uri.base)).toFilePath();
  }

  StringBuffer sb = new StringBuffer();
  sb.write(toRelativeFilePath(output));
  sb.write(":");
  List<String> paths = new List<String>(allDependencies.length);
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

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compile_platform;

import 'dart:async' show Future;

import 'dart:io' show exitCode, File;

import '../../compiler_options.dart' show CompilerOptions;

import '../base/processed_options.dart' show ProcessedOptions;

import '../kernel_generator_impl.dart' show generateKernel;

import 'compiler_command_line.dart' show CompilerCommandLine;

import 'compiler_context.dart' show CompilerContext;

import 'deprecated_problems.dart' show deprecated_InputError;

import 'kernel/utils.dart' show writeProgramToFile;

import 'severity.dart' show Severity;

import 'ticker.dart' show Ticker;

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

Future mainEntryPoint(List<String> arguments) async {
  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n");
    }
    try {
      await compilePlatform(arguments);
    } on deprecated_InputError catch (e) {
      exitCode = 1;
      CompilerCommandLine.deprecated_withDefaultOptions(() => CompilerContext
          .current
          .report(deprecated_InputError.toMessage(e), Severity.error));
      return null;
    }
  }
}

Future compilePlatform(List<String> arguments) async {
  Ticker ticker = new Ticker();
  await CompilerCommandLine.withGlobalOptions("compile_platform", arguments,
      (CompilerContext c) {
    Uri patchedSdk = Uri.base.resolveUri(new Uri.file(c.options.arguments[0]));
    Uri fullOutput = Uri.base.resolveUri(new Uri.file(c.options.arguments[1]));
    Uri outlineOutput =
        Uri.base.resolveUri(new Uri.file(c.options.arguments[2]));
    return compilePlatformInternal(
        c, ticker, patchedSdk, fullOutput, outlineOutput);
  });
}

Future compilePlatformInternal(CompilerContext c, Ticker ticker, Uri patchedSdk,
    Uri fullOutput, Uri outlineOutput) async {
  var options = new CompilerOptions()
    ..strongMode = c.options.strongMode
    ..sdkRoot = patchedSdk
    ..packagesFileUri = c.options.packages
    ..compileSdk = true
    ..chaseDependencies = true
    ..target = c.options.target
    ..debugDump = c.options.dumpIr
    ..verify = c.options.verify
    ..verbose = c.options.verbose;

  if (options.strongMode) {
    print("Note: strong mode support is preliminary and may not work.");
  }
  if (options.verbose) {
    print("Generating outline of $patchedSdk into $outlineOutput");
    print("Compiling $patchedSdk to $fullOutput");
  }

  var result = await generateKernel(
      new ProcessedOptions(options, false, [Uri.parse('dart:core')]),
      buildSummary: true,
      buildProgram: true);
  new File.fromUri(outlineOutput).writeAsBytesSync(result.summary);
  ticker.logMs("Wrote outline to ${outlineOutput.toFilePath()}");
  await writeProgramToFile(result.program, fullOutput);
  ticker.logMs("Wrote program to ${fullOutput.toFilePath()}");
}

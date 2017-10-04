// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compile_platform;

import 'dart:async' show Future;

import 'dart:io' show exitCode, File;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/deprecated_problems.dart'
    show deprecated_InputError;

import 'package:front_end/src/fasta/kernel/utils.dart' show writeProgramToFile;

import 'package:front_end/src/fasta/severity.dart' show Severity;

import 'package:front_end/src/kernel_generator_impl.dart'
    show generateKernelInternal;

import 'command_line.dart' show withGlobalOptions;

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

Future main(List<String> arguments) async {
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
    c.options.inputs.add(Uri.parse('dart:core'));
    // Note: the patchedSdk argument is already stored in c.options.sdkRoot.
    Uri fullOutput = Uri.base.resolveUri(new Uri.file(restArguments[1]));
    Uri outlineOutput = Uri.base.resolveUri(new Uri.file(restArguments[2]));
    return compilePlatformInternal(c, fullOutput, outlineOutput);
  });
}

Future compilePlatformInternal(
    CompilerContext c, Uri fullOutput, Uri outlineOutput) async {
  if (c.options.strongMode) {
    print("Note: strong mode support is preliminary and may not work.");
  }
  if (c.options.verbose) {
    print("Generating outline of ${c.options.sdkRoot} into $outlineOutput");
    print("Compiling ${c.options.sdkRoot} to $fullOutput");
  }

  var result =
      await generateKernelInternal(buildSummary: true, buildProgram: true);
  if (result == null) {
    // Note: an error should have been reported by now.
    print('The platform .dill files were not created.');
    return;
  }
  new File.fromUri(outlineOutput).writeAsBytesSync(result.summary);
  c.options.ticker.logMs("Wrote outline to ${outlineOutput.toFilePath()}");
  await writeProgramToFile(result.program, fullOutput);
  c.options.ticker.logMs("Wrote program to ${fullOutput.toFilePath()}");
}

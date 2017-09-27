// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:io' show File;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/kernel/utils.dart' show writeProgramToFile;

import 'package:front_end/src/kernel_generator_impl.dart'
    show generateKernelInternal;

import 'command_line.dart' show withGlobalOptions;

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

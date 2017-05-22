// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compile_platform;

import 'dart:async' show Future;

import 'dart:io' show exitCode;

import 'compiler_command_line.dart' show CompilerCommandLine;

import 'compiler_context.dart' show CompilerContext;

import 'dill/dill_target.dart' show DillTarget;

import 'errors.dart' show InputError;

import 'kernel/kernel_target.dart' show KernelTarget;

import 'kernel/utils.dart' show printProgramText, writeProgramToFile;

import 'ticker.dart' show Ticker;

import 'translate_uri.dart' show TranslateUri;

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

Future mainEntryPoint(List<String> arguments) async {
  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n");
    }
    try {
      await compilePlatform(arguments);
    } on InputError catch (e) {
      exitCode = 1;
      print(e.format());
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
  if (c.options.strongMode) {
    print("Note: strong mode support is preliminary and may not work.");
  }
  ticker.isVerbose = c.options.verbose;
  Uri deps = Uri.base.resolveUri(new Uri.file("${fullOutput.toFilePath()}.d"));
  ticker.logMs("Parsed arguments");
  if (ticker.isVerbose) {
    print("Generating outline of $patchedSdk into $outlineOutput");
    print("Compiling $patchedSdk to $fullOutput");
  }

  TranslateUri uriTranslator =
      await TranslateUri.parse(c.fileSystem, patchedSdk, c.options.packages);
  ticker.logMs("Read packages file");

  DillTarget dillTarget =
      new DillTarget(ticker, uriTranslator, c.options.target);
  KernelTarget kernelTarget = new KernelTarget(c.fileSystem, dillTarget,
      uriTranslator, c.options.strongMode, c.uriToSource);

  kernelTarget.read(Uri.parse("dart:core"));
  await dillTarget.buildOutlines();
  var outline = await kernelTarget.buildOutlines();

  await writeProgramToFile(outline, outlineOutput);
  ticker.logMs("Wrote outline to ${outlineOutput.toFilePath()}");

  if (exitCode != 0) return null;

  var program = await kernelTarget.buildProgram(verify: c.options.verify);
  if (c.options.dumpIr) printProgramText(program);
  await writeProgramToFile(program, fullOutput);
  ticker.logMs("Wrote program to ${fullOutput.toFilePath()}");
  await kernelTarget.writeDepsFile(fullOutput, deps);
}

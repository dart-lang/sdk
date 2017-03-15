// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compile_platform;

import 'dart:async' show Future;

import 'ticker.dart' show Ticker;

import 'dart:io' show exitCode;

import 'compiler_command_line.dart' show CompilerCommandLine;

import 'compiler_context.dart' show CompilerContext;

import 'errors.dart' show InputError;

import 'kernel/kernel_target.dart' show KernelTarget;

import 'dill/dill_target.dart' show DillTarget;

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
    Uri output = Uri.base.resolveUri(new Uri.file(c.options.arguments[1]));
    return compilePlatformInternal(c, ticker, patchedSdk, output);
  });
}

Future compilePlatformInternal(
    CompilerContext c, Ticker ticker, Uri patchedSdk, Uri output) async {
  ticker.isVerbose = c.options.verbose;
  Uri deps = Uri.base.resolveUri(new Uri.file("${output.toFilePath()}.d"));
  ticker.logMs("Parsed arguments");
  if (ticker.isVerbose) {
    print("Compiling $patchedSdk to $output");
  }

  TranslateUri uriTranslator =
      await TranslateUri.parse(patchedSdk, c.options.packages);
  ticker.logMs("Read packages file");

  DillTarget dillTarget = new DillTarget(ticker, uriTranslator);
  KernelTarget kernelTarget =
      new KernelTarget(dillTarget, uriTranslator, c.uriToSource);

  kernelTarget.read(Uri.parse("dart:core"));
  await dillTarget.writeOutline(null);
  await kernelTarget.writeOutline(output);

  if (exitCode != 0) return null;
  await kernelTarget.writeProgram(output,
      dumpIr: c.options.dumpIr, verify: c.options.verify);
  await kernelTarget.writeDepsFile(output, deps);
}

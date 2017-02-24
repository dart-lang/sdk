// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compile_platform;

import 'dart:async' show
    Future;

import 'kernel/verifier.dart' show
    verifyProgram;

import 'ticker.dart' show
    Ticker;

import 'dart:io' show
    exitCode;

import 'compiler_command_line.dart' show
    CompilerCommandLine;

import 'compiler_context.dart' show
    CompilerContext;

import 'errors.dart' show
    InputError;

import 'kernel/kernel_target.dart' show
    KernelTarget;

import 'dill/dill_target.dart' show
    DillTarget;

import 'translate_uri.dart' show
    TranslateUri;

import 'ast_kind.dart' show
    AstKind;

Future main(List<String> arguments) async {
  Ticker ticker = new Ticker();
  try {
    await CompilerCommandLine.withGlobalOptions(
        "compile_platform", arguments,
        (CompilerContext c) => compilePlatform(c, ticker));
  } on InputError catch (e) {
    exitCode = 1;
    print(e.format());
    return null;
  }
}

Future compilePlatform(CompilerContext c, Ticker ticker) async {
  ticker.isVerbose = c.options.verbose;
  Uri output = Uri.base.resolveUri(new Uri.file(c.options.arguments[1]));
  Uri patchedSdk =
      Uri.base.resolveUri(new Uri.file(c.options.arguments[0]));
  ticker.logMs("Parsed arguments");
  if (ticker.isVerbose) {
    print("Compiling $patchedSdk to $output");
  }

  TranslateUri uriTranslator = await TranslateUri.parse(
      patchedSdk, c.options.packages);
  ticker.logMs("Read packages file");

  DillTarget dillTarget = new DillTarget(ticker, uriTranslator);
  KernelTarget kernelTarget = new KernelTarget(
      dillTarget, uriTranslator, c.uriToSource);

  kernelTarget.read(Uri.parse("dart:core"));
  await dillTarget.writeOutline(null);
  await kernelTarget.writeOutline(output);

  if (exitCode != 0) return null;
  await kernelTarget.writeProgram(output, AstKind.Kernel);
  if (c.options.dumpIr) {
    kernelTarget.dumpIr();
  }
  if (c.options.verify) {
    try {
      verifyProgram(kernelTarget.program);
      ticker.logMs("Verified program");
    } catch (e, s) {
      exitCode = 1;
      print("Verification of program failed: $e");
      if (s != null && c.options.verbose) {
        print(s);
      }
    }
  }
}

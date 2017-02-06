// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.outline;

import 'dart:async' show
    Future;

import 'dart:io' show
    exitCode;

import 'package:kernel/verifier.dart' show
    verifyProgram;

import 'compiler_command_line.dart' show
    CompilerCommandLine;

import 'errors.dart' show
    InputError,
    inputError;

import 'kernel/kernel_target.dart' show
    KernelSourceTarget;

import 'dill/dill_target.dart' show
    DillTarget;

import 'ticker.dart' show
    Ticker;

import 'translate_uri.dart' show
    TranslateUri;

import 'ast_kind.dart' show
    AstKind;

// TODO(ahe): Remove this import. Instead make the SDK available as resource in
// the executable, or something similar.
import 'testing/kernel_chain.dart' show
    computePatchedSdk;

CompilerCommandLine parseArguments(String programName, List<String> arguments) {
  return new CompilerCommandLine(programName, arguments);
}

Future<KernelSourceTarget> outline(List<String> arguments) async {
  try {
    CompilerCommandLine cl = parseArguments("outline", arguments);
    if (cl.verbose) print("Building outlines for ${arguments.join(' ')}");
    return await doOutline(cl, new Ticker(isVerbose: cl.verbose), cl.output);
  } on InputError catch (e) {
    exitCode = 1;
    print(e.format());
    return null;
  }
}

Future<Uri> compile(List<String> arguments) async {
  try {
    CompilerCommandLine cl = parseArguments("compile", arguments);
    if (cl.verbose) {
      print("Compiling directly to Kernel: ${arguments.join(' ')}");
    }
    return
        await doCompile(cl, new Ticker(isVerbose: cl.verbose), AstKind.Kernel);
  } on InputError catch (e) {
    exitCode = 1;
    print(e.format());
    return null;
  }
}

Future<Uri> kompile(List<String> arguments) async {
  try {
    CompilerCommandLine cl = parseArguments("kompile", arguments);
    if (cl.verbose) print("Compiling via analyzer: ${arguments.join(' ')}");
    return await doCompile(
        cl, new Ticker(isVerbose: cl.verbose), AstKind.Analyzer);
  } on InputError catch (e) {
    exitCode = 1;
    print(e.format());
    return null;
  }
}

Future<KernelSourceTarget> doOutline(CompilerCommandLine cl, Ticker ticker,
    [Uri output]) async {
  Uri sdk = await computePatchedSdk();
  ticker.logMs("Found patched SDK");
  TranslateUri uriTranslator = await TranslateUri.parse(sdk);
  ticker.logMs("Read packages file");
  DillTarget dillTarget = new DillTarget(ticker, uriTranslator);
  KernelSourceTarget sourceTarget =
      new KernelSourceTarget(dillTarget, uriTranslator);
  Uri platform = cl.platform;
  if (platform != null) {
    dillTarget.read(platform);
  }
  String argument = cl.arguments.first;
  Uri uri = Uri.base.resolve(argument);
  String path = uriTranslator.translate(uri)?.path ?? argument;
  if (path.endsWith(".dart")) {
    sourceTarget.read(uri);
  } else {
    inputError(uri, -1, "Unexpected input: $uri");
  }
  await dillTarget.writeOutline(null);
  await sourceTarget.writeOutline(output);
  if (cl.dumpIr && output != null) {
    sourceTarget.dumpIr();
  }
  return sourceTarget;
}

Future<Uri> doCompile(CompilerCommandLine cl, Ticker ticker,
    AstKind kind) async {
  KernelSourceTarget sourceTarget = await doOutline(cl, ticker);
  if (exitCode != 0) return null;
  Uri uri = cl.output;
  await sourceTarget.writeProgram(uri, kind);
  if (cl.dumpIr) {
    sourceTarget.dumpIr();
  }
  if (cl.verify) {
    try {
      verifyProgram(sourceTarget.program);
      ticker.logMs("Verified program");
    } catch (e, s) {
      exitCode = 1;
      print("Verification of program failed: $e");
      if (s != null && cl.verbose) {
        print(s);
      }
    }
  }
  return uri;
}

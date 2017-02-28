// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.outline;

import 'dart:async' show Future;

import 'dart:io' show exitCode;

import 'kernel/verifier.dart' show verifyProgram;

import 'compiler_command_line.dart' show CompilerCommandLine;

import 'compiler_context.dart' show CompilerContext;

import 'errors.dart' show InputError, inputError;

import 'kernel/kernel_target.dart' show KernelTarget;

import 'dill/dill_target.dart' show DillTarget;

import 'ticker.dart' show Ticker;

import 'translate_uri.dart' show TranslateUri;

import 'ast_kind.dart' show AstKind;

Future<KernelTarget> outline(List<String> arguments) async {
  try {
    return await CompilerCommandLine.withGlobalOptions("outline", arguments,
        (CompilerContext c) async {
      if (c.options.verbose) {
        print("Building outlines for ${arguments.join(' ')}");
      }
      return await doOutline(
          c, new Ticker(isVerbose: c.options.verbose), c.options.output);
    });
  } on InputError catch (e) {
    exitCode = 1;
    print(e.format());
    return null;
  }
}

Future<Uri> compile(List<String> arguments) async {
  try {
    return await CompilerCommandLine.withGlobalOptions("compile", arguments,
        (CompilerContext c) async {
      if (c.options.verbose) {
        print("Compiling directly to Kernel: ${arguments.join(' ')}");
      }
      return await doCompile(
          c, new Ticker(isVerbose: c.options.verbose), AstKind.Kernel);
    });
  } on InputError catch (e) {
    exitCode = 1;
    print(e.format());
    return null;
  }
}

Future<Uri> kompile(List<String> arguments) async {
  try {
    return await CompilerCommandLine.withGlobalOptions("kompile", arguments,
        (CompilerContext c) async {
      if (c.options.verbose) {
        print("Compiling via analyzer: ${arguments.join(' ')}");
      }
      return await doCompile(
          c, new Ticker(isVerbose: c.options.verbose), AstKind.Analyzer);
    });
  } on InputError catch (e) {
    exitCode = 1;
    print(e.format());
    return null;
  }
}

Future<KernelTarget> doOutline(CompilerContext c, Ticker ticker,
    [Uri output]) async {
  TranslateUri uriTranslator = await TranslateUri.parse(c.options.sdk);
  ticker.logMs("Read packages file");
  DillTarget dillTarget = new DillTarget(ticker, uriTranslator);
  KernelTarget kernelTarget =
      new KernelTarget(dillTarget, uriTranslator, c.uriToSource);
  Uri platform = c.options.platform;
  if (platform != null) {
    dillTarget.read(platform);
  }
  String argument = c.options.arguments.first;
  Uri uri = Uri.base.resolve(argument);
  String path = uriTranslator.translate(uri)?.path ?? argument;
  if (path.endsWith(".dart")) {
    kernelTarget.read(uri);
  } else {
    inputError(uri, -1, "Unexpected input: $uri");
  }
  await dillTarget.writeOutline(null);
  await kernelTarget.writeOutline(output);
  if (c.options.dumpIr && output != null) {
    kernelTarget.dumpIr();
  }
  return kernelTarget;
}

Future<Uri> doCompile(CompilerContext c, Ticker ticker, AstKind kind) async {
  KernelTarget kernelTarget = await doOutline(c, ticker);
  if (exitCode != 0) return null;
  Uri uri = c.options.output;
  await kernelTarget.writeProgram(uri, kind);
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
  return uri;
}

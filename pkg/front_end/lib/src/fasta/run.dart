// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.run;

import 'dart:async' show
    Future;

import 'dart:io' show
    stdout;

import 'package:testing/testing.dart' show
    StdioProcess;

import 'testing/kernel_chain.dart' show
    TestContext;

import 'compiler_command_line.dart' show
    CompilerCommandLine;

Future<int> run(Uri uri, CompilerCommandLine cl) async {
  Uri dartVm;

  Future<TestContext> constructor(
      suite, Map<String, String> environment, String sdk, Uri vm,
      Uri packages, bool strongMode, dartSdk, bool updateExpectations) {
    dartVm = vm;
    return null;
  }
  // TODO(ahe): Using [TestContext] to compute a value for [dartVm]. Make the
  // API simpler.
  await TestContext.create(null, <String, String>{}, constructor);
  List<String> arguments = <String>["${uri.toFilePath()}"]
      ..addAll(cl.arguments.skip(1));
  if (cl.verbose) {
    print("Running ${dartVm.toFilePath()} ${arguments.join(' ')}");
  }
  StdioProcess result = await StdioProcess.run(dartVm.toFilePath(), arguments);
  stdout.write(result.output);
  return result.exitCode;
}

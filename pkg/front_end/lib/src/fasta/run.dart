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
    computeDartVm,
    computePatchedSdk;

import 'compiler_context.dart' show
    CompilerContext;

Future<int> run(Uri uri, CompilerContext c) async {
  Uri sdk = await computePatchedSdk();
  Uri dartVm = computeDartVm(sdk);
  List<String> arguments = <String>["${uri.toFilePath()}"]
      ..addAll(c.options.arguments.skip(1));
  if (c.options.verbose) {
    print("Running ${dartVm.toFilePath()} ${arguments.join(' ')}");
  }
  StdioProcess result = await StdioProcess.run(dartVm.toFilePath(), arguments);
  stdout.write(result.output);
  return result.exitCode;
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'dart:io' show Directory, Platform;

import 'dart:isolate' show Isolate;

import 'package:async_helper/async_helper.dart' show asyncEnd, asyncStart;

import 'package:front_end/src/fasta/testing/kernel_chain.dart'
    show computePatchedSdk;

import 'package:testing/testing.dart' show StdioProcess;

Future main() async {
  asyncStart();
  Uri sourceCompiler = await Isolate.resolvePackageUri(
      Uri.parse("package:front_end/src/fasta/bin/compile.dart"));
  Uri packages = await Isolate.packageConfig;
  try {
    Directory tmp = await Directory.systemTemp.createTemp("fasta_bootstrap");
    Uri compiledOnceOutput = tmp.uri.resolve("fasta1.dill");
    Uri compiledTwiceOutput = tmp.uri.resolve("fasta2.dill");
    try {
      await runCompiler(sourceCompiler, sourceCompiler, compiledOnceOutput);
      await runCompiler(
          compiledOnceOutput, sourceCompiler, compiledTwiceOutput);
    } finally {
      await tmp.delete(recursive: true);
    }
  } finally {
    asyncEnd();
  }
}

Future runCompiler(Uri compiler, Uri input, Uri output) async {
  Uri patchedSdk = await computePatchedSdk();
  Uri dartVm = Uri.base.resolve(Platform.resolvedExecutable);
  StdioProcess result = await StdioProcess.run(dartVm.toFilePath(), <String>[
    compiler.toFilePath(),
    "--compile-sdk=${patchedSdk.toFilePath()}",
    "--output=${output.toFilePath()}",
    input.toFilePath(),
  ]);
  print(result.output);
  if (result.exitCode != 1) {
    // TODO(ahe): Due to known errors in the VM's patch files, this compiler
    // should report an error. Also, it may not be able to compile everything
    // yet.
    throw "Compilation failed.";
  }
}

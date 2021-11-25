// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, Platform;

import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart'
    show IncrementalCompilerResult;
import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import 'package:kernel/ast.dart' show Component;

import 'incremental_suite.dart' show getOptions;

Future<void> main() async {
  Uri compileTarget = Platform.script.resolve("binary_md_dill_reader.dart");
  if (!(new File.fromUri(compileTarget)).existsSync()) {
    throw "$compileTarget doesn't exist";
  }

  List<Future> futures = [];
  List<int> compilesLeft = new List<int>.filled(5, 8);
  for (int i = 0; i < compilesLeft.length; i++) {
    Future<Component?> compileAgain() async {
      print("$i has ${compilesLeft[i]} left.");
      if (compilesLeft[i] > 0) {
        compilesLeft[i]--;
        return compile(i, compileTarget).then((value) => compileAgain());
      }
      return null;
    }

    print("Starting first compile for $i");
    futures.add(compile(i, compileTarget).then((value) => compileAgain()));
  }
  await Future.wait(futures);

  print("Checkpoint #1: Can compiles several at once "
      "(with different compilers!)");

  for (int i = 0; i < 5; i++) {
    futures.clear();
    for (int j = 0; j < 10; j++) {
      futures.add(compile(0, compileTarget));
    }
    await Future.wait(futures);
  }

  print("Checkpoint #2: Can compiles several at once "
      "(with the same compiler) (without crashing)");
}

List<IncrementalCompiler?> compilers = [];

Future<Component> compile(int compilerNum, Uri uri) async {
  if (compilers.length <= compilerNum) {
    compilers.length = compilerNum + 1;
  }
  IncrementalCompiler? compiler = compilers[compilerNum];
  if (compiler == null) {
    var options = getOptions();
    compiler = new IncrementalCompiler(new CompilerContext(
        new ProcessedOptions(options: options, inputs: [uri])));
    compilers[compilerNum] = compiler;
  } else {
    compiler.invalidateAllSources();
  }
  IncrementalCompilerResult compilerResult = await compiler.computeDelta();
  Component result = compilerResult.component;
  print("Now compile is done!");
  return result;
}

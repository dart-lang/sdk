// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, Platform;

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart'
    show IncrementalCompilerResult;
import 'package:front_end/src/base/compiler_context.dart' show CompilerContext;
import 'package:front_end/src/base/incremental_compiler.dart'
    show IncrementalCompiler;
import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;
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

  print(
    "Checkpoint #1: Can compiles several at once "
    "(with different compilers!)",
  );

  for (int i = 0; i < 5; i++) {
    futures.clear();
    for (int j = 0; j < 10; j++) {
      futures.add(compile(0, compileTarget));
    }
    await Future.wait(futures);
  }

  print(
    "Checkpoint #2: Can compiles several at once "
    "(with the same compiler) (without crashing)",
  );

  // Crash a compile mid-way.
  FileSystem oldFileSystem = compilerOptions[0]!.fileSystem;
  compilerOptions[0]!.fileSystem = new CrashingFileSystem();
  compilers[0]!.context.options.clearFileSystemCache();
  try {
    await compile(0, compileTarget);
    throw "Didn't crash when expected to";
  } on CrashingFileSystemException {
    // Expected.
  }
  compilerOptions[0]!.fileSystem = oldFileSystem;
  compilers[0]!.context.options.clearFileSystemCache();

  for (int i = 0; i < 2; i++) {
    futures.clear();
    for (int j = 0; j < 4; j++) {
      // Adding a timeout because the VM might otherwise figure out that nothing
      // can happen and shut down.
      futures.add(
        compile(0, compileTarget).timeout(const Duration(seconds: 42)),
      );
    }
    await Future.wait(futures);
  }

  print(
    "Checkpoint #3: Can compiles several at once "
    "(with the same compiler) where a crash doesn't hold back later compiles.",
  );
}

List<IncrementalCompiler?> compilers = [];
List<CompilerOptions?> compilerOptions = [];

Future<Component> compile(int compilerNum, Uri uri) async {
  if (compilers.length <= compilerNum) {
    compilers.length = compilerNum + 1;
    compilerOptions.length = compilerNum + 1;
  }
  IncrementalCompiler? compiler = compilers[compilerNum];
  if (compiler == null) {
    CompilerOptions options = getOptions();
    compiler = new IncrementalCompiler(
      new CompilerContext(
        new ProcessedOptions(options: options, inputs: [uri]),
      ),
    );
    compilers[compilerNum] = compiler;
    compilerOptions[compilerNum] = options;
  } else {
    compiler.invalidateAllSources();
  }

  IncrementalCompilerResult compilerResult = await compiler.computeDelta();
  Component result = compilerResult.component;

  // Set invalidations correctly for any waiting compilers.
  compiler.invalidateAllSources();
  return result;
}

class CrashingFileSystem extends FileSystem {
  @override
  FileSystemEntity entityForUri(Uri uri) {
    throw new CrashingFileSystemException();
  }
}

class CrashingFileSystemException {}

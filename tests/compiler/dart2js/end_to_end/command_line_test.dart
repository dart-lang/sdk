// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the command line options of dart2js.

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'package:compiler/compiler_new.dart' as api;
import 'package:compiler/src/dart2js.dart' as entry;
import 'package:compiler/src/options.dart' show CompilerOptions;

main() {
  entry.enableWriteString = false;
  asyncTest(() async {
    await test([], exitCode: 1);
    await test(['foo.dart']);
  });
}

Future test(List<String> arguments, {int exitCode}) async {
  print('--------------------------------------------------------------------');
  print('dart2js ${arguments.join(' ')}');
  print('--------------------------------------------------------------------');
  entry.CompileFunc oldCompileFunc = entry.compileFunc;
  entry.ExitFunc oldExitFunc = entry.exitFunc;

  CompilerOptions options;
  int actualExitCode;
  entry.compileFunc = (_options, input, diagnostics, output) {
    options = _options;
    return new Future<api.CompilationResult>.value(
        new api.CompilationResult(null));
  };
  entry.exitFunc = (_exitCode) {
    actualExitCode = _exitCode;
    throw 'exited';
  };
  try {
    await entry.compilerMain(arguments);
  } catch (e, s) {
    Expect.equals('exited', e, "Unexpected exception: $e\n$s");
  }
  Expect.equals(exitCode, actualExitCode, "Unexpected exit code");
  if (actualExitCode == null) {
    Expect.isNotNull(options, "Missing options object");
  }

  entry.compileFunc = oldCompileFunc;
  entry.exitFunc = oldExitFunc;
}

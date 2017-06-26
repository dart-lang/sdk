// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we can compile from dill and run the generated code with d8.
library dart2js.kernel.run_from_dill_test;

import 'dart:async';
import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/dart2js.dart' as dart2js;
import 'package:compiler/src/filenames.dart';

import 'compiler_helper.dart';
import '../sourcemaps/stacktrace_test.dart';
import '../serialization/helper.dart';

const SOURCE = const {
  'main.dart': '''
main() {
  for (int i = 0; i < 10; i++) {
    if (i == 5) continue;
    print('Hello World: \$i!');
    if (i == 7) break;
  }
}
'''
};

const OUTPUT = '''
Hello World: 0!
Hello World: 1!
Hello World: 2!
Hello World: 3!
Hello World: 4!
Hello World: 6!
Hello World: 7!
''';

main(List<String> args) {
  asyncTest(() async {
    await mainInternal(args);
  });
}

enum ResultKind { crashes, errors, warnings, success, failure }

Future<ResultKind> mainInternal(List<String> args,
    {bool skipWarnings: false, bool skipErrors: false}) async {
  Arguments arguments = new Arguments.from(args);
  Uri entryPoint;
  Map<String, String> memorySourceFiles;
  if (arguments.uri != null) {
    entryPoint = arguments.uri;
    memorySourceFiles = const <String, String>{};
  } else {
    entryPoint = Uri.parse('memory:main.dart');
    memorySourceFiles = SOURCE;
  }

  Uri dillFile =
      await createTemp(entryPoint, memorySourceFiles, printSteps: true);
  String output = uriPathToNative(dillFile.resolve('out.js').path);
  List<String> dart2jsArgs = [
    dillFile.toString(),
    '-o$output',
    Flags.loadFromDill,
    Flags.disableTypeInference,
    Flags.disableInlining,
    Flags.enableAssertMessage
  ];
  print('Running: dart2js ${dart2jsArgs.join(' ')}');

  await dart2js.internalMain(dart2jsArgs);

  print('---- run from dill --------------------------------------------');
  ProcessResult runResult = Process.runSync(d8executable,
      ['sdk/lib/_internal/js_runtime/lib/preambles/d8.js', output]);
  String out = '${runResult.stderr}\n${runResult.stdout}';
  print('d8 output:');
  print(out);
  Expect.equals(0, runResult.exitCode);
  Expect.equals(OUTPUT, runResult.stdout.replaceAll('\r\n', '\n'));

  return ResultKind.success;
}

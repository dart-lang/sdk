// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Test that the expected output targets are generated for various compiler
/// options.

import 'dart:async';
import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/dart2js.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/null_compiler_output.dart';
import 'package:compiler/src/options.dart';
import 'package:compiler/src/source_file_provider.dart';
import 'package:front_end/src/api_unstable/dart2js.dart' as fe;
import 'package:compiler/src/inferrer/debug.dart' show PRINT_GRAPH;
import 'package:compiler/src/tracer.dart' show TRACE_FILTER_PATTERN_FOR_TEST;
import 'package:expect/expect.dart';

import '../helpers/memory_compiler.dart';

class TestRandomAccessFileOutputProvider implements CompilerOutput {
  final RandomAccessFileOutputProvider provider;
  List<String> outputs = <String>[];

  TestRandomAccessFileOutputProvider(this.provider);

  @override
  OutputSink createOutputSink(String name, String extension, OutputType type) {
    outputs.add(fe.relativizeUri(provider.out,
        provider.createUri(name, extension, type), Platform.isWindows));
    return NullSink.outputProvider(name, extension, type);
  }

  @override
  BinaryOutputSink createBinarySink(Uri uri) => new NullBinarySink(uri);
}

CompileFunc oldCompileFunc;

Future<Null> test(List<String> arguments, List<String> expectedOutput,
    {List<String> groupOutputs: const <String>[]}) async {
  List<String> options = new List<String>.from(arguments)
    ..add('--platform-binaries=$sdkPlatformBinariesPath')
    ..add('--libraries-spec=$sdkLibrariesSpecificationUri');
  print('--------------------------------------------------------------------');
  print('dart2js ${options.join(' ')}');
  TestRandomAccessFileOutputProvider outputProvider;
  compileFunc = (CompilerOptions compilerOptions,
      CompilerInput compilerInput,
      CompilerDiagnostics compilerDiagnostics,
      CompilerOutput compilerOutput) async {
    return oldCompileFunc(
        compilerOptions,
        compilerInput,
        compilerDiagnostics,
        outputProvider =
            new TestRandomAccessFileOutputProvider(compilerOutput));
  };
  await internalMain(options);
  List<String> outputs = outputProvider.outputs;
  for (String outputGroup in groupOutputs) {
    int countBefore = outputs.length;
    outputs = outputs
        .where((String output) => !output.endsWith(outputGroup))
        .toList();
    Expect.notEquals(0, countBefore - outputs.length,
        'Expected output group ${outputGroup}');
  }
  Expect.setEquals(expectedOutput, outputs,
      "Output mismatch. Expected $expectedOutput, actual $outputs.");
}

main() {
  enableWriteString = false;
  oldCompileFunc = compileFunc;

  runTests() async {
    PRINT_GRAPH = true;
    TRACE_FILTER_PATTERN_FOR_TEST = 'x';
    await test([
      'pkg/compiler/test/deferred/data/deferred_helper.dart',
      '--out=custom.js',
      '--deferred-map=def/deferred.json',
      Flags.dumpInfo,
    ], [
      'custom.js', 'custom.js.map',
      'custom.js_1.part.js', 'custom.js_1.part.js.map',
      'def/deferred.json', // From --deferred-map
      'custom.js.info.json', // From --dump-info
      'custom.js.cfg', // From TRACE_FILTER_PATTERN_FOR_TEST
    ], groupOutputs: [
      '.dot', // From PRINT_GRAPH
    ]);

    PRINT_GRAPH = false;
    TRACE_FILTER_PATTERN_FOR_TEST = null;
    List<String> additionOptionals = <String>[];
    List<String> expectedOutput = <String>[
      'out.js',
      'out.js.map',
      'out.js_1.part.js',
      'out.js_1.part.js.map',
    ];

    await test(
        [
          'pkg/compiler/test/deferred/data/deferred_helper.dart',
          Flags.useContentSecurityPolicy,
        ]..addAll(additionOptionals),
        expectedOutput);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

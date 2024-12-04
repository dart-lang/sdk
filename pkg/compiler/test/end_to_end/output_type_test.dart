// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that the expected output targets are generated for various compiler
/// options.

import 'dart:async';
import 'dart:io';

import 'package:compiler/compiler_api.dart' as api;
import 'package:compiler/src/dart2js.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/null_compiler_output.dart';
import 'package:compiler/src/options.dart';
import 'package:compiler/src/source_file_provider.dart';
import 'package:front_end/src/api_unstable/dart2js.dart' as fe;
import 'package:compiler/src/inferrer/debug.dart' show PRINT_GRAPH;
import 'package:compiler/src/tracer.dart' show TRACE_FILTER_PATTERN_FOR_TEST;
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

import 'package:compiler/src/util/memory_compiler.dart';

class TestRandomAccessFileOutputProvider implements api.CompilerOutput {
  final RandomAccessFileOutputProvider provider;
  List<String> outputs = <String>[];

  TestRandomAccessFileOutputProvider(this.provider);

  @override
  api.OutputSink createOutputSink(
      String name, String extension, api.OutputType type) {
    outputs.add(fe.relativizeUri(provider.out!,
        provider.createUri(name, extension, type), Platform.isWindows));
    return NullSink.outputProvider(name, extension, type);
  }

  @override
  api.BinaryOutputSink createBinarySink(Uri uri) => NullBinarySink(uri);
}

late CompileFunc oldCompileFunc;

Future<Null> test(List<String> arguments, List<String> expectedOutput,
    {List<String> groupOutputs = const <String>[]}) async {
  List<String> options = List<String>.from(arguments)
    // TODO(nshahan) Should change to sdkPlatformBinariesPath when testing
    // with unsound null safety is no longer needed.
    ..add('--platform-binaries=$buildPlatformBinariesPath')
    ..add('--libraries-spec=$sdkLibrariesSpecificationUri');
  print('--------------------------------------------------------------------');
  print('dart2js ${options.join(' ')}');
  late TestRandomAccessFileOutputProvider outputProvider;
  compileFunc = (CompilerOptions compilerOptions,
      api.CompilerInput compilerInput,
      api.CompilerDiagnostics compilerDiagnostics,
      api.CompilerOutput compilerOutput) async {
    return oldCompileFunc(
        compilerOptions,
        compilerInput,
        compilerDiagnostics,
        outputProvider = TestRandomAccessFileOutputProvider(
            compilerOutput as RandomAccessFileOutputProvider));
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
      '--no-sound-null-safety',
      '--no-csp',
      '--stage=dump-info-all',
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
    List<String> additionOptionals = [];
    List<String> expectedOutput = [
      'out.js',
      'out.js.map',
      'out.js_1.part.js',
      'out.js_1.part.js.map',
    ];

    await test([
      'pkg/compiler/test/deferred/data/deferred_helper.dart',
      '--no-sound-null-safety',
      '--csp',
      ...additionOptionals,
    ], expectedOutput);

    // If we add the '--write-resources' flag, we get another file
    // `out.js.resources.json'.
    await test([
      'pkg/compiler/test/deferred/data/deferred_helper.dart',
      '--no-sound-null-safety',
      '--csp',
      Flags.writeResources,
      ...additionOptionals,
    ], [
      ...expectedOutput,
      'out.js.resources.json',
    ]);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

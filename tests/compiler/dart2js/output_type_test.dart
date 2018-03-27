// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
import 'package:compiler/src/util/uri_extras.dart';
import 'package:compiler/src/inferrer/debug.dart' show PRINT_GRAPH;
import 'package:compiler/src/tracer.dart' show TRACE_FILTER_PATTERN_FOR_TEST;
import 'package:expect/expect.dart';

class TestRandomAccessFileOutputProvider implements CompilerOutput {
  final RandomAccessFileOutputProvider provider;
  List<String> outputs = <String>[];

  TestRandomAccessFileOutputProvider(this.provider);

  @override
  OutputSink createOutputSink(String name, String extension, OutputType type) {
    outputs.add(relativize(provider.out,
        provider.createUri(name, extension, type), Platform.isWindows));
    return NullSink.outputProvider(name, extension, type);
  }
}

CompileFunc oldCompileFunc;

Future<Null> test(List<String> arguments, List<String> expectedOutput,
    {List<String> groupOutputs: const <String>[], bool useKernel}) async {
  List<String> options = new List<String>.from(arguments)
    ..add("--library-root=${Uri.base.resolve('sdk/')}");
  if (!useKernel) {
    options.add(Flags.useOldFrontend);
  }
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

  runTests({bool useKernel}) async {
    PRINT_GRAPH = true;
    TRACE_FILTER_PATTERN_FOR_TEST = 'x';
    await test([
      'tests/compiler/dart2js/deferred/data/deferred_helper.dart',
      '--out=custom.js',
      '--deferred-map=def/deferred.json',
      Flags.dumpInfo,
    ], [
      'custom.js', 'custom.js.map',
      'custom.js_1.part.js', 'custom.js_1.part.js.map',
      'def/deferred.json', // From --deferred-map
      'custom.js.info.json', // From --dump-info
      'dart.cfg', // From TRACE_FILTER_PATTERN_FOR_TEST
    ], groupOutputs: [
      '.dot', // From PRINT_GRAPH
    ], useKernel: useKernel);

    PRINT_GRAPH = false;
    TRACE_FILTER_PATTERN_FOR_TEST = null;
    List<String> additionOptionals = <String>[];
    List<String> expectedOutput = <String>[
      'out.js',
      'out.js.map',
      'out.js_1.part.js',
      'out.js_1.part.js.map',
    ];
    if (!useKernel) {
      // Option --use-multi-source-info is only supported for the old frontend.
      expectedOutput.add('out.js.map.v2');
      expectedOutput.add('out.js_1.part.js.map.v2');
      additionOptionals.add(Flags.useMultiSourceInfo);
    }

    await test(
        [
          'tests/compiler/dart2js/deferred/data/deferred_helper.dart',
          Flags.useContentSecurityPolicy,
        ]..addAll(additionOptionals),
        expectedOutput,
        useKernel: useKernel);
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTests(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTests(useKernel: true);
  });
}

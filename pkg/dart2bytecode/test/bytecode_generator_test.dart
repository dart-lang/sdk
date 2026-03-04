// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data' show BytesBuilder;

import 'package:dart2bytecode/bytecode_generator.dart' show generateBytecode;
import 'package:dart2bytecode/bytecode_serialization.dart'
    show LinkReader, BufferedReader;
import 'package:dart2bytecode/declarations.dart' as bytecode_declarations
    show Component;
import 'package:dart2bytecode/options.dart' show BytecodeOptions;
import 'package:front_end/src/api_unstable/vm.dart'
    show
        CompilerOptions,
        computePlatformBinariesLocation,
        CfeDiagnosticMessage,
        kernelForProgram;
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:test/test.dart';
import 'package:vm/kernel_front_end.dart' show createLoadedLibrariesSet;
import 'package:vm/modular/target/vm.dart';

/// Environment define to update expectation files on failures.
const kUpdateExpectations = 'updateExpectations';

final String dartSdkPkgDir = Platform.script.resolve('../..').toFilePath();

runTestCase(Uri source, {bool isClosureContextLoweringEnabled = false}) async {
  final target = VmTarget(TargetFlags(
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled));
  final result = await compileTestCaseToKernelProgram(source, target: target);

  final mainLibrary = result.component.mainMethod!.enclosingLibrary;

  final sink = ByteSink();
  final coreTypes = result.coreTypes ?? CoreTypes(result.component);
  final hierarchy =
      result.classHierarchy ?? ClassHierarchy(result.component, coreTypes);
  generateBytecode(result.component, sink,
      options: BytecodeOptions(),
      libraries: [mainLibrary],
      extraLoadedLibraries: result.loadedLibraries,
      coreTypes: coreTypes,
      hierarchy: hierarchy,
      target: target);

  final reader = BufferedReader(LinkReader(), sink.builder.takeBytes());
  String actual = bytecode_declarations.Component.read(reader).toString();

  // Remove absolute library URIs.
  actual = actual.replaceAll(
      new Uri.file(dartSdkPkgDir).toString(), 'DART_SDK/pkg/');

  compareResultWithExpectationsFile(source, actual);
}

// Similar to CompilerResult from pkg/vm/bin/kernel_service.dart.
class CompilerResult {
  final Component component;
  final Set<Library> loadedLibraries;
  final ClassHierarchy? classHierarchy;
  final CoreTypes? coreTypes;

  CompilerResult(
    this.component,
    this.loadedLibraries,
    this.classHierarchy,
    this.coreTypes,
  );
}

Future<CompilerResult> compileTestCaseToKernelProgram(Uri sourceUri,
    {required Target target}) async {
  final platformKernel =
      computePlatformBinariesLocation().resolve('vm_platform.dill');
  final options = CompilerOptions()
    ..target = target
    ..omitPlatform = true
    ..additionalDills = <Uri>[platformKernel]
    ..environmentDefines = {}
    ..onDiagnostic = (CfeDiagnosticMessage message) {
      fail("Compilation error: ${message.plainTextFormatted.join('\n')}");
    };

  final result = (await kernelForProgram(sourceUri, options))!;
  final Component component = result.component!;

  // Make sure the library name is the same and does not depend on the order
  // of test cases.
  component.mainMethod!.enclosingLibrary.name = '#lib';
  return CompilerResult(
    component,
    // Use the same calculation as SingleShotCompilerWrapper.
    createLoadedLibrariesSet(result.loadedComponents, result.sdkComponent,
        includePlatform: false),
    result.classHierarchy,
    result.coreTypes,
  );
}

class ByteSink implements Sink<List<int>> {
  final BytesBuilder builder = BytesBuilder();

  @override
  void add(List<int> data) {
    builder.add(data);
  }

  @override
  void close() {}
}

class Difference {
  final int line;
  final String actual;
  final String expected;

  Difference(this.line, this.actual, this.expected);
}

Difference findFirstDifference(String actual, String expected) {
  final actualLines = actual.split('\n');
  final expectedLines = expected.split('\n');
  int i = 0;
  for (; i < actualLines.length && i < expectedLines.length; ++i) {
    if (actualLines[i] != expectedLines[i]) {
      return Difference(i + 1, actualLines[i], expectedLines[i]);
    }
  }
  return Difference(i + 1, i < actualLines.length ? actualLines[i] : '<END>',
      i < expectedLines.length ? expectedLines[i] : '<END>');
}

void compareResultWithExpectationsFile(
  Uri source,
  String actual, {
  String expectFilePostfix = '',
}) {
  final baseFilename = '${source.toFilePath()}$expectFilePostfix';
  final expectFile = new File('$baseFilename.expect');
  final expected = expectFile.existsSync() ? expectFile.readAsStringSync() : '';

  if (actual != expected) {
    if (bool.fromEnvironment(kUpdateExpectations)) {
      expectFile.writeAsStringSync(actual);
      print("  Updated $expectFile");
    } else {
      Difference diff = findFirstDifference(actual, expected);
      fail("""

Result is different for the test case $source

The first difference is at line ${diff.line}.
Actual:   ${diff.actual}
Expected: ${diff.expected}

This failure can be caused by changes in the front-end if it starts generating
different kernel AST for the same Dart programs.

In order to re-generate expectations run tests with -D$kUpdateExpectations=true VM option:

  tools/test.py -m release --vm-options -D$kUpdateExpectations=true pkg/dart2bytecode/

""");
    }
  }
}

main() {
  group('gen-bytecode', () {
    final testCasesDir =
        new Directory(dartSdkPkgDir + 'dart2bytecode/testcases');

    for (var entry
        in testCasesDir.listSync(recursive: true, followLinks: false)) {
      if (entry.path.endsWith(".dart")) {
        test(entry.path, () => runTestCase(entry.uri));
      }
    }
  });

  // The following tests are known to fail due to the experiment.
  const Set<String> knownFailures = {
    'closures.dart',
    'async.dart',
    'switch.dart',
    'type_ops.dart',
    'try_blocks.dart',
    'loops.dart',
    'instance_creation.dart',
    'super_calls.dart',
    'literals.dart',
    'asserts.dart',
    'field_initializers.dart',
    'optional_params.dart',
    'bootstrapping.dart',
    'ffi.dart',
  };

  group('gen-bytecode-with-closure-context-lowering', () {
    final testCasesDir =
        new Directory(dartSdkPkgDir + 'dart2bytecode/testcases');

    for (var entry
        in testCasesDir.listSync(recursive: true, followLinks: false)) {
      if (entry.path.endsWith(".dart") &&
          !knownFailures.contains(entry.uri.pathSegments.last)) {
        test(
            entry.path,
            () =>
                runTestCase(entry.uri, isClosureContextLoweringEnabled: true));
      }
    }
  });
}

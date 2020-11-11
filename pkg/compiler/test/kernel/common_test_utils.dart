// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:front_end/src/api_unstable/dart2js.dart'
    show
        CompilerOptions,
        DiagnosticMessage,
        computePlatformBinariesLocation,
        kernelForProgram,
        parseExperimentalArguments,
        parseExperimentalFlags;
import 'package:kernel/ast.dart';
import 'package:kernel/text/ast_to_text.dart' show Printer;
import 'package:kernel/target/targets.dart';
import 'package:test/test.dart';

import 'package:compiler/src/kernel/dart2js_target.dart' show Dart2jsTarget;

/// Environment define to update expectation files on failures.
const kUpdateExpectations = 'updateExpectations';

/// Environment define to dump actual results alongside expectations.
const kDumpActualResult = 'dump.actual.result';

class TestingDart2jsTarget extends Dart2jsTarget {
  TestingDart2jsTarget(TargetFlags flags) : super('dart2js', flags);
}

Future<Component> compileTestCaseToKernelProgram(Uri sourceUri,
    {Target target,
    bool enableSuperMixins = false,
    List<String> experimentalFlags,
    Map<String, String> environmentDefines}) async {
  final platformKernel =
      computePlatformBinariesLocation().resolve('dart2js_platform.dill');
  target ??= TestingDart2jsTarget(TargetFlags());
  environmentDefines ??= <String, String>{};
  final options = CompilerOptions()
    ..target = target
    ..additionalDills = <Uri>[platformKernel]
    ..environmentDefines = environmentDefines
    ..explicitExperimentalFlags =
        parseExperimentalFlags(parseExperimentalArguments(experimentalFlags),
            onError: (String message) {
      throw message;
    })
    ..onDiagnostic = (DiagnosticMessage message) {
      fail("Compilation error: ${message.plainTextFormatted.join('\n')}");
    };

  final Component component =
      (await kernelForProgram(sourceUri, options)).component;

  // Make sure the library name is the same and does not depend on the order
  // of test cases.
  component.mainMethod.enclosingLibrary.name = '#lib';

  return component;
}

String kernelLibraryToString(Library library) {
  final buffer = StringBuffer();
  Printer(buffer, showMetadata: true).writeLibraryFile(library);
  return buffer
      .toString()
      .replaceAll(library.importUri.toString(), library.name);
}

String kernelComponentToString(Component component) {
  final buffer = StringBuffer();
  Printer(buffer, showMetadata: true).writeComponentFile(component);
  final mainLibrary = component.mainMethod.enclosingLibrary;
  return buffer
      .toString()
      .replaceAll(mainLibrary.importUri.toString(), mainLibrary.name);
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

void compareResultWithExpectationsFile(Uri source, String actual) {
  final expectFile = File(source.toFilePath() + '.expect');
  final expected = expectFile.existsSync() ? expectFile.readAsStringSync() : '';

  if (actual != expected) {
    if (bool.fromEnvironment(kUpdateExpectations)) {
      expectFile.writeAsStringSync(actual);
      print("  Updated $expectFile");
    } else {
      if (bool.fromEnvironment(kDumpActualResult)) {
        File(source.toFilePath() + '.actual').writeAsStringSync(actual);
      }
      Difference diff = findFirstDifference(actual, expected);
      fail("""

Result is different for the test case $source

The first difference is at line ${diff.line}.
Actual:   ${diff.actual}
Expected: ${diff.expected}

This failure can be caused by changes in the front-end if it starts generating
different kernel AST for the same Dart programs.

In order to re-generate expectations run tests with -D$kUpdateExpectations=true VM option:

  sdk/bin/dart -D$kUpdateExpectations=true pkg/compiler/test/kernel/goldens_test.dart

In order to dump actual results into .actual files run tests with -D$kDumpActualResult=true VM option.
""");
    }
  }
}

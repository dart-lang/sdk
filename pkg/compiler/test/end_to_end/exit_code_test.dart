// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test the exit code of dart2js in case of exceptions, errors, warnings, etc.

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'package:compiler/compiler_new.dart' as api;
import 'package:compiler/src/backend_strategy.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/codegen.dart';
import 'package:compiler/src/common/work.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/dart2js.dart' as entry;
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/diagnostics/invariant.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/diagnostics/spannable.dart';
import 'package:compiler/src/apiimpl.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:compiler/src/null_compiler_output.dart';
import 'package:compiler/src/serialization/serialization.dart';
import 'package:compiler/src/options.dart' show CompilerOptions;
import 'package:compiler/src/universe/world_impact.dart';
import 'package:compiler/src/world.dart';
import 'diagnostic_reporter_helper.dart';
import '../helpers/memory_compiler.dart';

class TestCompiler extends CompilerImpl {
  final String testMarker;
  final String testType;
  final Function onTest;
  @override
  TestDiagnosticReporter reporter;

  TestCompiler(
      api.CompilerInput inputProvider,
      api.CompilerOutput outputProvider,
      api.CompilerDiagnostics handler,
      CompilerOptions options,
      String this.testMarker,
      String this.testType,
      Function this.onTest)
      : reporter = new TestDiagnosticReporter(),
        super(inputProvider, outputProvider, handler, options) {
    reporter.compiler = this;
    reporter.reporter = super.reporter;
    test('Compiler');
  }

  @override
  BackendStrategy createBackendStrategy() {
    return new TestBackendStrategy(this);
  }

  @override
  Future<bool> run(Uri uri) {
    test('Compiler.run');
    return super.run(uri);
  }

  test(String marker) {
    if (marker == testMarker) {
      switch (testType) {
        case 'assert':
          onTest(testMarker, testType);
          assert(false);
          break;
        case 'failedAt':
          onTest(testMarker, testType);
          failedAt(NO_LOCATION_SPANNABLE, marker);
          break;
        case 'warning':
          onTest(testMarker, testType);
          reporter.reportWarningMessage(
              NO_LOCATION_SPANNABLE, MessageKind.GENERIC, {'text': marker});
          break;
        case 'error':
          onTest(testMarker, testType);
          reporter.reportErrorMessage(
              NO_LOCATION_SPANNABLE, MessageKind.GENERIC, {'text': marker});
          break;
        case 'internalError':
          onTest(testMarker, testType);
          reporter.internalError(NO_LOCATION_SPANNABLE, marker);
          break;
        case 'NoSuchMethodError':
          onTest(testMarker, testType);
          dynamic n;
          n.foo;
          break;
        case '':
          onTest(testMarker, testType);
          break;
      }
    }
  }
}

class TestBackendStrategy extends JsBackendStrategy {
  final TestCompiler compiler;

  TestBackendStrategy(TestCompiler compiler)
      : this.compiler = compiler,
        super(compiler);

  @override
  WorldImpact generateCode(
      WorkItem work,
      JClosedWorld closedWorld,
      CodegenResults codegenResults,
      EntityLookup entityLookup,
      ComponentLookup componentLookup) {
    compiler.test('Compiler.codegen');
    return super.generateCode(
        work, closedWorld, codegenResults, entityLookup, componentLookup);
  }
}

class TestDiagnosticReporter extends DiagnosticReporterWrapper {
  TestCompiler compiler;
  @override
  DiagnosticReporter reporter;

  @override
  withCurrentElement(Entity element, f()) {
    return super.withCurrentElement(element, () {
      compiler.test('Compiler.withCurrentElement');
      return f();
    });
  }
}

int checkedResults = 0;

Future testExitCode(
    String marker, String type, int expectedExitCode, List options) {
  bool testOccurred = false;

  void onTest(String testMarker, String testType) {
    if (testMarker == marker && testType == type) {
      testOccurred = true;
    }
  }

  return new Future(() {
    Future<api.CompilationResult> compile(
        CompilerOptions compilerOptions,
        api.CompilerInput compilerInput,
        api.CompilerDiagnostics compilerDiagnostics,
        api.CompilerOutput compilerOutput) {
      compilerOutput = const NullCompilerOutput();
      // Use this to silence the test when debugging:
      // handler = (uri, begin, end, message, kind) {};
      Compiler compiler = new TestCompiler(compilerInput, compilerOutput,
          compilerDiagnostics, compilerOptions, marker, type, onTest);
      return compiler.run(compilerOptions.entryPoint).then((bool success) {
        return new api.CompilationResult(compiler, isSuccess: success);
      });
    }

    int foundExitCode;

    checkResult() {
      Expect.isTrue(testOccurred, 'testExitCode($marker, $type) did not occur');
      if (foundExitCode == null) foundExitCode = 0;
      print('testExitCode($marker, $type) '
          'exitCode=$foundExitCode expected=$expectedExitCode');
      Expect.equals(
          expectedExitCode,
          foundExitCode,
          'testExitCode($marker, $type) '
          'exitCode=$foundExitCode expected=${expectedExitCode}');
      checkedResults++;
    }

    void exit(exitCode) {
      if (foundExitCode == null) {
        foundExitCode = exitCode;
      }
    }

    ;

    entry.exitFunc = exit;
    entry.compileFunc = compile;

    List<String> args = new List<String>.from(options)
      ..add("--libraries-spec=$sdkLibrariesSpecificationUri")
      ..add("--platform-binaries=$sdkPlatformBinariesPath")
      ..add("pkg/compiler/test/end_to_end/data/exit_code_helper.dart");
    Future result = entry.internalMain(args);
    return result.catchError((e, s) {
      // Capture crashes.
    }).whenComplete(checkResult);
  });
}

Future testExitCodes(
    String marker, Map<String, int> expectedExitCodes, List<String> options) {
  return Future.forEach(expectedExitCodes.keys, (String type) {
    return testExitCode(marker, type, expectedExitCodes[type], options);
  });
}

void main() {
  bool isCheckedMode = false;
  assert((isCheckedMode = true));

  entry.enableWriteString = false;

  Map<String, int> _expectedExitCode(
      {bool beforeRun: false, bool fatalWarnings: false}) {
    if (beforeRun) {
      return {
        '': 0,
        'NoSuchMethodError': 253,
        'assert': isCheckedMode ? 253 : 0,
        'failedAt': 253
      };
    }

    // duringRun:
    return {
      '': 0,
      'NoSuchMethodError': 253,
      'assert': isCheckedMode ? 253 : 0,
      'failedAt': 253,
      'warning': fatalWarnings ? 1 : 0,
      'error': 1,
      'internalError': 253,
    };
  }

  const beforeRun = false;
  const duringRun = true;
  final tests = {
    'Compiler': beforeRun,
    'Compiler.run': beforeRun,
    'Compiler.withCurrentElement': duringRun,
    'Compiler.codegen': duringRun,
  };
  int totalExpectedErrors = 0;

  asyncTest(() async {
    for (String marker in tests.keys) {
      var expected = _expectedExitCode(beforeRun: tests[marker]);
      totalExpectedErrors += expected.length;
      await testExitCodes(marker, expected, []);

      expected =
          _expectedExitCode(beforeRun: tests[marker], fatalWarnings: true);
      totalExpectedErrors += expected.length;
      await testExitCodes(marker, expected, [Flags.fatalWarnings]);
    }

    Expect.equals(totalExpectedErrors, checkedResults);
  });
}

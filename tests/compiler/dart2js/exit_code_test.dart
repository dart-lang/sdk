// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the exit code of dart2js in case of exceptions, errors, warnings, etc.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'package:compiler/compiler_new.dart' as api;
import 'package:compiler/src/common/backend_api.dart';
import 'package:compiler/src/common/codegen.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/compile_time_constants.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/dart2js.dart' as entry;
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/diagnostics/invariant.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/diagnostics/spannable.dart';
import 'package:compiler/src/apiimpl.dart' as apiimpl;
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/js_backend/js_backend.dart';
import 'package:compiler/src/library_loader.dart';
import 'package:compiler/src/null_compiler_output.dart';
import 'package:compiler/src/options.dart' show CompilerOptions;
import 'package:compiler/src/resolution/resolution.dart';
import 'package:compiler/src/scanner/scanner_task.dart';
import 'package:compiler/src/universe/world_impact.dart';
import 'package:compiler/src/world.dart';
import 'diagnostic_reporter_helper.dart';

class TestCompiler extends apiimpl.CompilerImpl {
  final String testMarker;
  final String testType;
  final Function onTest;
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
  JavaScriptBackend createBackend() {
    return new TestBackend(this);
  }

  @override
  ScannerTask createScannerTask() => new TestScanner(this);

  @override
  Resolution createResolution() => new TestResolution(this);

  @override
  ResolverTask createResolverTask() {
    return new TestResolver(this, backend.constantCompilerTask);
  }

  Future<bool> run(Uri uri) {
    test('Compiler.run');
    return super.run(uri);
  }

  LoadedLibraries processLoadedLibraries(LoadedLibraries loadedLibraries) {
    test('Compiler.processLoadedLibraries');
    return super.processLoadedLibraries(loadedLibraries);
  }

  test(String marker) {
    if (marker == testMarker) {
      switch (testType) {
        case 'assert':
          onTest(testMarker, testType);
          assert(false);
          break;
        case 'invariant':
          onTest(testMarker, testType);
          invariant(NO_LOCATION_SPANNABLE, false, message: marker);
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
          null.foo;
          break;
        case '':
          onTest(testMarker, testType);
          break;
      }
    }
  }
}

class TestBackend extends JavaScriptBackend {
  final TestCompiler compiler;
  TestBackend(TestCompiler compiler)
      : this.compiler = compiler,
        super(compiler,
            generateSourceMap: compiler.options.generateSourceMap,
            useStartupEmitter: compiler.options.useStartupEmitter,
            useMultiSourceInfo: compiler.options.useMultiSourceInfo,
            useNewSourceInfo: compiler.options.useNewSourceInfo);

  @override
  WorldImpact codegen(CodegenWorkItem work, ClosedWorld closedWorld) {
    compiler.test('Compiler.codegen');
    return super.codegen(work, closedWorld);
  }
}

class TestDiagnosticReporter extends DiagnosticReporterWrapper {
  TestCompiler compiler;
  DiagnosticReporter reporter;

  @override
  withCurrentElement(Element element, f()) {
    return super.withCurrentElement(element, () {
      compiler.test('Compiler.withCurrentElement');
      return f();
    });
  }
}

class TestScanner extends ScannerTask {
  final TestCompiler compiler;

  TestScanner(TestCompiler compiler)
      : compiler = compiler,
        super(compiler.dietParser, compiler.reporter, compiler.measurer);

  void scanElements(CompilationUnitElement compilationUnit) {
    compiler.test('ScannerTask.scanElements');
    super.scanElements(compilationUnit);
  }
}

class TestResolver extends ResolverTask {
  final TestCompiler compiler;

  TestResolver(TestCompiler compiler, ConstantCompiler constantCompiler)
      : this.compiler = compiler,
        super(compiler.resolution, constantCompiler, compiler.measurer);

  void computeClassMembers(ClassElement element) {
    compiler.test('ResolverTask.computeClassMembers');
    super.computeClassMembers(element);
  }
}

class TestResolution extends CompilerResolution {
  TestCompiler compiler;

  TestResolution(TestCompiler compiler)
      : this.compiler = compiler,
        super(compiler);

  @override
  WorldImpact computeWorldImpact(Element element) {
    compiler.test('Compiler.analyzeElement');
    return super.computeWorldImpact(element);
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
      ..add("--library-root=${Platform.script.resolve('../../../sdk/')}")
      ..add("tests/compiler/dart2js/data/exit_code_helper.dart");
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

  Map _expectedExitCode({bool beforeRun: false, bool fatalWarnings: false}) {
    if (beforeRun) {
      return {
        '': 0,
        'NoSuchMethodError': 253,
        'assert': isCheckedMode ? 253 : 0,
        'invariant': 253
      };
    }

    // duringRun:
    return {
      '': 0,
      'NoSuchMethodError': 253,
      'assert': isCheckedMode ? 253 : 0,
      'invariant': 253,
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
    'Compiler.processLoadedLibraries': beforeRun,
    'ScannerTask.scanElements': duringRun,
    'Compiler.withCurrentElement': duringRun,
    'Compiler.analyzeElement': duringRun,
    'Compiler.codegen': duringRun,
    'ResolverTask.computeClassMembers': duringRun,
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
      await testExitCodes(marker, expected, ['--fatal-warnings']);
    }

    Expect.equals(totalExpectedErrors, checkedResults);
  });
}

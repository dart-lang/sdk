// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the exit code of dart2js in case of exceptions, fatal errors, errors,
// warnings, etc.


import 'dart:async';
import 'dart:io' show Platform;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import '../../../sdk/lib/_internal/compiler/compiler.dart' as api;
import '../../../sdk/lib/_internal/compiler/implementation/dart2js.dart' as entry;
import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart';
import '../../../sdk/lib/_internal/compiler/implementation/apiimpl.dart' as apiimpl;
import '../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart';
import '../../../sdk/lib/_internal/compiler/implementation/resolution/resolution.dart';
import '../../../sdk/lib/_internal/compiler/implementation/scanner/scannerlib.dart';
import '../../../sdk/lib/_internal/compiler/implementation/util/util.dart';

class TestCompiler extends apiimpl.Compiler {
  final String testMarker;
  final String testType;
  final Function onTest;

  TestCompiler(api.CompilerInputProvider inputProvider,
                api.CompilerOutputProvider outputProvider,
                api.DiagnosticHandler handler,
                Uri libraryRoot,
                Uri packageRoot,
                List<String> options,
                Map<String, dynamic> environment,
                String this.testMarker,
                String this.testType,
                Function this.onTest)
      : super(inputProvider, outputProvider, handler, libraryRoot,
              packageRoot, options, environment) {
    scanner = new TestScanner(this);
    resolver = new TestResolver(this);
    test('Compiler');
  }

  Future<bool> run(Uri uri) {
    test('Compiler.run');
    return super.run(uri);
  }

  Future scanBuiltinLibraries() {
    test('Compiler.scanBuiltinLibraries');
    return super.scanBuiltinLibraries();
  }

  void initializeSpecialClasses() {
    test('Compiler.initializeSpecialClasses');
    super.initializeSpecialClasses();
  }

  TreeElements analyzeElement(Element element) {
    test('Compiler.analyzeElement');
    return super.analyzeElement(element);
  }

  void codegen(CodegenWorkItem work, CodegenEnqueuer world) {
    test('Compiler.codegen');
    super.codegen(work, world);
  }

  withCurrentElement(Element element, f()) {
    return super.withCurrentElement(element, () {
      test('Compiler.withCurrentElement');
      return f();
    });
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
        invariant(CURRENT_ELEMENT_SPANNABLE, false, message: marker);
        break;
      case 'warning':
        onTest(testMarker, testType);
        reportWarning(CURRENT_ELEMENT_SPANNABLE,
                      MessageKind.GENERIC, {'text': marker});
        break;
      case 'error':
        onTest(testMarker, testType);
        reportError(CURRENT_ELEMENT_SPANNABLE,
                    MessageKind.GENERIC, {'text': marker});
        break;
      case 'fatalError':
        onTest(testMarker, testType);
        reportFatalError(CURRENT_ELEMENT_SPANNABLE,
                         MessageKind.GENERIC, {'text': marker});
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

class TestScanner extends ScannerTask {
  TestScanner(TestCompiler compiler) : super(compiler);

  TestCompiler get compiler => super.compiler;

  void scanElements(CompilationUnitElement compilationUnit) {
    compiler.test('ScannerTask.scanElements');
    super.scanElements(compilationUnit);
  }
}

class TestResolver extends ResolverTask {
  TestResolver(TestCompiler compiler) : super(compiler);

  TestCompiler get compiler => super.compiler;

  void computeClassMembers(ClassElement element) {
    compiler.test('ResolverTask.computeClassMembers');
    super.computeClassMembers(element);
  }
}

int checkedResults = 0;

Future testExitCode(String marker, String type, int expectedExitCode) {
  bool testOccurred = false;

  void onTest(String testMarker, String testType) {
    if (testMarker == marker && testType == type) {
      testOccurred = true;
    }
  }
  return new Future(() {
    Future<String> compile(Uri script,
                           Uri libraryRoot,
                           Uri packageRoot,
                           api.CompilerInputProvider inputProvider,
                           api.DiagnosticHandler handler,
                           [List<String> options = const [],
                            api.CompilerOutputProvider outputProvider,
                            Map<String, dynamic> environment = const {}]) {
      libraryRoot = Platform.script.resolve('../../../sdk/');
      outputProvider = NullSink.outputProvider;
      handler = (uri, begin, end, message, kind) {};
      Compiler compiler = new TestCompiler(inputProvider,
                                           outputProvider,
                                           handler,
                                           libraryRoot,
                                           packageRoot,
                                           options,
                                           environment,
                                           marker,
                                           type,
                                           onTest);
      return compiler.run(script).then((_) {
        String code = compiler.assembledCode;
        if (code != null && outputProvider != null) {
          String outputType = 'js';
          if (options.contains('--output-type=dart')) {
            outputType = 'dart';
          }
          outputProvider('', outputType)
              ..add(code)
              ..close();
          code = ''; // Non-null signals success.
        }
        return code;
      });
    }

    int foundExitCode;

    checkResult() {
      Expect.isTrue(testOccurred, 'testExitCode($marker, $type) did not occur');
      if (foundExitCode == null) foundExitCode = 0;
      print('testExitCode($marker, $type) '
            'exitCode=$foundExitCode expected=$expectedExitCode');
      Expect.equals(expectedExitCode, foundExitCode,
          'testExitCode($marker, $type) '
          'exitCode=$foundExitCode expected=${expectedExitCode}');
      checkedResults++;
    }

    void exit(exitCode) {
      if (foundExitCode == null) {
        foundExitCode = exitCode;
      }
    };

    entry.exitFunc = exit;
    entry.compileFunc = compile;

    Future result = entry.internalMain(
        ["tests/compiler/dart2js/exit_code_helper.dart"]);
    return result.whenComplete(checkResult);
  });
}

Future testExitCodes(String marker, Map<String,int> expectedExitCodes) {
  return Future.forEach(expectedExitCodes.keys, (String type) {
    return testExitCode(marker, type, expectedExitCodes[type]);
  });
}

void main() {
  bool isCheckedMode = false;
  assert(isCheckedMode = true);
  Expect.isTrue(isCheckedMode, 'This test must be run in checked mode.');

  const beforeRun = const {
    '': 0,
    'NoSuchMethodError': 253,
    'assert': 253,
    'invariant': 253
  };

  const duringRun = const {
    '': 0,
    'NoSuchMethodError': 253,
    'assert': 253,
    'invariant': 253,
    'warning': 0,
    'error': 1,
    'fatalError': 1,
  };

  const tests = const {
    'Compiler': beforeRun,
    'Compiler.run': beforeRun,
    'Compiler.scanBuiltinLibraries': beforeRun,
    'Compiler.initializeSpecialClasses': beforeRun,
    'ScannerTask.scanElements': duringRun,
    'Compiler.withCurrentElement': duringRun,
    'Compiler.analyzeElement': duringRun,
    'Compiler.codegen': duringRun,
    'ResolverTask.computeClassMembers': duringRun,
  };

  asyncStart();
  Future.forEach(tests.keys, (marker) {
    return testExitCodes(marker, tests[marker]);
  }).then((_) {
    int countResults(Map runType) {
      return runType.length *
             tests.values.where((r) => r == runType).length;
    }

    Expect.equals(countResults(beforeRun) + countResults(duringRun),
                  checkedResults);
    asyncEnd();
  });
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the exit code of dart2js in case of exceptions, errors, warnings, etc.


import 'dart:async';
import 'dart:io' show Platform;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'package:compiler/compiler.dart' as api;
import 'package:compiler/src/compile_time_constants.dart';
import 'package:compiler/src/dart2js.dart' as entry;
import 'package:compiler/src/dart2jslib.dart';
import 'package:compiler/src/apiimpl.dart' as apiimpl;
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/library_loader.dart';
import 'package:compiler/src/resolution/resolution.dart';
import 'package:compiler/src/scanner/scannerlib.dart';
import 'package:compiler/src/util/util.dart';

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
                Uri packageConfig,
                api.PackagesDiscoveryProvider findPackages,
                String this.testMarker,
                String this.testType,
                Function this.onTest)
      : super(inputProvider, outputProvider, handler, libraryRoot,
              packageRoot, options, environment, packageConfig, findPackages) {
    scanner = new TestScanner(this);
    resolver = new TestResolver(this, backend.constantCompilerTask);
    test('Compiler');
  }

  Future<bool> run(Uri uri) {
    test('Compiler.run');
    return super.run(uri);
  }

  Future onLibraryScanned(LibraryElement element, LibraryLoader loader) {
    test('Compiler.onLibraryScanned');
    return super.onLibraryScanned(element, loader);
  }

  Future onLibrariesLoaded(LoadedLibraries loadedLibraries) {
    test('Compiler.onLibrariesLoaded');
    return super.onLibrariesLoaded(loadedLibraries);
  }

  WorldImpact analyzeElement(Element element) {
    test('Compiler.analyzeElement');
    return super.analyzeElement(element);
  }

  WorldImpact codegen(CodegenWorkItem work, CodegenEnqueuer world) {
    test('Compiler.codegen');
    return super.codegen(work, world);
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
        invariant(NO_LOCATION_SPANNABLE, false, message: marker);
        break;
      case 'warning':
        onTest(testMarker, testType);
        reportWarning(NO_LOCATION_SPANNABLE,
                      MessageKind.GENERIC, {'text': marker});
        break;
      case 'error':
        onTest(testMarker, testType);
        reportError(NO_LOCATION_SPANNABLE,
                    MessageKind.GENERIC, {'text': marker});
        break;
      case 'internalError':
        onTest(testMarker, testType);
        internalError(NO_LOCATION_SPANNABLE, marker);
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
  TestResolver(TestCompiler compiler, ConstantCompiler constantCompiler)
      : super(compiler, constantCompiler);

  TestCompiler get compiler => super.compiler;

  void computeClassMembers(ClassElement element) {
    compiler.test('ResolverTask.computeClassMembers');
    super.computeClassMembers(element);
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
        Uri script,
        Uri libraryRoot,
        Uri packageRoot,
        api.CompilerInputProvider inputProvider,
        api.DiagnosticHandler handler,
        [List<String> options = const [],
         api.CompilerOutputProvider outputProvider,
         Map<String, dynamic> environment = const {},
         Uri packageConfig,
         api.PackagesDiscoveryProvider findPackages]) {
      libraryRoot = Platform.script.resolve('../../../sdk/');
      outputProvider = NullSink.outputProvider;
      // Use this to silence the test when debugging:
      // handler = (uri, begin, end, message, kind) {};
      Compiler compiler = new TestCompiler(inputProvider,
                                           outputProvider,
                                           handler,
                                           libraryRoot,
                                           packageRoot,
                                           options,
                                           environment,
                                           packageConfig,
                                           findPackages,
                                           marker,
                                           type,
                                           onTest);
      return compiler.run(script).then((bool success) {
        return new api.CompilationResult(compiler, isSuccess: success);
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

    List<String> args = new List<String>.from(options)
        ..add("tests/compiler/dart2js/exit_code_helper.dart");
    Future result = entry.internalMain(args);
    return result.catchError((e, s) {
      // Capture crashes.
    }).whenComplete(checkResult);
  });
}

Future testExitCodes(
    String marker, Map<String,int> expectedExitCodes, List<String> options) {
  return Future.forEach(expectedExitCodes.keys, (String type) {
    return testExitCode(marker, type, expectedExitCodes[type], options);
  });
}

void main() {
  bool isCheckedMode = false;
  assert((isCheckedMode = true));

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
    'Compiler.onLibraryScanned': beforeRun,
    'Compiler.onLibrariesLoaded': beforeRun,
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

      expected = _expectedExitCode(
          beforeRun: tests[marker], fatalWarnings: true);
      totalExpectedErrors += expected.length;
      await testExitCodes(marker, expected, ['--fatal-warnings']);
    }

    Expect.equals(totalExpectedErrors, checkedResults);
  });
}

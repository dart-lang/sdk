// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:analysis_server/src/protocol_server.dart'
    hide DiagnosticMessage;
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/src/dart/analysis/results.dart' as engine;
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as engine;
import 'package:analyzer/src/error/codes.dart' as engine;
import 'package:analyzer/src/generated/source.dart' as engine;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'constants.dart';
import 'mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisErrorTest);
    defineReflectiveTests(EnumTest);
  });
}

@reflectiveTest
class AnalysisErrorTest {
  MockSource source = MockSource();
  MockAnalysisError engineError;
  ResolvedUnitResult result;

  void setUp() {
    // prepare Source
    source.fullName = 'foo.dart';
    // prepare AnalysisError
    engineError = MockAnalysisError(source,
        engine.CompileTimeErrorCode.AMBIGUOUS_EXPORT, 10, 20, 'my message');
    // prepare ResolvedUnitResult
    var lineInfo = engine.LineInfo([0, 5, 9, 20]);
    result = engine.ResolvedUnitResultImpl(null, 'foo.dart', null, true, null,
        lineInfo, false, null, [engineError]);
  }

  void tearDown() {
    source = null;
    engineError = null;
  }

  void test_fromEngine_hasContextMessage() {
    engineError.contextMessages.add(engine.DiagnosticMessageImpl(
        filePath: 'bar.dart', offset: 30, length: 5, message: 'context'));
    var session = MockAnalysisSession();
    session.addFileResult(engine.FileResultImpl(
        session, 'bar.dart', null, engine.LineInfo([0, 5, 9, 20]), false));
    var error = newAnalysisError_fromEngine(
        engine.ResolvedUnitResultImpl(session, 'foo.dart', null, true, null,
            engine.LineInfo([0, 5, 9, 20]), false, null, [engineError]),
        engineError);
    expect(error.toJson(), {
      'severity': 'ERROR',
      'type': 'COMPILE_TIME_ERROR',
      'location': {
        'file': 'foo.dart',
        'offset': 10,
        'length': 20,
        'startLine': 3,
        'startColumn': 2
      },
      'message': 'my message',
      'code': 'ambiguous_export',
      'contextMessages': [
        {
          'message': 'context',
          'location': {
            'file': 'bar.dart',
            'offset': 30,
            'length': 5,
            'startLine': 4,
            'startColumn': 11
          }
        }
      ],
      'hasFix': false
    });
  }

  void test_fromEngine_hasCorrection() {
    engineError.correction = 'my correction';
    var error = newAnalysisError_fromEngine(result, engineError);
    expect(error.toJson(), {
      SEVERITY: 'ERROR',
      TYPE: 'COMPILE_TIME_ERROR',
      LOCATION: {
        FILE: 'foo.dart',
        OFFSET: 10,
        LENGTH: 20,
        START_LINE: 3,
        START_COLUMN: 2
      },
      MESSAGE: 'my message',
      CORRECTION: 'my correction',
      CODE: 'ambiguous_export',
      HAS_FIX: false
    });
  }

  void test_fromEngine_hasUrl() {
    engineError = MockAnalysisError(
        source,
        MockErrorCode(url: 'http://codes.dartlang.org/TEST_ERROR'),
        10,
        20,
        'my message');
    var error = newAnalysisError_fromEngine(result, engineError);
    expect(error.toJson(), {
      SEVERITY: 'ERROR',
      TYPE: 'COMPILE_TIME_ERROR',
      LOCATION: {
        FILE: 'foo.dart',
        OFFSET: 10,
        LENGTH: 20,
        START_LINE: 3,
        START_COLUMN: 2
      },
      MESSAGE: 'my message',
      CODE: 'test_error',
      URL: 'http://codes.dartlang.org/TEST_ERROR',
      HAS_FIX: false
    });
  }

  void test_fromEngine_lint() {
    engineError = MockAnalysisError(
        source,
        LintCode('my_lint', 'my message', correction: 'correction'),
        10,
        20,
        'my message');
    var error = newAnalysisError_fromEngine(result, engineError);
    expect(error.toJson(), {
      SEVERITY: 'INFO',
      TYPE: 'LINT',
      LOCATION: {
        FILE: 'foo.dart',
        OFFSET: 10,
        LENGTH: 20,
        START_LINE: 3,
        START_COLUMN: 2
      },
      MESSAGE: 'my message',
      CODE: 'my_lint',
      URL: 'https://dart-lang.github.io/linter/lints/my_lint.html',
      HAS_FIX: false
    });
  }

  void test_fromEngine_noCorrection() {
    engineError.correction = null;
    var error = newAnalysisError_fromEngine(result, engineError);
    expect(error.toJson(), {
      SEVERITY: 'ERROR',
      TYPE: 'COMPILE_TIME_ERROR',
      LOCATION: {
        FILE: 'foo.dart',
        OFFSET: 10,
        LENGTH: 20,
        START_LINE: 3,
        START_COLUMN: 2
      },
      MESSAGE: 'my message',
      CODE: 'ambiguous_export',
      HAS_FIX: false
    });
  }

  void test_fromEngine_noLineInfo() {
    engineError.correction = null;
    var error = newAnalysisError_fromEngine(
        engine.ResolvedUnitResultImpl(null, 'foo.dart', null, true, null, null,
            false, null, [engineError]),
        engineError);
    expect(error.toJson(), {
      SEVERITY: 'ERROR',
      TYPE: 'COMPILE_TIME_ERROR',
      LOCATION: {
        FILE: 'foo.dart',
        OFFSET: 10,
        LENGTH: 20,
        START_LINE: -1,
        START_COLUMN: -1
      },
      MESSAGE: 'my message',
      CODE: 'ambiguous_export',
      HAS_FIX: false
    });
  }
}

@reflectiveTest
class EnumTest {
  void test_AnalysisErrorSeverity() {
    EnumTester<engine.ErrorSeverity, AnalysisErrorSeverity>().run(
        (engine.ErrorSeverity engineErrorSeverity) =>
            AnalysisErrorSeverity(engineErrorSeverity.name),
        exceptions: {engine.ErrorSeverity.NONE: null});
  }

  void test_AnalysisErrorType() {
    EnumTester<engine.ErrorType, AnalysisErrorType>().run(
        (engine.ErrorType engineErrorType) =>
            AnalysisErrorType(engineErrorType.name));
  }

  void test_ElementKind() {
    EnumTester<engine.ElementKind, ElementKind>()
        .run(convertElementKind, exceptions: {
      // TODO(paulberry): do any of the exceptions below constitute bugs?
      engine.ElementKind.DYNAMIC: ElementKind.UNKNOWN,
      engine.ElementKind.ERROR: ElementKind.UNKNOWN,
      engine.ElementKind.EXPORT: ElementKind.UNKNOWN,
      engine.ElementKind.GENERIC_FUNCTION_TYPE: ElementKind.FUNCTION_TYPE_ALIAS,
      engine.ElementKind.IMPORT: ElementKind.UNKNOWN,
      engine.ElementKind.NAME: ElementKind.UNKNOWN,
      engine.ElementKind.NEVER: ElementKind.UNKNOWN,
      engine.ElementKind.TYPE_ALIAS: ElementKind.UNKNOWN,
      engine.ElementKind.UNIVERSE: ElementKind.UNKNOWN
    });
  }

  void test_SearchResultKind() {
    // TODO(paulberry): why does the MatchKind class exist at all?  Can't we
    // use SearchResultKind inside the analysis server?
    EnumTester<MatchKind, SearchResultKind>()
        .run(newSearchResultKind_fromEngine);
  }
}

/// Helper class for testing the correspondence between an analysis engine enum
/// and an analysis server API enum.
class EnumTester<EngineEnum, ApiEnum> {
  /// Test that the function [convert] properly converts all possible values of
  /// [EngineEnum] to an [ApiEnum] with the same name, with the exceptions noted
  /// in [exceptions].  For each key in [exceptions], if the corresponding value
  /// is null, then we check that converting the given key results in an error.
  /// If the corresponding value is an [ApiEnum], then we check that converting
  /// the given key results in the given value.
  void run(ApiEnum Function(EngineEnum) convert,
      {Map<EngineEnum, ApiEnum> exceptions = const {}}) {
    var engineClass = reflectClass(EngineEnum);
    engineClass.staticMembers.forEach((Symbol symbol, MethodMirror method) {
      if (symbol == #values) {
        return;
      }
      if (!method.isGetter) {
        return;
      }
      var enumName = MirrorSystem.getName(symbol);
      var engineValue = engineClass.getField(symbol).reflectee as EngineEnum;
      expect(engineValue, TypeMatcher<EngineEnum>());
      if (exceptions.containsKey(engineValue)) {
        var expectedResult = exceptions[engineValue];
        if (expectedResult == null) {
          expect(() {
            convert(engineValue);
          }, throwsException);
        } else {
          var apiValue = convert(engineValue);
          expect(apiValue, equals(expectedResult));
        }
      } else {
        var apiValue = convert(engineValue);
        expect((apiValue as dynamic).name, equals(enumName));
      }
    });
  }
}

class MockAnalysisError implements engine.AnalysisError {
  @override
  MockSource source;

  @override
  engine.ErrorCode errorCode;

  @override
  int offset;

  @override
  String message;

  @override
  String correction;

  @override
  int length;

  @override
  List<DiagnosticMessage> contextMessages = <DiagnosticMessage>[];

  MockAnalysisError(
      this.source, this.errorCode, this.offset, this.length, this.message);

  @override
  String get correctionMessage => null;

  @override
  DiagnosticMessage get problemMessage => null;

  @override
  Severity get severity => null;
}

class MockAnalysisSession implements AnalysisSession {
  Map<String, FileResult> fileResults = {};

  void addFileResult(FileResult result) {
    fileResults[result.path] = result;
  }

  @override
  FileResult getFile(String path) => fileResults[path];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockErrorCode implements engine.ErrorCode {
  @override
  engine.ErrorType type;

  @override
  engine.ErrorSeverity errorSeverity;

  @override
  String name;

  @override
  String url;

  MockErrorCode(
      {this.type = engine.ErrorType.COMPILE_TIME_ERROR,
      this.errorSeverity = engine.ErrorSeverity.ERROR,
      this.name = 'TEST_ERROR',
      this.url});

  @override
  String get correction {
    throw StateError('Unexpected invocation of correction');
  }

  @override
  bool get hasPublishedDocs => false;

  @override
  bool get isIgnorable => true;

  @override
  bool get isUnresolvedIdentifier => false;

  @override
  String get message {
    throw StateError('Unexpected invocation of message');
  }

  @override
  String get uniqueName {
    throw StateError('Unexpected invocation of uniqueName');
  }
}

// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:analysis_server/src/protocol_server.dart'
    hide DiagnosticMessage, Enum;
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/diagnostic/diagnostic.dart' as engine;
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/source/line_info.dart' as engine;
import 'package:analyzer/source/source.dart' as engine;
import 'package:analyzer/src/dart/analysis/results.dart' as engine;
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/diagnostic/diagnostic_message.dart' as engine;
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
  late MockSource source;
  late MockDiagnostic engineDiagnostic;
  late ResolvedUnitResult result;

  void setUp() {
    // prepare Source
    source = MockSource(fullName: 'foo.dart');
    // prepare AnalysisError
    engineDiagnostic = MockDiagnostic(
      source: source,
      diagnosticCode: diag.ambiguousExport,
      offset: 10,
      length: 20,
      message: 'my message',
    );
    // prepare ResolvedUnitResult
    var lineInfo = engine.LineInfo([0, 5, 9, 20]);
    result = _ResolvedUnitResultImplMock(
      lineInfo: lineInfo,
      diagnostics: [engineDiagnostic],
      path: 'foo.dart',
    );
  }

  void test_fromEngine_hasContextMessage() {
    engineDiagnostic.contextMessages.add(
      engine.DiagnosticMessageImpl(
        filePath: 'bar.dart',
        offset: 30,
        length: 5,
        message: 'context',
        url: null,
      ),
    );
    var error = newAnalysisError_fromEngine(
      _ResolvedUnitResultImplMock(
        lineInfo: engine.LineInfo([0, 5, 9, 20]),
        diagnostics: [engineDiagnostic],
        path: 'bar.dart',
      ),
      engineDiagnostic,
    );
    expect(error.toJson(), {
      severityKey: 'ERROR',
      typeKey: 'COMPILE_TIME_ERROR',
      locationKey: {
        fileKey: 'foo.dart',
        offsetKey: 10,
        lengthKey: 20,
        startLineKey: 3,
        startColumnKey: 2,
        endLineKey: 4,
        endColumnKey: 11,
      },
      messageKey: 'my message',
      codeKey: 'ambiguous_export',
      urlKey: 'https://dart.dev/diagnostics/ambiguous_export',
      contextReferencesKey: [
        {
          messageKey: 'context',
          locationKey: {
            fileKey: 'bar.dart',
            offsetKey: 30,
            lengthKey: 5,
            startLineKey: 4,
            startColumnKey: 11,
            endLineKey: 4,
            endColumnKey: 16,
          },
        },
      ],
      hasFixKey: false,
    });
  }

  void test_fromEngine_hasCorrection() {
    engineDiagnostic = MockDiagnostic(
      source: source,
      diagnosticCode: diag.ambiguousExport,
      offset: 10,
      length: 20,
      message: 'my message',
      correctionMessage: 'my correction',
    );
    var error = newAnalysisError_fromEngine(result, engineDiagnostic);
    expect(error.toJson(), {
      severityKey: 'ERROR',
      typeKey: 'COMPILE_TIME_ERROR',
      locationKey: {
        fileKey: 'foo.dart',
        offsetKey: 10,
        lengthKey: 20,
        startLineKey: 3,
        startColumnKey: 2,
        endLineKey: 4,
        endColumnKey: 11,
      },
      messageKey: 'my message',
      correctionKey: 'my correction',
      codeKey: 'ambiguous_export',
      urlKey: 'https://dart.dev/diagnostics/ambiguous_export',
      hasFixKey: false,
    });
  }

  void test_fromEngine_hasUrl() {
    engineDiagnostic = MockDiagnostic(
      source: source,
      diagnosticCode: MockDiagnosticCode(
        url: 'http://codes.dartlang.org/TEST_ERROR',
      ),
      offset: 10,
      length: 20,
      message: 'my message',
    );
    var error = newAnalysisError_fromEngine(result, engineDiagnostic);
    expect(error.toJson(), {
      severityKey: 'ERROR',
      typeKey: 'COMPILE_TIME_ERROR',
      locationKey: {
        fileKey: 'foo.dart',
        offsetKey: 10,
        lengthKey: 20,
        startLineKey: 3,
        startColumnKey: 2,
        endLineKey: 4,
        endColumnKey: 11,
      },
      messageKey: 'my message',
      codeKey: 'test_error',
      urlKey: 'http://codes.dartlang.org/TEST_ERROR',
      hasFixKey: false,
    });
  }

  void test_fromEngine_lint() {
    engineDiagnostic = MockDiagnostic(
      source: source,
      diagnosticCode: LintCode(
        'my_lint',
        'my message',
        correctionMessage: 'correction',
        uniqueName: 'LintCode.my_lint',
      ),
      offset: 10,
      length: 20,
      message: 'my message',
    );
    var error = newAnalysisError_fromEngine(result, engineDiagnostic);
    expect(error.toJson(), {
      severityKey: 'INFO',
      typeKey: 'LINT',
      locationKey: {
        fileKey: 'foo.dart',
        offsetKey: 10,
        lengthKey: 20,
        startLineKey: 3,
        startColumnKey: 2,
        endLineKey: 4,
        endColumnKey: 11,
      },
      messageKey: 'my message',
      codeKey: 'my_lint',
      hasFixKey: false,
    });
  }

  void test_fromEngine_noCorrection() {
    engineDiagnostic = MockDiagnostic(
      source: source,
      diagnosticCode: diag.ambiguousExport,
      offset: 10,
      length: 20,
      message: 'my message',
    );
    var error = newAnalysisError_fromEngine(result, engineDiagnostic);
    expect(error.toJson(), {
      severityKey: 'ERROR',
      typeKey: 'COMPILE_TIME_ERROR',
      locationKey: {
        fileKey: 'foo.dart',
        offsetKey: 10,
        lengthKey: 20,
        startLineKey: 3,
        startColumnKey: 2,
        endLineKey: 4,
        endColumnKey: 11,
      },
      messageKey: 'my message',
      codeKey: 'ambiguous_export',
      urlKey: 'https://dart.dev/diagnostics/ambiguous_export',
      hasFixKey: false,
    });
  }
}

@reflectiveTest
class EnumTest {
  void test_AnalysisErrorSeverity() {
    EnumTester<engine.DiagnosticSeverity, AnalysisErrorSeverity>().run(
      (engineSeverity) =>
          AnalysisErrorSeverity.values.byName(engineSeverity.name),
      exceptions: {engine.DiagnosticSeverity.NONE: null},
    );
  }

  void test_AnalysisErrorType() {
    EnumTester<engine.DiagnosticType, AnalysisErrorType>().run(
      (engineErrorType) =>
          AnalysisErrorType.values.byName(engineErrorType.name),
    );
  }

  void test_ElementKind() {
    EnumTester<engine.ElementKind, ElementKind>().run(
      convertElementKind,
      exceptions: {
        // TODO(paulberry): do any of the exceptions below constitute bugs?
        engine.ElementKind.AUGMENTATION_IMPORT: ElementKind.UNKNOWN,
        engine.ElementKind.CLASS_AUGMENTATION: ElementKind.UNKNOWN,
        engine.ElementKind.DYNAMIC: ElementKind.UNKNOWN,
        engine.ElementKind.ERROR: ElementKind.UNKNOWN,
        engine.ElementKind.EXPORT: ElementKind.UNKNOWN,
        engine.ElementKind.GENERIC_FUNCTION_TYPE:
            ElementKind.FUNCTION_TYPE_ALIAS,
        engine.ElementKind.IMPORT: ElementKind.UNKNOWN,
        engine.ElementKind.LIBRARY_AUGMENTATION: ElementKind.UNKNOWN,
        engine.ElementKind.NAME: ElementKind.UNKNOWN,
        engine.ElementKind.NEVER: ElementKind.UNKNOWN,
        engine.ElementKind.PART: ElementKind.COMPILATION_UNIT,
        engine.ElementKind.RECORD: ElementKind.UNKNOWN,
        engine.ElementKind.UNIVERSE: ElementKind.UNKNOWN,
      },
    );
  }

  void test_SearchResultKind() {
    // TODO(paulberry): why does the MatchKind class exist at all?  Can't we
    // use SearchResultKind inside the analysis server?
    EnumTester<MatchKind, SearchResultKind>().run(
      newSearchResultKind_fromEngine,
      exceptions: {
        MatchKind.REFERENCE_IN_PATTERN_FIELD: SearchResultKind.REFERENCE,
        MatchKind.DOT_SHORTHANDS_CONSTRUCTOR_INVOCATION:
            SearchResultKind.INVOCATION,
        MatchKind.INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS:
            SearchResultKind.INVOCATION,
        MatchKind.DOT_SHORTHANDS_CONSTRUCTOR_TEAR_OFF:
            SearchResultKind.REFERENCE,
        MatchKind.REFERENCE_BY_CONSTRUCTOR_TEAR_OFF: SearchResultKind.REFERENCE,
        MatchKind.REFERENCE_IN_EXTENDS_CLAUSE: SearchResultKind.REFERENCE,
        MatchKind.REFERENCE_IN_IMPLEMENTS_CLAUSE: SearchResultKind.REFERENCE,
        MatchKind.REFERENCE_IN_WITH_CLAUSE: SearchResultKind.REFERENCE,
        MatchKind.REFERENCE_IN_ON_CLAUSE: SearchResultKind.REFERENCE,
      },
    );
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
  void run(
    ApiEnum Function(EngineEnum) convert, {
    Map<EngineEnum, ApiEnum?> exceptions = const {},
  }) {
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
          }, throwsArgumentError);
        } else {
          var apiValue = convert(engineValue);
          expect(apiValue, equals(expectedResult));
        }
      } else {
        var apiValue = convert(engineValue);
        expect((apiValue as Enum).name, equals(enumName));
      }
    });
  }
}

class MockDiagnostic implements engine.Diagnostic {
  final MockSource? _source;
  final engine.DiagnosticCode? _diagnosticCode;
  final int? _offset;
  final int? _length;
  final String? _message;

  final DiagnosticMessage? _problemMessage;
  final String? _correctionMessage;

  @override
  List<DiagnosticMessage> contextMessages = <DiagnosticMessage>[];

  MockDiagnostic({
    MockSource? source,
    engine.DiagnosticCode? diagnosticCode,
    int? offset,
    int? length,
    String? message,
    DiagnosticMessage? problemMessage,
    String? correctionMessage,
  }) : _source = source,
       _diagnosticCode = diagnosticCode,
       _offset = offset,
       _length = length,
       _message = message,
       _problemMessage = problemMessage,
       _correctionMessage = correctionMessage;

  @override
  String? get correction => null;

  @override
  String? get correctionMessage => _correctionMessage;

  @override
  engine.DiagnosticCode get diagnosticCode => _diagnosticCode!;

  @override
  engine.DiagnosticCode get errorCode => diagnosticCode;

  @override
  int get length => _length!;

  @override
  String get message => _message!;

  @override
  int get offset => _offset!;

  @override
  DiagnosticMessage get problemMessage => _problemMessage!;

  @override
  Severity get severity => throw UnimplementedError();

  @override
  engine.Source get source => _source!;
}

class MockDiagnosticCode implements engine.DiagnosticCode {
  @override
  engine.DiagnosticType type;

  @override
  engine.DiagnosticSeverity severity;

  @override
  String name;

  @override
  String? url;

  MockDiagnosticCode({
    this.type = engine.DiagnosticType.COMPILE_TIME_ERROR,
    this.severity = engine.DiagnosticSeverity.ERROR,
    this.name = 'TEST_ERROR',
    this.url,
  });

  @override
  String get correctionMessage {
    throw StateError('Unexpected invocation of correctionMessage');
  }

  @override
  bool get hasPublishedDocs => false;

  @override
  bool get isIgnorable => true;

  @override
  bool get isUnresolvedIdentifier => false;

  @override
  String get problemMessage {
    throw StateError('Unexpected invocation of problemMessage');
  }

  @override
  String get uniqueName {
    throw StateError('Unexpected invocation of uniqueName');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ResolvedUnitResultImplMock implements engine.ResolvedUnitResultImpl {
  @override
  final engine.LineInfo lineInfo;

  @override
  final List<engine.Diagnostic> diagnostics;

  @override
  final String path;

  _ResolvedUnitResultImplMock({
    required this.lineInfo,
    required this.diagnostics,
    required this.path,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

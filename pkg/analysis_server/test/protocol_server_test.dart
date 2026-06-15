// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:analysis_server/src/protocol_server.dart'
    hide DiagnosticMessage, Enum;
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_context.dart';
import 'constants.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisErrorTest);
    defineReflectiveTests(EnumTest);
  });
}

@reflectiveTest
class AnalysisErrorTest extends AbstractContextTest {
  void test_fromEngine_hasContextMessage() async {
    var content = r'''
void f() {
  print(x);
  var x = 1;
}
''';
    var normalizedContent = normalizeSource(content);
    var file = newFile('$testPackageLibPath/foo.dart', content);
    var result = await getResolvedUnit(file);

    var engineDiagnostic = result.diagnostics.firstWhere(
      (d) => d.diagnosticCode == diag.referencedBeforeDeclaration,
    );

    var error = newAnalysisError_fromEngine(result, engineDiagnostic);
    expect(error.toJson(), {
      severityKey: 'ERROR',
      typeKey: 'COMPILE_TIME_ERROR',
      locationKey: {
        fileKey: file.path,
        offsetKey: normalizedContent.indexOf('x'),
        lengthKey: 1,
        startLineKey: 2,
        startColumnKey: 9,
        endLineKey: 2,
        endColumnKey: 10,
      },
      messageKey:
          "Local variable 'x' can't be referenced before it is declared.",
      correctionKey:
          "Try moving the declaration to before the first use, or renaming the local variable so that it doesn't hide a name from an enclosing scope.",
      codeKey: 'referenced_before_declaration',
      urlKey: 'https://dart.dev/diagnostics/referenced_before_declaration',
      contextReferencesKey: [
        {
          messageKey: "The declaration of 'x' is here.",
          locationKey: {
            fileKey: file.path,
            offsetKey: normalizedContent.indexOf('x = 1'),
            lengthKey: 1,
            startLineKey: 3,
            startColumnKey: 7,
            endLineKey: 3,
            endColumnKey: 8,
          },
        },
      ],
      hasFixKey: false,
    });
  }

  void test_fromEngine_hasCorrection() async {
    newFile('$testPackageLibPath/lib1.dart', 'class N {}\n');
    newFile('$testPackageLibPath/lib2.dart', 'class N {}\n');
    var content = r'''
export 'lib1.dart';
export 'lib2.dart';
''';
    var normalizedContent = normalizeSource(content);
    var file = newFile('$testPackageLibPath/foo.dart', content);
    var result = await getResolvedUnit(file);

    var engineDiagnostic = result.diagnostics.firstWhere(
      (d) => d.diagnosticCode == diag.ambiguousExport,
    );

    var error = newAnalysisError_fromEngine(result, engineDiagnostic);
    expect(error.toJson(), {
      severityKey: 'ERROR',
      typeKey: 'COMPILE_TIME_ERROR',
      locationKey: {
        fileKey: file.path,
        offsetKey: normalizedContent.indexOf("'lib2.dart'"),
        lengthKey: 11,
        startLineKey: 2,
        startColumnKey: 8,
        endLineKey: 2,
        endColumnKey: 19,
      },
      messageKey: engineDiagnostic.message,
      correctionKey:
          'Try removing the export of one of the libraries, or explicitly hiding the name in one of the export directives.',
      codeKey: 'ambiguous_export',
      urlKey: 'https://dart.dev/diagnostics/ambiguous_export',
      hasFixKey: false,
    });
  }

  void test_fromEngine_hasUrl() async {
    var content = r'''
void f() {
  print(x);
  var x = 1;
}
''';
    var normalizedContent = normalizeSource(content);
    var file = newFile('$testPackageLibPath/foo.dart', content);
    var result = await getResolvedUnit(file);

    var engineDiagnostic = result.diagnostics.firstWhere(
      (d) => d.diagnosticCode == diag.referencedBeforeDeclaration,
    );

    var error = newAnalysisError_fromEngine(result, engineDiagnostic);
    expect(error.toJson(), {
      severityKey: 'ERROR',
      typeKey: 'COMPILE_TIME_ERROR',
      locationKey: {
        fileKey: file.path,
        offsetKey: normalizedContent.indexOf('x'),
        lengthKey: 1,
        startLineKey: 2,
        startColumnKey: 9,
        endLineKey: 2,
        endColumnKey: 10,
      },
      messageKey:
          "Local variable 'x' can't be referenced before it is declared.",
      correctionKey:
          "Try moving the declaration to before the first use, or renaming the local variable so that it doesn't hide a name from an enclosing scope.",
      codeKey: 'referenced_before_declaration',
      urlKey: 'https://dart.dev/diagnostics/referenced_before_declaration',
      contextReferencesKey: [
        {
          messageKey: "The declaration of 'x' is here.",
          locationKey: {
            fileKey: file.path,
            offsetKey: normalizedContent.indexOf('x = 1'),
            lengthKey: 1,
            startLineKey: 3,
            startColumnKey: 7,
            endLineKey: 3,
            endColumnKey: 8,
          },
        },
      ],
      hasFixKey: false,
    });
  }

  void test_fromEngine_lint() async {
    createAnalysisOptionsFile(lints: ['avoid_print']);
    var content = r'''
void f() {
  print('hello');
}
''';
    var normalizedContent = normalizeSource(content);
    var file = newFile('$testPackageLibPath/foo.dart', content);
    var result = await getResolvedUnit(file);

    var engineDiagnostic = result.diagnostics.firstWhere(
      (d) => d.diagnosticCode.lowerCaseName == 'avoid_print',
    );

    var error = newAnalysisError_fromEngine(result, engineDiagnostic);
    expect(error.toJson(), {
      severityKey: 'INFO',
      typeKey: 'LINT',
      locationKey: {
        fileKey: file.path,
        offsetKey: normalizedContent.indexOf('print'),
        lengthKey: 5,
        startLineKey: 2,
        startColumnKey: 3,
        endLineKey: 2,
        endColumnKey: 8,
      },
      messageKey: engineDiagnostic.message,
      correctionKey: 'Try using a logging framework.',
      codeKey: 'avoid_print',
      urlKey: 'https://dart.dev/diagnostics/avoid_print',
      hasFixKey: false,
    });
  }

  void test_fromEngine_noCorrection() async {
    var content = r'''
void f() {
  // TODO: something
}
''';
    var normalizedContent = normalizeSource(content);
    var file = newFile('$testPackageLibPath/foo.dart', content);
    var result = await getResolvedUnit(file);

    var engineDiagnostic = result.diagnostics.firstWhere(
      (d) => d.diagnosticCode.type == engine.DiagnosticType.TODO,
    );

    var error = newAnalysisError_fromEngine(result, engineDiagnostic);
    expect(error.toJson(), {
      severityKey: 'INFO',
      typeKey: 'TODO',
      locationKey: {
        fileKey: file.path,
        offsetKey: normalizedContent.indexOf('TODO'),
        lengthKey: 15,
        startLineKey: 2,
        startColumnKey: 6,
        endLineKey: 2,
        endColumnKey: 21,
      },
      messageKey: engineDiagnostic.message,
      codeKey: 'todo',
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
        MatchKind.REFERENCE_BY_NAMED_ARGUMENT: SearchResultKind.REFERENCE,
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
        expect((apiValue as Enum).name, equals(engineValue.toString()));
      }
    });
  }
}

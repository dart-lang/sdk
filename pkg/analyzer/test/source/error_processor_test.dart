// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../generated/test_support.dart';
import '../src/util/yaml_test.dart';

main() {
  Diagnostic invalid_assignment = Diagnostic.tmp(
    source: TestSource(),
    offset: 0,
    length: 1,
    diagnosticCode: CompileTimeErrorCode.invalidAssignment,
    arguments: [
      ['x'],
      ['y'],
    ],
  );

  Diagnostic assignment_of_do_not_store = Diagnostic.tmp(
    source: TestSource(),
    offset: 0,
    length: 1,
    diagnosticCode: WarningCode.assignmentOfDoNotStore,
    arguments: [
      ['x'],
    ],
  );

  Diagnostic unused_local_variable = Diagnostic.tmp(
    source: TestSource(),
    offset: 0,
    length: 1,
    diagnosticCode: WarningCode.unusedLocalVariable,
    arguments: [
      ['x'],
    ],
  );

  Diagnostic use_of_void_result = Diagnostic.tmp(
    source: TestSource(),
    offset: 0,
    length: 1,
    diagnosticCode: CompileTimeErrorCode.useOfVoidResult,
  );

  // We in-line a lint code here in order to avoid adding a dependency on the
  // linter package.
  Diagnostic annotate_overrides = Diagnostic.tmp(
    source: TestSource(),
    offset: 0,
    length: 1,
    diagnosticCode: LintCode('annotate_overrides', ''),
  );

  group('ErrorProcessor', () {
    late _TestContext context;

    setUp(() {
      context = _TestContext();
    });

    test('configureOptions', () {
      context.configureOptions('''
analyzer:
  errors:
    invalid_assignment: error # severity ERROR
    assignment_of_do_not_store: false # ignore
    unused_local_variable: true # skipped
    use_of_void_result: unsupported_action # skipped
''');
      expect(
        context.getProcessor(invalid_assignment)!.severity,
        DiagnosticSeverity.ERROR,
      );
      expect(
        context.getProcessor(assignment_of_do_not_store)!.severity,
        isNull,
      );
      expect(context.getProcessor(unused_local_variable), isNull);
      expect(context.getProcessor(use_of_void_result), isNull);
    });

    test('does not upgrade other warnings to errors in strong mode', () {
      context.configureOptions('''
analyzer:
  strong-mode: true
''');
      expect(context.getProcessor(unused_local_variable), isNull);
    });
  });

  group('ErrorConfig', () {
    var config = '''
analyzer:
  errors:
    invalid_assignment: unsupported_action # should be skipped
    assignment_of_do_not_store: false
    unused_local_variable: error
''';

    group('processing', () {
      test('yaml map', () {
        var options = AnalysisOptionsProvider().getOptionsFromString(config);
        var errorConfig = ErrorConfig(
          (options['analyzer'] as YamlMap)['errors'] as YamlNode?,
        );
        expect(errorConfig.processors, hasLength(2));

        // ignore
        var missingReturnProcessor = errorConfig.processors.firstWhere(
          (p) => p.appliesTo(assignment_of_do_not_store),
        );
        expect(missingReturnProcessor.severity, isNull);

        // error
        var unusedLocalProcessor = errorConfig.processors.firstWhere(
          (p) => p.appliesTo(unused_local_variable),
        );
        expect(unusedLocalProcessor.severity, DiagnosticSeverity.ERROR);

        // skip
        var invalidAssignmentProcessor = errorConfig.processors
            .firstWhereOrNull((p) => p.appliesTo(invalid_assignment));
        expect(invalidAssignmentProcessor, isNull);
      });

      test('string map', () {
        var options = wrap({
          'invalid_assignment': 'unsupported_action', // should be skipped
          'assignment_of_do_not_store': 'false',
          'unused_local_variable': 'error',
        });
        var errorConfig = ErrorConfig(options);
        expect(errorConfig.processors, hasLength(2));

        // ignore
        var missingReturnProcessor = errorConfig.processors.firstWhere(
          (p) => p.appliesTo(assignment_of_do_not_store),
        );
        expect(missingReturnProcessor.severity, isNull);

        // error
        var unusedLocalProcessor = errorConfig.processors.firstWhere(
          (p) => p.appliesTo(unused_local_variable),
        );
        expect(unusedLocalProcessor.severity, DiagnosticSeverity.ERROR);

        // skip
        var invalidAssignmentProcessor = errorConfig.processors
            .firstWhereOrNull((p) => p.appliesTo(invalid_assignment));
        expect(invalidAssignmentProcessor, isNull);
      });
    });

    test('configure lints', () {
      var options = AnalysisOptionsProvider().getOptionsFromString(
        'analyzer:\n  errors:\n    annotate_overrides: warning\n',
      );
      var errorConfig = ErrorConfig(
        (options['analyzer'] as YamlMap)['errors'] as YamlNode?,
      );
      expect(errorConfig.processors, hasLength(1));

      ErrorProcessor processor = errorConfig.processors.first;
      expect(processor.appliesTo(annotate_overrides), true);
      expect(processor.severity, DiagnosticSeverity.WARNING);
    });
  });
}

class _TestContext {
  late AnalysisOptions analysisOptions;

  void configureOptions(String options) {
    analysisOptions = AnalysisOptionsImpl.fromYaml(
      optionsMap: AnalysisOptionsProvider().getOptionsFromString(options),
    );
  }

  ErrorProcessor? getProcessor(Diagnostic diagnostic) {
    return ErrorProcessor.getProcessor(analysisOptions, diagnostic);
  }
}

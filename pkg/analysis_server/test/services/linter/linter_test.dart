// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LinterRuleOptionsValidatorTest);
  });
}

@reflectiveTest
class LinterRuleOptionsValidatorTest {
  final LinterRuleOptionsValidator validator = new LinterRuleOptionsValidator();
  final AnalysisOptionsProvider optionsProvider = new AnalysisOptionsProvider();

  RecordingErrorListener recorder;
  ErrorReporter reporter;

  List<AnalysisError> get errors => recorder.errors;

  setUp() {
    registerLintRules();
    recorder = new RecordingErrorListener();
    reporter = new ErrorReporter(recorder, new _TestSource());
  }

  test_linter_defined_rules() {
    validate('''
linter:
  rules:
    - camel_case_types
    ''', []);
  }

  test_linter_no_rules() {
    validate('''
linter:
  rules:
    ''', []);
  }

  test_linter_null_rule() {
    validate('''
linter:
  rules:
    -

    ''', []);
  }

  test_linter_undefined_rule() {
    validate('''
linter:
  rules:
    - undefined
    ''', [UNDEFINED_LINT_WARNING]);
  }

  validate(String source, List<ErrorCode> expected) {
    var options = optionsProvider.getOptionsFromString(source);
    validator.validate(reporter, options);
    expect(errors.map((AnalysisError e) => e.errorCode),
        unorderedEquals(expected));
  }
}

class _TestSource implements Source {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

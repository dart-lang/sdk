// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LinterRuleOptionsValidatorTest);
  });
}

@reflectiveTest
class LinterRuleOptionsValidatorTest with ResourceProviderMixin {
  late RecordingDiagnosticListener recorder;
  late SourceFactory sourceFactory;
  late DiagnosticReporter reporter;

  List<Diagnostic> get diagnostics => recorder.diagnostics;

  LinterRuleOptionsValidator get validator => LinterRuleOptionsValidator(
    optionsProvider: AnalysisOptionsProvider(SourceFactoryImpl([])),
    resourceProvider: resourceProvider,
    sourceFactory: sourceFactory,
  );

  void setUp() {
    registerLintRules();
    sourceFactory = SourceFactory([ResourceUriResolver(resourceProvider)]);
    recorder = RecordingDiagnosticListener();
    reporter = DiagnosticReporter(recorder, _TestSource());
  }

  void test_linter_defined_rules() {
    validate('''
linter:
  rules:
    - camel_case_types
    ''', []);
  }

  void test_linter_no_rules() {
    validate('''
linter:
  rules:
    ''', []);
  }

  void test_linter_null_rule() {
    validate('''
linter:
  rules:
    -

    ''', []);
  }

  void test_linter_undefined_rule() {
    validate(
      '''
linter:
  rules:
    - undefined
    ''',
      [diag.undefinedLint],
    );
  }

  void validate(String source, List<DiagnosticCode> expected) {
    var options = AnalysisOptionsProvider(
      SourceFactoryImpl([]),
    ).getOptionsFromString(source);
    validator.validate(reporter, options);
    expect(diagnostics.map((e) => e.diagnosticCode), unorderedEquals(expected));
  }
}

class _TestSource implements Source {
  @override
  String get fullName => '/package/lib/test.dart';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

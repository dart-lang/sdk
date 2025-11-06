// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionsProviderTest);

    // TODO(srawlins): add tests for multiple includes.
    // TODO(srawlins): add tests with duplicate legacy plugin names.
    // https://github.com/dart-lang/sdk/issues/50980
  });
}

class ErrorProcessorMatcher extends Matcher {
  final ErrorProcessor required;

  ErrorProcessorMatcher(this.required);

  @override
  Description describe(Description desc) => desc
    ..add("an ErrorProcessor setting ${required.code} to ${required.severity}");

  @override
  bool matches(dynamic o, Map<dynamic, dynamic> options) {
    return o is ErrorProcessor &&
        o.code.toUpperCase() == required.code.toUpperCase() &&
        o.severity == required.severity;
  }
}

@reflectiveTest
class OptionsProviderTest with ResourceProviderMixin, LintRegistrationMixin {
  late final SourceFactory sourceFactory;

  late final AnalysisOptionsProvider provider;

  String get optionsFilePath => '/analysis_options.yaml';

  void setUp() {
    sourceFactory = SourceFactory([ResourceUriResolver(resourceProvider)]);
    provider = AnalysisOptionsProvider(sourceFactory);
  }

  void tearDown() {
    unregisterLintRules();
  }

  test_chooseFirstLegacyPlugin() {
    newFile('/more_options.yaml', '''
analyzer:
  plugins:
    - plugin_ddd
    - plugin_ggg
    - plugin_aaa
''');
    newFile('/other_options.yaml', '''
include: more_options.yaml
analyzer:
  plugins:
    - plugin_eee
    - plugin_hhh
    - plugin_bbb
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
analyzer:
  plugins:
    - plugin_fff
    - plugin_iii
    - plugin_ccc
''');

    var options = _getOptionsObject('/');
    expect(options.enabledLegacyPluginNames, unorderedEquals(['plugin_ddd']));
  }

  test_include_analyzerErrorSeveritiesAreMerged() {
    newFile('/other_options.yaml', '''
analyzer:
  errors:
    toplevelerror: warning
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
analyzer:
  errors:
    lowlevelerror: warning
''');

    var options = _getOptionsObject('/');

    expect(
      options.errorProcessors,
      unorderedMatches([
        ErrorProcessorMatcher(
          ErrorProcessor('toplevelerror', DiagnosticSeverity.WARNING),
        ),
        ErrorProcessorMatcher(
          ErrorProcessor('lowlevelerror', DiagnosticSeverity.WARNING),
        ),
      ]),
    );
  }

  test_include_analyzerErrorSeveritiesAreMerged_chainOfIncludes() {
    newFile('/first_options.yaml', '''
analyzer:
  errors:
    error_1: error
''');
    newFile('/second_options.yaml', '''
include: first_options.yaml
analyzer:
  errors:
    error_2: warning
''');
    newFile(optionsFilePath, r'''
include: second_options.yaml
''');

    var options = _getOptionsObject('/');

    expect(
      options.errorProcessors,
      contains(
        ErrorProcessorMatcher(
          ErrorProcessor('error_1', DiagnosticSeverity.ERROR),
        ),
      ),
    );
  }

  test_include_analyzerErrorSeveritiesAreMerged_multipleIncludes() {
    newFile('/first_options.yaml', '''
analyzer:
  errors:
    error_1: error
''');
    newFile('/second_options.yaml', '''
analyzer:
  errors:
    error_2: warning
''');
    newFile(optionsFilePath, r'''
include:
  - first_options.yaml
  - second_options.yaml
''');

    var options = _getOptionsObject('/');

    expect(
      options.errorProcessors,
      unorderedMatches([
        ErrorProcessorMatcher(
          ErrorProcessor('error_1', DiagnosticSeverity.ERROR),
        ),
        ErrorProcessorMatcher(
          ErrorProcessor('error_2', DiagnosticSeverity.WARNING),
        ),
      ]),
    );
  }

  test_include_analyzerErrorSeveritiesAreMerged_outermostWins() {
    newFile('/other_options.yaml', '''
analyzer:
  errors:
    error_1: warning
    error_2: warning
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
analyzer:
  errors:
    error_1: ignore
''');

    var options = _getOptionsObject('/');

    expect(
      options.errorProcessors,
      unorderedMatches([
        // We want to explicitly state the expected severity.
        // ignore: avoid_redundant_argument_values
        ErrorProcessorMatcher(ErrorProcessor('error_1', null)),
        ErrorProcessorMatcher(
          ErrorProcessor('error_2', DiagnosticSeverity.WARNING),
        ),
      ]),
    );
  }

  test_include_analyzerErrorSeveritiesAreMerged_subsequentIncludeWins() {
    newFile('/first_options.yaml', '''
analyzer:
  errors:
    error_1: warning
    error_2: warning
''');
    newFile('/second_options.yaml', '''
analyzer:
  errors:
    error_1: ignore
    error_2: warning
''');
    newFile(optionsFilePath, r'''
include:
  - first_options.yaml
  - second_options.yaml
''');

    var options = _getOptionsObject('/');

    expect(
      options.errorProcessors,
      unorderedMatches([
        // We want to explicitly state the expected severity.
        // ignore: avoid_redundant_argument_values
        ErrorProcessorMatcher(ErrorProcessor('error_1', null)),
        ErrorProcessorMatcher(
          ErrorProcessor('error_2', DiagnosticSeverity.WARNING),
        ),
      ]),
    );
  }

  test_include_analyzerExcludeListsAreMerged() {
    newFile('/other_options.yaml', '''
analyzer:
  exclude:
    - toplevelexclude.dart
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
analyzer:
  exclude:
    - lowlevelexclude.dart
''');

    var options = _getOptionsObject('/');

    expect(
      options.excludePatterns,
      unorderedEquals(['toplevelexclude.dart', 'lowlevelexclude.dart']),
    );
  }

  test_include_analyzerLanguageModesAreMerged() {
    newFile('/other_options.yaml', '''
analyzer:
  language:
    strict-casts: true
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
analyzer:
  language:
    strict-inference: true
''');

    var options = _getOptionsObject('/');

    expect(options.strictCasts, true);
    expect(options.strictInference, true);
    expect(options.strictRawTypes, false);
  }

  test_include_legacyPluginCanBeIncluded() {
    newFile('/other_options.yaml', '''
analyzer:
  plugins:
    toplevelplugin:
      enabled: true
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
''');

    var options = _getOptionsObject('/');

    expect(
      options.enabledLegacyPluginNames,
      unorderedEquals(['toplevelplugin']),
    );
  }

  test_include_linterRulesAreMerged() {
    newFile('/other_options.yaml', '''
linter:
  rules:
    - top_level_lint
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
linter:
  rules:
    - low_level_lint
''');

    var lowLevelLint = TestRule.withName('low_level_lint');
    var topLevelLint = TestRule.withName('top_level_lint');
    registerLintRules([lowLevelLint, topLevelLint]);
    var options = _getOptionsObject('/');

    expect(options.lintRules, unorderedEquals([topLevelLint, lowLevelLint]));
  }

  test_include_linterRulesAreMerged_differentFormats() {
    newFile('/other_options.yaml', '''
linter:
  rules:
    top_level_lint: true
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
linter:
  rules:
    - low_level_lint
''');

    var lowLevelLint = TestRule.withName('low_level_lint');
    var topLevelLint = TestRule.withName('top_level_lint');
    registerLintRules([lowLevelLint, topLevelLint]);
    var options = _getOptionsObject('/');

    expect(options.lintRules, unorderedEquals([topLevelLint, lowLevelLint]));
  }

  test_include_linterRulesAreMerged_outermostWins() {
    newFile('/other_options.yaml', '''
linter:
  rules:
    - top_level_lint
''');
    newFile(optionsFilePath, r'''
include: other_options.yaml
linter:
  rules:
    top_level_lint: false
''');

    var topLevelLint = TestRule.withName('top_level_lint');
    registerLintRule(topLevelLint);
    var options = _getOptionsObject('/');

    expect(options.lintRules, isNot(contains(topLevelLint)));
  }

  test_include_plugins() {
    newFile('/project/analysis_options.yaml', '''
plugins:
  plugin_one:
    path: foo/bar
''');
    newFile('/project/foo/analysis_options.yaml', r'''
include: ../analysis_options.yaml
''');

    var options = _getOptionsObject('/project/foo') as AnalysisOptionsImpl;

    expect(options.pluginsOptions.configurations, hasLength(1));
    var pluginConfiguration = options.pluginsOptions.configurations.first;
    expect(
      pluginConfiguration.source,
      isA<PathPluginSource>().having(
        (e) => e.toYaml(name: 'plugin_one'),
        'toYaml',
        '''
  plugin_one:
    path: ${convertPath('/project/foo/bar')}
''',
      ),
    );
  }

  AnalysisOptions _getOptionsObject(String filePath) =>
      AnalysisOptionsImpl.fromYaml(
        optionsMap: provider.getOptions(getFolder(filePath)),
        file: getFile(filePath),
      );
}

class TestRule extends LintRule {
  static const LintCode code = LintCode(
    'fantastic_test_rule',
    'Fantastic test rule.',
    correctionMessage: 'Try fantastic test rule.',
  );

  TestRule() : super(name: 'fantastic_test_rule', description: '');

  TestRule.withName(String name) : super(name: name, description: '');

  @override
  DiagnosticCode get diagnosticCode => code;
}

// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:collection/collection.dart';
import 'package:linter/src/rules.dart' as linter_rules;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsFromYamlTest);
    defineReflectiveTests(AnalysisOptionsMergedYamlTest);
    defineReflectiveTests(AnalysisOptionsEffectiveOptionsTest);

    // TODO(srawlins): add tests for multiple includes.
    // TODO(srawlins): add tests with duplicate legacy plugin names.
    // https://github.com/dart-lang/sdk/issues/50980
  });

  group('AnalysisOptionsMergedYaml', () {
    void expectMergesTo(String defaults, String overrides, String expected) {
      var optionsProvider = AnalysisOptionsProvider(SourceFactoryImpl([]));
      var defaultOptions = optionsProvider.getOptionsFromString(defaults);
      var overrideOptions = optionsProvider.getOptionsFromString(overrides);
      var merged = optionsProvider.merge(defaultOptions, overrideOptions);
      expectEquals(merged, optionsProvider.getOptionsFromString(expected));
    }

    group('merging', () {
      test('integration', () {
        expectMergesTo(
          '''
analyzer:
  plugins:
    - p1
    - p2
  errors:
    unused_local_variable : error
linter:
  rules:
    - camel_case_types
    - one_member_abstracts
''',
          '''
analyzer:
  plugins:
    - p3
  errors:
    unused_local_variable : ignore # overrides error
linter:
  rules:
    one_member_abstracts: false # promotes and disables
    always_specify_return_types: true
''',
          '''
analyzer:
  plugins:
    - p1
    - p2
    - p3
  errors:
    unused_local_variable : ignore
linter:
  rules:
    camel_case_types: true
    one_member_abstracts: false
    always_specify_return_types: true
''',
        );
      });
    });
  });

  group('AnalysisOptionsMergedYaml', () {
    test('test_bad_yaml (1)', () {
      var src = '''
    analyzer: # <= bang
strong-mode: true
''';

      var optionsProvider = AnalysisOptionsProvider(SourceFactoryImpl([]));
      expect(
        () => optionsProvider.getOptionsFromString(src),
        throwsA(TypeMatcher<OptionsFormatException>()),
      );
    });

    test('test_bad_yaml (2)', () {
      var src = '''
analyzer:
  strong-mode:true # missing space (sdk/issues/24885)
''';

      var optionsProvider = AnalysisOptionsProvider(SourceFactoryImpl([]));
      // Should not throw an exception.
      var options = optionsProvider.getOptionsFromString(src);
      // Should return a non-null options list.
      expect(options, isNotNull);
    });
  });
}

bool containsKey(Map<Object, YamlNode> map, Object key) =>
    _getValue(map, key) != null;

void expectEquals(YamlNode? actual, YamlNode? expected) {
  if (expected is YamlScalar) {
    actual!;
    expect(actual, TypeMatcher<YamlScalar>());
    expect(expected.value, actual.value);
  } else if (expected is YamlList) {
    if (actual is YamlList) {
      expect(actual.length, expected.length);
      List<YamlNode> expectedNodes = expected.nodes;
      List<YamlNode> actualNodes = actual.nodes;
      for (int i = 0; i < expectedNodes.length; i++) {
        expectEquals(actualNodes[i], expectedNodes[i]);
      }
    } else {
      fail('Expected a YamlList, found ${actual.runtimeType}');
    }
  } else if (expected is YamlMap) {
    if (actual is YamlMap) {
      expect(actual.length, expected.length);
      var expectedNodes = expected.nodes.cast<Object, YamlNode>();
      var actualNodes = actual.nodes.cast<Object, YamlNode>();
      for (var expectedKey in expectedNodes.keys) {
        if (!containsKey(actualNodes, expectedKey)) {
          fail('Missing key $expectedKey');
        }
      }
      for (var actualKey in actualNodes.keys) {
        if (!containsKey(expectedNodes, actualKey)) {
          fail('Extra key $actualKey');
        }
      }
      for (var expectedKey in expectedNodes.keys) {
        expectEquals(
          _getValue(actualNodes, expectedKey),
          _getValue(expectedNodes, expectedKey),
        );
      }
    } else {
      fail('Expected a YamlMap, found ${actual.runtimeType}');
    }
  } else {
    fail('Unknown type of node: ${expected.runtimeType}');
  }
}

Object? valueOf(Object object) => object is YamlNode ? object.value : object;

YamlNode? _getValue(Map<Object, YamlNode?> map, Object key) {
  var keyValue = valueOf(key);
  for (var existingKey in map.keys) {
    if (valueOf(existingKey) == keyValue) {
      return map[existingKey];
    }
  }
  return null;
}

@reflectiveTest
class AnalysisOptionsEffectiveOptionsTest
    with ResourceProviderMixin, LintRegistrationMixin {
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

  AnalysisOptions _getOptionsObject(String folderPath) {
    var file = getFolder(folderPath).getFile(file_paths.analysisOptionsYaml);
    return AnalysisOptionsImpl.fromYaml(
      optionsMap: provider.getOptionsFromFile(file),
      file: getFile(folderPath),
    );
  }
}

@reflectiveTest
class AnalysisOptionsFromYamlTest with ResourceProviderMixin {
  final AnalysisOptionsProvider optionsProvider = AnalysisOptionsProvider(
    SourceFactoryImpl([]),
  );

  // TODO(srawlins): Add tests that exercise
  // `optionsProvider.getOptionsFromString` throwing an exception.
  AnalysisOptionsImpl parseOptions(String content) =>
      AnalysisOptionsImpl.fromYaml(
        optionsMap: optionsProvider.getOptionsFromString(content),
        file: getFile('/project/analysis_options.yaml'),
        resourceProvider: resourceProvider,
      );

  test_analyzer_cannotIgnore() {
    var analysisOptions = parseOptions('''
analyzer:
  cannot-ignore:
    - one_error_code
    - another
''');

    var unignorableCodeNames = analysisOptions.unignorableDiagnosticCodeNames;
    expect(
      unignorableCodeNames,
      unorderedEquals(['one_error_code', 'another']),
    );
  }

  test_analyzer_cannotIgnore_severity() {
    var analysisOptions = parseOptions('''
analyzer:
  cannot-ignore:
    - error
''');

    var unignorableCodeNames = analysisOptions.unignorableDiagnosticCodeNames;
    expect(unignorableCodeNames, contains('invalid_annotation'));
    expect(unignorableCodeNames.length, greaterThan(500));
  }

  test_analyzer_cannotIgnore_severity_withProcessor() {
    var analysisOptions = parseOptions('''
analyzer:
  errors:
    unused_import: error
  cannot-ignore:
    - error
''');

    var unignorableCodeNames = analysisOptions.unignorableDiagnosticCodeNames;
    expect(unignorableCodeNames, contains('unused_import'));
  }

  test_analyzer_cannotIgnore_severity_withProcessor_oldSeverity() {
    var analysisOptions = parseOptions('''
analyzer:
  errors:
    unused_import: error
  cannot-ignore:
    - warning
''');

    // Since `unused_import` has been reclassified as an error,
    // `cannot-ignore: - warning` should not apply to it.
    var unignorableCodeNames = analysisOptions.unignorableDiagnosticCodeNames;
    expect(unignorableCodeNames, isNot(contains('unused_import')));
  }

  test_analyzer_chromeos_checks() {
    var analysisOptions = parseOptions('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks
''');
    expect(analysisOptions.chromeOsManifestChecks, true);
  }

  test_analyzer_chromeos_checks_map() {
    var analysisOptions = parseOptions('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks : true
''');
    expect(analysisOptions.chromeOsManifestChecks, true);
  }

  test_analyzer_errors_cannotBeIgnoredByUniqueName() {
    var analysisOptions = parseOptions('''
analyzer:
  errors:
    return_type_invalid_for_catch_error: ignore
''');

    var processors = analysisOptions.errorProcessors;
    expect(processors, hasLength(1));

    var warning = Diagnostic.tmp(
      source: FileSource(newFile('/test.dart', '')),
      offset: 0,
      length: 1,
      diagnosticCode: diag.returnTypeInvalidForCatchError,
      arguments: [
        ['x'],
        ['y'],
      ],
    );

    var processor = processors.first;
    expect(processor.appliesTo(warning), isFalse);
  }

  test_analyzer_errors_severityIsError() {
    var analysisOptions = parseOptions('''
analyzer:
  errors:
    unused_local_variable: error
''');

    var processors = analysisOptions.errorProcessors;
    expect(processors, hasLength(1));

    var warning = Diagnostic.tmp(
      source: FileSource(newFile('/test.dart', '')),
      offset: 0,
      length: 1,
      diagnosticCode: diag.unusedLocalVariable,
      arguments: [
        ['x'],
      ],
    );

    var processor = processors.first;
    expect(processor.appliesTo(warning), isTrue);
    expect(processor.severity, DiagnosticSeverity.ERROR);
  }

  test_analyzer_errors_severityIsIgnore() {
    var analysisOptions = parseOptions('''
analyzer:
  errors:
    invalid_assignment: ignore
''');

    var processors = analysisOptions.errorProcessors;
    expect(processors, hasLength(1));

    var error = Diagnostic.tmp(
      source: FileSource(newFile('/test.dart', '')),
      offset: 0,
      length: 1,
      diagnosticCode: diag.invalidAssignment,
      arguments: [
        ['x'],
        ['y'],
      ],
    );

    var processor = processors.first;
    expect(processor.appliesTo(error), isTrue);
    expect(processor.severity, isNull);
  }

  test_analyzer_errors_sharedNameAppliesToAllSharedCodes() {
    var analysisOptions = parseOptions('''
analyzer:
  errors:
    invalid_return_type_for_catch_error: ignore
''');

    var processors = analysisOptions.errorProcessors;
    expect(processors, hasLength(1));

    var warning = Diagnostic.tmp(
      source: FileSource(newFile('/test.dart', '')),
      offset: 0,
      length: 1,
      diagnosticCode: diag.returnTypeInvalidForCatchError,
      arguments: [
        ['x'],
        ['y'],
      ],
    );

    var processor = processors.first;
    expect(processor.appliesTo(warning), isTrue);
    expect(processor.severity, isNull);
  }

  test_analyzer_exclude() {
    var analysisOptions = parseOptions('''
analyzer:
  exclude:
    - foo/bar.dart
    - 'test/**'
''');

    var excludes = analysisOptions.excludePatterns;
    expect(excludes, unorderedEquals(['foo/bar.dart', 'test/**']));
  }

  test_analyzer_exclude_withNonStrings() {
    var analysisOptions = parseOptions('''
analyzer:
  exclude:
    - foo/bar.dart
    - 'test/**'
    - a: b
''');

    var excludes = analysisOptions.excludePatterns;
    expect(excludes, unorderedEquals(['foo/bar.dart', 'test/**']));
  }

  test_analyzer_legacyPlugins_list() {
    // TODO(srawlins): Test legacy plugins as a list of non-scalar values
    // (`- angular2: yes`).
    var analysisOptions = parseOptions('''
analyzer:
  plugins:
    - angular2
    - intl
''');

    var names = analysisOptions.enabledLegacyPluginNames;
    expect(names, ['angular2']);
  }

  test_analyzer_legacyPlugins_map() {
    // TODO(srawlins): Test legacy plugins as a map of scalar values
    // (`angular2: yes`).
    var analysisOptions = parseOptions('''
analyzer:
  plugins:
    angular2:
      enabled: true
''');

    var names = analysisOptions.enabledLegacyPluginNames;
    expect(names, ['angular2']);
  }

  test_analyzer_legacyPlugins_string() {
    var analysisOptions = parseOptions('''
analyzer:
  plugins:
    angular2
''');

    var names = analysisOptions.enabledLegacyPluginNames;
    expect(names, ['angular2']);
  }

  test_analyzer_optionalChecks_propagateLinterExceptions_default() {
    var analysisOptions = parseOptions('''
analyzer:
  optional-checks:
''');
    expect(analysisOptions.propagateLinterExceptions, false);
  }

  test_analyzer_optionalChecks_propagateLinterExceptions_empty() {
    var analysisOptions = parseOptions('''
analyzer:
  optional-checks:
    propagate-linter-exceptions
''');
    expect(analysisOptions.propagateLinterExceptions, true);
  }

  test_analyzer_optionalChecks_propagateLinterExceptions_false() {
    var analysisOptions = parseOptions('''
analyzer:
  optional-checks:
    propagate-linter-exceptions: false
''');
    expect(analysisOptions.propagateLinterExceptions, false);
  }

  test_analyzer_optionalChecks_propagateLinterExceptions_true() {
    var analysisOptions = parseOptions('''
analyzer:
  optional-checks:
    propagate-linter-exceptions: true
''');
    expect(analysisOptions.propagateLinterExceptions, true);
  }

  test_codeStyle_format_false() {
    var analysisOptions = parseOptions('''
code-style:
  format: false
''');
    expect(analysisOptions.codeStyleOptions.useFormatter, false);
  }

  test_codeStyle_format_true() {
    var analysisOptions = parseOptions('''
code-style:
  format: true
''');
    expect(analysisOptions.codeStyleOptions.useFormatter, true);
  }

  test_plugins_dependency_overrides_git() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one: ^1.2.3
  dependency_overrides:
    some_package:
      git:
        url: https://github.com/dart-lang/some_package.git
        ref: main
''');

    var dependencyOverrides =
        analysisOptions.pluginsOptions.dependencyOverrides;
    expect(dependencyOverrides, isNotNull);
    expect(dependencyOverrides, hasLength(1));

    var packageOverride = dependencyOverrides!.entries.singleOrNull;
    expect(packageOverride, isNotNull);
    expect(packageOverride!.key, 'some_package');
    expect(
      packageOverride.value,
      isA<GitPluginSource>().having(
        (e) => e.toYaml(name: 'some_package'),
        'toYaml',
        '''
  some_package:
    git:
      url: https://github.com/dart-lang/some_package.git
      ref: main
''',
      ),
    );
  }

  test_plugins_dependency_overrides_relative() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one:
    path: foo/bar
  dependency_overrides:
    some_package1:
      path: ../some_package1
    some_package2:
      path: sub_folder/some_package2
''');

    var dependencyOverrides =
        analysisOptions.pluginsOptions.dependencyOverrides;
    expect(dependencyOverrides, isNotNull);
    expect(dependencyOverrides, hasLength(2));
    var package1 = dependencyOverrides!.entries.singleWhereOrNull(
      (entry) => entry.key == 'some_package1',
    );
    var package2 = dependencyOverrides.entries.singleWhereOrNull(
      (entry) => entry.key == 'some_package2',
    );
    expect(package1, isNotNull);
    expect(package1!.key, 'some_package1');
    expect(
      package1.value,
      isA<PathPluginSource>().having(
        (e) => e.toYaml(name: 'some_package1'),
        'toYaml',
        '''
  some_package1:
    path: ${convertPath('/some_package1')}
''',
      ),
    );
    expect(package2, isNotNull);
    expect(package2!.key, 'some_package2');
    expect(
      package2.value,
      isA<PathPluginSource>().having(
        (e) => e.toYaml(name: 'some_package2'),
        'toYaml',
        '''
  some_package2:
    path: ${convertPath('/project/sub_folder/some_package2')}
''',
      ),
    );
  }

  test_plugins_dependency_overrides_versionConstraintHosted() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one: ^1.2.3
  dependency_overrides:
    some_package1:
      version: ^3.2.1
      hosted: https://example.com/packages/
''');

    var dependencyOverrides =
        analysisOptions.pluginsOptions.dependencyOverrides;
    expect(dependencyOverrides, isNotNull);
    expect(dependencyOverrides, hasLength(1));

    var packageOverride = dependencyOverrides!.entries.singleOrNull;
    expect(packageOverride, isNotNull);
    expect(packageOverride!.key, 'some_package1');
    expect(
      packageOverride.value,
      isA<VersionedPluginSource>().having(
        (e) => e.toYaml(name: 'some_package1'),
        'toYaml',
        '''
  some_package1:
    version: ^3.2.1
    hosted: https://example.com/packages/
''',
      ),
    );
  }

  test_plugins_gitConstraint() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one:
    git: https://github.com/dart-lang/plugin_one.git
''');

    var configuration = analysisOptions.pluginConfigurations.single;
    expect(configuration.isEnabled, isTrue);
    expect(configuration.name, 'plugin_one');
    expect(
      configuration.source,
      isA<GitPluginSource>().having(
        (e) => e.toYaml(name: 'plugin_one'),
        'toYaml',
        '''
  plugin_one:
    git:
      url: https://github.com/dart-lang/plugin_one.git
''',
      ),
    );
  }

  test_plugins_gitConstraint_full() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one:
    git:
      url: https://github.com/dart-lang/sdk.git
      ref: main
      path: pkg/plugin_one
      tag_pattern: 'v*'
''');

    var configuration = analysisOptions.pluginConfigurations.single;
    expect(configuration.isEnabled, isTrue);
    expect(configuration.name, 'plugin_one');
    expect(
      configuration.source,
      isA<GitPluginSource>().having(
        (e) => e.toYaml(name: 'plugin_one'),
        'toYaml',
        '''
  plugin_one:
    git:
      url: https://github.com/dart-lang/sdk.git
      ref: main
      path: pkg/plugin_one
      tag_pattern: v*
''',
      ),
    );
  }

  test_plugins_gitConstraint_scalar() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one:
    git: https://github.com/dart-lang/plugin_one.git
''');

    var configuration = analysisOptions.pluginConfigurations.single;
    expect(configuration.isEnabled, isTrue);
    expect(configuration.name, 'plugin_one');
    expect(
      configuration.source,
      isA<GitPluginSource>().having(
        (e) => e.toYaml(name: 'plugin_one'),
        'toYaml',
        '''
  plugin_one:
    git:
      url: https://github.com/dart-lang/plugin_one.git
''',
      ),
    );
  }

  test_plugins_pathConstraint() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one:
    path: /foo/bar
''');

    var configuration = analysisOptions.pluginConfigurations.single;
    expect(configuration.isEnabled, isTrue);
    expect(configuration.name, 'plugin_one');
    expect(
      configuration.source,
      isA<PathPluginSource>().having(
        (e) => e.toYaml(name: 'plugin_one'),
        'toYaml',
        '''
  plugin_one:
    path: /foo/bar
''',
      ),
    );
  }

  test_plugins_pathConstraint_relative() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one:
    path: foo/bar
''');

    var configuration = analysisOptions.pluginConfigurations.single;
    expect(configuration.isEnabled, isTrue);
    expect(configuration.name, 'plugin_one');
    expect(
      configuration.source,
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

  test_plugins_pathConstraint_relativeNonNormal() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one:
    path: .././foo/bar/../baz
''');

    var configuration = analysisOptions.pluginConfigurations.single;
    expect(configuration.isEnabled, isTrue);
    expect(configuration.name, 'plugin_one');
    expect(
      configuration.source,
      isA<PathPluginSource>().having(
        (e) => e.toYaml(name: 'plugin_one'),
        'toYaml',
        '''
  plugin_one:
    path: ${convertPath('/foo/baz')}
''',
      ),
    );
  }

  test_plugins_scalarConstraint() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one: ^1.2.3
''');

    var configuration = analysisOptions.pluginConfigurations.single;
    expect(configuration.isEnabled, isTrue);
    expect(configuration.name, 'plugin_one');
    expect(
      configuration.source,
      isA<VersionedPluginSource>().having(
        (e) => e.toYaml(name: 'plugin_one'),
        'toYaml',
        '  plugin_one: ^1.2.3\n',
      ),
    );
  }

  test_plugins_versionConstraint() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one:
    version: ^1.2.3
''');

    var configuration = analysisOptions.pluginConfigurations.single;
    expect(configuration.isEnabled, isTrue);
    expect(configuration.name, 'plugin_one');
    expect(
      configuration.source,
      isA<VersionedPluginSource>().having(
        (e) => e.toYaml(name: 'plugin_one'),
        'toYaml',
        '  plugin_one: ^1.2.3\n',
      ),
    );
  }

  test_plugins_versionConstraintHosted() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one:
    version: ^1.2.3
    hosted: https://example.com/packages/
''');

    var configuration = analysisOptions.pluginConfigurations.single;
    expect(configuration.isEnabled, isTrue);
    expect(configuration.name, 'plugin_one');
    expect(
      configuration.source,
      isA<VersionedPluginSource>().having(
        (e) => e.toYaml(name: 'plugin_one'),
        'toYaml',
        '''
  plugin_one:
    version: ^1.2.3
    hosted: https://example.com/packages/
''',
      ),
    );
  }

  test_signature_differs_for_hosted_plugin() {
    var options = parseOptions('''
plugins:
  plugin_one:
    version: ^1.2.3
    hosted: https://example.com/packages/
''');
    var sig1 = options.signature;

    for (var i = 0; i < 10; i++) {
      var options2 = parseOptions('''
plugins:
  plugin_one: ^1.2.3
''');
      var sig2 = options2.signature;
      expect(sig1, isNot(sig2));
    }
  }

  test_signature_on_different_error_ordering() {
    var options = parseOptions('''
analyzer:
  errors:
    a: warning
    b: ignore
    c: ignore
''');
    var sig1 = options.signature;
    for (var i = 0; i < 10; i++) {
      var options2 = parseOptions('''
analyzer:
  errors:
    b: ignore
    a: warning
    c: ignore
''');
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }

  test_signature_on_different_lints_ordering() {
    linter_rules.registerLintRules();
    var knownRules = Registry.ruleRegistry.rules
        .map((rule) => "    - ${rule.name}")
        .toList(growable: false);
    var options = parseOptions('''
linter:
  rules:
${knownRules.reversed.join("\n")}
''');
    var sig1 = options.signature;
    for (var i = 0; i < 10; i++) {
      knownRules.shuffle();
      var options2 = parseOptions('''
linter:
  rules:
${knownRules.join("\n")}
''');
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }

  test_signature_on_different_plugin_ordering() {
    var options = parseOptions('''
plugins:
  plugin_one: ^1.2.3
  plugin_two: ^1.2.3
  plugin_three: ^1.2.3
''');
    var sig1 = options.signature;
    for (var i = 0; i < 10; i++) {
      var options2 = parseOptions('''
plugins:
  plugin_three: ^1.2.3
  plugin_one: ^1.2.3
  plugin_two: ^1.2.3
''');
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }

  test_signature_on_merge() {
    var sourceFactory = SourceFactory([ResourceUriResolver(resourceProvider)]);
    var optionsProvider = AnalysisOptionsProvider(sourceFactory);
    var otherOptions = resourceProvider.getFile(
      convertPath("/project/analysis_options_helper.yaml"),
    );
    otherOptions.writeAsStringSync('''
analyzer:
  errors:
    a: warning
    b: ignore
    c: ignore
''');
    var mainOptions = resourceProvider.getFile(
      convertPath("/project/analysis_options.yaml"),
    );
    mainOptions.writeAsStringSync('''
include: analysis_options_helper.yaml
analyzer:
  errors:
    d: ignore
''');

    var options = AnalysisOptionsImpl.fromYaml(
      optionsMap: optionsProvider.getOptionsFromFile(mainOptions),
      file: mainOptions,
      resourceProvider: resourceProvider,
    );
    var sig1 = options.signature;
    for (var i = 0; i < 100; i++) {
      var options2 = AnalysisOptionsImpl.fromYaml(
        optionsMap: optionsProvider.getOptionsFromFile(mainOptions),
        file: mainOptions,
        resourceProvider: resourceProvider,
      );
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }
}

@reflectiveTest
class AnalysisOptionsMergedYamlTest with ResourceProviderMixin {
  String get analysisOptionsYaml => file_paths.analysisOptionsYaml;

  void test_getOptions_crawlUp_hasInFolder() {
    newFolder('/foo/bar');
    newFile('/foo/$analysisOptionsYaml', r'''
analyzer:
  ignore:
    - foo
''');
    newFile('/foo/bar/$analysisOptionsYaml', r'''
analyzer:
  ignore:
    - bar
''');
    YamlMap options = _getOptions('/foo/bar');
    expect(options, hasLength(1));
    {
      var analyzer = options.valueAt('analyzer') as YamlMap;
      expect(analyzer, isNotNull);
      expect(analyzer.valueAt('ignore'), unorderedEquals(['bar']));
    }
  }

  void test_getOptions_doesNotExist() {
    newFolder('/notFile');
    YamlMap options = _getOptions('/notFile');
    expect(options, isEmpty);
  }

  void test_getOptions_empty() {
    newFile('/$analysisOptionsYaml', r'''#empty''');
    YamlMap options = _getOptions('/');
    expect(options, isNotNull);
    expect(options, isEmpty);
  }

  void test_getOptions_include() {
    newFile('/foo.yaml', r'''
analyzer:
  ignore:
    - ignoreme.dart
    - 'sdk_ext/**'
''');
    newFile('/$analysisOptionsYaml', r'''
include: foo.yaml
''');
    var options = _getOptions('/');
    expect(options, hasLength(2));

    var analyzer = options.valueAt('analyzer') as YamlMap;
    expect(analyzer, hasLength(1));

    var ignore = analyzer.valueAt('ignore') as YamlList;
    expect(ignore, hasLength(2));
    expect(ignore[0], 'ignoreme.dart');
    expect(ignore[1], 'sdk_ext/**');
  }

  void test_getOptions_include_emptyLints() {
    newFile('/foo.yaml', r'''
linter:
  rules:
    - prefer_single_quotes
''');
    newFile('/$analysisOptionsYaml', r'''
include: foo.yaml
linter:
  rules:
    # avoid_print: false
''');
    var options = _getOptions('/');
    expect(options, hasLength(2));

    var linter = options.valueAt('linter') as YamlMap;
    expect(linter, hasLength(1));

    var rules = linter.valueAt('rules') as YamlList;
    expect(rules, hasLength(1));
    expect(rules[0], 'prefer_single_quotes');
  }

  void test_getOptions_include_missing() {
    newFile('/$analysisOptionsYaml', r'''
include: /foo.yaml
''');
    var options = _getOptions('/');
    expect(options, hasLength(1));
  }

  void test_getOptions_invalid() {
    newFile('/$analysisOptionsYaml', r''':''');
    var options = _getOptions('/');
    expect(options, hasLength(1));
  }

  void test_getOptions_simple() {
    newFile('/$analysisOptionsYaml', r'''
analyzer:
  ignore:
    - ignoreme.dart
    - 'sdk_ext/**'
''');
    var options = _getOptions('/');
    expect(options, hasLength(1));

    var analyzer = options.valueAt('analyzer') as YamlMap;
    expect(analyzer, hasLength(1));

    var ignore = analyzer.valueAt('ignore') as YamlList;
    expect(ignore, hasLength(2));
    expect(ignore[0], 'ignoreme.dart');
    expect(ignore[1], 'sdk_ext/**');
  }

  YamlMap _getOptions(String posixPath) {
    var folder = getFolder(posixPath);
    var file = folder.getFile(file_paths.analysisOptionsYaml);
    var sourceFactory = SourceFactory([ResourceUriResolver(resourceProvider)]);
    return AnalysisOptionsProvider(sourceFactory).getOptionsFromFile(file);
  }
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
        o.code == required.code &&
        o.severity == required.severity;
  }
}

class TestRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'fantastic_test_rule',
    'Fantastic test rule.',
    correctionMessage: 'Try fantastic test rule.',
    uniqueName: 'LintCode.fantastic_test_rule',
  );

  TestRule() : super(name: 'fantastic_test_rule', description: '');

  TestRule.withName(String name) : super(name: name, description: '');

  @override
  DiagnosticCode get diagnosticCode => code;
}

// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/apply_options.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ApplyOptionsTest);
    defineReflectiveTests(OptionsProviderTest);
  });
}

@reflectiveTest
class ApplyOptionsTest {
  final AnalysisOptionsImpl analysisOptions = AnalysisOptionsImpl();

  final AnalysisOptionsProvider optionsProvider = AnalysisOptionsProvider();

  void configureContext(String optionsSource) =>
      analysisOptions.applyOptions(parseOptions(optionsSource));

  // TODO(srawlins): Add tests that exercise
  // `optionsProvider.getOptionsFromString` throwing an exception.
  YamlMap parseOptions(String content) =>
      optionsProvider.getOptionsFromString(content);

  test_analyzer_cannotIgnore() {
    configureContext('''
analyzer:
  cannot-ignore:
    - one_error_code
    - another
''');

    var unignorableNames = analysisOptions.unignorableNames;
    expect(unignorableNames, unorderedEquals(['ONE_ERROR_CODE', 'ANOTHER']));
  }

  test_analyzer_cannotIgnore_severity() {
    configureContext('''
analyzer:
  cannot-ignore:
    - error
''');

    var unignorableNames = analysisOptions.unignorableNames;
    expect(unignorableNames, contains('INVALID_ANNOTATION'));
    expect(unignorableNames.length, greaterThan(500));
  }

  test_analyzer_cannotIgnore_severity_withProcessor() {
    configureContext('''
analyzer:
  errors:
    unused_import: error
  cannot-ignore:
    - error
''');

    var unignorableNames = analysisOptions.unignorableNames;
    expect(unignorableNames, contains('UNUSED_IMPORT'));
  }

  test_analyzer_chromeos_checks() {
    configureContext('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks
''');
    expect(analysisOptions.chromeOsManifestChecks, true);
  }

  test_analyzer_chromeos_checks_map() {
    configureContext('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks : true
''');
    expect(analysisOptions.chromeOsManifestChecks, true);
  }

  test_analyzer_errors_processors() {
    configureContext('''
analyzer:
  errors:
    invalid_assignment: ignore
    unused_local_variable: error
''');

    var processors = analysisOptions.errorProcessors;
    expect(processors, hasLength(2));

    var unusedLocal = AnalysisError.tmp(
      source: TestSource(),
      offset: 0,
      length: 1,
      errorCode: HintCode.UNUSED_LOCAL_VARIABLE,
      arguments: [
        ['x'],
      ],
    );
    var invalidAssignment = AnalysisError.tmp(
      source: TestSource(),
      offset: 0,
      length: 1,
      errorCode: CompileTimeErrorCode.INVALID_ASSIGNMENT,
      arguments: [
        ['x'],
        ['y'],
      ],
    );

    // ignore
    var invalidAssignmentProcessor =
        processors.firstWhere((p) => p.appliesTo(invalidAssignment));
    expect(invalidAssignmentProcessor.severity, isNull);

    // error
    var unusedLocalProcessor =
        processors.firstWhere((p) => p.appliesTo(unusedLocal));
    expect(unusedLocalProcessor.severity, ErrorSeverity.ERROR);
  }

  test_analyzer_exclude() {
    configureContext('''
analyzer:
  exclude:
    - foo/bar.dart
    - 'test/**'
''');

    var excludes = analysisOptions.excludePatterns;
    expect(excludes, unorderedEquals(['foo/bar.dart', 'test/**']));
  }

  test_analyzer_exclude_withNonStrings() {
    configureContext('''
analyzer:
  exclude:
    - foo/bar.dart
    - 'test/**'
    - a: b
''');

    var excludes = analysisOptions.excludePatterns;
    expect(excludes, unorderedEquals(['foo/bar.dart', 'test/**']));
  }

  test_analyzer_plugins_list() {
    // TODO(srawlins): Test plugins as a list of non-scalar values
    // (`- angular2: yes`).
    configureContext('''
analyzer:
  plugins:
    - angular2
    - intl
''');

    var names = analysisOptions.enabledPluginNames;
    expect(names, ['angular2']);
  }

  test_analyzer_plugins_map() {
    // TODO(srawlins): Test plugins as a map of scalar values (`angular2: yes`).
    configureContext('''
analyzer:
  plugins:
    angular2:
      enabled: true
''');

    var names = analysisOptions.enabledPluginNames;
    expect(names, ['angular2']);
  }

  test_analyzer_plugins_string() {
    configureContext('''
analyzer:
  plugins:
    angular2
''');

    var names = analysisOptions.enabledPluginNames;
    expect(names, ['angular2']);
  }

  test_codeStyle_format_false() {
    configureContext('''
code-style:
  format: false
''');
    expect(analysisOptions.codeStyleOptions.useFormatter, false);
  }

  test_codeStyle_format_true() {
    configureContext('''
code-style:
  format: true
''');
    expect(analysisOptions.codeStyleOptions.useFormatter, true);
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
        o.code.toUpperCase() == required.code.toUpperCase() &&
        o.severity == required.severity;
  }
}

@reflectiveTest
class OptionsProviderTest with ResourceProviderMixin {
  late final SourceFactory sourceFactory;

  late final AnalysisOptionsProvider provider;

  String get optionsFilePath => '/analysis_options.yaml';

  void setUp() {
    sourceFactory = SourceFactory([ResourceUriResolver(resourceProvider)]);
    provider = AnalysisOptionsProvider(sourceFactory);
  }

  test_chooseFirstPlugin() {
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

    final options = _getOptionsObject('/');
    expect(options.enabledPluginNames, unorderedEquals(['plugin_ddd']));
  }

  test_mergeIncludedOptions() {
    // TODO(srawlins): Split this into smaller tests.
    // TODO(srawlins): add tests for multiple includes.
    // TODO(https://github.com/dart-lang/sdk/issues/50980): add tests with
    // duplicate plugin names.

    newFile('/other_options.yaml', '''
analyzer:
  exclude:
    - toplevelexclude.dart
  plugins:
    toplevelplugin:
      enabled: true
  errors:
    toplevelerror: warning
linter:
  rules:
    - toplevellint
''');
    String code = r'''
include: other_options.yaml
analyzer:
  exclude:
    - lowlevelexclude.dart
  errors:
    lowlevelerror: warning
linter:
  rules:
    - lowlevellint
''';
    newFile(optionsFilePath, code);

    final lowlevellint = TestRule.withName('lowlevellint');
    final toplevellint = TestRule.withName('toplevellint');
    Registry.ruleRegistry.register(lowlevellint);
    Registry.ruleRegistry.register(toplevellint);
    final options = _getOptionsObject('/');

    expect(options.lintRules, unorderedEquals([toplevellint, lowlevellint]));
    expect(options.enabledPluginNames, unorderedEquals(['toplevelplugin']));
    expect(options.excludePatterns,
        unorderedEquals(['toplevelexclude.dart', 'lowlevelexclude.dart']));
    expect(
        options.errorProcessors,
        unorderedMatches([
          ErrorProcessorMatcher(
              ErrorProcessor('toplevelerror', ErrorSeverity.WARNING)),
          ErrorProcessorMatcher(
              ErrorProcessor('lowlevelerror', ErrorSeverity.WARNING))
        ]));
  }

  AnalysisOptions _getOptionsObject(String posixPath) {
    final map = provider.getOptions(getFolder(posixPath));
    return AnalysisOptionsImpl()..applyOptions(map);
  }
}

class TestRule extends LintRule {
  TestRule()
      : super(
          name: 'fantastic_test_rule',
          description: '',
          details: '',
          group: Group.style,
        );

  TestRule.withName(String name)
      : super(
          name: name,
          description: '',
          details: '',
          group: Group.style,
        );
}

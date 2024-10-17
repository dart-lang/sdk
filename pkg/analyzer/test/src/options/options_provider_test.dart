// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionsProviderTest);
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
class OptionsProviderTest with ResourceProviderMixin {
  late final SourceFactory sourceFactory;

  late final AnalysisOptionsProvider provider;

  String get optionsFilePath => '/analysis_options.yaml';

  void setUp() {
    sourceFactory = SourceFactory([ResourceUriResolver(resourceProvider)]);
    provider = AnalysisOptionsProvider(sourceFactory);
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

  test_mergeIncludedOptions() {
    // TODO(srawlins): Split this into smaller tests.
    // TODO(srawlins): add tests for multiple includes.
    // TODO(srawlins): add tests with duplicate legacy plugin names.
    // https://github.com/dart-lang/sdk/issues/50980

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

    var lowlevellint = TestRule.withName('lowlevellint');
    var toplevellint = TestRule.withName('toplevellint');
    Registry.ruleRegistry.register(lowlevellint);
    Registry.ruleRegistry.register(toplevellint);
    var options = _getOptionsObject('/');

    expect(options.lintRules, unorderedEquals([toplevellint, lowlevellint]));
    expect(
        options.enabledLegacyPluginNames, unorderedEquals(['toplevelplugin']));
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

  AnalysisOptions _getOptionsObject(String posixPath) =>
      AnalysisOptionsImpl.fromYaml(
          optionsMap: provider.getOptions(getFolder(posixPath)));
}

class TestRule extends LintRule {
  static const LintCode code = LintCode(
      'fantastic_test_rule', 'Fantastic test rule.',
      correctionMessage: 'Try fantastic test rule.');

  TestRule()
      : super(
          name: 'fantastic_test_rule',
          description: '',
        );

  TestRule.withName(String name)
      : super(
          name: name,
          description: '',
        );

  @override
  LintCode get lintCode => code;
}

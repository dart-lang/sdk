// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/config.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../util/yaml_test.dart';

main() {
  defineTests();
}

defineTests() {
  /// Process the given option [fileContents] and produce a corresponding
  /// [LintConfig]. Return `null` if [fileContents] is not a YAML map, or
  /// does not have the `linter` child map.
  Map<String, RuleConfig>? processAnalysisOptionsFile(String fileContents) {
    var yaml = loadYamlNode(fileContents);
    if (yaml is YamlMap) {
      return parseLinterSection(yaml);
    }
    return null;
  }

  // In the future, options might be marshaled in maps and passed to rules.
  //  acme:
  //    some_rule:
  //      some_option: # Note this nesting might be arbitrarily complex?
  //        - param1
  //        - param2

  group('lint config', () {
    group('rule', () {
      test('configs', () {
        var ruleConfigs = parseLinterSection(
          loadYamlNode('''
linter:
  # Unsupported sections here to check that no exceptions are thrown when
  # YAML includes unknown sections.
  files:
    include: foo # un-quoted
    exclude:
      - 'test/**'       # file globs can be scalars or lists
      - '**/_data.dart' # unquoted stars treated by YAML as aliases
  rules:
    style_guide:
      unnecessary_getters: false #disable
      camel_case_types: true #enable
    pub:
      package_names: false
''')
              as YamlMap,
        );
        expect(ruleConfigs, hasLength(3));
      });

      test('config', () {
        var ruleConfigs = parseLinterSection(
          loadYamlNode('''
linter:
  rules:
    style_guide:
      unnecessary_getters: false
''')
              as YamlMap,
        )!;
        expect(ruleConfigs, hasLength(1));
        var ruleConfig = ruleConfigs.values.first;
        expect(ruleConfig.group, 'style_guide');
        expect(ruleConfig.name, 'unnecessary_getters');
        expect(ruleConfig.isEnabled, isFalse);
        expect(ruleConfig.disables('unnecessary_getters'), isTrue);
      });
    });
  });

  group('analysis options', () {
    group('parsing', () {
      group('groups', () {
        test('basic', () {
          var src = '''
plugin_a:
  option_a: false
plugin_b:
  option_b: true
linter:
  rules:
    style_guide:
      unnecessary_getters: false #disable
      camel_case_types: true #enable
''';
          var ruleConfigs = processAnalysisOptionsFile(src)!;
          var ruleNames = ruleConfigs.values.map((rc) => rc.name);
          expect(ruleNames, hasLength(2));
          expect(ruleNames, contains('unnecessary_getters'));
          expect(ruleNames, contains('camel_case_types'));
        });
      });

      group('w/o groups', () {
        test('rule list', () {
          var src = '''
plugin_a:
  option_a: false
plugin_b:
  option_b: true
linter:
  rules:
    - camel_case_types
''';
          var ruleConfigs = processAnalysisOptionsFile(src)!;
          expect(ruleConfigs, hasLength(1));
          // Verify that defaults are enabled.
          expect(ruleConfigs.values.first.isEnabled, isTrue);
        });

        test('rule map (bools)', () {
          var src = '''
plugin_a:
  option_a: false
plugin_b:
  option_b: true
linter:
  rules:
    camel_case_types: true #enable
    unnecessary_getters: false #disable
''';
          var ruleConfigs = processAnalysisOptionsFile(src)!.values.toList();
          ruleConfigs.sort(
            (RuleConfig rc1, RuleConfig rc2) => rc1.name.compareTo(rc2.name),
          );
          expect(ruleConfigs, hasLength(2));
          expect(ruleConfigs[0].name, 'camel_case_types');
          expect(ruleConfigs[0].isEnabled, isTrue);
          expect(ruleConfigs[1].name, 'unnecessary_getters');
          expect(ruleConfigs[1].isEnabled, isFalse);
        });
      });
    });

    test('empty file', () {
      expect(processAnalysisOptionsFile(''), isNull);
    });

    test('bad format', () {
      expect(processAnalysisOptionsFile('foo: '), isNull);
    });
  });

  group('diagnostics section', () {
    group('rule with map config', () {
      test('map value is parsed as options', () {
        var ruleConfigs = parseDiagnosticsSection(
          loadYamlNode('''
my_rule:
  max_depth: 2
  some_flag: true
''')
              as YamlMap,
        );
        expect(ruleConfigs, hasLength(1));
        var config = ruleConfigs['my_rule'];
        expect(config?.name, 'my_rule');
        expect(config?.severity, ConfiguredSeverity.enable);
        expect(config?.isEnabled, isTrue);
        expect(config?.options, {'max_depth': 2, 'some_flag': true});
      });

      test('string option value', () {
        var ruleConfigs = parseDiagnosticsSection(
          loadYamlNode('''
my_rule:
  max_depth: 3
  pattern: "^_"
''')
              as YamlMap,
        );
        expect(ruleConfigs, hasLength(1));
        var config = ruleConfigs['my_rule'];
        expect(config?.severity, ConfiguredSeverity.enable);
        expect(config?.options, {'max_depth': 3, 'pattern': '^_'});
      });

      test('mixed scalar and map config styles', () {
        var ruleConfigs = parseDiagnosticsSection(
          loadYamlNode('''
simple_rule: true
configured_rule:
  threshold: 5
disabled_rule: false
severity_rule: warning
''')
              as YamlMap,
        );
        expect(ruleConfigs, hasLength(4));
        expect(ruleConfigs['simple_rule']?.isEnabled, isTrue);
        expect(ruleConfigs['simple_rule']?.options, isEmpty);
        expect(ruleConfigs['configured_rule']?.isEnabled, isTrue);
        expect(ruleConfigs['configured_rule']?.options, {'threshold': 5});
        expect(ruleConfigs['disabled_rule']?.isEnabled, isFalse);
        expect(
          ruleConfigs['severity_rule']?.severity,
          ConfiguredSeverity.warning,
        );
      });

      test('bool and string values have empty options', () {
        var ruleConfigs = parseDiagnosticsSection(
          loadYamlNode('''
rule_a: true
rule_b: error
''')
              as YamlMap,
        );
        expect(ruleConfigs['rule_a']?.options, isEmpty);
        expect(ruleConfigs['rule_b']?.options, isEmpty);
      });
    });
  });

  group('options processing', () {
    group('raw maps', () {
      Map<String, RuleConfig> parseMap(Map<Object, Object?> map) {
        return parseLinterSection(wrap(map) as YamlMap)!;
      }

      test('rule list', () {
        var options = <Object, Object?>{};
        var lintOptions = {
          'rules': ['camel_case_types'],
        };
        options['linter'] = lintOptions;

        var ruleConfigs = parseMap(options);
        expect(ruleConfigs, isNotNull);
        expect(ruleConfigs, hasLength(1));
      });

      test('rule map (bool)', () {
        var options = <Object, Object?>{};
        var lintOptions = {
          'rules': {'camel_case_types': true},
        };
        options['linter'] = lintOptions;

        var ruleConfigs = parseMap(options);
        expect(ruleConfigs, isNotNull);
        expect(ruleConfigs, hasLength(1));
      });

      test('nested rule map (bool)', () {
        var options = <Object, Object?>{};
        var lintOptions = {
          'rules': {
            'style_guide': {'camel_case_types': true},
          },
        };
        options['linter'] = lintOptions;

        var ruleConfigs = parseMap(options);
        expect(ruleConfigs, isNotNull);
        expect(ruleConfigs, hasLength(1));
      });

      test('nested rule map (string)', () {
        var options = <Object, Object?>{};
        var lintOptions = {
          'rules': {
            'style_guide': {'camel_case_types': true},
          },
        };
        options['linter'] = lintOptions;

        var ruleConfigs = parseMap(options);
        expect(ruleConfigs, isNotNull);
        expect(ruleConfigs, hasLength(1));
      });
    });
  });
}

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.config;

import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:yaml/yaml.dart';

/// Process the given option [fileContents] and produce a corresponding
/// [LintConfig].
LintConfig processAnalysisOptionsFile(String fileContents, {String fileUrl}) {
  var yaml = loadYamlNode(fileContents, sourceUrl: fileUrl);
  if (yaml is YamlMap) {
    return _parseConfig(yaml);
  }
  return null;
}

LintConfig _parseConfig(Map optionsMap) {
  if (optionsMap != null) {
    var options = optionsMap['linter'];
    // Quick check of basic contract.
    if (options is YamlMap) {
      return new _LintConfig().._parseYaml(options);
    }
  }
  return null;
}

/// Processes analysis options files and translates them into [LintConfig]s.
class AnalysisOptionsProcessor extends OptionsProcessor {
  Map<String, YamlNode> options;
  Exception exception;

  LintConfig createConfig() => _parseConfig(options);

  @override
  void onError(Exception exception) {
    this.exception = exception;
  }

  @override
  void optionsProcessed(
      AnalysisContext context, Map<String, YamlNode> options) {
    this.options = options;
  }
}

abstract class LintConfig {
  factory LintConfig.parse(String source, {String sourceUrl}) =>
      new _LintConfig().._parse(source, sourceUrl: sourceUrl);
  List<String> get fileExcludes;
  List<String> get fileIncludes;
  List<RuleConfig> get ruleConfigs;
}

abstract class RuleConfig {
  Map<String, dynamic> args;
  String get group;
  String get name;

  /// Provisional
  bool disables(String ruleName) =>
      ruleName == name && args['enabled'] == false;

  bool enables(String ruleName) => ruleName == name && args['enabled'] == true;
}

class _LintConfig implements LintConfig {
  final fileIncludes = <String>[];
  final fileExcludes = <String>[];
  final ruleConfigs = <RuleConfig>[];

  addAsListOrString(value, List<String> list) {
    if (value is YamlList) {
      value.forEach((v) => list.add(v));
    } else if (value is String) {
      list.add(value);
    }
  }

  String asString(scalar) {
    //TODO: add mis-format warnings
    if (scalar is String) {
      return scalar;
    }
    return null;
  }

  Object parseArgs(args) {
    //TODO: add mis-format warnings
    if (args is bool) {
      return {'enabled': args};
    }
    return null;
  }

  void _parse(String src, {String sourceUrl}) {
    var yaml = loadYamlNode(src, sourceUrl: sourceUrl);
    if (yaml is YamlMap) {
      _parseYaml(yaml);
    }
  }

  void _parseYaml(YamlMap yaml) {
    yaml.nodes.forEach((k, v) {
      //TODO: add mis-format warnings
      if (k is! YamlScalar) {
        return;
      }
      YamlScalar key = k;
      switch (key.toString()) {
        case 'files':
          if (v is YamlMap) {
            addAsListOrString(v['include'], fileIncludes);
            addAsListOrString(v['exclude'], fileExcludes);
          }
          break;

        case 'rules':

          // - unnecessary_getters
          // - camel_case_types
          if (v is List) {
            v.forEach((rule) {
              var config = new _RuleConfig();
              config.name = asString(rule);
              config.args = {'enabled': true};
              ruleConfigs.add(config);
            });
          }

          // style_guide: {unnecessary_getters: false, camel_case_types: true}
          if (v is YamlMap) {
            v.forEach((key, value) {
              //{unnecessary_getters: false}
              if (value is bool) {
                var config = new _RuleConfig();
                config.name = asString(key);
                config.args = {'enabled': value};
                ruleConfigs.add(config);
              }

              // style_guide: {unnecessary_getters: false, camel_case_types: true}
              if (value is YamlMap) {
                value.forEach((rule, args) {
                  // TODO: verify format
                  // unnecessary_getters: false
                  var config = new _RuleConfig();
                  config.group = key;
                  config.name = asString(rule);
                  config.args = parseArgs(args);
                  ruleConfigs.add(config);
                });
              }
            });
          }
          break;
      }
    });
  }
}

class _RuleConfig extends RuleConfig {
  String group;
  String name;
  var args = <String, dynamic>{};
}

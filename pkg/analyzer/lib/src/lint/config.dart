// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:yaml/yaml.dart';

/// Parses [optionsMap] into a [LintConfig], returning the config, or `null` if
/// [optionsMap] does not have `linter` map.
List<RuleConfig>? parseLintRuleConfigs(YamlMap optionsMap) {
  var options = optionsMap.valueAt('linter');
  // Quick check of basic contract.
  if (options is YamlMap) {
    var ruleConfigs = <RuleConfig>[];
    var rulesNode = options.valueAt(AnalyzerOptions.rules);
    if (rulesNode != null) {
      ruleConfigs.addAll(_ruleConfigs(rulesNode));
    }

    return ruleConfigs;
  }

  return null;
}

/// Returns [scalar] as a [bool], if it can be parsed as one.
bool? _asBool(YamlNode scalar) {
  var value = scalar is YamlScalar ? scalar.valueOrThrow : scalar;
  return switch (value) {
    bool() => value,
    'true' => true,
    'false' => false,
    _ => null,
  };
}

/// Returns [scalar] as a [String], if it can be parsed as one.
String? _asString(Object scalar) {
  var value = scalar is YamlScalar ? scalar.value : scalar;
  return value is String ? value : null;
}

Map<String, bool> _parseArgs(YamlNode args) {
  var enabled = _asBool(args);
  if (enabled != null) {
    return {'enabled': enabled};
  }
  return {};
}

/// Returns the [RuleConfig]s that are parsed from [value], which can be either
/// a YAML list or a YAML map.
List<RuleConfig> _ruleConfigs(YamlNode value) {
  // For example:
  //
  // ```yaml
  // - unnecessary_getters
  // - camel_case_types
  // ```
  if (value is YamlList) {
    return [
      for (var rule in value.nodes)
        RuleConfig(name: _asString(rule), args: {'enabled': true}),
    ];
  }

  // style_guide: {unnecessary_getters: false, camel_case_types: true}
  if (value is YamlMap) {
    var ruleConfigs = <RuleConfig>[];
    value.nodes.cast<Object, YamlNode>().forEach((key, value) {
      // For example: `{unnecessary_getters: false}`.
      var valueAsBool = _asBool(value);
      if (valueAsBool != null) {
        ruleConfigs.add(RuleConfig(
          name: _asString(key),
          args: {'enabled': valueAsBool},
        ));
      }

      // style_guide: {unnecessary_getters: false, camel_case_types: true}
      if (value is YamlMap) {
        value.nodes.cast<Object, YamlNode>().forEach((rule, args) {
          // TODO(brianwilkerson): verify format.
          // For example: `unnecessary_getters: false`.
          ruleConfigs.add(RuleConfig(
            name: _asString(rule),
            args: _parseArgs(args),
            group: _asString(key),
          ));
        });
      }
    });
    return ruleConfigs;
  }

  return const [];
}

/// The configuration of a single lint rule within an analysis options file.
class RuleConfig {
  final Map<String, bool> args;
  final String? group;
  final String? name;

  RuleConfig({required this.name, required this.args, this.group});

  /// Returns whether [ruleName] is disabled in this configuration.
  bool disables(String ruleName) =>
      ruleName == name && args['enabled'] == false;

  /// Returns whether [ruleName] is enabled in this configuration.
  bool enables(String ruleName) => ruleName == name && args['enabled'] == true;
}

// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/yaml.dart';
import 'package:yaml/yaml.dart';

/// Parses [optionsMap] into a [LintConfig], returning the config, or `null` if
/// [optionsMap] does not have `linter` map.
LintConfig? parseConfig(YamlMap optionsMap) {
  var options = optionsMap.valueAt('linter');
  // Quick check of basic contract.
  if (options is YamlMap) {
    return LintConfig.parseMap(options);
  }

  return null;
}

/// Process the given option [fileContents] and produce a corresponding
/// [LintConfig]. Return `null` if [fileContents] is not a YAML map, or
/// does not have the `linter` child map.
LintConfig? processAnalysisOptionsFile(String fileContents, {String? fileUrl}) {
  var yaml = loadYamlNode(fileContents,
      sourceUrl: fileUrl != null ? Uri.parse(fileUrl) : null);
  if (yaml is YamlMap) {
    return parseConfig(yaml);
  }
  return null;
}

/// The configuration of lint rules within an analysis options file.
class LintConfig {
  final List<String> fileIncludes;

  final List<String> fileExcludes;

  final List<RuleConfig> ruleConfigs;

  LintConfig(this.fileIncludes, this.fileExcludes, this.ruleConfigs);

  factory LintConfig.parse(String source, {String? sourceUrl}) {
    var yaml = loadYamlNode(source,
        sourceUrl: sourceUrl != null ? Uri.parse(sourceUrl) : null);
    if (yaml is! YamlMap) {
      throw StateError("Expected YAML at '$source' to be a Map, but is "
          '${yaml.runtimeType}.');
    }

    return LintConfig.parseMap(yaml);
  }

  factory LintConfig.parseMap(YamlMap yaml) {
    var fileIncludes = <String>[];
    var fileExcludes = <String>[];
    var ruleConfigs = <RuleConfig>[];

    yaml.nodes.forEach((key, value) {
      if (key is! YamlScalar) {
        return;
      }
      switch (key.toString()) {
        case 'files':
          if (value is YamlMap) {
            _addAsListOrString(value['include'], fileIncludes);
            _addAsListOrString(value['exclude'], fileExcludes);
          }

        case 'rules':
          ruleConfigs.addAll(_ruleConfigs(value));
      }
    });

    return LintConfig(fileIncludes, fileExcludes, ruleConfigs);
  }

  static void _addAsListOrString(Object? value, List<String> list) {
    if (value is List) {
      for (var entry in value) {
        list.add(entry as String);
      }
    } else if (value is String) {
      list.add(value);
    }
  }

  static bool? _asBool(YamlNode scalar) {
    var value = scalar is YamlScalar ? scalar.valueOrThrow : scalar;
    return switch (value) {
      bool() => value,
      'true' => true,
      'false' => false,
      _ => null,
    };
  }

  static String? _asString(Object scalar) {
    var value = scalar is YamlScalar ? scalar.value : scalar;
    return value is String ? value : null;
  }

  static Map<String, bool> _parseArgs(YamlNode args) {
    var enabled = _asBool(args);
    if (enabled != null) {
      return {'enabled': enabled};
    }
    return {};
  }

  static List<RuleConfig> _ruleConfigs(YamlNode value) {
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
}

/// The configuration of a single lint rule within an analysis options file.
class RuleConfig {
  final Map<String, bool> args;
  final String? group;
  final String? name;

  RuleConfig({required this.name, required this.args, this.group});

  bool disables(String ruleName) =>
      ruleName == name && args['enabled'] == false;

  bool enables(String ruleName) => ruleName == name && args['enabled'] == true;
}

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.config;

import 'package:yaml/yaml.dart';

abstract class LintConfig {
  factory LintConfig.parse(String source, {String sourceUrl}) =>
      new _LintConfig(source, sourceUrl: sourceUrl);
  List<String> get fileExcludes;
  List<String> get fileIncludes;
  List<RuleConfig> get ruleConfigs;
}

abstract class RuleConfig {
  Map<String, dynamic> args;
  String get group;
  String get name;
}

class _LintConfig implements LintConfig {
  final fileIncludes = <String>[];
  final fileExcludes = <String>[];
  final ruleConfigs = <RuleConfig>[];

  _LintConfig(String src, {String sourceUrl}) {
    _parse(src, sourceUrl: sourceUrl);
  }

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

  _parse(String src, {String sourceUrl}) {
    var yaml = loadYamlNode(src, sourceUrl: sourceUrl);
    if (yaml is! YamlMap) {
      return;
    }
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
          if (v is YamlMap) {
            v.forEach((group, rules) {
              // {unnecessary_getters: false, camel_case_types: true}
              if (rules is YamlMap) {
                rules.forEach((rule, args) {
                  // TODO: verify format
                  // unnecessary_getters: false
                  var config = new _RuleConfig();
                  config.group = group;
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

class _RuleConfig implements RuleConfig {
  String group;
  String name;
  var args = <String, dynamic>{};
}

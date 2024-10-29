// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/lint/state.dart';
import 'package:linter/src/rules.dart';
import 'package:yaml/yaml.dart';

import '../util/path_utils.dart';

/// Checks the 'example/all.yaml' file for correctness.
///
/// Prints any errors.
void main() {
  var errors = checkAllYaml();
  if (errors != null) {
    // ignore: avoid_print
    print(errors);
    exitCode = 1;
  }
}

/// Checks the 'example/all.yaml' file for correctness, returning a String if
/// there are errors, and `null` otherwise.
String? checkAllYaml() {
  var allYamlPath = pathRelativeToPackageRoot(['example', 'all.yaml']);
  var src = readFile(allYamlPath);

  var options = _getOptionsFromString(src);
  var linterSection = options['linter'] as YamlMap?;
  if (linterSection == null) {
    return "Error: '$allYamlPath' does not have a 'linter' section.";
  }

  var configuredRules = (linterSection['rules'] as YamlList?)?.cast<String>();
  if (configuredRules == null) {
    return "Error: '$allYamlPath' does not have a 'rules' section.";
  }

  var sortedRules = configuredRules.toList()..sort();

  for (var i = 0; i < configuredRules.length; i++) {
    if (configuredRules[i] != sortedRules[i]) {
      return "Error: Rules in '$allYamlPath' are not sorted alphabetically, "
          "starting at '${configuredRules[i]}'.";
    }
  }

  registerLintRules();

  var registeredRules = Registry.ruleRegistry
      .where((r) =>
          !r.state.isDeprecated && !r.state.isInternal && !r.state.isRemoved)
      .map((r) => r.name);

  var extraRules = <String>[];
  var missingRules = <String>[];

  for (var rule in configuredRules) {
    if (!registeredRules.contains(rule)) {
      extraRules.add(rule);
    }
  }
  for (var rule in registeredRules) {
    if (!configuredRules.contains(rule)) {
      missingRules.add(rule);
    }
  }

  if (extraRules.isEmpty && missingRules.isEmpty) {
    return null;
  }

  var errors = StringBuffer();
  if (extraRules.isNotEmpty) {
    errors.writeln('Found unknown (or deprecated/removed) rules:');
    for (var rule in extraRules) {
      errors.writeln('- $rule');
    }
  }
  if (missingRules.isNotEmpty) {
    errors.writeln('Missing rules:');
    for (var rule in missingRules) {
      errors.writeln('- $rule');
    }
  }
  return errors.toString();
}

/// Provides the options found in [optionsSource].
Map<String, YamlNode> _getOptionsFromString(String optionsSource) {
  var options = <String, YamlNode>{};
  var doc = loadYamlNode(optionsSource);

  // Empty options.
  if (doc is YamlScalar && doc.value == null) {
    return options;
  }
  if (doc is! YamlMap) {
    throw Exception(
        'Bad options file format (expected map, got ${doc.runtimeType})');
  }
  doc.nodes.forEach((k, YamlNode v) {
    if (k is! YamlScalar) {
      throw YamlException(
        'Bad options file format (expected YamlScalar key, got '
        "'${k.runtimeType}'",
        v.span,
      );
    }
    var key = k.value;
    if (key is! String) {
      throw YamlException(
        'Bad options file format (expected String key, got '
        "'${key.runtimeType})'",
        v.span,
      );
    }
    options[key] = v;
  });
  return options;
}

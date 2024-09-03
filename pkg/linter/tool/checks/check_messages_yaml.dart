// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/state.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';

import '../messages_data.dart';

/// Checks the 'messages.yaml' file for correctness.
///
/// Prints any errors.
void main() {
  var errors = checkMessagesYaml();
  if (errors != null) {
    // ignore: avoid_print
    print(errors);
    exitCode = 1;
  }
}

/// Checks the 'messages.yaml' file for correctness, returning a String if
/// there are errors, and `null` otherwise.
String? checkMessagesYaml() {
  var lintCodeSection = messagesYaml.lintCodes;

  var codeNames = [
    for (var codeName in lintCodeSection.keys) codeName as String,
  ];

  var sortedRules = codeNames.toList()..sort();

  for (var i = 0; i < codeNames.length; i++) {
    if (codeNames[i] != sortedRules[i]) {
      return "Error: Rules in 'messages.yaml' are not sorted alphabetically, "
          "starting at '${codeNames[i]}'.";
    }
  }

  registerLintRules();

  var registeredRules = Analyzer.facade.registeredRules.where((r) =>
      !r.state.isDeprecated && !r.state.isInternal && !r.state.isRemoved);

  var sharedCodeNames = <String>{};
  var extraRuleNames = <String>[];
  var missingRules = <String>[];

  lintCodeSection.forEach((codeName, data) {
    var name = codeName as String;
    data as Map;
    if (data.containsKey('sharedName')) {
      name = data['sharedName'] as String;
    }
    sharedCodeNames.add(name);
    if (data.containsKey('removedIn')) return;

    const knownUnregisteredRules = {'erase_dart_type_extension_types'};
    if (knownUnregisteredRules.contains(name)) return;

    if (!registeredRules.any((r) => r.name == name)) {
      extraRuleNames.add(codeName);
    }
  });
  for (var rule in registeredRules) {
    if (!sharedCodeNames.contains(rule.name)) {
      missingRules.add(rule.name);
    }
  }

  if (extraRuleNames.isEmpty && missingRules.isEmpty) {
    return null;
  }

  var errors = StringBuffer();
  if (extraRuleNames.isNotEmpty) {
    errors.writeln('Found unknown (or deprecated/removed) rules:');
    for (var rule in extraRuleNames) {
      errors.writeln('- $rule');
    }
  }
  if (missingRules.isNotEmpty) {
    errors.writeln('Missing rules:');
    for (var rule in missingRules) {
      errors.writeln('- $rule');
    }
  }

  const categoryNames = {
    'binarySize',
    'brevity',
    'documentationCommentMaintenance',
    'effectiveDart',
    'errorProne',
    'flutter',
    'languageFeatureUsage',
    'memoryLeaks',
    'nonPerformant',
    'pub',
    'publicInterface',
    'style',
    'unintentional',
    'unusedCode',
    'web',
  };
  messagesYaml.categoryMappings.forEach((codeName, categories) {
    if (categories.isEmpty) {
      errors.writeln("Missing 'categories' list for '$codeName'");
    }
    for (var category in categories) {
      if (!categoryNames.contains(category)) {
        errors.writeln("Invalid category for '$codeName': $category");
      }
    }
  });

  return errors.toString();
}

// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/analyzer_messages.dart';
import 'package:analyzer_utilities/located_error.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Decoded messages from the linter's `messages.yaml` file.
final List<LintMessage> lintMessages = decodeAnalyzerMessagesYaml(
  linterPkgPath,
  decodeMessage: LintMessage.new,
  package: AnalyzerDiagnosticPackage.linter,
);

enum LintCategory {
  binarySize,
  brevity,
  documentationCommentMaintenance,
  effectiveDart,
  errorProne,
  flutter,
  languageFeatureUsage,
  memoryLeaks,
  nonPerformant,
  pub,
  publicInterface,
  style,
  unintentional,
  unusedCode,
  web;

  static final Map<String, LintCategory> _stringToValue = {
    for (var value in values) value.name: value,
  };

  static LintCategory? fromString(String s) => _stringToValue[s];
}

class LintMessage extends AnalyzerMessage {
  final Set<LintCategory>? categories;

  final String? deprecatedDetails;

  final Map<LintStateName, Version>? state;

  LintMessage(
    super.messageYaml, {
    required super.analyzerCode,
    required super.package,
  }) : categories = messageYaml.get(
         'categories',
         decode: decodeCategories,
         ifAbsent: () => null,
       ),
       deprecatedDetails = messageYaml.getOptionalString('deprecatedDetails'),
       state = messageYaml.get(
         'state',
         decode: decodeState,
         ifAbsent: () => null,
       ),
       super.internal();

  static Set<LintCategory> decodeCategories(YamlNode node) {
    if (node is! YamlList) throw 'Must be a list';
    var categoryList = node.nodes.map(
      (element) =>
          LocatedError.wrap(() => decodeCategory(element), span: element.span),
    );
    var categorySet = categoryList.toSet();
    if (categorySet.length != categoryList.length) {
      throw 'Duplicate entries in category list';
    }
    return categorySet;
  }

  static LintCategory decodeCategory(YamlNode node) => switch (node) {
    YamlScalar(:String value) =>
      LintCategory.fromString(value) ?? (throw 'Unknown lint category'),
    _ => throw 'Must be a string',
  };

  static Map<LintStateName, Version> decodeState(YamlNode node) {
    if (node is! YamlMap) throw 'Must be a map';
    return {
      for (var entry in node.nodes.entries)
        LocatedError.wrap(
          () => decodeStateName(entry.key as YamlScalar),
          span: (entry.key as YamlScalar).span,
        ): LocatedError.wrap(
          () => decodeVersion(entry.value),
          span: entry.value.span,
        ),
    };
  }

  static LintStateName decodeStateName(YamlNode node) => switch (node) {
    YamlScalar(:String value) =>
      LintStateName.fromString(value) ?? (throw 'Unknown lint state name'),
    _ => throw 'Must be a string',
  };

  static Version decodeVersion(YamlNode node) => switch (node) {
    YamlScalar(:String value) => Version.parse('$value.0'),
    _ => throw 'Must be a string',
  };
}

enum LintStateName {
  experimental,
  stable,
  internal,
  deprecated,
  removed;

  static final Map<String, LintStateName> _stringToValue = {
    for (var value in values) value.name: value,
  };

  static LintStateName? fromString(String s) => _stringToValue[s];
}

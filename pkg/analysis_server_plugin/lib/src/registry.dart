// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analysis_server_plugin/src/correction/assist_generators.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analysis_server_plugin/src/correction/ignore_diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

final class PluginRegistryImpl implements PluginRegistry {
  final String pluginName;

  final List<AssistKind> assistKinds = [];

  final Map<FixKind, List<String>> fixKinds = {};

  final List<String> warningRules = [];

  final List<String> lintRules = [];

  PluginRegistryImpl(this.pluginName);

  @override
  void registerAssist(ProducerGenerator generator) {
    var producer = generator(context: StubCorrectionProducerContext.instance);
    var assistKind = producer.assistKind;
    if (assistKind == null) {
      throw ArgumentError.value(
        generator,
        'generator',
        "Assist producer '${producer.runtimeType}' must declare a non-null "
            "'assistKind'.",
      );
    }

    registeredAssistGenerators.registerGenerator(generator);
    assistKinds.add(assistKind);
  }

  @override
  void registerFixForRule(LintCode code, ProducerGenerator generator) {
    var producer = generator(context: StubCorrectionProducerContext.instance);
    var fixKind = producer.fixKind;
    if (fixKind == null) {
      throw ArgumentError.value(
        generator,
        'generator',
        "Fix producer '${producer.runtimeType}' must declare a non-null "
            "'fixKind'.",
      );
    }

    registeredFixGenerators.registerFixForLint(code, generator);
    fixKinds.putIfAbsent(fixKind, () => []).add(code.name);
  }

  @override
  void registerLintRule(AbstractAnalysisRule rule) {
    Registry.ruleRegistry.registerLintRule(rule);
    lintRules.add(rule.name);
  }

  @override
  void registerWarningRule(AbstractAnalysisRule rule) {
    Registry.ruleRegistry.registerWarningRule(rule);
    warningRules.add(rule.name);
  }

  /// Registers the "ignore diagnostic" producer generators.
  static void registerIgnoreProducerGenerators() {
    registeredFixGenerators.ignoreProducerGenerators.addAll([
      IgnoreDiagnosticOnLine.new,
      IgnoreDiagnosticInFile.new,
      IgnoreDiagnosticInAnalysisOptionsFile.new,
    ]);
  }
}

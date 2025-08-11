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

final class PluginRegistryImpl implements PluginRegistry {
  /// Returns currently registered rules.
  Iterable<AbstractAnalysisRule> get registeredRules => Registry.ruleRegistry;

  @override
  void registerAssist(ProducerGenerator generator) {
    var producer = generator(context: StubCorrectionProducerContext.instance);
    if (producer.assistKind == null) {
      throw ArgumentError.value(
        generator,
        'generator',
        "Assist producer '${producer.runtimeType}' must declare a non-null "
            "'assistKind'.",
      );
    }
    registeredAssistGenerators.registerGenerator(generator);
  }

  @override
  void registerFixForRule(LintCode code, ProducerGenerator generator) {
    var producer = generator(context: StubCorrectionProducerContext.instance);
    if (producer.fixKind == null) {
      throw ArgumentError.value(
        generator,
        'generator',
        "Fix producer '${producer.runtimeType}' must declare a non-null "
            "'fixKind'.",
      );
    }
    registeredFixGenerators.registerFixForLint(code, generator);
  }

  /// Registers the "ignore diagnostic" producer generators.
  void registerIgnoreProducerGenerators() {
    registeredFixGenerators.ignoreProducerGenerators.addAll([
      IgnoreDiagnosticOnLine.new,
      IgnoreDiagnosticInFile.new,
      IgnoreDiagnosticInAnalysisOptionsFile.new,
    ]);
  }

  @override
  void registerLintRule(AbstractAnalysisRule rule) {
    Registry.ruleRegistry.registerLintRule(rule);
  }

  @override
  void registerWarningRule(AbstractAnalysisRule rule) {
    Registry.ruleRegistry.registerWarningRule(rule);
  }

  AbstractAnalysisRule? ruleNamed(String name) => Registry.ruleRegistry[name];
}

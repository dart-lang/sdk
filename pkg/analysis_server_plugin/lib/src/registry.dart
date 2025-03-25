// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/registry.dart';
import 'package:analysis_server_plugin/src/correction/assist_generators.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analysis_server_plugin/src/correction/ignore_diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';

final class PluginRegistryImpl implements PluginRegistry {
  /// Returns currently registered lint rules.
  Iterable<AnalysisRule> get registeredRules => Registry.ruleRegistry;

  @override
  void registerAssist(ProducerGenerator generator) {
    registeredAssistGenerators.registerGenerator(generator);
  }

  @override
  void registerFixForRule(LintCode code, ProducerGenerator generator) {
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
  void registerLintRule(AnalysisRule rule) {
    Registry.ruleRegistry.registerLintRule(rule);
  }

  @override
  void registerWarningRule(AnalysisRule rule) {
    Registry.ruleRegistry.registerWarningRule(rule);
  }

  AnalysisRule? ruleNamed(String name) => Registry.ruleRegistry[name];
}

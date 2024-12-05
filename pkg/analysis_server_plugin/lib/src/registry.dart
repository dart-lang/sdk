// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/registry.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';

final class PluginRegistryImpl implements PluginRegistry {
  /// Returns currently registered lint rules.
  Iterable<LintRule> get registeredRules => Registry.ruleRegistry;

  @override
  void registerFixForRule(LintCode code, ProducerGenerator generator) {
    registeredFixGenerators.registerFixForLint(code, generator);
  }

  @override
  void registerRule(LintRule lint) {
    Registry.ruleRegistry.register(lint);
  }
}

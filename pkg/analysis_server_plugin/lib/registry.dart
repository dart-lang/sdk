// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/linter.dart';

abstract class PluginRegistry {
  void registerFixForRule(LintCode code, ProducerGenerator generator);

  /// Register this [rule] with the analyzer's rule registry.
  void registerLintRule(AnalysisRule rule);

  /// Register this [rule] with the analyzer's rule registry.
  void registerWarningRule(AnalysisRule rule);
}

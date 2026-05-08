// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/registry.dart';

abstract class PluginRegistry extends RegistryBase {
  /// Registers this assist [generator] with the analyzer's rule registry.
  void registerAssist(ProducerGenerator generator);

  /// Registers this fix [generator] for the given lint [code] with the
  /// analyzer's rule registry.
  void registerFixForRule(DiagnosticCode code, ProducerGenerator generator);
}

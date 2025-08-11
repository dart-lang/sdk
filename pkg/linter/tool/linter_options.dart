// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';

class LinterOptions {
  final Iterable<AbstractAnalysisRule> enabledRules;

  /// The path to the Dart SDK.
  final String? dartSdkPath;

  LinterOptions({
    Iterable<AbstractAnalysisRule>? enabledRules,
    this.dartSdkPath,
  }) : enabledRules = enabledRules ?? Registry.ruleRegistry;
}

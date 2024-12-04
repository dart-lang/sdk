// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: implementation_imports
import 'package:analyzer/src/lint/linter.dart';
// ignore: implementation_imports
import 'package:analyzer/src/lint/registry.dart';

class LinterOptions {
  final Iterable<LintRule> enabledRules;

  /// The path to the Dart SDK.
  String? dartSdkPath;

  /// Whether to gather timing data during analysis.
  bool enableTiming = false;

  LinterOptions({
    Iterable<LintRule>? enabledRules,
  }) : enabledRules = enabledRules ?? Registry.ruleRegistry;
}

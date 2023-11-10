// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/lint/registry.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/util/score_utils.dart' as score_utils;

// TODO(pq): reign in the nullable types

final _flutterOptionsUrl = Uri.https('raw.githubusercontent.com',
    '/flutter/packages/main/packages/flutter_lints/lib/flutter.yaml');
final _flutterRepoOptionsUrl = Uri.https(
    'raw.githubusercontent.com', '/flutter/flutter/main/analysis_options.yaml');

List<String>? _flutterRepoRules;
List<String>? _flutterRules;
Iterable<LintRule>? _registeredLints;

Future<List<String>> get flutterRepoRules async =>
    _flutterRepoRules ??= await score_utils.fetchRules(_flutterRepoOptionsUrl);

Future<List<String>> get flutterRules async =>
    _flutterRules ??= await score_utils.fetchRules(_flutterOptionsUrl);

Iterable<LintRule> get registeredLints {
  if (_registeredLints == null) {
    registerLintRules();
    _registeredLints = Registry.ruleRegistry;
  }
  return _registeredLints!;
}

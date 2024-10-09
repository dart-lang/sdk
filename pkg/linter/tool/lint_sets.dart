// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/lint/config.dart';
import 'package:http/http.dart' as http;
import 'package:linter/src/utils.dart';

Future<List<String>> get dartCoreLints =>
    _fetchRulesFromGitHub('/dart-lang/lints/blob/main/lib/core.yaml');

Future<List<String>> get dartRecommendedLints =>
    _fetchRulesFromGitHub('/dart-lang/lints/blob/main/lib/recommended.yaml');

Future<List<String>> get flutterRepoLints =>
    _fetchRulesFromGitHub('/flutter/flutter/main/analysis_options.yaml');

Future<List<String>> get flutterUserLints => _fetchRulesFromGitHub(
    '/flutter/packages/main/packages/flutter_lints/lib/flutter.yaml');

Future<List<String>> _fetchRulesFromGitHub(String optionsPath) async {
  var optionsUrl = Uri.https('raw.githubusercontent.com', optionsPath);
  var req = await http.get(optionsUrl);
  var config = processAnalysisOptionsFile(req.body);
  if (config == null) {
    printToConsole('No config found for: $optionsUrl (SKIPPED)');
    return [];
  }
  return config.ruleConfigs.map((r) => r.name).nonNulls.toList(growable: false);
}

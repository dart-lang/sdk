// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/config.dart';
import 'package:http/http.dart' as http;

const _flutterOptionsUrl =
    'https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/analysis_options_user.yaml';
const _flutterRepoOptionsUrl =
    'https://raw.githubusercontent.com/flutter/flutter/master/analysis_options.yaml';
const _pedanticOptionsUrl =
    'https://raw.githubusercontent.com/dart-lang/pedantic/master/lib/analysis_options.yaml';
const _stagehandOptionsUrl =
    'https://raw.githubusercontent.com/dart-lang/stagehand/master/templates/analysis_options.yaml';

List<String> _flutterRules;
List<String> _flutterRepoRules;
List<String> _pedanticRules;
List<String> _stagehandRules;

Future<List<String>> get flutterRules async =>
    _flutterRules ??= await _fetchRules(_flutterOptionsUrl);

Future<List<String>> get flutterRepoRules async =>
    _flutterRepoRules ??= await _fetchRules(_flutterRepoOptionsUrl);

Future<List<String>> get pedanticRules async =>
    _pedanticRules ??= await _fetchRules(_pedanticOptionsUrl);

Future<List<String>> get stagehandRules async =>
    _stagehandRules ??= await _fetchRules(_stagehandOptionsUrl);

Future<LintConfig> _fetchConfig(String url) async {
  var client = new http.Client();
  var req = await client.get(url);
  return processAnalysisOptionsFile(req.body);
}

Future<List<String>> _fetchRules(String optionsUrl) async {
  var config = await _fetchConfig(optionsUrl);
  var rules = <String>[];
  for (var ruleConfig in config.ruleConfigs) {
    rules.add(ruleConfig.name);
  }
  return rules;
}

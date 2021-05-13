// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/config.dart'; // ignore: implementation_imports
import 'package:http/http.dart' as http;

Future<List<String>> _readPedanticLints() async {
  var version = await pedanticLatestVersion;
  return _fetchLints(
      'https://raw.githubusercontent.com/dart-lang/pedantic/master/lib/analysis_options.$version.yaml');
}

Future<List<String>> _readCoreLints() async => _fetchLints(
    'https://raw.githubusercontent.com/dart-lang/lints/main/lib/core.yaml');

Future<String> get pedanticLatestVersion async {
  var url =
      'https://raw.githubusercontent.com/dart-lang/pedantic/master/lib/analysis_options.yaml';
  var client = http.Client();
  print('loading $url...');
  var req = await client.get(Uri.parse(url));
  var parts = req.body.split('package:pedantic/analysis_options.');
  return parts[1].split('.yaml')[0];
}

/// todo(pq): de-duplicate these fetches / URIs
Future<List<String>> _readFlutterLints() async => _fetchLints(
    'https://raw.githubusercontent.com/flutter/packages/master/packages/flutter_lints/lib/flutter.yaml');

Future<List<String>> _readRecommendedLints() async => _fetchLints(
    'https://raw.githubusercontent.com/dart-lang/lints/main/lib/recommended.yaml');

/// todo(pq): update `scorecard.dart` to reuse these fetch functions.
Future<List<String>> _fetchLints(String url) async {
  var client = http.Client();
  var req = await client.get(Uri.parse(url));
  return _readLints(req.body);
}

List<String> _readLints(String contents) {
  var lintConfigs = processAnalysisOptionsFile(contents);
  if (lintConfigs == null) {
    return [];
  }
  return lintConfigs.ruleConfigs.map((c) => c.name ?? '<unknown>').toList();
}

List<String>? _pedanticRules;
List<String>? _coreRules;
List<String>? _recommendedRules;
List<String>? _flutterRules;

Future<List<String>> get pedanticRules async =>
    _pedanticRules ??= await _readPedanticLints();

Future<List<String>> get coreRules async =>
    _coreRules ??= await _readCoreLints();

Future<List<String>> get recommendedRules async =>
    _recommendedRules ??= await _readRecommendedLints();

Future<List<String>> get flutterRules async =>
    _flutterRules ??= await _readFlutterLints();

Future<List<String>> fetchRules(Uri optionsUrl) async {
  var config = await _fetchConfig(optionsUrl);
  if (config == null) {
    print('no config found for: $optionsUrl (SKIPPED)');
    return <String>[];
  }
  var rules = <String>[];
  for (var ruleConfig in config.ruleConfigs) {
    var name = ruleConfig.name;
    if (name != null) {
      rules.add(name);
    }
  }
  return rules;
}

Future<LintConfig?> _fetchConfig(Uri url) async {
  print('loading $url...');
  var req = await http.get(url);
  return processAnalysisOptionsFile(req.body);
}

// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:http/http.dart' as http;
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:yaml/yaml.dart';

const _allPathSuffix = '/example/all.yaml';
const _repoPathPrefix = 'https://raw.githubusercontent.com/dart-lang/linter/';
const _rulePathPrefix = 'https://raw.githubusercontent.com/dart-lang/linter';

const _flutterOptionsUrl =
    'https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/analysis_options_user.yaml';
const _flutterRepoOptionsUrl =
    'https://raw.githubusercontent.com/flutter/flutter/master/analysis_options.yaml';
const _pedanticOptionsUrl =
    'https://raw.githubusercontent.com/dart-lang/pedantic/master/lib/analysis_options.yaml';
const _stagehandOptionsUrl =
    'https://raw.githubusercontent.com/dart-lang/stagehand/master/templates/analysis_options.yaml';

int _latestMinor;

Map<String, List<String>> _sinceMap = <String, List<String>>{};

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

Future<int> get latestMinor async =>
    _latestMinor ??= await _readLatestMinorVersion();

Iterable<LintRule> _registeredLints;

Iterable<LintRule> get registeredLints {
  if (_registeredLints == null) {
    registerLintRules();
    _registeredLints = Registry.ruleRegistry;
  }
  return _registeredLints;
}

Future<String> findSinceLinter(LintRule lint) async {
  // History recorded in `all.yaml` starts in minor 31.
  var rules_31 = await rulesForVersion(31);
  if (rules_31.contains(lint.name)) {
    var version = await _crawlForVersion(lint);
    if (version != null) {
      return version;
    }
  }

  var latest = await latestMinor;
  for (var minor = 31; minor <= latest; ++minor) {
    var rules = await rulesForVersion(minor);
    if (rules != null) {
      if (rules.contains(lint.name)) {
        return '0.1.$minor';
      }
    }
  }

  return null;
}

Future<int> _readLatestMinorVersion() async {
  var contents = await new File('pubspec.yaml').readAsString();
  YamlMap pubspec = loadYamlNode(contents);
  return int.parse(pubspec['version'].split('.').last);
}

Future<String> _crawlForVersion(LintRule lint) async {
  var client = new http.Client();
  for (int minor = 1; minor < 31; ++minor) {
    var version = '0.1.$minor';
    var req = await client
        .get('$_rulePathPrefix/$version/lib/src/rules/${lint.name}.dart');
    if (req.statusCode == 200) {
      return version;
    }
  }
  return null;
}

Future<List<String>> rulesForVersion(int minor) async {
  var version = '0.1.$minor';
  if (minor >= 31) {
    return _sinceMap[version] ??=
        await _fetchRules('$_repoPathPrefix$version$_allPathSuffix');
  }
  return null;
}

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

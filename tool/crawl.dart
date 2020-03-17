// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/registry.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/util/score_utils.dart' as score_utils;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

const _allPathSuffix = '/example/all.yaml';
const _effectiveDartOptionsRootUrl =
    'https://raw.githubusercontent.com/tenhobi/effective_dart/master/lib';
const _effectiveDartOptionsUrl =
    '$_effectiveDartOptionsRootUrl/analysis_options.yaml';

const _flutterOptionsUrl =
    'https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/analysis_options_user.yaml';
const _flutterRepoOptionsUrl =
    'https://raw.githubusercontent.com/flutter/flutter/master/analysis_options.yaml';
const _repoPathPrefix = 'https://raw.githubusercontent.com/dart-lang/linter/';
const _rulePathPrefix = 'https://raw.githubusercontent.com/dart-lang/linter';
const _stagehandOptionsUrl =
    'https://raw.githubusercontent.com/dart-lang/stagehand/master/templates/analysis_options.yaml';

/// We don't care about SDKs previous to this bottom.
final Version bottomDartSdk = Version(2, 0, 0);

Map<String, String> _dartSdkToLinterMap = <String, String>{};

List<String> _effectiveDartRules;
List<String> _flutterRepoRules;
List<String> _flutterRules;
int _latestMinor;

Iterable<LintRule> _registeredLints;

List<String> _sdkTags;

Map<String, List<String>> _sinceMap = <String, List<String>>{};

List<String> _stagehandRules;

Future<List<String>> get effectiveDartRules async =>
    _effectiveDartRules ??= await _fetchEffectiveDartRules();

Future<List<String>> get flutterRepoRules async =>
    _flutterRepoRules ??= await score_utils.fetchRules(_flutterRepoOptionsUrl);

Future<List<String>> get flutterRules async =>
    _flutterRules ??= await score_utils.fetchRules(_flutterOptionsUrl);

Future<int> get latestMinor async =>
    _latestMinor ??= await _readLatestMinorVersion();

Future<List<String>> get pedanticRules async => score_utils.pedanticRules;

Iterable<LintRule> get registeredLints {
  if (_registeredLints == null) {
    registerLintRules();
    _registeredLints = Registry.ruleRegistry;
  }
  return _registeredLints;
}

Future<List<String>> get sdkTags async => _sdkTags ??= await _fetchSdkTags();

Future<List<String>> get stagehandRules async =>
    _stagehandRules ??= await score_utils.fetchRules(_stagehandOptionsUrl);

Future<String> dartSdkForLinter(String version) async {
  var sdkVersions = <String>[];
  var sdks = await sdkTags;
  for (var sdk in sdks) {
    var linterVersion = await linterForDartSdk(sdk);
    if (linterVersion == version) {
      sdkVersions.add(sdk);
    }
  }

  sdkVersions.sort();
  return sdkVersions.isNotEmpty ? sdkVersions.first : null;
}

Future<List<String>> fetchRulesForVersion(String version) async =>
    score_utils.fetchRules('$_repoPathPrefix$version$_allPathSuffix');

Future<String> findSinceDartSdk(String linterVersion) async =>
    await dartSdkForLinter(linterVersion);

Future<String> findSinceLinter(String lint) async {
  // History recorded in `all.yaml` starts in minor 31.
  var rules_31 = await rulesForVersion(31);
  if (rules_31.contains(lint)) {
    var version = await _crawlForVersion(lint);
    if (version != null) {
      return version;
    }
  }

  var latest = await latestMinor;
  for (var minor = 31; minor <= latest; ++minor) {
    var rules = await rulesForVersion(minor);
    if (rules != null) {
      if (rules.contains(lint)) {
        return '0.1.$minor';
      }
    }
  }

  return null;
}

Future<String> linterForDartSdk(String sdk) async =>
    _dartSdkToLinterMap[sdk] ??= await _fetchLinterForVersion(sdk);

Future<List<String>> rulesForVersion(int minor) async {
  var version = '0.1.$minor';
  if (minor >= 31) {
    return _sinceMap[version] ??= await fetchRulesForVersion(version);
  }
  return null;
}

Future<String> _crawlForVersion(String lint) async {
  var client = http.Client();
  for (var minor = 1; minor < 31; ++minor) {
    var version = '0.1.$minor';
    var req =
        await client.get('$_rulePathPrefix/$version/lib/src/rules/$lint.dart');
    if (req.statusCode == 200) {
      return version;
    }
  }
  return null;
}

Future<String> _fetchDEPSforVersion(String version) async {
  var client = http.Client();
  //https://raw.githubusercontent.com/dart-lang/sdk/2.1.0-dev.1.0/DEPS
  var req = await client
      .get('https://raw.githubusercontent.com/dart-lang/sdk/$version/DEPS');
  return req.body;
}

Future<List<String>> _fetchEffectiveDartRules() async {
  var client = http.Client();
  var req = await client.get(_effectiveDartOptionsUrl);
  var includedOptions =
      req.body.split('include: package:effective_dart/')[1].trim();
  return score_utils
      .fetchRules('$_effectiveDartOptionsRootUrl/$includedOptions');
}

Future<String> _fetchLinterForVersion(String version) async {
  var deps = await _fetchDEPSforVersion(version);
  if (deps != null) {
    for (var line in deps.split('\n')) {
      if (line.trim().startsWith('"lint')) {
        // "linter_tag": "0.1.59",
        var split = line.trim().split('"linter_tag":');
        if (split.length == 2) {
          //  "0.1.59",
          return split[1].split('"')[1];
        }
      }
    }
  }
  return null;
}

Future<List<String>> _fetchSdkTags() {
  final github = GitHub();
  final slug = RepositorySlug('dart-lang', 'sdk');
  return github.repositories
      .listTags(slug)
      .map((t) => t.name)
      .where((t) {
        // Filter on numeric release tags.
        if (!t.startsWith(RegExp(r'\d+'))) {
          return false;
        }

        // Filter on bottom.
        try {
          var version = Version.parse(t);
          return version.compareTo(bottomDartSdk) >= 0;
        } on FormatException {
          return false;
        }
      })
      .toList()
      .catchError((e) {
        print('exception caught fetching SDK tags');
        print(e);
        print('(using cached SDK values)');
        return Future.value(<String>[]);
      });
}

Future<int> _readLatestMinorVersion() async {
  var contents = await File('pubspec.yaml').readAsString();
  final pubspec = loadYamlNode(contents) as YamlMap;
  // 0.1.79 or 0.1.79-dev or 0.1.97+1
  return int.parse((pubspec['version'] as String)
      .split('.')
      .last
      .split('-')
      .first
      .split('+')
      .first);
}

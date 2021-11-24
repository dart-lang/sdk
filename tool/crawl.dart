// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/lint/registry.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/util/score_utils.dart' as score_utils;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// todo (pq): reign in the nullable types

const _allPathSuffix = '/example/all.yaml';

/// We don't care about SDKs previous to this bottom.
final Version bottomDartSdk = Version(2, 0, 0);
Map<String, String?> _dartSdkToLinterMap = <String, String?>{};

final _flutterOptionsUrl = Uri.https('raw.githubusercontent.com',
    '/flutter/packages/master/packages/flutter_lints/lib/flutter.yaml');
final _flutterRepoOptionsUrl = Uri.https('raw.githubusercontent.com',
    '/flutter/flutter/master/analysis_options.yaml');

List<String>? _flutterRepoRules;

List<String>? _flutterRules;

int? _latestMinor;
Iterable<LintRule>? _registeredLints;
final _repoPathPrefix =
    Uri.https('raw.githubusercontent.com', '/dart-lang/linter/');

List<String>? _sdkTags;

Map<String, List<String?>> _sinceMap = <String, List<String>>{};

final _stagehandOptionsUrl = Uri.https('raw.githubusercontent.com',
    '/dart-lang/stagehand/master/templates/analysis_options.yaml');

List<String>? _stagehandRules;

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
  return _registeredLints!;
}

Future<List<String>> get stagehandRules async =>
    _stagehandRules ??= await score_utils.fetchRules(_stagehandOptionsUrl);

Future<String?> dartSdkForLinter(String version, Authentication? auth) async {
  var sdkVersions = <String>[];
  var sdks = await getSdkTags(auth);
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
    score_utils.fetchRules(_repoPathPrefix.resolve('$version$_allPathSuffix'));

Future<String?> findSinceDartSdk(String linterVersion,
        {Authentication? auth}) async =>
    await dartSdkForLinter(linterVersion, auth);

Future<String?> findSinceLinter(String lint, {Authentication? auth}) async {
  var latest = await latestMinor;
  for (var minor = 0; minor <= latest; ++minor) {
    var rules = await rulesForVersion(minor);
    if (rules != null) {
      if (rules.contains(lint)) {
        return '1.$minor';
      }
    }
  }

  return null;
}

Future<List<String>> getSdkTags(Authentication? auth) async =>
    _sdkTags ??= await _fetchSdkTags(auth);

Future<String?> linterForDartSdk(String sdk) async =>
    _dartSdkToLinterMap[sdk] ??= await _fetchLinterForVersion(sdk);

Future<List<String?>?> rulesForVersion(int minor) async {
  var version = '1.$minor.0';
  var rules = await fetchRulesForVersion(version);
  return _sinceMap[version] ??= rules;
}

Future<String> _fetchDEPSforVersion(String version) async {
  var client = http.Client();
  //https://raw.githubusercontent.com/dart-lang/sdk/2.1.0-dev.1.0/DEPS
  var req = await client.get(
      Uri.https('raw.githubusercontent.com', '/dart-lang/sdk/$version/DEPS'));
  return req.body;
}

Future<String?> _fetchLinterForVersion(String version) async {
  var deps = await _fetchDEPSforVersion(version);
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
  return null;
}

Future<List<String>> _fetchSdkTags(Authentication? auth) async {
  var github = GitHub(auth: auth);
  var slug = RepositorySlug('dart-lang', 'sdk');

  print('list repository tags: $slug');
  print('authentication:  ${auth != null ? "(token)" : "(anonymous)"}');

  var tags = await github.repositories
      .listTags(slug)
      .map((t) => t.name)
      .toList()
      .catchError((e) {
    print('exception caught fetching SDK tags');
    print(e);
    print('(using cached SDK values)');
    return Future.value(<String>[]);
  });

  return tags.whereType<String>().where((t) {
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
  }).toList();
}

Future<int> _readLatestMinorVersion() async {
  var contents = await File('pubspec.yaml').readAsString();
  var pubspec = loadYamlNode(contents) as YamlMap;
  var version = pubspec['version'] as String;
  // 1.15.0
  return int.parse(version.split('.')[1]);
}

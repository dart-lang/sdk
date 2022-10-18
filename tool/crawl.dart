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
final Map<String, String?> _dartSdkToLinterMap = <String, String?>{};

final _flutterOptionsUrl = Uri.https('raw.githubusercontent.com',
    '/flutter/packages/main/packages/flutter_lints/lib/flutter.yaml');
final _flutterRepoOptionsUrl = Uri.https(
    'raw.githubusercontent.com', '/flutter/flutter/main/analysis_options.yaml');

List<String>? _flutterRepoRules;

List<String>? _flutterRules;

int? _latestMinor;
Iterable<LintRule>? _registeredLints;
final _repoPathPrefix =
    Uri.https('raw.githubusercontent.com', '/dart-lang/linter/');

List<String>? _sdkTags;

List<String>? _linterTags;

Map<String, List<String?>> _sinceMap = <String, List<String>>{};

Future<List<String>> get flutterRepoRules async =>
    _flutterRepoRules ??= await score_utils.fetchRules(_flutterRepoOptionsUrl);

Future<List<String>> get flutterRules async =>
    _flutterRules ??= await score_utils.fetchRules(_flutterOptionsUrl);

Future<int> get latestMinor async =>
    _latestMinor ??= await _readLatestMinorVersion();

Iterable<LintRule> get registeredLints {
  if (_registeredLints == null) {
    registerLintRules();
    _registeredLints = Registry.ruleRegistry;
  }
  return _registeredLints!;
}

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

Future<String?> findSinceLinter(String lint, [Authentication? auth]) async {
  var linterReleases = await getLinterReleases(auth);

  for (var version in linterReleases) {
    var rules = await rulesForVersion(version);
    if (rules != null) {
      if (rules.contains(lint)) {
        return version;
      }
    }
  }

  return null;
}

Future<List<String>> getSdkTags(Authentication? auth,
        {bool onlyStable = false}) async =>
    _sdkTags ??= await _fetchSdkTags(auth, onlyStable: onlyStable);

Future<List<String>> getLinterReleases([Authentication? auth]) async =>
    _linterTags ??=
        (await _fetchLinterReleaseTags(auth)).reversed.toList(growable: false);

Future<String?> linterForDartSdk(String sdk) async =>
    _dartSdkToLinterMap[sdk] ??= await _fetchLinterForVersion(sdk);

Future<List<String?>?> rulesForVersion(String version) async =>
    _sinceMap[version] ??= await fetchRulesForVersion(version);

Future<String> _fetchDEPSforVersion(String version) async {
  var client = http.Client();
  //https://raw.githubusercontent.com/dart-lang/sdk/2.1.0-dev.1.0/DEPS
  var req = await client.get(
      Uri.https('raw.githubusercontent.com', '/dart-lang/sdk/$version/DEPS'));
  return req.body;
}

final _linterReleasePattern = RegExp(r'\d+\.\d+(\.\d+)');

Future<String?> _commitReferenceToVersion(String version) async {
  if (_linterReleasePattern.hasMatch(version)) {
    return version;
  }

  // Get all tags which include this commit reference
  var result = await Process.run('git', ['tag', '--contains', version]);
  var output = result.stdout;
  if (output is String) {
    var tags = _linterReleasePattern.allMatches(output);
    // Take the earliest (first) release which includes this commit
    var latestTag = tags.first.group(0);
    if (latestTag != null) {
      return latestTag;
    }
  }

  return null;
}

Future<String?> _fetchLinterForVersion(String version) async {
  var deps = await _fetchDEPSforVersion(version);
  for (var untrimmedLine in deps.split('\n')) {
    var line = untrimmedLine.trim();
    if (line.startsWith('"lint')) {
      // "linter_tag": "0.1.59",
      var oldSplit = line.split('"linter_tag":');
      if (oldSplit.length == 2) {
        //  "0.1.59",
        return _commitReferenceToVersion(oldSplit[1].split('"')[1]);
      }

      // "linter_rev": "f2c55484e8ebda0aec8c2fea637b3bd5b17258ca",
      var newSplit = line.split('"linter_rev":');
      if (newSplit.length == 2) {
        // "f2c55484e8ebda0aec8c2fea637b3bd5b17258ca",
        var parsedLinterVersion = newSplit[1].split('"')[1];
        return _commitReferenceToVersion(parsedLinterVersion);
      }
    }
  }
  return null;
}

final _releaseTagPattern = RegExp(r'\d+');
final _stableReleasePattern = RegExp(r'^\d+\.\d+\.\d+$');

Future<List<String>> _fetchLinterReleaseTags(Authentication? auth) async =>
    await _fetchRepoTags(
        'dart-lang', 'linter', auth, _stableReleasePattern.hasMatch);

Future<List<String>> _fetchSdkTags(Authentication? auth,
        {bool onlyStable = false}) async =>
    await _fetchRepoTags('dart-lang', 'linter', auth, (t) {
      // Filter on numeric release tags.
      if (!t.startsWith(_releaseTagPattern)) {
        return false;
      }

      // Filter on bottom.
      try {
        var version = Version.parse(t);
        if (version < bottomDartSdk) {
          return false;
        }
      } on FormatException {
        return false;
      }

      if (onlyStable) {
        if (!_stableReleasePattern.hasMatch(t)) {
          return false;
        }
      }

      return true;
    });

Future<List<String>> _fetchRepoTags(String org, String repo,
    Authentication? auth, bool Function(String) where) async {
  var github = GitHub(auth: auth);
  var slug = RepositorySlug(org, repo);

  print('list repository tags: $slug');
  print('authentication:  ${auth != null ? "(token)" : "(anonymous)"}');

  var tags = await github.repositories
      .listTags(slug)
      .map((t) => t.name)
      .toList()
      .catchError((e) {
    print('exception caught fetching $repo tags');
    print(e);
    print('(using cached $repo values)');
    return Future.value(<String>[]);
  });

  return tags.whereType<String>().where(where).toList(growable: false);
}

Future<int> _readLatestMinorVersion() async {
  var contents = await File('pubspec.yaml').readAsString();
  var pubspec = loadYamlNode(contents) as YamlMap;
  var version = pubspec['version'] as String;
  // 1.15.0
  return int.parse(version.split('.')[1]);
}

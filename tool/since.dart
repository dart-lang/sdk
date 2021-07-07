// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:github/github.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'crawl.dart';

void main() async {
// Uncomment to (re)generate since/linter.yaml contents.
//  for (var lint in registeredLints) {
//    var since = await findSinceLinter(lint.name);
//    if (since != null) {
//      print('${lint.name}: $since');
//    }
//  }

// Uncomment to (re)generate since/dart_sdk.yaml contents.
//  var tags = await sdkTags;
//  for (var tag in sdkTags)) {
//    var version = await fetchLinterForVersion(tag);
//    if (version.startsWith('@')) {
//      version = version.substring(1);
//    }
//    print('$tag: $version');
//  }

  await getSinceMap().then((m) => m.entries.forEach(print));
}

Version earliestLinterInDart2 = Version.parse('0.1.58');

Map<String, String>? _dartSdkMap;

List<String>? _linterVersions;

Map<String, SinceInfo>? _sinceMap;

Future<List<String>?> get linterVersions async {
  if (_linterVersions == null) {
    _linterVersions = <String>[];
    for (var minor = 0; minor <= await latestMinor; ++minor) {
      _linterVersions!.add('0.1.$minor');
    }
  }
  return _linterVersions;
}

Future<Map<String, String>?> getDartSdkMap(Authentication? auth) async {
  if (_dartSdkMap == null) {
    var dartSdkCache = await File('tool/since/dart_sdk.yaml').readAsString();
    var yamlMap = loadYamlNode(dartSdkCache) as YamlMap;
    _dartSdkMap = yamlMap.map((k, v) => MapEntry(k.toString(), v.toString()));

    var sdks = await getSdkTags(auth);
    for (var sdk in sdks) {
      if (!_dartSdkMap!.containsKey(sdk)) {
        var linterVersion = await linterForDartSdk(sdk);
        if (linterVersion != null) {
          _dartSdkMap![sdk] = linterVersion;
          print('fetched...');
          print('$sdk : $linterVersion');
          print('(consider caching in tool/since/dart_sdk.yaml)');
        }
      }
    }
  }
  return _dartSdkMap;
}

Future<Map<String, SinceInfo>> getSinceMap([Authentication? auth]) async =>
    _sinceMap ??= await _getSinceInfo(auth);

Future<Map<String, SinceInfo>> _getSinceInfo(Authentication? auth) async {
  var linterCache = File('tool/since/linter.yaml').readAsStringSync();
  var linterVersionCache = loadYamlNode(linterCache) as YamlMap;

  var sinceMap = <String, SinceInfo>{};
  for (var lint in registeredLints.map((l) => l.name)) {
    var linterVersion = linterVersionCache[lint] as String?;
    if (linterVersion == null) {
      linterVersion = await findSinceLinter(lint, auth: auth);
      if (linterVersion != null) {
        print('fetched...');
        print('$lint : $linterVersion');
        print('(consider caching in tool/since/linter.yaml)');
      }
    }
    sinceMap[lint] = SinceInfo(
        sinceLinter: linterVersion ?? await findSinceLinter(lint),
        sinceDartSdk: await _sinceSdkForLinter(linterVersion, auth));
  }
  return sinceMap;
}

Future<String?> _nextLinterVersion(Version linterVersion) async {
  var versions = await linterVersions;
  if (versions != null) {
    for (var version in versions) {
      if (Version.parse(version).compareTo(linterVersion) > 0) {
        return version;
      }
    }
  }
  return null;
}

Future<String?> _sinceSdkForLinter(
    String? linterVersionString, Authentication? auth) async {
  if (linterVersionString == null) {
    return null;
  }

  var linterVersion = Version.parse(linterVersionString);
  if (linterVersion.compareTo(earliestLinterInDart2) < 0) {
    return bottomDartSdk.toString();
  }

  var sdkVersions = <String>[];
  var sdkCache = await getDartSdkMap(auth);
  if (sdkCache != null) {
    for (var sdkEntry in sdkCache.entries) {
      if (Version.parse(sdkEntry.value) == linterVersion) {
        sdkVersions.add(sdkEntry.key);
      }
    }
  }
  if (sdkVersions.isEmpty) {
    var nextLinter = await _nextLinterVersion(linterVersion);
    return _sinceSdkForLinter(nextLinter, auth);
  }

  sdkVersions.sort();
  return sdkVersions.first;
}

class SinceInfo {
  final String? sinceLinter;
  final String? sinceDartSdk;
  SinceInfo({this.sinceLinter, this.sinceDartSdk});

  @override
  String toString() => 'linter: $sinceLinter | sdk: $sinceDartSdk';
}

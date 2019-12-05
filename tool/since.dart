// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

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

  await sinceMap.then((m) => m.entries.forEach(print));
}

Map<String, SinceInfo> _sinceMap;

Future<Map<String, SinceInfo>> get sinceMap async =>
    _sinceMap ??= await _getSinceInfo();

Future<Map<String, SinceInfo>> _getSinceInfo() async {
  var linterCache = await File('tool/since/linter.yaml').readAsString();
  final linterVersionCache = loadYamlNode(linterCache) as YamlMap;

  var sinceMap = <String, SinceInfo>{};
  for (var lint in registeredLints.map((l) => l.name)) {
    var linterVersion = linterVersionCache[lint] as String;
    if (linterVersion == null) {
      linterVersion = await findSinceLinter(lint);
      if (linterVersion != null) {
        print('fetched...');
        print('$lint : $linterVersion');
        print('(consider caching in tool/since/linter.yaml)');
      }
    }
    sinceMap[lint] = SinceInfo(
        sinceLinter: linterVersion ?? await findSinceLinter(lint),
        sinceDartSdk: await _sinceSdkForLinter(linterVersion));
  }
  return sinceMap;
}

Map<String, String> _dartSdkMap;

Future<Map<String, String>> get dartSdkMap async {
  if (_dartSdkMap == null) {
    var dartSdkCache = await File('tool/since/dart_sdk.yaml').readAsString();
    final yamlMap = loadYamlNode(dartSdkCache) as YamlMap;
    _dartSdkMap = yamlMap.map((k, v) => MapEntry(k.toString(), v.toString()));

    var sdks = await sdkTags;
    for (var sdk in sdks) {
      if (!_dartSdkMap.containsKey(sdk)) {
        var linterVersion = await linterForDartSdk(sdk);
        _dartSdkMap[sdk] = linterVersion;
        print('fetched...');
        print('$sdk : $linterVersion');
        print('(consider caching in tool/since/dart_sdk.yaml)');
      }
    }
  }
  return _dartSdkMap;
}

Version earliestLinterInDart2 = Version.parse('0.1.58');

Future<String> _sinceSdkForLinter(String linterVersionString) async {
  if (linterVersionString == null) {
    return null;
  }

  var linterVersion = Version.parse(linterVersionString);
  if (linterVersion.compareTo(earliestLinterInDart2) < 0) {
    return bottomDartSdk.toString();
  }

  var sdkVersions = <String>[];
  var sdkCache = await dartSdkMap;
  for (var sdkEntry in sdkCache.entries) {
    if (Version.parse(sdkEntry.value) == linterVersion) {
      sdkVersions.add(sdkEntry.key);
    }
  }
  if (sdkVersions.isEmpty) {
    var nextLinter = await _nextLinterVersion(linterVersion);
    return _sinceSdkForLinter(nextLinter);
  }

  sdkVersions.sort();
  return sdkVersions.first;
}

Future<String> _nextLinterVersion(Version linterVersion) async {
  for (final version in await linterVersions) {
    if (Version.parse(version).compareTo(linterVersion) > 0) {
      return version;
    }
  }
  return null;
}

List<String> _linterVersions;
Future<List<String>> get linterVersions async {
  if (_linterVersions == null) {
    _linterVersions = <String>[];
    for (var minor = 0; minor <= await latestMinor; ++minor) {
      _linterVersions.add('0.1.$minor');
    }
  }
  return _linterVersions;
}

class SinceInfo {
  final String sinceLinter;
  final String sinceDartSdk;
  SinceInfo({this.sinceLinter, this.sinceDartSdk});

  @override
  String toString() => 'linter: $sinceLinter | sdk: $sinceDartSdk';
}

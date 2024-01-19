// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:io';

import 'package:yaml/yaml.dart';

import '../tool/util/path_utils.dart';
import 'changelog.dart';
import 'crawl.dart';

final Map<String, SinceInfo> sinceMap = _readSinceMap();

Map<String, SinceInfo> _readSinceMap() {
  var sinceFile = File(pathRelativeToPackageRoot(['tool', 'since', 'sdk.yaml']))
      .readAsStringSync();
  var versionMap = loadYamlNode(sinceFile) as YamlMap;

  var sinceMap = <String, SinceInfo>{};
  for (var rule in registeredLints.map((l) => l.name)) {
    var version = versionMap[rule] as String?;
    sinceMap[rule] = SinceInfo(sinceDartSdk: version);
  }

  return sinceMap;
}

class SdkVersionFile {
  static final filePath =
      pathRelativeToPackageRoot(['tool', 'since', 'sdk.yaml']);

  void addRule(String rule) {
    var sinceFile = File(filePath);
    var versionMap = loadYamlNode(sinceFile.readAsStringSync()) as Map;
    var sortedMap = SplayTreeMap<String, String>()
      ..addAll(versionMap.cast<String, String>());
    sortedMap[rule] = Changelog().readCurrentRelease();

    var output = StringBuffer();
    for (var MapEntry(key: lintName, value: sdkVersion) in sortedMap.entries) {
      output.writeln('$lintName: $sdkVersion');
    }

    sinceFile.writeAsStringSync(output.toString());
  }
}

class SinceInfo {
  final String? sinceDartSdk;
  SinceInfo({this.sinceDartSdk});

  @override
  String toString() => 'sdk: $sinceDartSdk';
}

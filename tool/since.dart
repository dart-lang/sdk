// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:yaml/yaml.dart';

import 'crawl.dart';

main() async {
  // Uncomment to (re)generate since.yaml contents.
//  for (var lint in registeredLints) {
//    var since = await findSinceLinter(lint);
//    if (since != null) {
//      print('${lint.name}: $since');
//    }
//  }

  await sinceMap.then((m) => m.entries.forEach(print));
}

Map<String, SinceInfo> _sinceMap;

Future<Map<String, SinceInfo>> get sinceMap async =>
    _sinceMap ??= await _getSinceInfo();

Future<Map<String, SinceInfo>> _getSinceInfo() async {
  var cache = await new File('tool/since.yaml').readAsString();
  YamlMap yaml = loadYamlNode(cache);
  Map<String, SinceInfo> sinceMap = <String, SinceInfo>{};
  for (var lint in registeredLints) {
    var linterVersion = yaml[lint.name];
    sinceMap[lint.name] =
        new SinceInfo(linterVersion ?? await findSinceLinter(lint));
  }
  return sinceMap;
}

class SinceInfo {
  // todo (pq): add sinceSdk
  String sinceLinter;
  SinceInfo(this.sinceLinter);

  @override
  String toString() => 'linter: $sinceLinter';
}

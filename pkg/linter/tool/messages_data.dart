// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/io.dart';
import 'package:yaml/yaml.dart';

import 'util/path_utils.dart';

MessagesData messagesYaml = () {
  var doc = loadYamlNode(readFile(_messagesYamlPath));
  if (doc is! YamlMap) throw StateError('messages.yaml is not a map');
  return MessagesData(doc);
}();

var _messagesYamlPath = pathRelativeToPackageRoot(['messages.yaml']);

extension type MessagesData(YamlMap _map) {
  Map<String, Set<String>> get categoryMappings {
    var result = <String, Set<String>>{};

    for (var code in lintCodes.keys) {
      var data = lintCodes[code] as YamlMap;
      if (data.containsKey('removedIn')) {
        continue;
      }
      var name = code as String;
      if (data.containsKey('sharedName')) {
        name = data['sharedName'] as String;
      }
      var categoriesData = data['categories'] as List?;
      var categories = (categoriesData ?? []).toSet().cast<String>();
      result.putIfAbsent(name, () => categories);
    }

    return result;
  }

  YamlMap get lintCodes {
    var lintRuleSection = _map['LintCode'] as YamlMap?;
    if (lintRuleSection == null) {
      throw StateError(
          "Error: '$_messagesYamlPath' does not have a 'LintCode' section.");
    }
    return lintRuleSection;
  }
}

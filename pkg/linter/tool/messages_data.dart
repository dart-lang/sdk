// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/io.dart';
import 'package:yaml/yaml.dart';

import 'util/path_utils.dart';

final MessagesData messagesYaml = () {
  var doc = loadYamlNode(readFile(_messagesYamlPath));
  if (doc is! YamlMap) throw StateError('messages.yaml is not a map');
  return MessagesData(doc);
}();

final String _messagesYamlPath = pathRelativeToPackageRoot(['messages.yaml']);

extension type MessagesData(YamlMap _map) {
  Map<String, String> get addedIn {
    var result = <String, String>{};

    for (var MapEntry(key: String name, value: YamlMap data)
        in lintCodes.entries) {
      if (data['addedIn'] case String addedInString) {
        if (data.containsKey('sharedName')) {
          name = data['sharedName'] as String;
        }

        if (addedInString.split('.').length < 2) {
          throw StateError("Lint $name's 'addedIn' version must be "
              'at least a major.minor version.');
        }

        var oldResult = result[name];
        if (oldResult != null && oldResult == addedInString) {
          throw StateError("Lint $name has a different 'addedIn' value "
              'between its shared codes!');
        }

        result[name] = addedInString;
      }
    }

    return result;
  }

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

  Map<String, String> get deprecatedDetails {
    var result = <String, String>{};

    for (var code in lintCodes.keys) {
      var name = code as String;
      var data = lintCodes[name] as YamlMap;
      if (data['deprecatedDetails'] case String deprecatedDetails) {
        if (data.containsKey('sharedName')) {
          name = data['sharedName'] as String;
        }

        result.putIfAbsent(name, () => deprecatedDetails);
      }
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

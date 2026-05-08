// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' hide json;
import 'dart:io';

import 'package:pub_formats/pub_formats.dart';
import 'package:yaml/yaml.dart';

extension PubspecYamlFile on PubspecYamlFileSyntax {
  static PubspecYamlFileSyntax loadSync(File file) {
    return PubspecYamlFileSyntax.fromJson(
      _convertYamlMapToJsonMap(
        loadYamlDocument(file.readAsStringSync()).contents as YamlMap,
      ),
    );
  }

  void writeSync(File file) {
    // JSON is valid YAML, and JSON encoding is much faster, write JSON.
    return file.writeAsStringSync(_jsonEncoder.convert(json));
  }
}

extension PubspecLockFile on PubspecLockFileSyntax {
  static PubspecLockFileSyntax loadSync(File file) {
    return PubspecLockFileSyntax.fromJson(
      _convertYamlMapToJsonMap(
        loadYamlDocument(file.readAsStringSync()).contents as YamlMap,
      ),
    );
  }
}

extension PackageGraphFile on PackageGraphFileSyntax {
  static PackageGraphFileSyntax loadSync(File file) {
    return PackageGraphFileSyntax.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, Object?>,
    );
  }
}

extension PackageConfigFile on PackageConfigFileSyntax {
  static PackageConfigFileSyntax loadSync(File file) {
    return PackageConfigFileSyntax.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, Object?>,
    );
  }
}

final _jsonEncoder = JsonEncoder.withIndent('  ');

Map<String, Object?> _convertYamlMapToJsonMap(YamlMap yamlMap) {
  final Map<String, Object?> jsonMap = {};
  yamlMap.forEach((key, value) {
    if (key is! String) {
      throw UnsupportedError(
        'YAML map keys must be strings for JSON conversion.',
      );
    }
    jsonMap[key] = _convertYamlValue(value);
  });
  return jsonMap;
}

Object? _convertYamlValue(dynamic yamlValue) {
  if (yamlValue is YamlMap) {
    return _convertYamlMapToJsonMap(yamlValue);
  } else if (yamlValue is YamlList) {
    return yamlValue.map((e) => _convertYamlValue(e)).toList();
  } else {
    // For primitive types: String, int, double, bool, null.
    return yamlValue;
  }
}

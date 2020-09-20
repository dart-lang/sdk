// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:yaml/yaml.dart';

extension YamlMapExtensions on YamlMap {
  /// Return the value associated with the key whose value matches the given
  /// [key], or `null` if there is no matching key.
  YamlNode valueAt(String key) {
    for (var keyNode in nodes.keys) {
      if (keyNode is YamlScalar && keyNode.value == key) {
        return nodes[key];
      }
    }
    return null;
  }
}

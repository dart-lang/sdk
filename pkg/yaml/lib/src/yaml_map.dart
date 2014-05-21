// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.map;

import 'dart:collection';

import 'package:collection/collection.dart';

import 'deep_equals.dart';
import 'utils.dart';

/// This class behaves almost identically to the normal Dart [Map]
/// implementation, with the following differences:
///
///  *  It allows NaN, list, and map keys.
///  *  It defines `==` structurally. That is, `yamlMap1 == yamlMap2` if they
///     have the same contents.
///  *  It has a compatible [hashCode] method.
///
/// This class is deprecated. In future releases, this package will use
/// a [HashMap] with a custom equality operation rather than a custom class.
@Deprecated('1.0.0')
class YamlMap extends DelegatingMap {
  YamlMap()
      : super(new HashMap(equals: deepEquals, hashCode: hashCodeFor));

  YamlMap.from(Map map)
      : super(new HashMap(equals: deepEquals, hashCode: hashCodeFor)) {
    addAll(map);
  }

  int get hashCode => hashCodeFor(this);

  bool operator ==(other) {
    if (other is! YamlMap) return false;
    return deepEquals(this, other);
  }
}

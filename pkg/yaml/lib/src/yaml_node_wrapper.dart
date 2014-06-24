// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.yaml_node_wrapper;

import 'dart:collection';

import 'package:collection/collection.dart' as pkg_collection;
import 'package:source_maps/source_maps.dart';

import 'null_span.dart';
import 'yaml_node.dart';

/// A wrapper that makes a normal Dart map behave like a [YamlMap].
class YamlMapWrapper extends MapBase
    with pkg_collection.UnmodifiableMapMixin<dynamic, YamlNode>
    implements YamlMap {
  final Map _dartMap;

  final Span span;

  final Map<dynamic, YamlNode> nodes;

  Map get value => this;

  Iterable get keys => _dartMap.keys;

  YamlMapWrapper(Map dartMap, String sourceName)
      : this._(dartMap, new NullSpan(sourceName));

  YamlMapWrapper._(Map dartMap, Span span)
      : _dartMap = dartMap,
        span = span,
        nodes = new _YamlMapNodes(dartMap, span);

  operator [](Object key) {
    var value = _dartMap[key];
    if (value is Map) return new YamlMapWrapper._(value, span);
    if (value is List) return new YamlListWrapper._(value, span);
    return value;
  }

  int get hashCode => _dartMap.hashCode;

  operator ==(Object other) =>
      other is YamlMapWrapper && other._dartMap == _dartMap;
}

/// The implementation of [YamlMapWrapper.nodes] as a wrapper around the Dart
/// map.
class _YamlMapNodes extends MapBase<dynamic, YamlNode>
    with pkg_collection.UnmodifiableMapMixin<dynamic, YamlNode> {
  final Map _dartMap;

  final Span _span;

  Iterable get keys =>
      _dartMap.keys.map((key) => new YamlScalar.internal(key, _span));

  _YamlMapNodes(this._dartMap, this._span);

  YamlNode operator [](Object key) {
    if (key is YamlScalar) key = key.value;
    if (!_dartMap.containsKey(key)) return null;
    return _nodeForValue(_dartMap[key], _span);
  }

  int get hashCode => _dartMap.hashCode;

  operator ==(Object other) =>
      other is _YamlMapNodes && other._dartMap == _dartMap;
}

// TODO(nweiz): Use UnmodifiableListMixin when issue 18970 is fixed.
/// A wrapper that makes a normal Dart list behave like a [YamlList].
class YamlListWrapper extends ListBase implements YamlList {
  final List _dartList;

  final Span span;

  final List<YamlNode> nodes;

  List get value => this;

  int get length => _dartList.length;

  set length(int index) {
    throw new UnsupportedError("Cannot modify an unmodifiable List.");
  }

  YamlListWrapper(List dartList, String sourceName)
      : this._(dartList, new NullSpan(sourceName));

  YamlListWrapper._(List dartList, Span span)
      : _dartList = dartList,
        span = span,
        nodes = new _YamlListNodes(dartList, span);

  operator [](int index) {
    var value = _dartList[index];
    if (value is Map) return new YamlMapWrapper._(value, span);
    if (value is List) return new YamlListWrapper._(value, span);
    return value;
  }

  operator []=(int index, value) {
    throw new UnsupportedError("Cannot modify an unmodifiable List.");
  }

  int get hashCode => _dartList.hashCode;

  operator ==(Object other) =>
      other is YamlListWrapper && other._dartList == _dartList;
}

// TODO(nweiz): Use UnmodifiableListMixin when issue 18970 is fixed.
/// The implementation of [YamlListWrapper.nodes] as a wrapper around the Dart
/// list.
class _YamlListNodes extends ListBase<YamlNode> {
  final List _dartList;

  final Span _span;

  int get length => _dartList.length;

  set length(int index) {
    throw new UnsupportedError("Cannot modify an unmodifiable List.");
  }

  _YamlListNodes(this._dartList, this._span);

  YamlNode operator [](int index) => _nodeForValue(_dartList[index], _span);

  operator []=(int index, value) {
    throw new UnsupportedError("Cannot modify an unmodifiable List.");
  }

  int get hashCode => _dartList.hashCode;

  operator ==(Object other) =>
      other is _YamlListNodes && other._dartList == _dartList;
}

YamlNode _nodeForValue(value, Span span) {
  if (value is Map) return new YamlMapWrapper._(value, span);
  if (value is List) return new YamlListWrapper._(value, span);
  return new YamlScalar.internal(value, span);
}

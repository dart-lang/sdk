// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.map;

import 'dart:collection' as collection;

import 'package:collection/collection.dart';
import 'package:source_maps/source_maps.dart';

/// An interface for parsed nodes from a YAML source tree.
///
/// [YamlMap]s and [YamlList]s implement this interface in addition to the
/// normal [Map] and [List] interfaces, so any maps and lists will be
/// [YamlNode]s regardless of how they're accessed.
///
/// Scalars values like strings and numbers, on the other hand, don't have this
/// interface by default. Instead, they can be accessed as [YamlScalar]s via
/// [YamlMap.nodes] or [YamlList.nodes].
abstract class YamlNode {
  /// The source span for this node.
  ///
  /// [Span.getLocationMessage] can be used to produce a human-friendly message
  /// about this node.
  Span get span;

  /// The inner value of this node.
  ///
  /// For [YamlScalar]s, this will return the wrapped value. For [YamlMap] and
  /// [YamlList], it will return [this], since they already implement [Map] and
  /// [List], respectively.
  get value;
}

/// A read-only [Map] parsed from YAML.
class YamlMap extends YamlNode with collection.MapMixin, UnmodifiableMapMixin  {
  final Span span;

  final Map<dynamic, YamlNode> nodes;

  Map get value => this;

  Iterable get keys => nodes.keys.map((node) => node.value);

  /// Users of the library should not construct [YamlMap]s manually.
  YamlMap(Map<dynamic, YamlNode> nodes, this.span)
      : nodes = new UnmodifiableMapView<dynamic, YamlNode>(nodes);

  operator [](key) {
    var node = nodes[key];
    return node == null ? null : node.value;
  }
}

// TODO(nweiz): Use UnmodifiableListMixin when issue 18970 is fixed.
/// A read-only [List] parsed from YAML.
class YamlList extends YamlNode with collection.ListMixin {
  final Span span;

  final List<YamlNode> nodes;

  List get value => this;

  int get length => nodes.length;

  set length(int index) {
    throw new UnsupportedError("Cannot modify an unmodifiable List");
  }

  /// Users of the library should not construct [YamlList]s manually.
  YamlList(List<YamlNode> nodes, this.span)
      : nodes = new UnmodifiableListView<YamlNode>(nodes);

  operator [](int index) => nodes[index].value;

  operator []=(int index, value) {
    throw new UnsupportedError("Cannot modify an unmodifiable List");
  }
}

/// A wrapped scalar value parsed from YAML.
class YamlScalar extends YamlNode {
  final Span span;

  final value;

  /// Users of the library should not construct [YamlScalar]s manually.
  YamlScalar(this.value, this.span);

  String toString() => value.toString();
}

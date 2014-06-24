// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.yaml_node;

import 'dart:collection' as collection;

import 'package:collection/collection.dart';
import 'package:source_maps/source_maps.dart';

import 'null_span.dart';
import 'yaml_node_wrapper.dart';

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

  /// A view of [this] where the keys and values are guaranteed to be
  /// [YamlNode]s.
  ///
  /// The key type is `dynamic` to allow values to be accessed using
  /// non-[YamlNode] keys, but [Map.keys] and [Map.forEach] will always expose
  /// them as [YamlNode]s. For example, for `{"foo": [1, 2, 3]}` [nodes] will be
  /// a map from a [YamlScalar] to a [YamlList], but since the key type is
  /// `dynamic` `map.nodes["foo"]` will still work.
  final Map<dynamic, YamlNode> nodes;

  Map get value => this;

  Iterable get keys => nodes.keys.map((node) => node.value);

  /// Creates an empty YamlMap.
  ///
  /// This map's [span] won't have useful location information. However, it will
  /// have a reasonable implementation of [Span.getLocationMessage]. If
  /// [sourceName] is passed, it's used as the [Span.sourceUrl].
  factory YamlMap({String sourceName}) =>
      new YamlMapWrapper(const {}, sourceName);

  /// Wraps a Dart map so that it can be accessed (recursively) like a
  /// [YamlMap].
  ///
  /// Any [Span]s returned by this map or its children will be dummies without
  /// useful location information. However, they will have a reasonable
  /// implementation of [Span.getLocationMessage]. If [sourceName] is passed,
  /// it's used as the [Span.sourceUrl].
  factory YamlMap.wrap(Map dartMap, {String sourceName}) =>
      new YamlMapWrapper(dartMap, sourceName);

  /// Users of the library should not use this constructor.
  YamlMap.internal(Map<dynamic, YamlNode> nodes, this.span)
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

  /// Creates an empty YamlList.
  ///
  /// This list's [span] won't have useful location information. However, it
  /// will have a reasonable implementation of [Span.getLocationMessage]. If
  /// [sourceName] is passed, it's used as the [Span.sourceUrl].
  factory YamlList({String sourceName}) =>
      new YamlListWrapper(const [], sourceName);

  /// Wraps a Dart list so that it can be accessed (recursively) like a
  /// [YamlList].
  ///
  /// Any [Span]s returned by this list or its children will be dummies without
  /// useful location information. However, they will have a reasonable
  /// implementation of [Span.getLocationMessage]. If [sourceName] is passed,
  /// it's used as the [Span.sourceUrl].
  factory YamlList.wrap(List dartList, {String sourceName}) =>
      new YamlListWrapper(dartList, sourceName);

  /// Users of the library should not use this constructor.
  YamlList.internal(List<YamlNode> nodes, this.span)
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

  /// Wraps a Dart value in a [YamlScalar].
  ///
  /// This scalar's [span] won't have useful location information. However, it
  /// will have a reasonable implementation of [Span.getLocationMessage]. If
  /// [sourceName] is passed, it's used as the [Span.sourceUrl].
  YamlScalar.wrap(this.value, {String sourceName})
      : span = new NullSpan(sourceName);

  /// Users of the library should not use this constructor.
  YamlScalar.internal(this.value, this.span);

  String toString() => value.toString();
}

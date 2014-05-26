// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.shelf_unmodifiable_map;

import 'dart:collection';

// TODO(kevmoo): MapView lacks a const ctor, so we have to use DelegatingMap
// from pkg/collection - https://codereview.chromium.org/294093003/
import 'package:collection/wrappers.dart' as pc;

/// A simple wrapper over [pc.UnmodifiableMapView] which avoids re-wrapping
/// itself.
class ShelfUnmodifiableMap<V> extends UnmodifiableMapView<String, V> {
  /// If [source] is a [ShelfUnmodifiableMap] with matching [ignoreKeyCase],
  /// then [source] is returned.
  ///
  /// If [source] is `null` it is treated like an empty map.
  ///
  /// If [ignoreKeyCase] is `true`, the keys will have case-insensitive access.
  ///
  /// [source] is copied to a new [Map] to ensure changes to the paramater value
  /// after constructions are not reflected.
  factory ShelfUnmodifiableMap(Map<String, V> source,
      {bool ignoreKeyCase: false}) {
    if (source is ShelfUnmodifiableMap<V>) {
      return source;
    }

    if (source == null || source.isEmpty) {
      return const _EmptyShelfUnmodifiableMap();
    }

    if (ignoreKeyCase) {
      // TODO(kevmoo) generalize this model with a 'canonical map' to align with
      // similiar implementation in http pkg [BaseRequest].
      var map = new LinkedHashMap<String, V>(
          equals: (key1, key2) => key1.toLowerCase() == key2.toLowerCase(),
          hashCode: (key) => key.toLowerCase().hashCode);

      map.addAll(source);

      source = map;
    } else {
      source = new Map<String, V>.from(source);
    }

    return new ShelfUnmodifiableMap<V>._(source);
  }

  ShelfUnmodifiableMap._(Map<String, V> source) : super(source);
}

/// An const empty implementation of [ShelfUnmodifiableMap].
class _EmptyShelfUnmodifiableMap<V> extends pc.DelegatingMap<String, V>
    implements ShelfUnmodifiableMap<V>  {
  const _EmptyShelfUnmodifiableMap() : super(const {});
}

// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:collection/collection.dart';

/// An [Equality] for [Message]s.
///
/// Similar to [DeepCollectionEquality] but with some customizations:
///
/// - Only supports JSON objects
/// - Supports ignoring specific map keys (applies to all nested maps)
/// - Uses unordered list comparisons for lists that are not made of ints.
/// - Supports conditionally skipping the top level `id` entry.
class MessageEquality implements Equality<Message> {
  final _CustomDeepCollectionEquality _recursiveEquality;

  MessageEquality({Set<String> ignoredKeys = const {}})
    : _recursiveEquality = _CustomDeepCollectionEquality(ignoredKeys);

  /// If [skipMatchId] is `true`, then the top level `id` field is ignored
  /// during comparison.
  @override
  bool equals(Message a, Message b, {bool skipMatchId = false}) {
    if (a.method != b.method) return false;
    if (!skipMatchId && a.id != b.id) return false;
    return switch (a.method) {
      // No method means this is a response, compare the result.
      null => _recursiveEquality.equals(a.result, b.result),
      // A method means this is a request, compare the params.
      String() => _recursiveEquality.equals(a.params, b.params),
    };
  }

  @override
  int hash(Message e) {
    return _recursiveEquality.hash(e.map);
  }

  @override
  bool isValidKey(Object? o) => o is Message;
}

/// Implementation for checking equality of the `params` and `result` fields
/// of [Message]s.
class _CustomDeepCollectionEquality implements Equality<Object?> {
  final Set<String> _ignoredKeys;
  late final _orderedListEquality = ListEquality<Object?>(this);
  late final _unorderedListEquality = UnorderedIterableEquality<Object?>(this);

  _CustomDeepCollectionEquality(this._ignoredKeys);

  @override
  bool equals(Object? e1, Object? e2) {
    if (identical(e1, e2)) return true;

    if (e1 is Map<String, Object?> && e2 is Map<String, Object?>) {
      return _mapEquals(e1, e2);
    } else if (e1 is List<Object?> && e2 is List<Object?>) {
      if (e1.every((entry) => entry is int)) {
        return _orderedListEquality.equals(e1, e2);
      }
      return _unorderedListEquality.equals(e1, e2);
    }

    return const DefaultEquality().equals(e1, e2);
  }

  @override
  int hash(Object? e) {
    if (e is Map<String, Object?>) {
      return _mapHash(e);
    } else if (e is Iterable<Object?>) {
      return _unorderedListEquality.hash(e);
    }
    return const DefaultEquality().hash(e);
  }

  @override
  bool isValidKey(Object? o) => true;

  bool _mapEquals(Map<String, Object?> e1, Map<String, Object?> e2) {
    var keys1 = e1.keys.where((k) => !_ignoredKeys.contains(k)).toSet();
    var keys2 = e2.keys.where((k) => !_ignoredKeys.contains(k)).toSet();

    if (keys1.length != keys2.length) return false;

    for (var key in keys1) {
      if (!keys2.contains(key)) return false;
      if (!equals(e1[key], e2[key])) return false;
    }

    return true;
  }

  /// A relatively weak but cheap underdered hash, which is important.
  ///
  /// We cannot use [MapEquality] because it doesn't support ignoring keys.
  int _mapHash(Map<String, Object?> e) {
    var resultMapHash = 0;
    for (var key in e.keys) {
      if (_ignoredKeys.contains(key)) continue;
      resultMapHash = resultMapHash ^ key.hashCode;
      resultMapHash = resultMapHash ^ hash(e[key]);
    }
    return resultMapHash;
  }
}

// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Generates a random 8-byte secret using a cryptographically secure RNG.
String generateSecret() {
  final kTokenByteSize = 8;
  final bytes = Uint8List(kTokenByteSize);
  // Use a secure random number generator.
  final rand = Random.secure();

  for (var i = 0; i < kTokenByteSize; i++) {
    bytes[i] = rand.nextInt(256);
  }
  return base64Url.encode(bytes);
}

/// [Set]-like containers which automatically generate [String] IDs for its
/// items.
///
/// Originally pulled from dart:_vmservice.
class NamedLookup<E> with IterableMixin<E> {
  NamedLookup({String prefix = ''}) : _generator = IdGenerator(prefix: prefix);
  final IdGenerator _generator;
  final Map<String, E> _elements = {};
  final Map<E, String> _ids = {};

  void add(E e) {
    final id = _generator.newId();
    _elements[id] = e;
    _ids[e] = id;
  }

  void remove(E e) {
    final id = _ids.remove(e)!;
    _elements.remove(id);
    _generator.release(id);
  }

  E? operator [](String id) => _elements[id];

  String? keyOf(E e) => _ids[e];

  @override
  Iterator<E> get iterator => _ids.keys.iterator;
}

/// Generator for unique IDs which recycles expired ones.
class IdGenerator {
  IdGenerator({this.prefix = ''});

  /// Fixed initial part of the ID
  final String prefix;

  // IDs in use.
  final _used = <String>{};

  /// IDs to be recycled (use these before generate new ones).
  final _free = <String>{};

  /// Next ID to generate when no recycled IDs are available.
  int _next = 0;

  /// Returns a new ID (possibly recycled).
  String newId() {
    String id;
    if (_free.isEmpty) {
      id = prefix + (_next++).toString();
    } else {
      id = _free.first;
    }
    _free.remove(id);
    _used.add(id);
    return id;
  }

  /// Releases the ID and mark it for recycling.
  void release(String id) {
    if (_used.remove(id)) {
      _free.add(id);
    }
  }
}

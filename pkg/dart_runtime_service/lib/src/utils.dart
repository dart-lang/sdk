// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'clients.dart';

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

mixin ClientLookup on IterableMixin<Client> {
  Client? findFirstClientThatHandlesService(String service) {
    for (final client in this) {
      if (client.hasService(service)) {
        return client;
      }
    }
    return null;
  }
}

/// An unmodifiable view of a [ClientNamedLookup].
class UnmodifiableClientNamedLookup with IterableMixin<Client>, ClientLookup {
  UnmodifiableClientNamedLookup(this._namedLookup);

  final ClientNamedLookup _namedLookup;

  Client? operator [](String id) => _namedLookup[id];

  String? keyOf(Client e) => _namedLookup.keyOf(e);

  @override
  Iterator<Client> get iterator => _namedLookup.iterator;
}

/// [Set]-like containers which automatically generate [String] IDs for its
/// items.
///
/// Originally pulled from dart:_vmservice.
final class ClientNamedLookup extends IterableMixin<Client> with ClientLookup {
  ClientNamedLookup({String prefix = ''})
    : _generator = IdGenerator(prefix: prefix);
  final IdGenerator _generator;
  final Map<Client, String> _ids = {};
  final Map<String, Client> _elements = {};

  String add(Client e) {
    final id = _generator.newId();
    _elements[id] = e;
    _ids[e] = id;
    return id;
  }

  void remove(Client e) {
    final id = _ids.remove(e)!;
    _elements.remove(id);
    _generator.release(id);
  }

  Client? operator [](String id) => _elements[id];

  String? keyOf(Client e) => _ids[e];

  @override
  Iterator<Client> get iterator => _ids.keys.iterator;
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

// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'clients.dart';

/// Generates a random 8-byte secret using a cryptographically secure RNG.
String generateSecret() {
  final kTokenByteSize = 8;
  final bytes = Uint8List(kTokenByteSize);
  Random rand;
  // Random.secure() may throw UnsupportedError if the platform does not
  // provide a cryptographically secure source of entropy (e.g., in some
  // sandboxed CI environments). Fall back to a pseudo-random generator
  // in this case.
  try {
    rand = Random.secure();
    // ignore: avoid_catching_errors
  } on UnsupportedError {
    rand = Random();
  }

  for (var i = 0; i < kTokenByteSize; i++) {
    bytes[i] = rand.nextInt(256);
  }
  return base64Url.encode(bytes);
}

/// An unmodifiable view of a [ClientNamedLookup].
class UnmodifiableClientNamedLookup with IterableMixin<Client> {
  UnmodifiableClientNamedLookup(this._namedLookup);

  final ClientNamedLookup _namedLookup;

  Client? operator [](String id) => _namedLookup[id];

  String? keyOf(Client e) => _namedLookup.keyOf(e);

  /// Finds the first client that has registered the specified [service].
  Client? findFirstClientThatHandlesService(String service) {
    for (final client in this) {
      if (client.hasService(service)) {
        return client;
      }
    }
    return null;
  }

  @override
  Iterator<Client> get iterator => _namedLookup.iterator;
}

/// [Set]-like containers which automatically generate [String] IDs for its
/// items.
///
/// Originally pulled from dart:_vmservice.
final class ClientNamedLookup extends IterableMixin<Client> {
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

/// Used to protect global state accessed in blocks containing calls to
/// asynchronous methods.
///
/// This mutex is not reentrant; calling [runGuarded] or [runGuardedWeak] from
/// within an already guarded section may deadlock.
class Mutex {
  int _weakGuards = 0;
  bool _locked = false;
  var _outstandingReadersCompleter = Completer<void>();
  final _outstandingRequests = Queue<Completer<void>>();

  /// Executes a block of code containing asynchronous calls atomically.
  ///
  /// If no other asynchronous context is currently executing within
  /// [criticalSection] or a [runGuardedWeak] scope, it will immediately be
  /// called. Otherwise, the caller will be suspended and entered into a queue
  /// to be resumed once the lock is released.
  Future<T> runGuarded<T>(FutureOr<T> Function() criticalSection) async {
    try {
      await _acquireLock();
      return await criticalSection();
    } finally {
      _releaseLock();
    }
  }

  /// Executes a block of code containing asynchronous calls, allowing for other
  /// weakly guarded sections to be executed concurrently.
  ///
  /// If no other asynchronous context is currently executing within a
  /// [runGuarded] scope, [criticalSection] will immediately be called.
  /// Otherwise, the caller will be suspended and entered into a queue to be
  /// resumed once the lock is released.
  Future<T> runGuardedWeak<T>(FutureOr<T> Function() criticalSection) async {
    await _acquireLock(strong: false);
    try {
      return await criticalSection();
    } finally {
      _weakGuards--;
      if (_weakGuards == 0) {
        // Notify callers of `runGuarded` that they can try to execute again.
        _outstandingReadersCompleter.complete();
      }
    }
  }

  Future<void> _acquireLock({bool strong = true}) async {
    if (!_locked) {
      if (strong) {
        _locked = true;
      } else {
        _incrementWeakGuards();
      }
    } else {
      final request = Completer<void>();
      _outstandingRequests.add(request);
      await request.future;
      if (!strong) {
        // Don't hold the exclusive lock for weakly guarded sections; register
        // this reader and immediately release the lock so subsequent queued
        // weak sections can enter concurrently (or the next strong section can
        // wait on `_outstandingReadersCompleter`).
        _incrementWeakGuards();
        _releaseLock();
      }
    }
    // The lock cannot be acquired by `runGuarded` if there is outstanding
    // execution in weakly guarded sections. Loop in case we've entered another
    // weakly guarded scope before we've woken up.
    while (strong && _weakGuards > 0) {
      await _outstandingReadersCompleter.future;
    }
  }

  void _incrementWeakGuards() {
    _weakGuards++;
    if (_weakGuards == 1) {
      // Reinitialize if this is the only weakly guarded scope.
      _outstandingReadersCompleter = Completer<void>();
    }
  }

  void _releaseLock() {
    if (_outstandingRequests.isNotEmpty) {
      final request = _outstandingRequests.removeFirst();
      request.complete();
      return;
    }
    // Only release the lock if no other requests are pending to prevent races
    // between the next request from the queue to be handled and incoming
    // requests.
    _locked = false;
  }
}

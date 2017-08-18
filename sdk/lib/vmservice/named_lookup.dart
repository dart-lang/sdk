// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._vmservice;

/// Set like containes which automatically generated String ids for its items
class NamedLookup<E> extends Object with IterableMixin<E> {
  final IdGenerator _generator;
  final Map<String, E> _elements = new Map<String, E>();
  final Map<E, String> _ids = new Map<E, String>();

  NamedLookup({String prologue = ''})
      : super(),
        _generator = new IdGenerator(prologue: prologue);

  void add(E e) {
    final id = _generator.newId();
    _elements[id] = e;
    _ids[e] = id;
  }

  void remove(E e) {
    final id = _ids.remove(e);
    _elements.remove(id);
    _generator.release(id);
  }

  E operator [](String id) => _elements[id];
  String keyOf(E e) => _ids[e];

  Iterator<E> get iterator => _ids.keys.iterator;
}

/// Generator for unique ids which recycles expired ones
class IdGenerator {
  /// Fixed initial part of the id
  final String prologue;
  // Ids in use
  final Set<String> _used = new Set<String>();

  /// Ids that has been released (use these before generate new ones)
  final Set<String> _free = new Set<String>();

  /// Next id to generate if no one can be recycled (first use _free);
  int _next = 0;

  IdGenerator({this.prologue = ''});

  /// Returns a new Id (possibly recycled)
  String newId() {
    var id;
    if (_free.isEmpty) {
      id = prologue + (_next++).toString();
    } else {
      id = _free.first;
    }
    _free.remove(id);
    _used.add(id);
    return id;
  }

  /// Releases the id and mark it for recycle
  void release(String id) {
    if (_used.remove(id)) {
      _free.add(id);
    }
  }
}

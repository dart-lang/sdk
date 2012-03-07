// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBObjectStore {

  final List<String> indexNames;

  final String keyPath;

  final String name;

  final IDBTransaction transaction;

  IDBRequest add(Dynamic value, [IDBKey key]);

  IDBRequest clear();

  IDBRequest count([var key_OR_range]);

  IDBIndex createIndex(String name, String keyPath);

  IDBRequest delete(var key_OR_keyRange);

  void deleteIndex(String name);

  IDBRequest getObject(IDBKey key);

  IDBIndex index(String name);

  IDBRequest openCursor([IDBKeyRange range, int direction]);

  IDBRequest put(Dynamic value, [IDBKey key]);
}

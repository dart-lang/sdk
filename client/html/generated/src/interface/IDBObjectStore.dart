// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBObjectStore {

  String get keyPath();

  String get name();

  IDBRequest add(String value, IDBKey key);

  IDBRequest clear();

  IDBIndex createIndex(String name, String keyPath);

  IDBRequest delete(IDBKey key);

  void deleteIndex(String name);

  IDBIndex index(String name);

  IDBRequest openCursor(IDBKeyRange range, int direction);

  IDBRequest put(String value, IDBKey key);
}

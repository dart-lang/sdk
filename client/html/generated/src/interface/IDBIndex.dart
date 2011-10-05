// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBIndex {

  String get keyPath();

  String get name();

  IDBObjectStore get objectStore();

  bool get unique();

  IDBRequest getKey(IDBKey key);

  IDBRequest openCursor(IDBKeyRange range, int direction);

  IDBRequest openKeyCursor(IDBKeyRange range, int direction);
}

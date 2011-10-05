// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBKeyRange {

  IDBKey get lower();

  bool get lowerOpen();

  IDBKey get upper();

  bool get upperOpen();

  IDBKeyRange bound(IDBKey lower, IDBKey upper, bool lowerOpen, bool upperOpen);

  IDBKeyRange lowerBound(IDBKey bound, bool open);

  IDBKeyRange only(IDBKey value);

  IDBKeyRange upperBound(IDBKey bound, bool open);
}

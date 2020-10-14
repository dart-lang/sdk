// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class ObjectPoolRef extends ObjectRef {
  int? get length;
}

abstract class ObjectPool extends Object implements ObjectPoolRef {
  Iterable<ObjectPoolEntry>? get entries;
}

enum ObjectPoolEntryKind { object, immediate, nativeEntryData, nativeEntry }

abstract class ObjectPoolEntry {
  int get offset;
  ObjectPoolEntryKind get kind;
  ObjectRef? get asObject;
  int? get asInteger;
}

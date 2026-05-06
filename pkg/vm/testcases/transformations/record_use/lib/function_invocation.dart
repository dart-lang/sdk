// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

class EntityId {
  final int id;

  const EntityId(this.id);
}

EntityId get1<T>(T t) {
  return EntityId(1);
}

EntityId get2<T>(T t) {
  return EntityId(2);
}

const _idExtractors = <String, Function>{'foo': get1, 'bar': get2};

typedef _IdExtractor<T> = EntityId Function(T thing);

@RecordUse()
_IdExtractor<T> idExtractor<T>(String entityType) {
  return (T v) => _idExtractors[entityType]!(v);
}

void main() {
  print(idExtractor('foo'));
}

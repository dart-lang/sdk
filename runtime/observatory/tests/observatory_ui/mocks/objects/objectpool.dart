// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class ObjectPoolRefMock implements M.ObjectPoolRef {
  final String id;
  final int length;

  const ObjectPoolRefMock({this.id: 'objectpool-id', this.length: 0});
}

class ObjectPoolMock implements M.ObjectPool {
  final String id;
  final M.ClassRef clazz;
  final String vmName;
  final int size;
  final int length;
  final Iterable<M.ObjectPoolEntry> entries;

  const ObjectPoolMock({this.id: 'objectpool-id', this.vmName: 'objpool-vmName',
                        this.clazz: const ClassRefMock(), this.size: 1,
                        this.length: 0, this.entries: const []});
}

class ObjectPoolEntryMock implements M.ObjectPoolEntry {
  final int offset;
  final M.ObjectPoolEntryKind kind;
  final M.ObjectRef asObject;
  final int asInteger;

  const ObjectPoolEntryMock({this.offset: 0,
                             this.kind: M.ObjectPoolEntryKind.object,
                             this.asObject: const InstanceRefMock(),
                             this.asInteger: null});
}

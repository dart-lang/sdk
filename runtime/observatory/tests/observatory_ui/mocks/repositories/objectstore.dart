// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

typedef Future<M.ObjectStore> ObjectStoreRepositoryMockGetter(M.IsolateRef i);

class ObjectStoreRepositoryMock implements M.ObjectStoreRepository {
  final ObjectStoreRepositoryMockGetter _getter;

  Future<M.ObjectStore> get(M.IsolateRef i) {
    if (_getter != null) {
      return _getter(i);
    }
    return new Future.value(new ObjectStoreMock());
  }

  ObjectStoreRepositoryMock({ObjectStoreRepositoryMockGetter getter})
    : _getter = getter;
}

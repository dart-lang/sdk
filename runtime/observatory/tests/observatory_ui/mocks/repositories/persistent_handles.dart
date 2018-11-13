// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

typedef Future<M.PersistentHandles> PersistentHandlesRepositoryMockGetter(
    M.IsolateRef i);

class PersistentHandlesRepositoryMock implements M.PersistentHandlesRepository {
  final PersistentHandlesRepositoryMockGetter _getter;

  Future<M.PersistentHandles> get(M.IsolateRef i) {
    if (_getter != null) {
      return _getter(i);
    }
    return new Future.value(new PortsAndHandlesMock());
  }

  PersistentHandlesRepositoryMock(
      {PersistentHandlesRepositoryMockGetter getter})
      : _getter = getter;
}

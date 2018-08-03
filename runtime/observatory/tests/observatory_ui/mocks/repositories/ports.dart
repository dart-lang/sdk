// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

typedef Future<M.Ports> PortsRepositoryMockGetter(M.IsolateRef i);

class PortsRepositoryMock implements M.PortsRepository {
  final PortsRepositoryMockGetter _getter;

  Future<M.Ports> get(M.IsolateRef i) {
    if (_getter != null) {
      return _getter(i);
    }
    return new Future.value(new PortsAndHandlesMock());
  }

  PortsRepositoryMock({PortsRepositoryMockGetter getter}) : _getter = getter;
}

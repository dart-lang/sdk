// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

typedef Future<M.InboundReferences>
        InboundReferencesRepositoryMockGetter(M.IsolateRef i, String id);

class InboundReferencesRepositoryMock implements M.InboundReferencesRepository {
  final InboundReferencesRepositoryMockGetter _getter;

  Future<M.InboundReferences> get(M.IsolateRef i, String id) {
    if (_getter != null) {
      return _getter(i, id);
    }
    return new Future.value(new InboundReferencesMock());
  }

  InboundReferencesRepositoryMock(
      {InboundReferencesRepositoryMockGetter getter})
    : _getter = getter;
}

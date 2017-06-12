// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

typedef Future<M.Object> ObjectRepositoryMockCallback(
    M.IsolateRef isolate, String id);

class ObjectRepositoryMock implements M.ObjectRepository {
  final ObjectRepositoryMockCallback _get;

  ObjectRepositoryMock({ObjectRepositoryMockCallback getter}) : _get = getter;

  Future<M.Object> get(M.IsolateRef isolate, String id, {int count}) {
    if (_get != null) {
      return _get(isolate, id);
    }
    return new Future.value(null);
  }
}

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

typedef Future<M.Guarded<M.Instance>>
        RetainedSizeRepositoryMockGetter(M.IsolateRef i, String id);

class RetainedSizeRepositoryMock implements M.RetainedSizeRepository {
  final RetainedSizeRepositoryMockGetter _getter;

  Future<M.Guarded<M.Instance>> get(M.IsolateRef i, String id) {
    if (_getter != null) {
      return _getter(i, id);
    }
    return new Future.value(
      new GuardedMock<M.Instance>.fromSentinel(new SentinelMock())
    );
  }

  RetainedSizeRepositoryMock({RetainedSizeRepositoryMockGetter getter})
    : _getter = getter;
}

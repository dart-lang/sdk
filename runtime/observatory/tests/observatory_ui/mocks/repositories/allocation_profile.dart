// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

typedef Future<
    M
        .AllocationProfile> AllocationProfileRepositoryMockGetterCallback(
    M.Isolate id, bool gc, bool force, bool combine);

class AllocationProfileRepositoryMock implements M.AllocationProfileRepository {
  final AllocationProfileRepositoryMockGetterCallback _get;

  AllocationProfileRepositoryMock(
      {AllocationProfileRepositoryMockGetterCallback getter})
      : _get = getter;

  Future<M.AllocationProfile> get(M.IsolateRef id,
      {bool gc: false, bool reset: false, bool combine: false}) {
    if (_get != null) {
      return _get(id, gc, reset, combine);
    }
    return new Future.value(null);
  }
}

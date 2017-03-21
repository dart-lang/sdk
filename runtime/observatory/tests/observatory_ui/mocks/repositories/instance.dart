// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

typedef Future<M.Instance> InstanceRepositoryMockCallback(M.IsolateRef isolate,
                                                          String id);

class InstanceRepositoryMock implements M.InstanceRepository {
  final InstanceRepositoryMockCallback _get;

  InstanceRepositoryMock({InstanceRepositoryMockCallback getter})
    : _get = getter;

  Future<M.Instance> get(M.IsolateRef isolate, String id, {int count}){
    if (_get != null) {
      return _get(isolate, id);
    }
    return new Future.value(null);
  }
}

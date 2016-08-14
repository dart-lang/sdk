// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

typedef Future<M.Instance> InstanceRepositoryMockCallback(String id);

class InstanceRepositoryMock implements M.InstanceRepository {
  final InstanceRepositoryMockCallback _get;

  InstanceRepositoryMock({InstanceRepositoryMockCallback getter})
    : _get = getter;

  Future<M.Instance> get(String id){
    if (_get != null) {
      return _get(id);
    }
    return new Future.value(null);
  }
}

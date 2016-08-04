// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

typedef Future<Iterable<M.Flag>> FlagsRepositoryMockCallback(M.VMRef vm);

class FlagsRepositoryMock implements M.FlagsRepository {
  final FlagsRepositoryMockCallback _list;

  Future<Iterable<M.Flag>> list(M.VMRef vm) {
    if (_list != null) {
      return _list(vm);
    }
    return new Future.value(const []);
  }

  FlagsRepositoryMock({FlagsRepositoryMockCallback list})
    : _list = list;
}

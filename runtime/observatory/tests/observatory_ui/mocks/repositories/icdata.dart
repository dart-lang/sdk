// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

typedef Future<M.ICData> ICDataRepositoryMockCallback(M.IsolateRef isolate,
                                                      String id);

class ICDataRepositoryMock implements M.ICDataRepository {
  final ICDataRepositoryMockCallback _get;

  ICDataRepositoryMock({ICDataRepositoryMockCallback getter})
    : _get = getter;

  Future<M.ICData> get(M.IsolateRef isolate, String id, {int count}){
    if (_get != null) {
      return _get(isolate, id);
    }
    return new Future.value(null);
  }
}

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

typedef Future<M.MegamorphicCache>
        MegamorphicCacheRepositoryMockCallback(M.IsolateRef isolate, String id);

class MegamorphicCacheRepositoryMock implements M.MegamorphicCacheRepository {
  final MegamorphicCacheRepositoryMockCallback _get;

  MegamorphicCacheRepositoryMock(
    {MegamorphicCacheRepositoryMockCallback getter})
    : _get = getter;

  Future<M.MegamorphicCache> get(M.IsolateRef isolate, String id, {int count}){
    if (_get != null) {
      return _get(isolate, id);
    }
    return new Future.value(null);
  }
}

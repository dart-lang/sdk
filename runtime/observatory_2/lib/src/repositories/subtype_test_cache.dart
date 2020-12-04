// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class SubtypeTestCacheRepository extends M.SubtypeTestCacheRepository {
  Future<M.SubtypeTestCache> get(M.IsolateRef i, String id) async {
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    return (await isolate.getObject(id)) as S.SubtypeTestCache;
  }
}

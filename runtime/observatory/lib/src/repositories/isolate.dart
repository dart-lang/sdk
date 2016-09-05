// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class IsolateRepository extends M.IsolateRepository {
  Future<M.Isolate> get(M.IsolateRef i) async{
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    await isolate.reload();
    return isolate;
  }

  Future reloadSources(M.IsolateRef i) async{
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    await isolate.reloadSources();
  }
}

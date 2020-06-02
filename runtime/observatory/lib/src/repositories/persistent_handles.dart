// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class PersistentHandlesRepository implements M.PersistentHandlesRepository {
  Future<M.PersistentHandles> get(M.IsolateRef i) async {
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    final response = await isolate.invokeRpc('_getPersistentHandles', {});
    return new S.PersistentHandles(response as S.ServiceMap);
  }
}

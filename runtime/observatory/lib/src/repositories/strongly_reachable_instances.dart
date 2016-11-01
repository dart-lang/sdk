// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class StronglyReachableInstancesRepository
    implements M.StronglyReachableInstancesRepository {
  Future<M.InstanceSet> get(M.IsolateRef i, M.ClassRef c,
      {int limit: 100}) async {
    S.Isolate isolate = i as S.Isolate;
    S.Class cls = c as S.Class;
    assert(isolate != null);
    assert(cls != null);
    assert(limit != null);
    return (await isolate.getInstances(cls, limit)) as S.InstanceSet;
  }
}

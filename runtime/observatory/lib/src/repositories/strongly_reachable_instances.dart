// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class StronglyReachableInstancesRepository
    implements M.StronglyReachableInstancesRepository {
  Future<M.InstanceSet> get(M.IsolateRef i, M.ClassRef c,
      {int limit = 100}) async {
    S.Isolate isolate = i as S.Isolate;
    S.Class cls = c as S.Class;
    return (await isolate.getInstances(cls, limit)) as S.InstanceSet;
  }

  Future<M.Guarded<M.InstanceRef>> getAsArray(M.IsolateRef i, M.ClassRef c,
      {bool includeSubclasses = false, includeImplementors = false}) async {
    S.Isolate isolate = i as S.Isolate;
    S.Class cls = c as S.Class;
    final response = await isolate.invokeRpc('getInstancesAsList', {
      'objectId': cls.id,
      'includeSubclasses': includeSubclasses,
      'includeImplementers': includeImplementors
    });
    return new S.Guarded<S.Instance>(response);
  }
}

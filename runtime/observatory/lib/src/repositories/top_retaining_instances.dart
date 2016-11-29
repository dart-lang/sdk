// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class TopRetainingInstancesRepository
    implements M.TopRetainingInstancesRepository {
  Future<Iterable<M.RetainingObject>> get(M.IsolateRef i, M.ClassRef c) async {
    S.Isolate isolate = i as S.Isolate;
    S.Class cls = c as S.Class;
    assert(isolate != null);
    assert(cls != null);
    final raw =
        await isolate.fetchHeapSnapshot(M.HeapSnapshotRoots.vm, true).last;
    final snapshot = new HeapSnapshot();
    await snapshot.loadProgress(isolate, raw).last;
    return (await Future.wait(
            snapshot.getMostRetained(isolate, classId: cls.vmCid, limit: 10)))
        .map((object) => new S.RetainingObject(object));
  }
}

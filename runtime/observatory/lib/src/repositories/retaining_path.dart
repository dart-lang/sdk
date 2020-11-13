// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class RetainingPathRepository implements M.RetainingPathRepository {
  Future<M.RetainingPath> get(M.IsolateRef i, String id) async {
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    final response = await isolate
        .invokeRpc('getRetainingPath', {'targetId': id, 'limit': 100});
    return new S.RetainingPath(response as S.ServiceMap);
  }
}

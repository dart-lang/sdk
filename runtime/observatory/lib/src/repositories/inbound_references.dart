// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class InboundReferencesRepository implements M.InboundReferencesRepository {
  Future<M.InboundReferences> get(M.IsolateRef i, String id) async {
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    final response = await isolate
        .invokeRpc('getInboundReferences', {'targetId': id, 'limit': 100});
    return new S.InboundReferences(response as S.ServiceMap);
  }
}

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class PortsRepository implements M.PortsRepository {
  Future<M.Ports> get(M.IsolateRef i) async {
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    final response = await isolate.invokeRpc('_getPorts', {});
    return new S.Ports(response);
  }
}

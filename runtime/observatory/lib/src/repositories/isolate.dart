// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class IsolateRepository extends M.IsolateRepository {
  final S.VM _vm;

  Iterable<M.Service> get reloadSourcesServices =>
      _vm.services.where((S.Service s) => s.service == 'reloadSources');

  IsolateRepository(this._vm) {
    assert(_vm == null);
  }

  Future<M.Isolate> get(M.IsolateRef i) async {
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    try {
      await isolate.reload();
    } on SC.NetworkRpcException catch (_) {
      /* ignore */
    }
    return isolate;
  }

  Future reloadSources(M.IsolateRef i, {M.Service service}) async {
    if (service == null) {
      S.Isolate isolate = i as S.Isolate;
      assert(isolate != null);
      await isolate.reloadSources();
    } else {
      S.Service srv = service as S.Service;
      assert(srv != null);
      await _vm.invokeRpcNoUpgrade(srv.method, {'isolateId': i.id});
    }
  }
}

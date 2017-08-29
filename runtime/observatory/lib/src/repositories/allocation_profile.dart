// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class AllocationProfileRepository implements M.AllocationProfileRepository {
  static const _api = '_getAllocationProfile';
  static const _defaultsApi = '_getDefaultClassesAliases';

  Future<M.AllocationProfile> get(M.IsolateRef i,
      {bool gc: false, bool reset: false, bool combine: true}) async {
    assert(gc != null);
    assert(reset != null);
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    var params = {};
    if (gc) {
      params['gc'] = 'full';
    }
    if (reset) {
      params['reset'] = true;
    }
    final response = await isolate.invokeRpc(_api, params);
    Map defaults;
    if (combine) {
      defaults = await isolate.vm.invokeRpcNoUpgrade(_defaultsApi, {});
      defaults = defaults['map'];
    }
    isolate.updateHeapsFromMap(response['heaps']);
    for (S.ServiceMap clsAllocations in response['members']) {
      S.Class cls = clsAllocations['class'];
      if (cls == null) {
        continue;
      }
      cls.newSpace.update(clsAllocations['new']);
      cls.oldSpace.update(clsAllocations['old']);
    }
    return new AllocationProfile(response, defaults: defaults);
  }
}

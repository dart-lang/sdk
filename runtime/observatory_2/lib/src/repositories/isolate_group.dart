// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class IsolateGroupRepository extends M.IsolateGroupRepository {
  final S.VM _vm;

  IsolateGroupRepository(this._vm) : assert(_vm != null);

  Future<M.IsolateGroup> get(M.IsolateGroupRef i) async {
    S.IsolateGroup isolateGroup = i as S.IsolateGroup;
    assert(isolateGroup != null);
    try {
      await isolateGroup.reload();
    } on SC.NetworkRpcException catch (_) {
      /* ignore */
    }
    return isolateGroup;
  }
}

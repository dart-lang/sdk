// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class IsolateGroupRepository extends M.IsolateGroupRepository {
  IsolateGroupRepository();

  Future<M.IsolateGroup> get(M.IsolateGroupRef i) async {
    S.IsolateGroup isolateGroup = i as S.IsolateGroup;
    try {
      await isolateGroup.reload();
    } on SC.NetworkRpcException catch (_) {
      /* ignore */
    }
    return isolateGroup;
  }
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of repositories;

class VMRepository implements M.VMRepository {
  Future<M.VM> get(M.VMRef ref) async {
    S.VM vm = ref as S.VM;
    assert(vm != null);
    await vm.reload();
    return vm;
  }
}

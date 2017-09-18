// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class TimelineRepository implements M.TimelineRepository {
  Future<M.TimelineFlags> getFlags(M.VMRef ref) async {
    S.VM vm = ref as S.VM;
    S.ServiceMap response = await vm.invokeRpc('_getVMTimelineFlags', {});
    return new S.TimelineFlags(response);
  }

  Future setRecordedStreams(M.VMRef ref, Iterable<M.TimelineStream> streams) {
    S.VM vm = ref as S.VM;
    assert(vm != null);
    return vm.invokeRpc('_setVMTimelineFlags', {
      'recordedStreams': '[${streams.map((s) => s.name).join(', ')}]',
    });
  }

  Future clear(M.VMRef ref) {
    S.VM vm = ref as S.VM;
    return vm.invokeRpc('_clearVMTimeline', {});
  }

  Future<Map<String, dynamic>> getIFrameParams(M.VMRef ref) async {
    final SH.WebSocketVM vm = ref as SH.WebSocketVM;
    assert(vm != null);
    await vm.reload();
    await vm.reloadIsolates();

    return <String, dynamic>{
      'vmAddress': vm.target.networkAddress,
      'isolateIds': vm.isolates.map((i) => i.id).toList()
    };
  }
}

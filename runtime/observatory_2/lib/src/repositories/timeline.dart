// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class TimelineRepository extends TimelineRepositoryBase
    implements M.TimelineRepository {
  static const _kStackFrames = 'stackFrames';
  static const _kTraceEvents = 'traceEvents';

  Future<M.TimelineFlags> getFlags(M.VMRef ref) async {
    S.VM vm = ref as S.VM;
    S.ServiceMap response = await vm.invokeRpc('getVMTimelineFlags', {});
    return new S.TimelineFlags(response);
  }

  Future setRecordedStreams(M.VMRef ref, Iterable<M.TimelineStream> streams) {
    S.VM vm = ref as S.VM;
    assert(vm != null);
    return vm.invokeRpc('setVMTimelineFlags', {
      'recordedStreams': '[${streams.map((s) => s.name).join(', ')}]',
    });
  }

  Future clear(M.VMRef ref) {
    S.VM vm = ref as S.VM;
    return vm.invokeRpc('clearVMTimeline', {});
  }
}

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
    S.ServiceMap response =
        await vm.invokeRpc('getVMTimelineFlags', {}) as S.ServiceMap;
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

  Future<void> _formatSamples(
      M.Isolate isolate, Map traceObject, S.ServiceMap cpuSamples) async {
    const kRootFrameId = 0;
    final profile = SampleProfile();
    await profile.load(isolate as S.ServiceObjectOwner, cpuSamples);
    final trie = profile.loadFunctionTree(M.ProfileTreeDirection.inclusive);
    final root = trie.root;
    int nextId = kRootFrameId;
    processFrame(FunctionCallTreeNode current, FunctionCallTreeNode? parent) {
      int id = nextId;
      ++nextId;
      current.frameId = id;
      // Skip the root.
      if (id != kRootFrameId) {
        final function = current.profileFunction.function;
        final key = '${isolate.id}-$id';
        traceObject[_kStackFrames][key] = {
          'category': 'Dart',
          'name': function.qualifiedName,
          'resolvedUrl': current.profileFunction.resolvedUrl,
          if (parent != null && parent.frameId != kRootFrameId)
            'parent': '${isolate.id}-${parent.frameId}',
        };
      }

      for (final child in current.children) {
        processFrame(child, current);
      }
    }

    processFrame(root, null);

    for (final sample in profile.samples) {
      FunctionCallTreeNode trie = sample[SampleProfile.kTimelineFunctionTrie];

      if (trie.frameId != kRootFrameId) {
        traceObject[_kTraceEvents].add({
          'ph': 'P', // kind = sample event
          'name': '', // Blank to keep about:tracing happy
          'pid': profile.pid,
          'tid': sample['tid'],
          'ts': sample['timestamp'],
          'cat': 'Dart',
          'sf': '${isolate.id}-${trie.frameId}',
        });
      }
    }
  }
}

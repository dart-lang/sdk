// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:observatory_2/sample_profile.dart';
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/service.dart' as S;

class TimelineRepositoryBase {
  static const _kStackFrames = 'stackFrames';
  static const _kTraceEvents = 'traceEvents';
  static const kTimeOriginMicros = 'timeOriginMicros';
  static const kTimeExtentMicros = 'timeExtentMicros';

  Future<void> _formatSamples(M.Isolate isolate, Map traceObject,
      Future<S.ServiceObject> cpuSamples) async {
    const kRootFrameId = 0;
    final profile = SampleProfile();
    await profile.load(isolate as S.ServiceObjectOwner, await cpuSamples);
    final trie = profile.loadFunctionTree(M.ProfileTreeDirection.inclusive);
    final root = trie.root;
    int nextId = kRootFrameId;
    processFrame(FunctionCallTreeNode current, FunctionCallTreeNode parent) {
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

  Future<Map> getCpuProfileTimeline(M.VMRef ref,
      {int timeOriginMicros, int timeExtentMicros}) async {
    final S.VM vm = ref as S.VM;
    final traceObject = <String, dynamic>{
      _kStackFrames: {},
      _kTraceEvents: [],
    };

    await Future.wait(vm.isolates.map((isolate) {
      final samples = vm.invokeRpc('getCpuSamples', {
        'isolateId': isolate.id,
        if (timeOriginMicros != null) kTimeOriginMicros: timeOriginMicros,
        if (timeExtentMicros != null) kTimeExtentMicros: timeExtentMicros,
      });
      return _formatSamples(isolate, traceObject, samples);
    }));

    return traceObject;
  }

  Future<Map> getTimeline(M.VMRef ref) async {
    final S.VM vm = ref as S.VM;
    final S.ServiceMap vmTimelineResponse =
        await vm.invokeRpc('getVMTimeline', {});
    final timeOriginMicros = vmTimelineResponse[kTimeOriginMicros];
    final timeExtentMicros = vmTimelineResponse[kTimeExtentMicros];
    var traceObject = <String, dynamic>{
      _kStackFrames: {},
      _kTraceEvents: [],
    };
    try {
      final cpuProfile = await getCpuProfileTimeline(
        vm,
        timeOriginMicros: timeOriginMicros,
        timeExtentMicros: timeExtentMicros,
      );
      traceObject = cpuProfile;
    } on S.ServerRpcException catch (e) {
      if (e.code != S.ServerRpcException.kFeatureDisabled) {
        rethrow;
      }
      Logger.root.info(
          "CPU profiler is disabled. Creating timeline without CPU profile.");
    }
    traceObject[_kTraceEvents].addAll(vmTimelineResponse[_kTraceEvents]);
    return traceObject;
  }
}

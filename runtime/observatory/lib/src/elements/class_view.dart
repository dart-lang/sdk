// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library class_view_element;

import 'dart:async';
import 'observatory_element.dart';
import 'sample_buffer_control.dart';
import 'stack_trace_tree_config.dart';
import 'cpu_profile/virtual_tree.dart';
import 'package:observatory/heap_snapshot.dart';
import 'package:observatory/elements.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service.dart';
import 'package:observatory/repositories.dart';
import 'package:polymer/polymer.dart';

@CustomTag('class-view')
class ClassViewElement extends ObservatoryElement {
  @published Class cls;
  @observable ServiceMap instances;
  @observable int reachableBytes;
  @observable int retainedBytes;
  @observable ObservableList mostRetained;
  SampleBufferControlElement sampleBufferControlElement;
  StackTraceTreeConfigElement stackTraceTreeConfigElement;
  CpuProfileVirtualTreeElement cpuProfileTreeElement;
  ClassSampleProfileRepository repository = new ClassSampleProfileRepository();


  ClassViewElement.created() : super.created();

  Future<ServiceObject> evaluate(String expression) {
    return cls.evaluate(expression);
  }

  Future<ServiceObject> reachable(var limit) {
    return cls.isolate.getInstances(cls, limit).then((ServiceMap obj) {
      instances = obj;
    });
  }

  Future retainedToplist(var limit) async {
      final raw = await cls.isolate.fetchHeapSnapshot(true).last;
      final snapshot = new HeapSnapshot();
      await snapshot.loadProgress(cls.isolate, raw).last;
      final most = await Future.wait(snapshot.getMostRetained(cls.isolate,
                                                              classId: cls.vmCid,
                                                              limit: 10));
      mostRetained = new ObservableList.from(most);
  }

  // TODO(koda): Add no-arg "calculate-link" instead of reusing "eval-link".
  Future<ServiceObject> reachableSize(var dummy) {
    return cls.isolate.getReachableSize(cls).then((Instance obj) {
      reachableBytes = int.parse(obj.valueAsString);
    });
  }

  Future<ServiceObject> retainedSize(var dummy) {
    return cls.isolate.getRetainedSize(cls).then((Instance obj) {
      retainedBytes = int.parse(obj.valueAsString);
    });
  }

  void attached() {
    super.attached();
    cls.fields.forEach((field) => field.reload());
  }

  Future refresh() async {
    instances = null;
    retainedBytes = null;
    mostRetained = null;
    await cls.reload();
    await Future.wait(cls.fields.map((field) => field.reload()));
  }

  M.SampleProfileTag _tag = M.SampleProfileTag.none;

  Future refreshAllocationProfile() async {
    shadowRoot.querySelector('#sampleBufferControl').children = const [];
    shadowRoot.querySelector('#stackTraceTreeConfig').children = const [];
    shadowRoot.querySelector('#cpuProfileTree').children = const [];
    final stream = repository.get(cls, _tag);
    var progress = (await stream.first).progress;
    shadowRoot.querySelector('#sampleBufferControl')..children = [
      new SampleBufferControlElement(progress, stream, queue: app.queue,
          selectedTag: _tag)
        ..onTagChange.listen((e) {
          _tag = e.element.selectedTag;
          refreshAllocationProfile();
        })
    ];
    if (M.isSampleProcessRunning(progress.status)) {
      progress = (await stream.last).progress;
    }
    if (progress.status == M.SampleProfileLoadingStatus.loaded) {
      shadowRoot.querySelector('#stackTraceTreeConfig')..children = [
        new StackTraceTreeConfigElement(
          queue: app.queue)
          ..showFilter = false
          ..onModeChange.listen((e) {
            cpuProfileTreeElement.mode = e.element.mode;
          })
          ..onDirectionChange.listen((e) {
            cpuProfileTreeElement.direction = e.element.direction;
          })
      ];
      shadowRoot.querySelector('#cpuProfileTree')..children = [
        cpuProfileTreeElement = new CpuProfileVirtualTreeElement(cls.isolate,
          progress.profile, queue: app.queue)
      ];
    }
  }

  Future toggleAllocationTrace() {
    if (cls == null) {
      return new Future(refresh);
    }
    if (cls.traceAllocations) {
      refreshAllocationProfile();
    }
    return cls.setTraceAllocations(!cls.traceAllocations).whenComplete(refresh);
  }
}

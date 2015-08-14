// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library class_view_element;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/cpu_profile.dart';
import 'package:observatory/elements.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('class-view')
class ClassViewElement extends ObservatoryElement {
  @published Class cls;
  @observable ServiceMap instances;
  @observable int retainedBytes;
  @observable ObservableList mostRetained;
  SampleBufferControlElement sampleBufferControlElement;
  StackTraceTreeConfigElement stackTraceTreeConfigElement;
  CpuProfileTreeElement cpuProfileTreeElement;

  ClassViewElement.created() : super.created();

  Future<ServiceObject> evaluate(String expression) {
    return cls.evaluate(expression);
  }

  Future<ServiceObject> reachable(var limit) {
    return cls.isolate.getInstances(cls, limit).then((ServiceMap obj) {
      instances = obj;
    });
  }

  Future<ServiceObject> retainedToplist(var limit) {
    return cls.isolate.fetchHeapSnapshot().last
      .then((HeapSnapshot snapshot) =>
          Future.wait(snapshot.getMostRetained(classId: cls.vmCid,
                                               limit: 10)))
      .then((List<ServiceObject> most) {
        mostRetained = new ObservableList.from(most);
      });
  }

  // TODO(koda): Add no-arg "calculate-link" instead of reusing "eval-link".
  Future<ServiceObject> retainedSize(var dummy) {
    return cls.isolate.getRetainedSize(cls).then((Instance obj) {
      retainedBytes = int.parse(obj.valueAsString);
    });
  }

  void attached() {
    super.attached();
    sampleBufferControlElement =
        shadowRoot.querySelector('#sampleBufferControl');
    assert(sampleBufferControlElement != null);
    sampleBufferControlElement.onSampleBufferUpdate = onSampleBufferChange;
    sampleBufferControlElement.state =
        SampleBufferControlElement.kNotLoadedState;
    stackTraceTreeConfigElement =
        shadowRoot.querySelector('#stackTraceTreeConfig');
    assert(stackTraceTreeConfigElement != null);
    stackTraceTreeConfigElement.onTreeConfigChange = onTreeConfigChange;
    stackTraceTreeConfigElement.show = false;
    cpuProfileTreeElement = shadowRoot.querySelector('#cpuProfileTree');
    assert(cpuProfileTreeElement != null);
    cpuProfileTreeElement.profile = sampleBufferControlElement.profile;
    cpuProfileTreeElement.show = false;
    cls.fields.forEach((field) => field.reload());
    sampleBufferControlElement.allocationProfileClass = cls;
  }

  Future refresh() {
    instances = null;
    retainedBytes = null;
    mostRetained = null;
    var loads = [];
    loads.add(cls.reload());
    cls.fields.forEach((field) => loads.add(field.reload()));
    return Future.wait(loads);
  }

  Future refreshCoverage() {
    return cls.refreshCoverage();
  }

  onSampleBufferChange(CpuProfile sampleBuffer) {
    stackTraceTreeConfigElement.show = sampleBuffer.sampleCount > 0;
    cpuProfileTreeElement.show = sampleBuffer.sampleCount > 0;
    cpuProfileTreeElement.render();
  }

  onTreeConfigChange(String modeSelector, String directionSelector) {
    ProfileTreeDirection direction = ProfileTreeDirection.Exclusive;
    if (directionSelector != 'Up') {
      direction = ProfileTreeDirection.Inclusive;
    }
    ProfileTreeMode mode = ProfileTreeMode.Function;
    if (modeSelector == 'Code') {
      mode = ProfileTreeMode.Code;
    }
    cpuProfileTreeElement.direction = direction;
    cpuProfileTreeElement.mode = mode;
    cpuProfileTreeElement.render();
  }

  Future refreshAllocationProfile() async {
    return sampleBufferControlElement.reload(cls.isolate);
  }

  Future toggleAllocationTrace() {
    if (cls == null) {
      return new Future(refresh);
    }
    return cls.setTraceAllocations(!cls.traceAllocations).whenComplete(refresh);
  }
}

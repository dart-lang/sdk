// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/cpu_profile/virtual_tree.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/sample_buffer_control.dart';
import 'package:observatory/src/elements/stack_trace_tree_config.dart';

class ClassAllocationProfileElement extends CustomElement
    implements Renderable {
  late RenderingScheduler<ClassAllocationProfileElement> _r;

  Stream<RenderedEvent<ClassAllocationProfileElement>> get onRendered =>
      _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.Class _cls;
  late M.ClassSampleProfileRepository _profiles;
  late Stream<M.SampleProfileLoadingProgressEvent> _progressStream;
  M.SampleProfileLoadingProgress? _progress;
  late M.SampleProfileTag _tag = M.SampleProfileTag.none;
  late ProfileTreeMode _mode = ProfileTreeMode.function;
  late M.ProfileTreeDirection _direction = M.ProfileTreeDirection.exclusive;

  M.IsolateRef get isolate => _isolate;
  M.Class get cls => _cls;

  factory ClassAllocationProfileElement(M.VM vm, M.IsolateRef isolate,
      M.Class cls, M.ClassSampleProfileRepository profiles,
      {RenderingQueue? queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(cls != null);
    assert(profiles != null);
    ClassAllocationProfileElement e =
        new ClassAllocationProfileElement.created();
    e._r =
        new RenderingScheduler<ClassAllocationProfileElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._cls = cls;
    e._profiles = profiles;
    return e;
  }

  ClassAllocationProfileElement.created()
      : super.created('class-allocation-profile');

  @override
  void attached() {
    super.attached();
    _r.enable();
    _request();
  }

  @override
  void detached() {
    super.detached();
    children = <Element>[];
    _r.disable(notify: true);
  }

  void render() {
    if (_progress == null) {
      children = const [];
      return;
    }
    final content = <HtmlElement>[
      (new SampleBufferControlElement(_vm, _progress!, _progressStream,
              selectedTag: _tag, queue: _r.queue)
            ..onTagChange.listen((e) {
              _tag = e.element.selectedTag;
              _request(forceFetch: true);
            }))
          .element
    ];
    if (_progress!.status == M.SampleProfileLoadingStatus.loaded) {
      late CpuProfileVirtualTreeElement tree;
      content.addAll([
        new BRElement(),
        (new StackTraceTreeConfigElement(
                mode: _mode,
                direction: _direction,
                showFilter: false,
                queue: _r.queue)
              ..onModeChange.listen((e) {
                _mode = tree.mode = e.element.mode;
              })
              ..onDirectionChange.listen((e) {
                _direction = tree.direction = e.element.direction;
              }))
            .element,
        new BRElement(),
        (tree = new CpuProfileVirtualTreeElement(_isolate, _progress!.profile,
                queue: _r.queue))
            .element
      ]);
    }
    children = content;
  }

  Future _request({bool forceFetch: false}) async {
    _progress = null;
    _progressStream =
        _profiles.get(_isolate, _cls, _tag, forceFetch: forceFetch);
    _r.dirty();
    _progress = (await _progressStream.first).progress;
    _r.dirty();
    if (M.isSampleProcessRunning(_progress!.status)) {
      _progress = (await _progressStream.last).progress;
      _r.dirty();
    }
  }
}

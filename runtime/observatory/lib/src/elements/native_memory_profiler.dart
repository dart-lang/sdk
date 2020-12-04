// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library native_memory_profile;

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/cpu_profile/virtual_tree.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/sample_buffer_control.dart';
import 'package:observatory/src/elements/stack_trace_tree_config.dart';

class NativeMemoryProfileElement extends CustomElement implements Renderable {
  late RenderingScheduler<NativeMemoryProfileElement> _r;

  Stream<RenderedEvent<NativeMemoryProfileElement>> get onRendered =>
      _r.onRendered;

  late M.VM _vm;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.NativeMemorySampleProfileRepository _profiles;
  Stream<M.SampleProfileLoadingProgressEvent>? _progressStream;
  M.SampleProfileLoadingProgress? _progress;
  late M.SampleProfileTag _tag = M.SampleProfileTag.none;
  late ProfileTreeMode _mode = ProfileTreeMode.function;
  late M.ProfileTreeDirection _direction = M.ProfileTreeDirection.exclusive;
  late String _filter = '';

  M.NotificationRepository get notifications => _notifications;
  M.NativeMemorySampleProfileRepository get profiles => _profiles;

  factory NativeMemoryProfileElement(
      M.VM vm,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.NativeMemorySampleProfileRepository profiles,
      {RenderingQueue? queue}) {
    assert(vm != null);
    assert(events != null);
    assert(notifications != null);
    assert(profiles != null);
    NativeMemoryProfileElement e = new NativeMemoryProfileElement.created();
    e._r = new RenderingScheduler<NativeMemoryProfileElement>(e, queue: queue);
    e._vm = vm;
    e._events = events;
    e._notifications = notifications;
    e._profiles = profiles;
    return e;
  }

  NativeMemoryProfileElement.created() : super.created('native-memory-profile');

  @override
  attached() {
    super.attached();
    _r.enable();
    _request();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = <Element>[];
  }

  void render() {
    var content = <Element>[
      navBar(<Element>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        navMenu('native memory profile', link: Uris.nativeMemory()),
        (new NavRefreshElement(queue: _r.queue)..onRefresh.listen(_refresh))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
    ];
    if (_progress == null) {
      children = content;
      return;
    }
    content.add((new SampleBufferControlElement(
            _vm, _progress!, _progressStream!,
            selectedTag: _tag, queue: _r.queue)
          ..onTagChange.listen((e) {
            _tag = e.element.selectedTag;
            _request();
          }))
        .element);
    if (_progress!.status == M.SampleProfileLoadingStatus.loaded) {
      late CpuProfileVirtualTreeElement tree;
      content.addAll([
        new BRElement(),
        (new StackTraceTreeConfigElement(
                mode: _mode,
                direction: _direction,
                filter: _filter,
                queue: _r.queue)
              ..onModeChange.listen((e) {
                _mode = tree.mode = e.element.mode;
              })
              ..onFilterChange.listen((e) {
                _filter = e.element.filter.trim();
                tree.filters = _filter.isNotEmpty
                    ? [
                        (node) {
                          return node.name.contains(_filter);
                        }
                      ]
                    : const [];
              })
              ..onDirectionChange.listen((e) {
                _direction = tree.direction = e.element.direction;
              }))
            .element,
        new BRElement(),
        (tree = new CpuProfileVirtualTreeElement(null, _progress!.profile,
                queue: _r.queue, type: M.SampleProfileType.memory))
            .element,
      ]);
    }
    children = content;
  }

  Future _request({bool forceFetch: false}) async {
    if (forceFetch) {
      for (M.IsolateRef isolate in _vm.isolates) {
        await isolate.collectAllGarbage();
      }
    }
    _progress = null;
    _progressStream = _profiles.get(_vm, _tag, forceFetch: forceFetch);
    _r.dirty();
    _progress = (await _progressStream!.first).progress;
    _r.dirty();
    if (M.isSampleProcessRunning(_progress!.status)) {
      _progress = (await _progressStream!.last).progress;
      _r.dirty();
    }
  }

  Future _refresh(e) async {
    e.element.disabled = true;
    await _request(forceFetch: true);
    e.element.disabled = false;
  }
}

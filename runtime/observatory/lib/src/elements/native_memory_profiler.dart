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
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/sample_buffer_control.dart';
import 'package:observatory/src/elements/stack_trace_tree_config.dart';

class NativeMemoryProfileElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NativeMemoryProfileElement>(
      'native-memory-profile',
      dependencies: const [
        NavTopMenuElement.tag,
        NavVMMenuElement.tag,
        NavRefreshElement.tag,
        NavNotifyElement.tag,
        SampleBufferControlElement.tag,
        StackTraceTreeConfigElement.tag,
        CpuProfileVirtualTreeElement.tag,
      ]);

  RenderingScheduler<NativeMemoryProfileElement> _r;

  Stream<RenderedEvent<NativeMemoryProfileElement>> get onRendered =>
      _r.onRendered;

  M.VM _vm;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.NativeMemorySampleProfileRepository _profiles;
  Stream<M.SampleProfileLoadingProgressEvent> _progressStream;
  M.SampleProfileLoadingProgress _progress;
  M.SampleProfileTag _tag = M.SampleProfileTag.none;
  ProfileTreeMode _mode = ProfileTreeMode.function;
  M.ProfileTreeDirection _direction = M.ProfileTreeDirection.exclusive;
  String _filter = '';

  M.NotificationRepository get notifications => _notifications;
  M.NativeMemorySampleProfileRepository get profiles => _profiles;

  factory NativeMemoryProfileElement(
      M.VM vm,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.NativeMemorySampleProfileRepository profiles,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(events != null);
    assert(notifications != null);
    assert(profiles != null);
    NativeMemoryProfileElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._events = events;
    e._notifications = notifications;
    e._profiles = profiles;
    return e;
  }

  NativeMemoryProfileElement.created() : super.created();

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
    children = [];
  }

  void render() {
    var content = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavVMMenuElement(_vm, _events, queue: _r.queue),
        navMenu('native memory profile', link: Uris.nativeMemory()),
        new NavRefreshElement(queue: _r.queue)..onRefresh.listen(_refresh),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
    ];
    if (_progress == null) {
      children = content;
      return;
    }
    content.add(new SampleBufferControlElement(_vm, _progress, _progressStream,
        selectedTag: _tag, queue: _r.queue)
      ..onTagChange.listen((e) {
        _tag = e.element.selectedTag;
        _request(forceFetch: true);
      }));
    if (_progress.status == M.SampleProfileLoadingStatus.loaded) {
      CpuProfileVirtualTreeElement tree;
      content.addAll([
        new BRElement(),
        new StackTraceTreeConfigElement(
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
          }),
        new BRElement(),
        tree = new CpuProfileVirtualTreeElement(_vm, _progress.profile,
            queue: _r.queue, type: M.SampleProfileType.memory)
      ]);
    }
    children = content;
  }

  Future _request({bool forceFetch: false}) async {
    for (M.Isolate isolate in _vm.isolates) {
      await isolate.collectAllGarbage();
    }
    _progress = null;
    _progressStream = _profiles.get(_vm, _tag, forceFetch: forceFetch);
    _r.dirty();
    _progress = (await _progressStream.first).progress;
    _r.dirty();
    if (M.isSampleProcessRunning(_progress.status)) {
      _progress = (await _progressStream.last).progress;
      _r.dirty();
    }
  }

  Future _refresh(e) async {
    e.element.disabled = true;
    await _request(forceFetch: true);
    e.element.disabled = false;
  }
}

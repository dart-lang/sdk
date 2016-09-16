// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cpu_profile_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/cpu_profile/virtual_tree.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/sample_buffer_control.dart';
import 'package:observatory/src/elements/stack_trace_tree_config.dart';

class CpuProfileElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<CpuProfileElement>('cpu-profile', dependencies: const [
    NavTopMenuElement.tag,
    NavVMMenuElement.tag,
    NavIsolateMenuElement.tag,
    NavRefreshElement.tag,
    NavNotifyElement.tag,
    SampleBufferControlElement.tag,
    StackTraceTreeConfigElement.tag,
    CpuProfileVirtualTreeElement.tag,
  ]);

  RenderingScheduler<CpuProfileElement> _r;

  Stream<RenderedEvent<CpuProfileElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.IsolateSampleProfileRepository _profiles;
  Stream<M.SampleProfileLoadingProgressEvent> _progressStream;
  M.SampleProfileLoadingProgress _progress;
  M.SampleProfileTag _tag = M.SampleProfileTag.none;
  ProfileTreeMode _mode = ProfileTreeMode.function;
  M.ProfileTreeDirection _direction = M.ProfileTreeDirection.exclusive;
  String _filter = '';

  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.IsolateSampleProfileRepository get profiles => _profiles;
  M.VMRef get vm => _vm;

  factory CpuProfileElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.IsolateSampleProfileRepository profiles,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(profiles != null);
    CpuProfileElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._profiles = profiles;
    return e;
  }

  CpuProfileElement.created() : super.created();

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
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue),
        navMenu('cpu profile', link: Uris.cpuProfiler(_isolate)),
        new NavRefreshElement(queue: _r.queue)..onRefresh.listen(_refresh),
        new NavRefreshElement(label: 'Clear', queue: _r.queue)
          ..onRefresh.listen(_clearCpuProfile),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
    ];
    if (_progress == null) {
      children = content;
      return;
    }
    content.add(new SampleBufferControlElement(_progress, _progressStream,
        selectedTag: _tag, queue: _r.queue)
      ..onTagChange.listen((e) {
        _tag = e.element.selectedTag;
        _request();
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
        tree = new CpuProfileVirtualTreeElement(_isolate, _progress.profile,
            queue: _r.queue)
      ]);
    }
    children = content;
  }

  Future _request({bool clear: false, bool forceFetch: false}) async {
    _progress = null;
    _progressStream =
        _profiles.get(isolate, _tag, clear: clear, forceFetch: forceFetch);
    _r.dirty();
    _progress = (await _progressStream.first).progress;
    _r.dirty();
    if (M.isSampleProcessRunning(_progress.status)) {
      _progress = (await _progressStream.last).progress;
      _r.dirty();
    }
  }

  Future _clearCpuProfile(RefreshEvent e) async {
    e.element.disabled = true;
    await _request(clear: true);
    e.element.disabled = false;
  }

  Future _refresh(e) async {
    e.element.disabled = true;
    await _request(forceFetch: true);
    e.element.disabled = false;
  }
}

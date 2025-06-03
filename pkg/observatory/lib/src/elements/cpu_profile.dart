// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cpu_profile_element;

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'cpu_profile/virtual_tree.dart';
import 'helpers/custom_element.dart';
import 'helpers/nav_bar.dart';
import 'helpers/nav_menu.dart';
import 'helpers/rendering_scheduler.dart';
import 'helpers/uris.dart';
import 'nav/isolate_menu.dart';
import 'nav/notify.dart';
import 'nav/refresh.dart';
import 'nav/top_menu.dart';
import 'nav/vm_menu.dart';
import 'sample_buffer_control.dart';
import 'stack_trace_tree_config.dart';

class CpuProfileElement extends CustomElement implements Renderable {
  late RenderingScheduler<CpuProfileElement> _r;

  Stream<RenderedEvent<CpuProfileElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.IsolateSampleProfileRepository _profiles;
  late Stream<M.SampleProfileLoadingProgressEvent> _progressStream;
  M.SampleProfileLoadingProgress? _progress;
  late M.SampleProfileTag _tag = M.SampleProfileTag.none;
  late ProfileTreeMode _mode = ProfileTreeMode.function;
  late M.ProfileTreeDirection _direction = M.ProfileTreeDirection.exclusive;
  late String _filter = '';

  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.IsolateSampleProfileRepository get profiles => _profiles;
  M.VMRef get vm => _vm;

  factory CpuProfileElement(
    M.VM vm,
    M.IsolateRef isolate,
    M.EventRepository events,
    M.NotificationRepository notifications,
    M.IsolateSampleProfileRepository profiles, {
    RenderingQueue? queue,
  }) {
    CpuProfileElement e = new CpuProfileElement.created();
    e._r = new RenderingScheduler<CpuProfileElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._profiles = profiles;
    return e;
  }

  CpuProfileElement.created() : super.created('cpu-profile');

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
    removeChildren();
  }

  void render() {
    var content = <HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu('cpu profile', link: Uris.cpuProfiler(_isolate)),
        (new NavRefreshElement(
          queue: _r.queue,
        )..onRefresh.listen(_refresh)).element,
        (new NavRefreshElement(
          label: 'Clear',
          queue: _r.queue,
        )..onRefresh.listen(_clearCpuProfile)).element,
        new NavNotifyElement(_notifications, queue: _r.queue).element,
      ]),
    ];
    if (_progress == null) {
      setChildren(content);
      return;
    }
    content.add(
      (new SampleBufferControlElement(
              _vm,
              _progress!,
              _progressStream,
              selectedTag: _tag,
              queue: _r.queue,
            )
            ..onTagChange.listen((e) {
              _tag = e.element.selectedTag;
              _request();
            }))
          .element,
    );
    if (_progress!.status == M.SampleProfileLoadingStatus.loaded) {
      late CpuProfileVirtualTreeElement tree;
      content.addAll([
        new HTMLBRElement(),
        (new StackTraceTreeConfigElement(
                mode: _mode,
                direction: _direction,
                filter: _filter,
                queue: _r.queue,
              )
              ..onModeChange.listen((e) {
                _mode = tree.mode = e.element.mode;
              })
              ..onFilterChange.listen((e) {
                _filter = e.element.filter.trim();
                tree.filters = _filter.isNotEmpty
                    ? [
                        (node) {
                          return node.name.contains(_filter);
                        },
                      ]
                    : const [];
              })
              ..onDirectionChange.listen((e) {
                _direction = tree.direction = e.element.direction;
              }))
            .element,
        new HTMLBRElement(),
        (tree = new CpuProfileVirtualTreeElement(
          _isolate,
          _progress!.profile,
          queue: _r.queue,
        )).element,
      ]);
    }
    setChildren(content);
  }

  Future _request({bool clear = false, bool forceFetch = false}) async {
    _progress = null;
    _progressStream = _profiles.get(
      isolate,
      _tag,
      clear: clear,
      forceFetch: forceFetch,
    );
    _r.dirty();
    _progress = (await _progressStream.first).progress;
    _r.dirty();
    if (M.isSampleProcessRunning(_progress!.status)) {
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

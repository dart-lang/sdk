// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This page is not directly reachable from the main Observatory ui.
/// It is mainly mented to be used from editors as an integrated tool.
///
/// This page mainly targeting developers and not VM experts, so concepts like
/// old and new heap are abstracted away.
///
/// The page comprises an overall memory usage of the VM from where it is
/// possible to select an isolate to deeply analyze.
/// See MemoryGraphElement
///
/// Once an isolate is selected it is possible to information specific to it.
/// See MemoryProfileElement
///
/// The logic in this Element is mainly mented to orchestrate the two
/// sub-components by means of positioning and message passing.

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/memory/graph.dart';
import 'package:observatory/src/elements/memory/profile.dart';

class MemoryDashboardElement extends HtmlElement implements Renderable {
  static const tag = const Tag<MemoryDashboardElement>('memory-dashboard',
      dependencies: const [
        NavNotifyElement.tag,
        MemoryGraphElement.tag,
        MemoryProfileElement.tag,
      ]);

  RenderingScheduler<MemoryDashboardElement> _r;

  Stream<RenderedEvent<MemoryDashboardElement>> get onRendered => _r.onRendered;

  M.VMRef _vm;
  M.VMRepository _vms;
  M.IsolateRepository _isolates;
  M.EditorRepository _editor;
  M.AllocationProfileRepository _allocations;
  M.HeapSnapshotRepository _snapshots;
  M.ObjectRepository _objects;
  M.EventRepository _events;
  M.NotificationRepository _notifications;

  M.VMRef get vm => _vm;
  M.NotificationRepository get notifications => _notifications;

  factory MemoryDashboardElement(
      M.VMRef vm,
      M.VMRepository vms,
      M.IsolateRepository isolates,
      M.EditorRepository editor,
      M.AllocationProfileRepository allocations,
      M.HeapSnapshotRepository snapshots,
      M.ObjectRepository objects,
      M.EventRepository events,
      M.NotificationRepository notifications,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(vms != null);
    assert(isolates != null);
    assert(editor != null);
    assert(allocations != null);
    assert(events != null);
    assert(notifications != null);
    MemoryDashboardElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._vms = vms;
    e._isolates = isolates;
    e._editor = editor;
    e._allocations = allocations;
    e._snapshots = snapshots;
    e._objects = objects;
    e._events = events;
    e._notifications = notifications;
    return e;
  }

  MemoryDashboardElement.created() : super.created();

  @override
  attached() {
    super.attached();
    _r.enable();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  M.IsolateRef _isolate;

  MemoryGraphElement _graph;

  void render() {
    if (_graph == null) {
      _graph =
          new MemoryGraphElement(vm, _vms, _isolates, _events, queue: _r.queue)
            ..onIsolateSelected.listen(_onIsolateSelected);
    }
    children = [
      navBar([new NavNotifyElement(_notifications, queue: _r.queue)]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new HeadingElement.h2()..text = 'Memory Dashboard',
          new HRElement(),
          _graph,
          new HRElement(),
        ],
    ];
    if (_isolate == null) {
      children.add(new DivElement()
        ..classes = ['content-centered-big']
        ..children = [new HeadingElement.h1()..text = "No isolate selected"]);
    } else {
      children.add(new MemoryProfileElement(
          _isolate, _editor, _allocations, _snapshots, _objects));
    }
  }

  void _onIsolateSelected(IsolateSelectedEvent e) {
    _isolate = _r.checkAndReact(_isolate, e.isolate);
  }
}

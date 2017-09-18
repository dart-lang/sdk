// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This Element is part of MemoryDashboardElement.
///
/// The Element is stripped down version of AllocationProfileElement where
/// concepts like old and new space has been hidden away.
///
/// For each class in the system it is shown the Total number of instances
/// alive, the Total memory used by these instances, the number of instances
/// created since the last reset, the memory used by these instances.
///
/// When a GC event is received the profile is reloaded.

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/memory/allocations.dart';
import 'package:observatory/src/elements/memory/snapshot.dart';

enum _Analysis { allocations, dominatorTree }

class MemoryProfileElement extends HtmlElement implements Renderable {
  static const tag = const Tag<MemoryProfileElement>('memory-profile',
      dependencies: const [
        MemoryAllocationsElement.tag,
        MemorySnapshotElement.tag
      ]);

  RenderingScheduler<MemoryProfileElement> _r;

  Stream<RenderedEvent<MemoryProfileElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.AllocationProfileRepository _allocations;
  M.EditorRepository _editor;
  M.HeapSnapshotRepository _snapshots;
  M.ObjectRepository _objects;

  _Analysis _analysis = _Analysis.allocations;

  M.IsolateRef get isolate => _isolate;

  factory MemoryProfileElement(
      M.IsolateRef isolate,
      M.EditorRepository editor,
      M.AllocationProfileRepository allocations,
      M.HeapSnapshotRepository snapshots,
      M.ObjectRepository objects,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(editor != null);
    assert(allocations != null);
    assert(snapshots != null);
    assert(objects != null);
    MemoryProfileElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._editor = editor;
    e._allocations = allocations;
    e._snapshots = snapshots;
    e._objects = objects;
    return e;
  }

  MemoryProfileElement.created() : super.created();

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

  void render() {
    HtmlElement current;
    var reload;
    switch (_analysis) {
      case _Analysis.allocations:
        final MemoryAllocationsElement allocations =
            new MemoryAllocationsElement(_isolate, _editor, _allocations);
        current = allocations;
        reload = ({bool gc: false}) => allocations.reload(gc: gc);
        break;
      case _Analysis.dominatorTree:
        final MemorySnapshotElement snapshot =
            new MemorySnapshotElement(_isolate, _editor, _snapshots, _objects);
        current = snapshot;
        reload = ({bool gc: false}) => snapshot.reload(gc: gc);
        break;
    }

    assert(current != null);

    final ButtonElement bReload = new ButtonElement();
    final ButtonElement bGC = new ButtonElement();
    children = [
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new HeadingElement.h1()
            ..children = [
              new Text(_isolate.name),
              bReload
                ..classes = ['header_button']
                ..text = ' ↺ Refresh'
                ..title = 'Refresh'
                ..onClick.listen((e) async {
                  bReload.disabled = true;
                  bGC.disabled = true;
                  await reload();
                  bReload.disabled = false;
                  bGC.disabled = false;
                }),
              bGC
                ..classes = ['header_button']
                ..text = ' ♺ Collect Garbage'
                ..title = 'Collect Garbage'
                ..onClick.listen((e) async {
                  bGC.disabled = true;
                  bReload.disabled = true;
                  await reload(gc: true);
                  bGC.disabled = false;
                  bReload.disabled = false;
                }),
              new SpanElement()
                ..classes = ['tab_buttons']
                ..children = [
                  new ButtonElement()
                    ..text = 'Allocations'
                    ..disabled = _analysis == _Analysis.allocations
                    ..onClick.listen((_) {
                      _analysis = _Analysis.allocations;
                      _r.dirty();
                    }),
                  new ButtonElement()
                    ..text = 'Dominator Tree'
                    ..disabled = _analysis == _Analysis.dominatorTree
                    ..onClick.listen((_) {
                      _analysis = _Analysis.dominatorTree;
                      _r.dirty();
                    }),
                ]
            ],
        ],
      current
    ];
  }
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:math' as Math;
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/containers/virtual_tree.dart';
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/utils.dart';

class MemorySnapshotElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<MemorySnapshotElement>('memory-snapshot', dependencies: const [
    ClassRefElement.tag,
    VirtualTreeElement.tag,
  ]);

  RenderingScheduler<MemorySnapshotElement> _r;

  Stream<RenderedEvent<MemorySnapshotElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.EditorRepository _editor;
  M.HeapSnapshotRepository _snapshots;
  M.ObjectRepository _objects;
  M.HeapSnapshot _snapshot;
  Stream<M.HeapSnapshotLoadingProgressEvent> _progressStream;
  M.HeapSnapshotLoadingProgress _progress;

  M.IsolateRef get isolate => _isolate;

  factory MemorySnapshotElement(M.IsolateRef isolate, M.EditorRepository editor,
      M.HeapSnapshotRepository snapshots, M.ObjectRepository objects,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(editor != null);
    assert(snapshots != null);
    assert(objects != null);
    MemorySnapshotElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._editor = editor;
    e._snapshots = snapshots;
    e._objects = objects;
    return e;
  }

  MemorySnapshotElement.created() : super.created();

  @override
  attached() {
    super.attached();
    _r.enable();
    _refresh();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  void render() {
    if (_progress == null) {
      children = const [];
      return;
    }
    List<HtmlElement> content;
    switch (_progress.status) {
      case M.HeapSnapshotLoadingStatus.fetching:
        content = _createStatusMessage('Fetching snapshot from VM...',
            description: _progress.stepDescription,
            progress: _progress.progress);
        break;
      case M.HeapSnapshotLoadingStatus.loading:
        content = _createStatusMessage('Loading snapshot...',
            description: _progress.stepDescription,
            progress: _progress.progress);
        break;
      case M.HeapSnapshotLoadingStatus.loaded:
        content = _createReport();
        break;
    }
    children = content;
  }

  Future reload({bool gc: false}) => _refresh(gc: gc);

  Future _refresh({bool gc: false}) async {
    _progress = null;
    _progressStream =
        _snapshots.get(isolate, roots: M.HeapSnapshotRoots.user, gc: gc);
    _r.dirty();
    _progressStream.listen((e) {
      _progress = e.progress;
      _r.dirty();
    });
    _progress = (await _progressStream.first).progress;
    _r.dirty();
    if (M.isHeapSnapshotProgressRunning(_progress.status)) {
      _progress = (await _progressStream.last).progress;
      _snapshot = _progress.snapshot;
      _r.dirty();
    }
  }

  static List<Element> _createStatusMessage(String message,
      {String description: '', double progress: 0.0}) {
    return [
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new DivElement()
            ..classes = ['statusBox', 'shadow', 'center']
            ..children = [
              new DivElement()
                ..classes = ['statusMessage']
                ..text = message,
              new DivElement()
                ..classes = ['statusDescription']
                ..text = description,
              new DivElement()
                ..style.background = '#0489c3'
                ..style.width = '$progress%'
                ..style.height = '15px'
                ..style.borderRadius = '4px'
            ]
        ]
    ];
  }

  VirtualTreeElement _tree;

  List<Element> _createReport() {
    final List roots = _getChildrenDominator(_snapshot.dominatorTree);
    _tree = new VirtualTreeElement(
        _createDominator, _updateDominator, _getChildrenDominator,
        items: roots, queue: _r.queue);
    if (roots.length == 1) {
      _tree.expand(roots.first, autoExpandSingleChildNodes: true);
    }
    final text = 'In a heap dominator tree, an object X is a parent of '
        'object Y if every path from the root to Y goes through '
        'X. This allows you to find "choke points" that are '
        'holding onto a lot of memory. If an object becomes '
        'garbage, all its children in the dominator tree become '
        'garbage as well. '
        'The retained size of an object is the sum of the '
        'retained sizes of its children in the dominator tree '
        'plus its own shallow size, and is the amount of memory '
        'that would be freed if the object became garbage.';
    return <HtmlElement>[
      new DivElement()
        ..classes = ['content-centered-big', 'explanation']
        ..text = text
        ..title = text,
      _tree
    ];
  }

  static Element _createDominator(toggle) {
    return new DivElement()
      ..classes = ['tree-item']
      ..children = [
        new SpanElement()
          ..classes = ['size']
          ..title = 'retained size',
        new SpanElement()..classes = ['lines'],
        new ButtonElement()
          ..classes = ['expander']
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new SpanElement()
          ..classes = ['percentage']
          ..title = 'percentage of heap being retained',
        new SpanElement()..classes = ['name']
      ];
  }

  static const int kMaxChildren = 100;
  static const int kMinRetainedSize = 4096;

  static _getChildrenDominator(M.HeapSnapshotDominatorNode node) {
    final list = node.children.toList();
    list.sort((a, b) => b.retainedSize - a.retainedSize);
    return list
        .where((child) => child.retainedSize >= kMinRetainedSize)
        .take(kMaxChildren);
  }

  void _updateDominator(
      HtmlElement element, M.HeapSnapshotDominatorNode node, int depth) {
    element.children[0].text = Utils.formatSize(node.retainedSize);
    _updateLines(element.children[1].children, depth);
    if (_getChildrenDominator(node).isNotEmpty) {
      element.children[2].text = _tree.isExpanded(node) ? '▼' : '►';
    } else {
      element.children[2].text = '';
    }
    element.children[3].text =
        Utils.formatPercentNormalized(node.retainedSize * 1.0 / _snapshot.size);
    final wrapper = new SpanElement()
      ..classes = ['name']
      ..text = 'Loading...';
    element.children[4] = wrapper;
    if (node.isStack) {
      wrapper
        ..text = ''
        ..children = [
          new AnchorElement(href: Uris.debugger(isolate))..text = 'stack frames'
        ];
    } else {
      node.object.then((object) {
        wrapper
          ..text = ''
          ..children = [
            anyRef(_isolate, object, _objects,
                queue: _r.queue, expandable: false)
          ];
      });
    }
    Element.clickEvent
        .forTarget(element.children[4], useCapture: true)
        .listen((e) {
      if (_editor.isAvailable) {
        e.preventDefault();
        _sendNodeToEditor(node);
      }
    });
  }

  Future _sendNodeToEditor(M.HeapSnapshotDominatorNode node) async {
    final object = await node.object;
    if (node.isStack) {
      // TODO (https://github.com/flutter/flutter-intellij/issues/1290)
      // open debugger
      return new Future.value();
    }
    _editor.openObject(_isolate, object);
  }

  static _updateLines(List<Element> lines, int n) {
    n = Math.max(0, n);
    while (lines.length > n) {
      lines.removeLast();
    }
    while (lines.length < n) {
      lines.add(new SpanElement());
    }
  }

  static String rootsToString(M.HeapSnapshotRoots roots) {
    switch (roots) {
      case M.HeapSnapshotRoots.user:
        return 'User';
      case M.HeapSnapshotRoots.vm:
        return 'VM';
    }
    throw new Exception('Unknown HeapSnapshotRoots');
  }
}

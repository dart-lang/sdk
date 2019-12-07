// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'package:observatory/models.dart' as M;
import 'package:observatory/heap_snapshot.dart' as S;
import 'package:observatory/object_graph.dart';
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/containers/virtual_tree.dart';
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/helpers/any_ref.dart';
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
import 'package:observatory/src/elements/tree_map.dart';
import 'package:observatory/utils.dart';

enum HeapSnapshotTreeMode {
  dominatorTree,
  dominatorTreeMap,
  mergedDominatorTree,
  mergedDominatorTreeMap,
  ownershipTable,
  ownershipTreeMap,
  classesTable,
  classesTreeMap,
  successors,
  predecessors,
  process,
}

class DominatorTreeMap extends TreeMap<SnapshotObject> {
  HeapSnapshotElement element;
  DominatorTreeMap(this.element);

  int getSize(SnapshotObject node) => node.retainedSize;
  String getType(SnapshotObject node) => node.klass.name;
  String getLabel(SnapshotObject node) => node.description;
  SnapshotObject getParent(SnapshotObject node) => node.parent;
  Iterable<SnapshotObject> getChildren(SnapshotObject node) => node.children;
  void onSelect(SnapshotObject node) {
    element.selection = node.objects;
    element._r.dirty();
  }

  void onDetails(SnapshotObject node) {
    element.selection = node.objects;
    element._mode = HeapSnapshotTreeMode.successors;
    element._r.dirty();
  }
}

class MergedDominatorTreeMap
    extends TreeMap<M.HeapSnapshotMergedDominatorNode> {
  HeapSnapshotElement element;
  MergedDominatorTreeMap(this.element);

  int getSize(M.HeapSnapshotMergedDominatorNode node) => node.retainedSize;
  String getType(M.HeapSnapshotMergedDominatorNode node) => node.klass.name;
  String getLabel(M.HeapSnapshotMergedDominatorNode node) =>
      (node as dynamic).description;
  M.HeapSnapshotMergedDominatorNode getParent(
          M.HeapSnapshotMergedDominatorNode node) =>
      (node as dynamic).parent;
  Iterable<M.HeapSnapshotMergedDominatorNode> getChildren(
          M.HeapSnapshotMergedDominatorNode node) =>
      node.children;
  void onSelect(M.HeapSnapshotMergedDominatorNode node) {
    element.mergedSelection = node;
    element._r.dirty();
  }

  void onDetails(M.HeapSnapshotMergedDominatorNode node) {
    dynamic n = node;
    element.selection = n.objects;
    element._mode = HeapSnapshotTreeMode.successors;
    element._r.dirty();
  }
}

// Using `null` to represent the root.
class ClassesShallowTreeMap extends TreeMap<SnapshotClass> {
  HeapSnapshotElement element;
  M.HeapSnapshot snapshot;

  ClassesShallowTreeMap(this.element, this.snapshot);

  int getSize(SnapshotClass node) =>
      node == null ? snapshot.size : node.shallowSize;
  String getType(SnapshotClass node) => node == null ? "Classes" : node.name;
  String getLabel(SnapshotClass node) => node == null
      ? "${snapshot.classes.length} classes"
      : "${node.instanceCount} instances of ${node.name}";
  SnapshotClass getParent(SnapshotClass node) => null;
  Iterable<SnapshotClass> getChildren(SnapshotClass node) =>
      node == null ? snapshot.classes : <SnapshotClass>[];
  void onSelect(SnapshotClass node) {}
  void onDetails(SnapshotClass node) {
    element.selection = node.instances.toList();
    element._mode = HeapSnapshotTreeMode.successors;
    element._r.dirty();
  }
}

class ProcessTreeMap extends TreeMap<String> {
  static const String root = "RSS";
  HeapSnapshotElement element;
  M.HeapSnapshot snapshot;

  ProcessTreeMap(this.element, this.snapshot);

  int getSize(String node) => snapshot.processPartitions[node];
  String getType(String node) => node;
  String getLabel(String node) => node;
  String getParent(String node) => node == root ? null : root;
  Iterable<String> getChildren(String node) {
    if (node == root) {
      var children = snapshot.processPartitions.keys.toList();
      children.remove(root);
      return children;
    }
    return <String>[];
  }

  void onSelect(String node) {}
  void onDetails(String node) {}
}

// Using `null` to represent the root.
class ClassesOwnershipTreeMap extends TreeMap<SnapshotClass> {
  HeapSnapshotElement element;
  M.HeapSnapshot snapshot;

  ClassesOwnershipTreeMap(this.element, this.snapshot);

  int getSize(SnapshotClass node) =>
      node == null ? snapshot.size : node.ownedSize;
  String getType(SnapshotClass node) => node == null ? "classes" : node.name;
  String getLabel(SnapshotClass node) => node == null
      ? "${snapshot.classes.length} Classes"
      : "${node.instanceCount} instances of ${node.name}";
  SnapshotClass getParent(SnapshotClass node) => null;
  Iterable<SnapshotClass> getChildren(SnapshotClass node) =>
      node == null ? snapshot.classes : <SnapshotClass>[];
  void onSelect(SnapshotClass node) {}
  void onDetails(SnapshotClass node) {
    element.selection = node.instances.toList();
    element._mode = HeapSnapshotTreeMode.successors;
    element._r.dirty();
  }
}

class HeapSnapshotElement extends CustomElement implements Renderable {
  static const tag =
      const Tag<HeapSnapshotElement>('heap-snapshot', dependencies: const [
    ClassRefElement.tag,
    NavTopMenuElement.tag,
    NavVMMenuElement.tag,
    NavIsolateMenuElement.tag,
    NavRefreshElement.tag,
    NavNotifyElement.tag,
    VirtualTreeElement.tag,
  ]);

  RenderingScheduler<HeapSnapshotElement> _r;

  Stream<RenderedEvent<HeapSnapshotElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.HeapSnapshotRepository _snapshots;
  M.ObjectRepository _objects;
  M.HeapSnapshot _snapshot;
  Stream<M.HeapSnapshotLoadingProgressEvent> _progressStream;
  M.HeapSnapshotLoadingProgress _progress;
  HeapSnapshotTreeMode _mode = HeapSnapshotTreeMode.mergedDominatorTreeMap;

  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.HeapSnapshotRepository get profiles => _snapshots;
  M.VMRef get vm => _vm;

  List<SnapshotObject> selection;
  M.HeapSnapshotMergedDominatorNode mergedSelection;

  factory HeapSnapshotElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.HeapSnapshotRepository snapshots,
      M.ObjectRepository objects,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(snapshots != null);
    assert(objects != null);
    HeapSnapshotElement e = new HeapSnapshotElement.created();
    e._r = new RenderingScheduler<HeapSnapshotElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._snapshots = snapshots;
    e._objects = objects;
    return e;
  }

  HeapSnapshotElement.created() : super.created(tag);

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
    children = <Element>[];
  }

  void render() {
    final content = <Element>[
      navBar(<Element>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu('heap snapshot'),
        (new NavRefreshElement(queue: _r.queue)
              ..disabled = M.isHeapSnapshotProgressRunning(_progress?.status)
              ..onRefresh.listen((e) {
                _refresh();
              }))
            .element,
        (new NavRefreshElement(label: 'save', queue: _r.queue)
              ..disabled = M.isHeapSnapshotProgressRunning(_progress?.status)
              ..onRefresh.listen((e) {
                _save();
              }))
            .element,
        (new NavRefreshElement(label: 'load', queue: _r.queue)
              ..disabled = M.isHeapSnapshotProgressRunning(_progress?.status)
              ..onRefresh.listen((e) {
                _load();
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
    ];
    if (_progress == null) {
      children = content;
      return;
    }
    switch (_progress.status) {
      case M.HeapSnapshotLoadingStatus.fetching:
        content.addAll(_createStatusMessage('Fetching snapshot from VM...',
            description: _progress.stepDescription,
            progress: _progress.progress));
        break;
      case M.HeapSnapshotLoadingStatus.loading:
        content.addAll(_createStatusMessage('Loading snapshot...',
            description: _progress.stepDescription,
            progress: _progress.progress));
        break;
      case M.HeapSnapshotLoadingStatus.loaded:
        content.addAll(_createReport());
        break;
    }
    children = content;
  }

  Future _refresh() async {
    _progress = null;
    _progressStream = _snapshots.get(isolate);
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

  _save() async {
    var blob = new Blob([_snapshot.encoded], 'application/octet-stream');
    var blobUrl = Url.createObjectUrl(blob);
    var link = new AnchorElement();
    link.href = blobUrl;
    var now = new DateTime.now();
    link.download = 'dart-heap-${now.year}-${now.month}-${now.day}.bin';
    link.click();
  }

  _load() async {
    var input = new InputElement();
    input.type = 'file';
    input.multiple = false;
    input.onChange.listen((event) {
      var file = input.files[0];
      var reader = new FileReader();
      reader.onLoad.listen((event) async {
        Uint8List encoded = reader.result;
        var snapshot = new S.HeapSnapshot();
        await snapshot.loadProgress(null, encoded).last;
        _snapshot = snapshot;
        selection = null;
        mergedSelection = null;
        _r.dirty();
      });
      reader.readAsArrayBuffer(file);
    });
    input.click();
  }

  static List<Element> _createStatusMessage(String message,
      {String description: '', double progress: 0.0}) {
    return [
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = <Element>[
          new DivElement()
            ..classes = ['statusBox', 'shadow', 'center']
            ..children = <Element>[
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
    var report = <HtmlElement>[
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberList']
            ..children = <Element>[
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'Size ',
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = Utils.formatSize(_snapshot.size)
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'View ',
                  new DivElement()
                    ..classes = ['memberName']
                    ..children = _createModeSelect()
                ]
            ]
        ],
    ];
    switch (_mode) {
      case HeapSnapshotTreeMode.dominatorTree:
        if (selection == null) {
          selection = _snapshot.root.objects;
        }
        _tree = new VirtualTreeElement(
            _createDominator, _updateDominator, _getChildrenDominator,
            items: selection, queue: _r.queue);
        if (selection.length == 1) {
          _tree.expand(selection.first);
        }
        final text = 'In a heap dominator tree, an object X is a parent of '
            'object Y if every path from the root to Y goes through '
            'X. This allows you to find "choke points" that are '
            'holding onto a lot of memory. If an object becomes '
            'garbage, all its children in the dominator tree become '
            'garbage as well.';
        report.addAll([
          new DivElement()
            ..classes = ['content-centered-big', 'explanation']
            ..text = text,
          _tree.element
        ]);
        break;
      case HeapSnapshotTreeMode.dominatorTreeMap:
        final content = new DivElement();
        content.style.border = '1px solid black';
        content.style.width = '100%';
        content.style.height = '100%';
        content.text = 'Performing layout...';
        Timer.run(() {
          // Generate the treemap after the content div has been added to the
          // document so that we can ask the browser how much space is
          // available for treemap layout.
          if (selection == null) {
            selection = _snapshot.root.objects;
          }
          new DominatorTreeMap(this).showIn(selection.first, content);
        });

        final text =
            'Double-click a tile to zoom in. Double-click the outermost tile to zoom out. Right-click a tile to inspect its object.';
        report.addAll([
          new DivElement()
            ..classes = ['content-centered-big', 'explanation']
            ..text = text,
          new DivElement()
            ..classes = ['content-centered-big']
            ..style.width = '100%'
            ..style.height = '100%'
            ..children = [content]
        ]);
        break;
      case HeapSnapshotTreeMode.mergedDominatorTree:
        _tree = new VirtualTreeElement(_createMergedDominator,
            _updateMergedDominator, _getChildrenMergedDominator,
            items: _getChildrenMergedDominator(_snapshot.mergedDominatorTree),
            queue: _r.queue);
        _tree.expand(_snapshot.mergedDominatorTree);
        final text = 'A heap dominator tree, where siblings with the same class'
            ' have been merged into a single node.';
        report.addAll([
          new DivElement()
            ..classes = ['content-centered-big', 'explanation']
            ..text = text,
          _tree.element
        ]);
        break;
      case HeapSnapshotTreeMode.mergedDominatorTreeMap:
        final content = new DivElement();
        content.style.border = '1px solid black';
        content.style.width = '100%';
        content.style.height = '100%';
        content.text = 'Performing layout...';
        Timer.run(() {
          // Generate the treemap after the content div has been added to the
          // document so that we can ask the browser how much space is
          // available for treemap layout.
          if (mergedSelection == null) {
            mergedSelection = _snapshot.mergedDominatorTree;
          }
          new MergedDominatorTreeMap(this).showIn(mergedSelection, content);
        });

        final text =
            'Double-click a tile to zoom in. Double-click the outermost tile to zoom out. Right-click a tile to inspect its objects.';
        report.addAll([
          new DivElement()
            ..classes = ['content-centered-big', 'explanation']
            ..text = text,
          new DivElement()
            ..classes = ['content-centered-big']
            ..style.width = '100%'
            ..style.height = '100%'
            ..children = [content]
        ]);
        break;
      case HeapSnapshotTreeMode.ownershipTable:
        final items = _snapshot.classes.where((c) => c.ownedSize > 0).toList();
        items.sort((a, b) => b.ownedSize - a.ownedSize);
        _tree = new VirtualTreeElement(_createOwnershipClass,
            _updateOwnershipClass, _getChildrenOwnershipClass,
            items: items, queue: _r.queue);
        _tree.expand(_snapshot.root);
        final text = 'An object X is said to "own" object Y if X is the only '
            'object that references Y, or X owns the only object that '
            'references Y. In particular, objects "own" the space of any '
            'unshared lists or maps they reference.';
        report.addAll([
          new DivElement()
            ..classes = ['content-centered-big', 'explanation']
            ..text = text,
          _tree.element
        ]);
        break;
      case HeapSnapshotTreeMode.ownershipTreeMap:
        final content = new DivElement();
        content.style.border = '1px solid black';
        content.style.width = '100%';
        content.style.height = '100%';
        content.text = 'Performing layout...';
        Timer.run(() {
          // Generate the treemap after the content div has been added to the
          // document so that we can ask the browser how much space is
          // available for treemap layout.
          new ClassesOwnershipTreeMap(this, _snapshot).showIn(null, content);
        });
        final text = 'An object X is said to "own" object Y if X is the only '
            'object that references Y, or X owns the only object that '
            'references Y. In particular, objects "own" the space of any '
            'unshared lists or maps they reference.';
        report.addAll([
          new DivElement()
            ..classes = ['content-centered-big', 'explanation']
            ..text = text,
          new DivElement()
            ..classes = ['content-centered-big']
            ..style.width = '100%'
            ..style.height = '100%'
            ..children = [content]
        ]);
        break;
      case HeapSnapshotTreeMode.successors:
        if (selection == null) {
          selection = _snapshot.root.objects;
        }
        _tree = new VirtualTreeElement(
            _createSuccessor, _updateSuccessor, _getChildrenSuccessor,
            items: selection, queue: _r.queue);
        if (selection.length == 1) {
          _tree.expand(selection.first);
        }
        final text = '';
        report.addAll([
          new DivElement()
            ..classes = ['content-centered-big', 'explanation']
            ..text = text,
          _tree.element
        ]);
        break;
      case HeapSnapshotTreeMode.predecessors:
        if (selection == null) {
          selection = _snapshot.root.objects;
        }
        _tree = new VirtualTreeElement(
            _createPredecessor, _updatePredecessor, _getChildrenPredecessor,
            items: selection, queue: _r.queue);
        if (selection.length == 1) {
          _tree.expand(selection.first);
        }
        final text = '';
        report.addAll([
          new DivElement()
            ..classes = ['content-centered-big', 'explanation']
            ..text = text,
          _tree.element
        ]);
        break;
      case HeapSnapshotTreeMode.classesTable:
        final items = _snapshot.classes.toList();
        items.sort((a, b) => b.shallowSize - a.shallowSize);
        _tree = new VirtualTreeElement(
            _createClass, _updateClass, _getChildrenClass,
            items: items, queue: _r.queue);
        report.add(_tree.element);
        break;
      case HeapSnapshotTreeMode.classesTreeMap:
        final content = new DivElement();
        content.style.border = '1px solid black';
        content.style.width = '100%';
        content.style.height = '100%';
        content.text = 'Performing layout...';
        Timer.run(() {
          // Generate the treemap after the content div has been added to the
          // document so that we can ask the browser how much space is
          // available for treemap layout.
          new ClassesShallowTreeMap(this, _snapshot).showIn(null, content);
        });
        report.addAll([
          new DivElement()
            ..classes = ['content-centered-big']
            ..style.width = '100%'
            ..style.height = '100%'
            ..children = [content]
        ]);
        break;
      case HeapSnapshotTreeMode.process:
        final content = new DivElement();
        content.style.border = '1px solid black';
        content.style.width = '100%';
        content.style.height = '100%';
        content.text = 'Performing layout...';
        Timer.run(() {
          // Generate the treemap after the content div has been added to the
          // document so that we can ask the browser how much space is
          // available for treemap layout.
          new ProcessTreeMap(this, _snapshot)
              .showIn(ProcessTreeMap.root, content);
        });
        report.addAll([
          new DivElement()
            ..classes = ['content-centered-big']
            ..style.width = '100%'
            ..style.height = '100%'
            ..children = [content]
        ]);
        break;
      default:
        break;
    }
    return report;
  }

  static HtmlElement _createDominator(toggle) {
    return new DivElement()
      ..classes = ['tree-item']
      ..children = <Element>[
        new SpanElement()
          ..classes = ['percentage']
          ..title = 'percentage of heap being retained',
        new SpanElement()
          ..classes = ['size']
          ..title = 'retained size',
        new SpanElement()..classes = ['lines'],
        new ButtonElement()
          ..classes = ['expander']
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new SpanElement()..classes = ['name'],
        new AnchorElement()
          ..classes = ['link']
          ..text = "[inspect]",
        new AnchorElement()
          ..classes = ['link']
          ..text = "[incoming]",
        new AnchorElement()
          ..classes = ['link']
          ..text = "[dominator-map]",
      ];
  }

  static HtmlElement _createSuccessor(toggle) {
    return new DivElement()
      ..classes = ['tree-item']
      ..children = <Element>[
        new SpanElement()..classes = ['lines'],
        new ButtonElement()
          ..classes = ['expander']
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new SpanElement()
          ..classes = ['size']
          ..title = 'retained size',
        new SpanElement()
          ..classes = ['edge']
          ..title = 'name of outgoing field',
        new SpanElement()..classes = ['name'],
        new AnchorElement()
          ..classes = ['link']
          ..text = "[incoming]",
        new AnchorElement()
          ..classes = ['link']
          ..text = "[dominator-tree]",
        new AnchorElement()
          ..classes = ['link']
          ..text = "[dominator-map]",
      ];
  }

  static HtmlElement _createPredecessor(toggle) {
    return new DivElement()
      ..classes = ['tree-item']
      ..children = <Element>[
        new SpanElement()..classes = ['lines'],
        new ButtonElement()
          ..classes = ['expander']
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new SpanElement()
          ..classes = ['size']
          ..title = 'retained size',
        new SpanElement()
          ..classes = ['edge']
          ..title = 'name of incoming field',
        new SpanElement()..classes = ['name'],
        new SpanElement()
          ..classes = ['link']
          ..text = "[inspect]",
        new AnchorElement()
          ..classes = ['link']
          ..text = "[dominator-tree]",
        new AnchorElement()
          ..classes = ['link']
          ..text = "[dominator-map]",
      ];
  }

  static HtmlElement _createMergedDominator(toggle) {
    return new DivElement()
      ..classes = ['tree-item']
      ..children = <Element>[
        new SpanElement()
          ..classes = ['percentage']
          ..title = 'percentage of heap being retained',
        new SpanElement()
          ..classes = ['size']
          ..title = 'retained size',
        new SpanElement()..classes = ['lines'],
        new ButtonElement()
          ..classes = ['expander']
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new SpanElement()..classes = ['name']
      ];
  }

  static HtmlElement _createOwnershipClass(toggle) {
    return new DivElement()
      ..classes = ['tree-item']
      ..children = <Element>[
        new SpanElement()
          ..classes = ['percentage']
          ..title = 'percentage of heap owned',
        new SpanElement()
          ..classes = ['size']
          ..title = 'owned size',
        new SpanElement()..classes = ['name']
      ];
  }

  static HtmlElement _createClass(toggle) {
    return new DivElement()
      ..classes = ['tree-item']
      ..children = <Element>[
        new SpanElement()..classes = ['lines'],
        new ButtonElement()
          ..classes = ['expander']
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new SpanElement()
          ..classes = ['percentage']
          ..title = 'percentage of heap owned',
        new SpanElement()
          ..classes = ['size']
          ..title = 'shallow size',
        new SpanElement()
          ..classes = ['size']
          ..title = 'instance count',
        new SpanElement()..classes = ['name']
      ];
  }

  static const int kMaxChildren = 100;
  static const int kMinRetainedSize = 4096;

  static Iterable _getChildrenDominator(nodeDynamic) {
    SnapshotObject node = nodeDynamic;
    final list = node.children.toList();
    list.sort((a, b) => b.retainedSize - a.retainedSize);
    return list
        .where((child) => child.retainedSize >= kMinRetainedSize)
        .take(kMaxChildren);
  }

  static Iterable _getChildrenSuccessor(nodeDynamic) {
    SnapshotObject node = nodeDynamic;
    final list = node.successors.toList();
    return list;
  }

  static Iterable _getChildrenPredecessor(nodeDynamic) {
    SnapshotObject node = nodeDynamic;
    final list = node.predecessors.toList();
    return list;
  }

  static Iterable _getChildrenMergedDominator(nodeDynamic) {
    M.HeapSnapshotMergedDominatorNode node = nodeDynamic;
    final list = node.children.toList();
    list.sort((a, b) => b.retainedSize - a.retainedSize);
    return list
        .where((child) => child.retainedSize >= kMinRetainedSize)
        .take(kMaxChildren);
  }

  static Iterable _getChildrenOwnershipClass(item) {
    return const [];
  }

  static Iterable _getChildrenClass(item) {
    return const [];
  }

  void _updateDominator(HtmlElement element, nodeDynamic, int depth) {
    SnapshotObject node = nodeDynamic;
    element.children[0].text =
        Utils.formatPercentNormalized(node.retainedSize * 1.0 / _snapshot.size);
    element.children[1].text = Utils.formatSize(node.retainedSize);
    _updateLines(element.children[2].children, depth);
    if (_getChildrenDominator(node).isNotEmpty) {
      element.children[3].text = _tree.isExpanded(node) ? '▼' : '►';
    } else {
      element.children[3].text = '';
    }
    element.children[4].text = node.description;
    element.children[5].onClick.listen((_) {
      selection = node.objects;
      _mode = HeapSnapshotTreeMode.successors;
      _r.dirty();
    });
    element.children[6].onClick.listen((_) {
      selection = node.objects;
      _mode = HeapSnapshotTreeMode.predecessors;
      _r.dirty();
    });
    element.children[7].onClick.listen((_) {
      selection = node.objects;
      _mode = HeapSnapshotTreeMode.dominatorTreeMap;
      _r.dirty();
    });
  }

  void _updateSuccessor(HtmlElement element, nodeDynamic, int depth) {
    SnapshotObject node = nodeDynamic;
    _updateLines(element.children[0].children, depth);
    if (_getChildrenSuccessor(node).isNotEmpty) {
      element.children[1].text = _tree.isExpanded(node) ? '▼' : '►';
    } else {
      element.children[1].text = '';
    }
    element.children[2].text = Utils.formatSize(node.retainedSize);
    element.children[3].text = node.label;
    element.children[4].text = node.description;
    element.children[5].onClick.listen((_) {
      selection = node.objects;
      _mode = HeapSnapshotTreeMode.predecessors;
      _r.dirty();
    });
    element.children[6].onClick.listen((_) {
      selection = node.objects;
      _mode = HeapSnapshotTreeMode.dominatorTree;
      _r.dirty();
    });
    element.children[7].onClick.listen((_) {
      selection = node.objects;
      _mode = HeapSnapshotTreeMode.dominatorTreeMap;
      _r.dirty();
    });
  }

  void _updatePredecessor(HtmlElement element, nodeDynamic, int depth) {
    SnapshotObject node = nodeDynamic;
    _updateLines(element.children[0].children, depth);
    if (_getChildrenSuccessor(node).isNotEmpty) {
      element.children[1].text = _tree.isExpanded(node) ? '▼' : '►';
    } else {
      element.children[1].text = '';
    }
    element.children[2].text = Utils.formatSize(node.retainedSize);
    element.children[3].text = node.label;
    element.children[4].text = node.description;
    element.children[5].onClick.listen((_) {
      selection = node.objects;
      _mode = HeapSnapshotTreeMode.successors;
      _r.dirty();
    });
    element.children[6].onClick.listen((_) {
      selection = node.objects;
      _mode = HeapSnapshotTreeMode.dominatorTree;
      _r.dirty();
    });
    element.children[7].onClick.listen((_) {
      selection = node.objects;
      _mode = HeapSnapshotTreeMode.dominatorTreeMap;
      _r.dirty();
    });
  }

  void _updateMergedDominator(HtmlElement element, nodeDynamic, int depth) {
    M.HeapSnapshotMergedDominatorNode node = nodeDynamic;
    element.children[0].text =
        Utils.formatPercentNormalized(node.retainedSize * 1.0 / _snapshot.size);
    element.children[1].text = Utils.formatSize(node.retainedSize);
    _updateLines(element.children[2].children, depth);
    if (_getChildrenMergedDominator(node).isNotEmpty) {
      element.children[3].text = _tree.isExpanded(node) ? '▼' : '►';
    } else {
      element.children[3].text = '';
    }
    element.children[4]
      ..text = '${node.instanceCount} instances of ${node.klass.name}';
  }

  void _updateOwnershipClass(HtmlElement element, nodeDynamic, int depth) {
    SnapshotClass node = nodeDynamic;
    _updateLines(element.children[1].children, depth);
    element.children[0].text =
        Utils.formatPercentNormalized(node.ownedSize * 1.0 / _snapshot.size);
    element.children[1].text = Utils.formatSize(node.ownedSize);
    element.children[2].text = node.name;
  }

  void _updateClass(HtmlElement element, nodeDynamic, int depth) {
    SnapshotClass node = nodeDynamic;
    _updateLines(element.children[1].children, depth);
    element.children[2].text =
        Utils.formatPercentNormalized(node.shallowSize * 1.0 / _snapshot.size);
    element.children[3].text = Utils.formatSize(node.shallowSize);
    element.children[4].text = node.instanceCount.toString();
    element.children[5].text = node.name;
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

  static String modeToString(HeapSnapshotTreeMode mode) {
    switch (mode) {
      case HeapSnapshotTreeMode.dominatorTree:
        return 'Dominators (tree)';
      case HeapSnapshotTreeMode.dominatorTreeMap:
        return 'Dominators (treemap)';
      case HeapSnapshotTreeMode.mergedDominatorTree:
        return 'Dominators (tree, siblings merged by class)';
      case HeapSnapshotTreeMode.mergedDominatorTreeMap:
        return 'Dominators (treemap, siblings merged by class)';
      case HeapSnapshotTreeMode.ownershipTable:
        return 'Ownership (table)';
      case HeapSnapshotTreeMode.ownershipTreeMap:
        return 'Ownership (treemap)';
      case HeapSnapshotTreeMode.classesTable:
        return 'Classes (table)';
      case HeapSnapshotTreeMode.classesTreeMap:
        return 'Classes (treemap)';
      case HeapSnapshotTreeMode.successors:
        return 'Successors / outgoing references';
      case HeapSnapshotTreeMode.predecessors:
        return 'Predecessors / incoming references';
      case HeapSnapshotTreeMode.process:
        return 'Process memory usage';
    }
    throw new Exception('Unknown HeapSnapshotTreeMode: $mode');
  }

  List<Element> _createModeSelect() {
    var s;
    return [
      s = new SelectElement()
        ..classes = ['analysis-select']
        ..value = modeToString(_mode)
        ..children = HeapSnapshotTreeMode.values.map((mode) {
          return new OptionElement(
              value: modeToString(mode), selected: _mode == mode)
            ..text = modeToString(mode);
        }).toList(growable: false)
        ..onChange.listen((_) {
          _mode = HeapSnapshotTreeMode.values[s.selectedIndex];
          _r.dirty();
        })
    ];
  }
}

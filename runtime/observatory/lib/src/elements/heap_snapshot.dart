// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:math' as Math;
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/containers/virtual_tree.dart';
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
import 'package:observatory/utils.dart';

enum HeapSnapshotTreeMode { dominatorTree, mergedDominatorTree, groupByClass }

class HeapSnapshotElement extends HtmlElement implements Renderable {
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
  M.HeapSnapshotRoots _roots = M.HeapSnapshotRoots.user;
  HeapSnapshotTreeMode _mode = HeapSnapshotTreeMode.dominatorTree;

  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.HeapSnapshotRepository get profiles => _snapshots;
  M.VMRef get vm => _vm;

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
    HeapSnapshotElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._snapshots = snapshots;
    e._objects = objects;
    return e;
  }

  HeapSnapshotElement.created() : super.created();

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
    final content = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavVMMenuElement(_vm, _events, queue: _r.queue),
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue),
        navMenu('heap snapshot'),
        new NavRefreshElement(queue: _r.queue)
          ..disabled = M.isHeapSnapshotProgressRunning(_progress?.status)
          ..onRefresh.listen((e) {
            _refresh();
          }),
        new NavNotifyElement(_notifications, queue: _r.queue)
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
    _progressStream = _snapshots.get(isolate, roots: _roots, gc: true);
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
    var report = [
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new DivElement()
            ..classes = ['memberList']
            ..children = [
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'Refreshed ',
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = Utils.formatDateTime(_snapshot.timestamp)
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'Objects ',
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = '${_snapshot.objects}'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'References ',
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = '${_snapshot.references}'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'Size ',
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = Utils.formatSize(_snapshot.size)
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'Roots ',
                  new DivElement()
                    ..classes = ['memberName']
                    ..children = _createRootsSelect()
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'Analysis ',
                  new DivElement()
                    ..classes = ['memberName']
                    ..children = _createModeSelect()
                ]
            ]
        ],
    ];
    switch (_mode) {
      case HeapSnapshotTreeMode.dominatorTree:
        _tree = new VirtualTreeElement(
            _createDominator, _updateDominator, _getChildrenDominator,
            items: _getChildrenDominator(_snapshot.dominatorTree),
            queue: _r.queue);
        _tree.expand(_snapshot.dominatorTree);
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
        report.addAll([
          new DivElement()
            ..classes = ['content-centered-big', 'explanation']
            ..text = text
            ..title = text,
          _tree
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
            ..text = text
            ..title = text,
          _tree
        ]);
        break;
      case HeapSnapshotTreeMode.groupByClass:
        final items = _snapshot.classReferences.toList();
        items.sort((a, b) => b.shallowSize - a.shallowSize);
        _tree = new VirtualTreeElement(
            _createGroup, _updateGroup, _getChildrenGroup,
            items: items, queue: _r.queue);
        _tree.expand(_snapshot.dominatorTree);
        report.add(_tree);
        break;
      default:
        break;
    }
    return report;
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

  static Element _createMergedDominator(toggle) {
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

  static Element _createGroup(toggle) {
    return new DivElement()
      ..classes = ['tree-item']
      ..children = [
        new SpanElement()
          ..classes = ['size']
          ..title = 'shallow size',
        new SpanElement()..classes = ['lines'],
        new ButtonElement()
          ..classes = ['expander']
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new SpanElement()
          ..classes = ['count']
          ..title = 'shallow size',
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

  static _getChildrenMergedDominator(M.HeapSnapshotMergedDominatorNode node) {
    final list = node.children.toList();
    list.sort((a, b) => b.retainedSize - a.retainedSize);
    return list
        .where((child) => child.retainedSize >= kMinRetainedSize)
        .take(kMaxChildren);
  }

  static _getChildrenGroup(item) {
    if (item is M.HeapSnapshotClassReferences) {
      if (item.inbounds.isNotEmpty || item.outbounds.isNotEmpty) {
        return [item.inbounds, item.outbounds];
      }
    } else if (item is Iterable) {
      return item.toList()..sort((a, b) => b.shallowSize - a.shallowSize);
    }
    return const [];
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
          ..children = [anyRef(_isolate, object, _objects, queue: _r.queue)];
      });
    }
  }

  void _updateMergedDominator(
      HtmlElement element, M.HeapSnapshotMergedDominatorNode node, int depth) {
    element.children[0].text = Utils.formatSize(node.retainedSize);
    _updateLines(element.children[1].children, depth);
    if (_getChildrenMergedDominator(node).isNotEmpty) {
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
      node.klass.then((klass) {
        wrapper
          ..text = ''
          ..children = [
            new SpanElement()..text = '${node.instanceCount} instances of ',
            anyRef(_isolate, klass, _objects, queue: _r.queue)
          ];
      });
    }
  }

  void _updateGroup(HtmlElement element, item, int depth) {
    _updateLines(element.children[1].children, depth);
    if (item is M.HeapSnapshotClassReferences) {
      element.children[0].text = Utils.formatSize(item.shallowSize);
      element.children[2].text = _tree.isExpanded(item) ? '▼' : '►';
      element.children[3].text = '${item.instances} instances of ';
      element.children[4] =
          new ClassRefElement(_isolate, item.clazz, queue: _r.queue)
            ..classes = ['name'];
    } else if (item is Iterable) {
      element.children[0].text = '';
      if (item.isNotEmpty) {
        element.children[2].text = _tree.isExpanded(item) ? '▼' : '►';
      } else {
        element.children[2].text = '';
      }
      element.children[3].text = '';
      int references = 0;
      for (var referenceGroup in item) {
        references += referenceGroup.count;
      }
      if (item is Iterable<M.HeapSnapshotClassInbound>) {
        element.children[4] = new SpanElement()
          ..classes = ['name']
          ..text = '$references incoming references';
      } else {
        element.children[4] = new SpanElement()
          ..classes = ['name']
          ..text = '$references outgoing references';
      }
    } else {
      element.children[0].text = '';
      element.children[2].text = '';
      element.children[3].text = '';
      element.children[4] = new SpanElement()..classes = ['name'];
      if (item is M.HeapSnapshotClassInbound) {
        element.children[3].text =
            '${item.count} references from instances of ';
        element.children[4].children = [
          new ClassRefElement(_isolate, item.source, queue: _r.queue)
        ];
      } else if (item is M.HeapSnapshotClassOutbound) {
        element.children[3]..text = '${item.count} references to instances of ';
        element.children[4].children = [
          new ClassRefElement(_isolate, item.target, queue: _r.queue)
        ];
      }
    }
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

  List<Element> _createRootsSelect() {
    var s;
    return [
      s = new SelectElement()
        ..classes = ['roots-select']
        ..value = rootsToString(_roots)
        ..children = M.HeapSnapshotRoots.values.map((roots) {
          return new OptionElement(
              value: rootsToString(roots), selected: _roots == roots)
            ..text = rootsToString(roots);
        }).toList(growable: false)
        ..onChange.listen((_) {
          _roots = M.HeapSnapshotRoots.values[s.selectedIndex];
          _refresh();
        })
    ];
  }

  static String modeToString(HeapSnapshotTreeMode mode) {
    switch (mode) {
      case HeapSnapshotTreeMode.dominatorTree:
        return 'Dominator tree';
      case HeapSnapshotTreeMode.mergedDominatorTree:
        return 'Dominator tree (merged siblings by class)';
      case HeapSnapshotTreeMode.groupByClass:
        return 'Group by class';
    }
    throw new Exception('Unknown HeapSnapshotTreeMode');
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

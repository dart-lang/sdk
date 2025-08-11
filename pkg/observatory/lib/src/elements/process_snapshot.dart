// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' as Math;

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'containers/virtual_tree.dart';
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/nav_bar.dart';
import 'helpers/nav_menu.dart';
import 'helpers/rendering_scheduler.dart';
import 'nav/notify.dart';
import 'nav/refresh.dart';
import 'nav/top_menu.dart';
import 'nav/vm_menu.dart';
import 'tree_map.dart';
import '../../utils.dart';

enum ProcessSnapshotTreeMode { treeMap, tree, treeMapDiff, treeDiff }

// Note the order of these lists is reflected in the UI, and the first option
// is the default.
const _viewModes = [
  ProcessSnapshotTreeMode.treeMap,
  ProcessSnapshotTreeMode.tree,
];

const _diffModes = [
  ProcessSnapshotTreeMode.treeMapDiff,
  ProcessSnapshotTreeMode.treeDiff,
];

class ProcessItemTreeMap extends NormalTreeMap<Map> {
  ProcessSnapshotElement element;
  ProcessItemTreeMap(this.element);

  int getSize(Map node) => node["size"];
  String getType(Map node) => node["name"];
  String getName(Map node) => node["name"];
  String getTooltip(Map node) => getLabel(node) + "\n" + node["description"];
  Map getParent(Map node) => node["parent"];
  Iterable<Map> getChildren(Map node) => new List<Map>.from(node["children"]);
  void onSelect(Map node) {
    element.selection = node;
    element._r.dirty();
  }

  void onDetails(Map node) {}
}

class ProcessItemDiff {
  Map? _a;
  Map? _b;
  ProcessItemDiff? parent;
  List<ProcessItemDiff>? children;
  int retainedGain = -1;
  int retainedLoss = -1;
  int retainedCommon = -1;

  int get retainedSizeA => _a == null ? 0 : _a!["size"];
  int get retainedSizeB => _b == null ? 0 : _b!["size"];
  int get retainedSizeDiff => retainedSizeB - retainedSizeA;

  int get shallowSizeA {
    if (_a == null) return 0;
    var s = _a!["size"];
    for (var c in _a!["children"]) {
      s -= c["size"];
    }
    return s;
  }

  int get shallowSizeB {
    if (_b == null) return 0;
    var s = _b!["size"];
    for (var c in _b!["children"]) {
      s -= c["size"];
    }
    return s;
  }

  int get shallowSizeDiff => shallowSizeB - shallowSizeA;

  String get name => _a == null ? _b!["name"] : _a!["name"];

  static ProcessItemDiff from(Map a, Map b) {
    var root = new ProcessItemDiff();
    root._a = a;
    root._b = b;

    // We must use an explicit stack instead of the call stack because the
    // dominator tree can be arbitrarily deep. We need to compute the full
    // tree to compute areas, so we do this eagerly to avoid having to
    // repeatedly test for initialization.
    var worklist = <ProcessItemDiff>[];
    worklist.add(root);
    // Compute children top-down.
    for (var i = 0; i < worklist.length; i++) {
      worklist[i]._computeChildren(worklist);
    }
    // Compute area bottom-up.
    for (var i = worklist.length - 1; i >= 0; i--) {
      worklist[i]._computeArea();
    }

    return root;
  }

  void _computeChildren(List<ProcessItemDiff> worklist) {
    assert(children == null);
    children = <ProcessItemDiff>[];

    // Matching children by name.
    final childrenB = <String, Map>{};
    if (_b != null)
      for (var childB in _b!["children"]) {
        childrenB[childB["name"]] = childB;
      }
    if (_a != null)
      for (var childA in _a!["children"]) {
        var childDiff = new ProcessItemDiff();
        childDiff.parent = this;
        childDiff._a = childA;
        var qualifiedName = childA["name"];
        var childB = childrenB[qualifiedName];
        if (childB != null) {
          childrenB.remove(qualifiedName);
          childDiff._b = childB;
        }
        children!.add(childDiff);
        worklist.add(childDiff);
      }
    for (var childB in childrenB.values) {
      var childDiff = new ProcessItemDiff();
      childDiff.parent = this;
      childDiff._b = childB;
      children!.add(childDiff);
      worklist.add(childDiff);
    }

    if (children!.length == 0) {
      // Compress.
      children = const <ProcessItemDiff>[];
    }
  }

  void _computeArea() {
    int g = 0;
    int l = 0;
    int c = 0;
    for (var child in children!) {
      g += child.retainedGain;
      l += child.retainedLoss;
      c += child.retainedCommon;
    }
    int d = shallowSizeDiff;
    if (d > 0) {
      g += d;
      c += shallowSizeA;
    } else {
      l -= d;
      c += shallowSizeB;
    }
    assert(retainedSizeA + g - l == retainedSizeB);
    retainedGain = g;
    retainedLoss = l;
    retainedCommon = c;
  }
}

class ProcessItemDiffTreeMap extends DiffTreeMap<ProcessItemDiff> {
  ProcessSnapshotElement element;
  ProcessItemDiffTreeMap(this.element);

  int getSizeA(ProcessItemDiff node) => node.retainedSizeA;
  int getSizeB(ProcessItemDiff node) => node.retainedSizeB;
  int getGain(ProcessItemDiff node) => node.retainedGain;
  int getLoss(ProcessItemDiff node) => node.retainedLoss;
  int getCommon(ProcessItemDiff node) => node.retainedCommon;

  String getType(ProcessItemDiff node) => node.name;
  String getName(ProcessItemDiff node) => node.name;
  ProcessItemDiff? getParent(ProcessItemDiff node) => node.parent;
  Iterable<ProcessItemDiff> getChildren(ProcessItemDiff node) => node.children!;
  void onSelect(ProcessItemDiff node) {
    element.diffSelection = node;
    element._r.dirty();
  }

  void onDetails(ProcessItemDiff node) {}
}

class ProcessSnapshotElement extends CustomElement implements Renderable {
  late RenderingScheduler<ProcessSnapshotElement> _r;

  Stream<RenderedEvent<ProcessSnapshotElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  M.NotificationRepository get notifications => _notifications;
  M.VMRef get vm => _vm;

  List<Map> _loadedSnapshots = <Map>[];
  Map? selection;
  ProcessItemDiff? diffSelection;
  Map? _snapshotA;
  Map? _snapshotB;
  ProcessSnapshotTreeMode _mode = ProcessSnapshotTreeMode.treeMap;

  factory ProcessSnapshotElement(
    M.VM vm,
    M.EventRepository events,
    M.NotificationRepository notifications, {
    RenderingQueue? queue,
  }) {
    ProcessSnapshotElement e = new ProcessSnapshotElement.created();
    e._r = new RenderingScheduler<ProcessSnapshotElement>(e, queue: queue);
    e._vm = vm;
    e._events = events;
    e._notifications = notifications;
    return e;
  }

  ProcessSnapshotElement.created() : super.created('process-snapshot');

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
    removeChildren();
  }

  void render() {
    final content = <HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        navMenu('process snapshot'),
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((e) {
                _refresh();
              }))
            .element,
        (new NavRefreshElement(label: 'save', queue: _r.queue)
              ..disabled = _snapshotA == null
              ..onRefresh.listen((e) {
                _save();
              }))
            .element,
        (new NavRefreshElement(label: 'load', queue: _r.queue)
              ..onRefresh.listen((e) {
                _load();
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element,
      ]),
    ];
    if (_snapshotA == null) {
      // Loading
      content.add(new HTMLSpanElement()..textContent = "Loading");
    } else {
      // Loaded
      content.addAll(_createReport());
    }
    children = content;
  }

  _refresh() async {
    Map snapshot = await (vm as dynamic).invokeRpcNoUpgrade(
      "getProcessMemoryUsage",
      {},
    );
    _snapshotLoaded(snapshot);
  }

  _save() {
    var blob = new Blob(
      [jsonEncode(_snapshotA).toJS].toJS,
      BlobPropertyBag(type: 'application/json'),
    );
    var blobUrl = URL.createObjectURL(blob);
    var link = new HTMLAnchorElement();
    link.href = blobUrl;
    var now = new DateTime.now();
    link.download = 'dart-process-${now.year}-${now.month}-${now.day}.json';
    link.click();
  }

  _load() {
    var input = new HTMLInputElement();
    input.type = 'file';
    input.multiple = false;
    input.onChange.listen((event) {
      final file = input.files!.item(0);
      final reader = FileReader();
      reader
        ..onLoadEnd.first.then((_) async {
          _snapshotLoaded(jsonDecode(reader.result as String));
        })
        ..readAsText(file as Blob);
    });
    input.click();
  }

  _snapshotLoaded(Map snapshot) {
    _loadedSnapshots.add(snapshot);
    _snapshotA = snapshot;
    _snapshotB = snapshot;
    selection = null;
    diffSelection = null;
    _r.dirty();
  }

  void _createTreeMap<T>(List<HTMLElement> report, TreeMap<T> treemap, T root) {
    final content = new HTMLDivElement();
    content.style.border = '1px solid black';
    content.style.width = '100%';
    content.style.height = '100%';
    content.textContent = 'Performing layout...';
    Timer.run(() {
      // Generate the treemap after the content div has been added to the
      // document so that we can ask the browser how much space is
      // available for treemap layout.
      treemap.showIn(root, content);
    });

    final text =
        'Double-click a tile to zoom in. Double-click the outermost tile to '
        'zoom out. Process memory that is not further subdivided is non-Dart '
        'memory not known to the VM.';
    report.addAll([
      new HTMLDivElement()
        ..className = 'content-centered-big explanation'
        ..textContent = text,
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..style.width = '100%'
        ..style.height = '100%'
        ..appendChild(content),
    ]);
  }

  List<HTMLElement> _createReport() {
    var report = <HTMLElement>[
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberList'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'Snapshot A',
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..appendChildren(_createSnapshotSelectA()),
                ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'Snapshot B',
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..appendChildren(_createSnapshotSelectB()),
                ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = (_snapshotA == _snapshotB)
                        ? 'View '
                        : 'Compare ',
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..appendChildren(_createModeSelect()),
                ]),
            ]),
        ]),
    ];

    switch (_mode) {
      case ProcessSnapshotTreeMode.treeMap:
        if (selection == null) {
          selection = _snapshotA!["root"];
        }
        _createTreeMap(report, new ProcessItemTreeMap(this), selection);
        break;
      case ProcessSnapshotTreeMode.tree:
        if (selection == null) {
          selection = _snapshotA!["root"];
        }
        _tree = new VirtualTreeElement(
          _createItem,
          _updateItem,
          _getChildrenItem,
          items: [selection],
          queue: _r.queue,
        );
        _tree!.expand(selection!);
        report.add(_tree!.element);
        break;
      case ProcessSnapshotTreeMode.treeMapDiff:
        if (diffSelection == null) {
          diffSelection = ProcessItemDiff.from(
            _snapshotA!["root"],
            _snapshotB!["root"],
          );
        }
        _createTreeMap(report, new ProcessItemDiffTreeMap(this), diffSelection);
        break;
      case ProcessSnapshotTreeMode.treeDiff:
        var root = ProcessItemDiff.from(
          _snapshotA!["root"],
          _snapshotB!["root"],
        );
        _tree = new VirtualTreeElement(
          _createItemDiff,
          _updateItemDiff,
          _getChildrenItemDiff,
          items: [root],
          queue: _r.queue,
        );
        _tree!.expand(root);
        report.add(_tree!.element);
        break;
    }

    return report;
  }

  VirtualTreeElement? _tree;

  static HTMLElement _createItem(toggle) {
    return new HTMLDivElement()
      ..className = 'tree-item'
      ..appendChildren(<HTMLElement>[
        new HTMLSpanElement()
          ..className = 'percentage'
          ..title = 'percentage of total',
        new HTMLSpanElement()
          ..className = 'size'
          ..title = 'retained size',
        new HTMLSpanElement()..className = 'lines',
        new HTMLButtonElement()
          ..className = 'expander'
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new HTMLSpanElement()..className = 'name',
      ]);
  }

  static HTMLElement _createItemDiff(toggle) {
    return new HTMLDivElement()
      ..className = 'tree-item'
      ..appendChildren(<HTMLElement>[
        new HTMLSpanElement()
          ..className = 'percentage'
          ..title = 'percentage of total',
        new HTMLSpanElement()
          ..className = 'size'
          ..title = 'retained size A',
        new HTMLSpanElement()
          ..className = 'percentage'
          ..title = 'percentage of total',
        new HTMLSpanElement()
          ..className = 'size'
          ..title = 'retained size B',
        new HTMLSpanElement()
          ..className = 'size'
          ..title = 'retained size change',
        new HTMLSpanElement()..className = 'lines',
        new HTMLButtonElement()
          ..className = 'expander'
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new HTMLSpanElement()..className = 'name',
      ]);
  }

  void _updateItem(HTMLElement element, node, int depth) {
    var size = node["size"];
    var rootSize = _snapshotA!["root"]["size"];
    (element.children.item(0) as HTMLElement).textContent =
        Utils.formatPercentNormalized(size * 1.0 / rootSize);
    (element.children.item(1) as HTMLElement).textContent = Utils.formatSize(
      size,
    );
    _updateLines(element.children.item(2) as HTMLElement, depth);
    if (_getChildrenItem(node).isNotEmpty) {
      (element.children.item(3) as HTMLElement).textContent =
          _tree!.isExpanded(node) ? '▼' : '►';
    } else {
      (element.children.item(3) as HTMLElement).textContent = '';
    }
    (element.children.item(4) as HTMLElement).textContent = node["name"];
    (element.children.item(4) as HTMLElement).title = node["description"];
  }

  void _updateItemDiff(HTMLElement element, nodeDynamic, int depth) {
    ProcessItemDiff node = nodeDynamic;
    (element.children.item(0) as HTMLElement).textContent =
        Utils.formatPercentNormalized(
          node.retainedSizeA * 1.0 / _snapshotA!["root"]["size"],
        );
    (element.children.item(1) as HTMLElement).textContent = Utils.formatSize(
      node.retainedSizeA,
    );
    (element.children.item(2) as HTMLElement).textContent =
        Utils.formatPercentNormalized(
          node.retainedSizeB * 1.0 / _snapshotB!["root"]["size"],
        );
    (element.children.item(3) as HTMLElement).textContent = Utils.formatSize(
      node.retainedSizeB,
    );
    (element.children.item(4) as HTMLElement).textContent =
        (node.retainedSizeDiff > 0 ? '+' : '') +
        Utils.formatSize(node.retainedSizeDiff);
    (element.children.item(4) as HTMLElement).style.color =
        node.retainedSizeDiff > 0 ? "red" : "green";
    _updateLines(element.children.item(5) as HTMLElement, depth);
    if (_getChildrenItemDiff(node).isNotEmpty) {
      (element.children.item(6) as HTMLElement).textContent =
          _tree!.isExpanded(node) ? '▼' : '►';
    } else {
      (element.children.item(6) as HTMLElement).textContent = '';
    }
    (element.children.item(7) as HTMLElement)..textContent = node.name;
  }

  static Iterable _getChildrenItem(node) {
    return new List<Map>.from(node["children"]);
  }

  static Iterable _getChildrenItemDiff(nodeDynamic) {
    ProcessItemDiff node = nodeDynamic;
    final list = node.children!.toList();
    list.sort((a, b) => b.retainedSizeDiff - a.retainedSizeDiff);
    return list;
  }

  static _updateLines(HTMLElement element, int n) {
    n = Math.max(0, n);
    while (element.children.length > n) {
      element.removeChild(element.lastChild!);
    }
    while (element.children.length < n) {
      element.appendChild(HTMLSpanElement());
    }
  }

  static String modeToString(ProcessSnapshotTreeMode mode) {
    switch (mode) {
      case ProcessSnapshotTreeMode.treeMap:
      case ProcessSnapshotTreeMode.treeMapDiff:
        return 'Tree Map';
      case ProcessSnapshotTreeMode.tree:
      case ProcessSnapshotTreeMode.treeDiff:
        return 'Tree';
    }
  }

  List<HTMLElement> _createModeSelect() {
    var modes = _snapshotA == _snapshotB ? _viewModes : _diffModes;
    if (!modes.contains(_mode)) {
      _mode = modes[0];
      _r.dirty();
    }
    final s = new HTMLSelectElement()
      ..className = 'analysis-select'
      ..value = modeToString(_mode)
      ..appendChildren(
        modes.map(
          (mode) => HTMLOptionElement()
            ..value = modeToString(mode)
            ..selected = _mode == mode
            ..textContent = modeToString(mode),
        ),
      );
    return [
      s
        ..onChange.listen((_) {
          _mode = modes[s.selectedIndex];
          _r.dirty();
        }),
    ];
  }

  String snapshotToString(snapshot) {
    if (snapshot == null) return "None";
    return snapshot["root"]["name"] +
        " " +
        Utils.formatSize(snapshot["root"]["size"]);
  }

  List<HTMLElement> _createSnapshotSelectA() {
    final s = HTMLSelectElement()
      ..className = 'analysis-select'
      ..value = snapshotToString(_snapshotA)
      ..appendChildren(
        _loadedSnapshots.map(
          (snapshot) => HTMLOptionElement()
            ..value = snapshotToString(snapshot)
            ..selected = _snapshotA == snapshot
            ..textContent = snapshotToString(snapshot),
        ),
      );
    return [
      s
        ..onChange.listen((_) {
          _snapshotA = _loadedSnapshots[s.selectedIndex];
          selection = null;
          diffSelection = null;
          _r.dirty();
        }),
    ];
  }

  List<HTMLElement> _createSnapshotSelectB() {
    final s = HTMLSelectElement()
      ..className = 'analysis-select'
      ..value = snapshotToString(_snapshotB)
      ..appendChildren(
        _loadedSnapshots.map(
          (snapshot) => HTMLOptionElement()
            ..value = snapshotToString(snapshot)
            ..selected = _snapshotB == snapshot
            ..textContent = snapshotToString(snapshot),
        ),
      );
    return [
      s
        ..onChange.listen((_) {
          _snapshotB = _loadedSnapshots[s.selectedIndex];
          selection = null;
          diffSelection = null;
          _r.dirty();
        }),
    ];
  }
}

// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:math' as Math;
import 'dart:convert';
import 'package:observatory/models.dart' as M;
import 'package:observatory/object_graph.dart';
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/containers/virtual_tree.dart';
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/tree_map.dart';
import 'package:observatory/repositories.dart';
import 'package:observatory/utils.dart';

enum ProcessSnapshotTreeMode {
  treeMap,
  tree,
  treeMapDiff,
  treeDiff,
}

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
    // Compute area botton-up.
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
      M.VM vm, M.EventRepository events, M.NotificationRepository notifications,
      {RenderingQueue? queue}) {
    assert(vm != null);
    assert(events != null);
    assert(notifications != null);
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
    children = <Element>[];
  }

  void render() {
    final content = <Element>[
      navBar(<Element>[
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
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
    ];
    if (_snapshotA == null) {
      // Loading
      content.add(new SpanElement()..text = "Loading");
    } else {
      // Loaded
      content.addAll(_createReport());
    }
    children = content;
  }

  _refresh() async {
    Map snapshot =
        await (vm as dynamic).invokeRpcNoUpgrade("getProcessMemoryUsage", {});
    _snapshotLoaded(snapshot);
  }

  _save() {
    var blob = new Blob([jsonEncode(_snapshotA)], 'application/json');
    var blobUrl = Url.createObjectUrl(blob);
    var link = new AnchorElement();
    // ignore: unsafe_html
    link.href = blobUrl;
    var now = new DateTime.now();
    link.download = 'dart-process-${now.year}-${now.month}-${now.day}.json';
    link.click();
  }

  _load() {
    var input = new InputElement();
    input.type = 'file';
    input.multiple = false;
    input.onChange.listen((event) {
      var file = input.files![0];
      var reader = new FileReader();
      reader.onLoad.listen((event) async {
        _snapshotLoaded(jsonDecode(reader.result as String));
      });
      reader.readAsText(file);
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

  void _createTreeMap<T>(List<HtmlElement> report, TreeMap<T> treemap, T root) {
    final content = new DivElement();
    content.style.border = '1px solid black';
    content.style.width = '100%';
    content.style.height = '100%';
    content.text = 'Performing layout...';
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
      new DivElement()
        ..classes = ['content-centered-big', 'explanation']
        ..text = text,
      new DivElement()
        ..classes = ['content-centered-big']
        ..style.width = '100%'
        ..style.height = '100%'
        ..children = [content]
    ]);
  }

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
                    ..text = 'Snapshot A',
                  new DivElement()
                    ..classes = ['memberName']
                    ..children = _createSnapshotSelectA()
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'Snapshot B',
                  new DivElement()
                    ..classes = ['memberName']
                    ..children = _createSnapshotSelectB()
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = (_snapshotA == _snapshotB) ? 'View ' : 'Compare ',
                  new DivElement()
                    ..classes = ['memberName']
                    ..children = _createModeSelect()
                ]
            ]
        ],
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
            _createItem, _updateItem, _getChildrenItem,
            items: [selection], queue: _r.queue);
        _tree!.expand(selection!);
        report.add(_tree!.element);
        break;
      case ProcessSnapshotTreeMode.treeMapDiff:
        if (diffSelection == null) {
          diffSelection =
              ProcessItemDiff.from(_snapshotA!["root"], _snapshotB!["root"]);
        }
        _createTreeMap(report, new ProcessItemDiffTreeMap(this), diffSelection);
        break;
      case ProcessSnapshotTreeMode.treeDiff:
        var root =
            ProcessItemDiff.from(_snapshotA!["root"], _snapshotB!["root"]);
        _tree = new VirtualTreeElement(
            _createItemDiff, _updateItemDiff, _getChildrenItemDiff,
            items: [root], queue: _r.queue);
        _tree!.expand(root);
        report.add(_tree!.element);
        break;
      default:
        throw new Exception('Unknown ProcessSnapshotTreeMode: $_mode');
    }

    return report;
  }

  VirtualTreeElement? _tree;

  static HtmlElement _createItem(toggle) {
    return new DivElement()
      ..classes = ['tree-item']
      ..children = <Element>[
        new SpanElement()
          ..classes = ['percentage']
          ..title = 'percentage of total',
        new SpanElement()
          ..classes = ['size']
          ..title = 'retained size',
        new SpanElement()..classes = ['lines'],
        new ButtonElement()
          ..classes = ['expander']
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new SpanElement()..classes = ['name'],
      ];
  }

  static HtmlElement _createItemDiff(toggle) {
    return new DivElement()
      ..classes = ['tree-item']
      ..children = <Element>[
        new SpanElement()
          ..classes = ['percentage']
          ..title = 'percentage of total',
        new SpanElement()
          ..classes = ['size']
          ..title = 'retained size A',
        new SpanElement()
          ..classes = ['percentage']
          ..title = 'percentage of total',
        new SpanElement()
          ..classes = ['size']
          ..title = 'retained size B',
        new SpanElement()
          ..classes = ['size']
          ..title = 'retained size change',
        new SpanElement()..classes = ['lines'],
        new ButtonElement()
          ..classes = ['expander']
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new SpanElement()..classes = ['name']
      ];
  }

  void _updateItem(HtmlElement element, node, int depth) {
    var size = node["size"];
    var rootSize = _snapshotA!["root"]["size"];
    element.children[0].text =
        Utils.formatPercentNormalized(size * 1.0 / rootSize);
    element.children[1].text = Utils.formatSize(size);
    _updateLines(element.children[2].children, depth);
    if (_getChildrenItem(node).isNotEmpty) {
      element.children[3].text = _tree!.isExpanded(node) ? '▼' : '►';
    } else {
      element.children[3].text = '';
    }
    element.children[4].text = node["name"];
    element.children[4].title = node["description"];
  }

  void _updateItemDiff(HtmlElement element, nodeDynamic, int depth) {
    ProcessItemDiff node = nodeDynamic;
    element.children[0].text = Utils.formatPercentNormalized(
        node.retainedSizeA * 1.0 / _snapshotA!["root"]["size"]);
    element.children[1].text = Utils.formatSize(node.retainedSizeA);
    element.children[2].text = Utils.formatPercentNormalized(
        node.retainedSizeB * 1.0 / _snapshotB!["root"]["size"]);
    element.children[3].text = Utils.formatSize(node.retainedSizeB);
    element.children[4].text = (node.retainedSizeDiff > 0 ? '+' : '') +
        Utils.formatSize(node.retainedSizeDiff);
    element.children[4].style.color =
        node.retainedSizeDiff > 0 ? "red" : "green";
    _updateLines(element.children[5].children, depth);
    if (_getChildrenItemDiff(node).isNotEmpty) {
      element.children[6].text = _tree!.isExpanded(node) ? '▼' : '►';
    } else {
      element.children[6].text = '';
    }
    element.children[7]..text = node.name;
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

  static _updateLines(List<Element> lines, int n) {
    n = Math.max(0, n);
    while (lines.length > n) {
      lines.removeLast();
    }
    while (lines.length < n) {
      lines.add(new SpanElement());
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
    throw new Exception('Unknown ProcessSnapshotTreeMode: $mode');
  }

  List<Element> _createModeSelect() {
    var s;
    var modes = _snapshotA == _snapshotB ? _viewModes : _diffModes;
    if (!modes.contains(_mode)) {
      _mode = modes[0];
      _r.dirty();
    }
    return [
      s = new SelectElement()
        ..classes = ['analysis-select']
        ..value = modeToString(_mode)
        ..children = modes.map((mode) {
          return new OptionElement(
              value: modeToString(mode), selected: _mode == mode)
            ..text = modeToString(mode);
        }).toList(growable: false)
        ..onChange.listen((_) {
          _mode = modes[s.selectedIndex];
          _r.dirty();
        })
    ];
  }

  String snapshotToString(snapshot) {
    if (snapshot == null) return "None";
    return snapshot["root"]["name"] +
        " " +
        Utils.formatSize(snapshot["root"]["size"]);
  }

  List<Element> _createSnapshotSelectA() {
    var s;
    return [
      s = new SelectElement()
        ..classes = ['analysis-select']
        ..value = snapshotToString(_snapshotA)
        ..children = _loadedSnapshots.map((snapshot) {
          return new OptionElement(
              value: snapshotToString(snapshot),
              selected: _snapshotA == snapshot)
            ..text = snapshotToString(snapshot);
        }).toList(growable: false)
        ..onChange.listen((_) {
          _snapshotA = _loadedSnapshots[s.selectedIndex];
          selection = null;
          diffSelection = null;
          _r.dirty();
        })
    ];
  }

  List<Element> _createSnapshotSelectB() {
    var s;
    return [
      s = new SelectElement()
        ..classes = ['analysis-select']
        ..value = snapshotToString(_snapshotB)
        ..children = _loadedSnapshots.map((snapshot) {
          return new OptionElement(
              value: snapshotToString(snapshot),
              selected: _snapshotB == snapshot)
            ..text = snapshotToString(snapshot);
        }).toList(growable: false)
        ..onChange.listen((_) {
          _snapshotB = _loadedSnapshots[s.selectedIndex];
          selection = null;
          diffSelection = null;
          _r.dirty();
        })
    ];
  }
}

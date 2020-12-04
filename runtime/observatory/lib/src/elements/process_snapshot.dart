// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
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
  Map? _snapshotA;
  Map? _snapshotB;

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
              // TODO(rmacnak): Diffing.
              // new DivElement()
              //  ..classes = ['memberItem']
              //  ..children = <Element>[
              //    new DivElement()
              //      ..classes = ['memberName']
              //      ..text = 'Snapshot B',
              //    new DivElement()
              //      ..classes = ['memberName']
              //      ..children = _createSnapshotSelectB()
              //  ],
            ]
        ],
    ];
    if (selection == null) {
      selection = _snapshotA!["root"];
    }
    _createTreeMap(report, new ProcessItemTreeMap(this), selection);
    return report;
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
          _r.dirty();
        })
    ];
  }
}

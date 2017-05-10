// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/instance_ref.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/view_footer.dart';

class PortsElement extends HtmlElement implements Renderable {
  static const tag = const Tag<PortsElement>('ports-page', dependencies: const [
    NavTopMenuElement.tag,
    NavVMMenuElement.tag,
    NavIsolateMenuElement.tag,
    NavRefreshElement.tag,
    NavNotifyElement.tag,
    InstanceRefElement.tag,
    ViewFooterElement.tag
  ]);

  RenderingScheduler<PortsElement> _r;

  Stream<RenderedEvent<PortsElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.PortsRepository _ports;
  M.ObjectRepository _objects;
  M.Ports _isolatePorts;

  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.PortsRepository get ports => _ports;
  M.VMRef get vm => _vm;

  factory PortsElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.PortsRepository ports,
      M.ObjectRepository objects,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(ports != null);
    assert(objects != null);
    PortsElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._ports = ports;
    e._objects = objects;
    return e;
  }

  PortsElement.created() : super.created();

  int get portCount {
    return _isolatePorts == null ? 0 : _isolatePorts.elements.length;
  }

  @override
  void attached() {
    super.attached();
    _r.enable();
    _refresh();
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
  }

  void render() {
    children = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavVMMenuElement(_vm, _events, queue: _r.queue),
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue),
        navMenu('ports'),
        new NavRefreshElement(queue: _r.queue)
          ..onRefresh.listen((_) => _refresh()),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
      new DivElement()
        ..classes = ['content-centered']
        ..children = [
          new HeadingElement.h1()..text = 'Ports ($portCount)',
          new HRElement(),
          new BRElement(),
          new DivElement()..children = _createList(),
        ],
      new ViewFooterElement(queue: _r.queue)
    ];
  }

  List<Element> _createList() {
    if (_isolatePorts == null) {
      return const [];
    }
    int i = 0;
    return _isolatePorts.elements
        .map((port) => new DivElement()
          ..classes = ['memberItem']
          ..children = [
            new DivElement()
              ..classes = ['memberName']
              ..children = [
                new SpanElement()
                  ..classes = ['port-number']
                  ..text = '[ ${++i} ] ',
                new SpanElement()..text = '${port.name}'
              ],
            new DivElement()
              ..classes = ['memberValue']
              ..children = [
                anyRef(_isolate, port.handler, _objects, queue: _r.queue)
              ]
          ])
        .toList();
  }

  Future _refresh() async {
    _isolatePorts = null;
    _r.dirty();
    _isolatePorts = await _ports.get(_isolate);
    _r.dirty();
  }
}

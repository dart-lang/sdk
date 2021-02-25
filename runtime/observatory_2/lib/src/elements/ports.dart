// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/src/elements/helpers/any_ref.dart';
import 'package:observatory_2/src/elements/helpers/nav_bar.dart';
import 'package:observatory_2/src/elements/helpers/nav_menu.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/src/elements/instance_ref.dart';
import 'package:observatory_2/src/elements/nav/isolate_menu.dart';
import 'package:observatory_2/src/elements/nav/notify.dart';
import 'package:observatory_2/src/elements/nav/refresh.dart';
import 'package:observatory_2/src/elements/nav/top_menu.dart';
import 'package:observatory_2/src/elements/nav/vm_menu.dart';
import 'package:observatory_2/src/elements/view_footer.dart';

class PortsElement extends CustomElement implements Renderable {
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
    PortsElement e = new PortsElement.created();
    e._r = new RenderingScheduler<PortsElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._ports = ports;
    e._objects = objects;
    return e;
  }

  PortsElement.created() : super.created('ports-page');

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
    children = <Element>[];
    _r.disable(notify: true);
  }

  void render() {
    children = <Element>[
      navBar(<Element>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu('ports'),
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((_) => _refresh()))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new DivElement()
        ..classes = ['content-centered']
        ..children = <Element>[
          new HeadingElement.h1()..text = 'Ports ($portCount)',
          new HRElement(),
          new BRElement(),
          new DivElement()..children = _createList(),
        ],
      new ViewFooterElement(queue: _r.queue).element
    ];
  }

  List<Element> _createList() {
    if (_isolatePorts == null) {
      return const [];
    }
    int i = 0;
    return _isolatePorts.elements
        .map<Element>((port) => new DivElement()
          ..classes = ['memberItem']
          ..children = <Element>[
            new DivElement()
              ..classes = ['memberName']
              ..children = <Element>[
                new SpanElement()
                  ..classes = ['port-number']
                  ..text = '[ ${++i} ] ',
                new SpanElement()..text = '${port.name}'
              ],
            new DivElement()
              ..classes = ['memberValue']
              ..children = <Element>[
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

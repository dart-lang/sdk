// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';

class PortsElement extends CustomElement implements Renderable {
  late RenderingScheduler<PortsElement> _r;

  Stream<RenderedEvent<PortsElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.PortsRepository _ports;
  late M.ObjectRepository _objects;
  M.Ports? _isolatePorts;

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
      {RenderingQueue? queue}) {
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
    return _isolatePorts == null ? 0 : _isolatePorts!.elements.length;
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
    removeChildren();
    _r.disable(notify: true);
  }

  void render() {
    setChildren(<HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu('ports'),
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((_) => _refresh()))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new HTMLDivElement()
        ..className = 'content-centered'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h1()..textContent = 'Ports ($portCount)',
          new HTMLHRElement(),
          new HTMLBRElement(),
          new HTMLDivElement()..appendChildren(_createList()),
        ]),
    ]);
  }

  List<HTMLElement> _createList() {
    if (_isolatePorts == null) {
      return const [];
    }
    int i = 0;
    return _isolatePorts!.elements
        .map<HTMLElement>((port) => new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..appendChildren(<HTMLElement>[
                new HTMLSpanElement()
                  ..className = 'port-number'
                  ..textContent = '[ ${++i} ] ',
                new HTMLSpanElement()..textContent = '${port.name}'
              ]),
            new HTMLDivElement()
              ..className = 'memberValue'
              ..appendChildren(<HTMLElement>[
                anyRef(_isolate, port.handler, _objects, queue: _r.queue)
              ])
          ]))
        .toList();
  }

  Future _refresh() async {
    _isolatePorts = null;
    _r.dirty();
    _isolatePorts = await _ports.get(_isolate);
    _r.dirty();
  }
}

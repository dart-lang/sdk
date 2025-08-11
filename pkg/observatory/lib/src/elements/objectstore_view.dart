// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library objectstore_view_element;

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'helpers/any_ref.dart';
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/nav_bar.dart';
import 'helpers/rendering_scheduler.dart';
import 'nav/isolate_menu.dart';
import 'nav/notify.dart';
import 'nav/refresh.dart';
import 'nav/top_menu.dart';
import 'nav/vm_menu.dart';

class ObjectStoreViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<ObjectStoreViewElement> _r;

  Stream<RenderedEvent<ObjectStoreViewElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  M.ObjectStore? _store;
  late M.ObjectStoreRepository _stores;
  late M.ObjectRepository _objects;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;

  factory ObjectStoreViewElement(
    M.VM vm,
    M.IsolateRef isolate,
    M.EventRepository events,
    M.NotificationRepository notifications,
    M.ObjectStoreRepository stores,
    M.ObjectRepository objects, {
    RenderingQueue? queue,
  }) {
    ObjectStoreViewElement e = new ObjectStoreViewElement.created();
    e._r = new RenderingScheduler<ObjectStoreViewElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._stores = stores;
    e._objects = objects;
    return e;
  }

  ObjectStoreViewElement.created() : super.created('objectstore-view');

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
    final fields = _store?.fields.toList(growable: false);
    children = <HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        (new NavRefreshElement(
          disabled: _store == null,
          queue: _r.queue,
        )..onRefresh.listen((e) => _refresh())).element,
        (new NavNotifyElement(_notifications, queue: _r.queue).element),
      ]),
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h1()
            ..textContent = fields == null
                ? 'Object Store'
                : 'Object Store (${fields.length})',
          new HTMLHRElement(),
          fields == null
              ? (new HTMLHeadingElement.h2()..textContent = 'Loading...')
              : (new HTMLDivElement()
                  ..className = 'memberList'
                  ..appendChildren(
                    fields.map<HTMLElement>(
                      (field) => new HTMLDivElement()
                        ..className = 'memberItem'
                        ..appendChildren(<HTMLElement>[
                          new HTMLDivElement()
                            ..className = 'memberName'
                            ..textContent = field.name,
                          new HTMLDivElement()
                            ..className = 'memberValue'
                            ..appendChildren(<HTMLElement>[
                              anyRef(
                                _isolate,
                                field.value,
                                _objects,
                                queue: _r.queue,
                              ),
                            ]),
                        ]),
                    ),
                  )),
        ]),
    ];
  }

  Future _refresh() async {
    _store = null;
    _r.dirty();
    _store = await _stores.get(_isolate);
    _r.dirty();
  }
}

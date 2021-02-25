// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library objectstore_view_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/instance_ref.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/view_footer.dart';

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
      M.ObjectRepository objects,
      {RenderingQueue? queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(stores != null);
    assert(objects != null);
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
    children = <Element>[];
  }

  void render() {
    final fields = _store?.fields.toList(growable: false);
    children = <Element>[
      navBar(<Element>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        (new NavRefreshElement(disabled: _store == null, queue: _r.queue)
              ..onRefresh.listen((e) => _refresh()))
            .element,
        (new NavNotifyElement(_notifications, queue: _r.queue).element)
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = <Element>[
          new HeadingElement.h1()
            ..text = fields == null
                ? 'Object Store'
                : 'Object Store (${fields.length})',
          new HRElement(),
          fields == null
              ? (new HeadingElement.h2()..text = 'Loading...')
              : (new DivElement()
                ..classes = ['memberList']
                ..children = fields
                    .map<Element>((field) => new DivElement()
                      ..classes = ['memberItem']
                      ..children = <Element>[
                        new DivElement()
                          ..classes = ['memberName']
                          ..text = field.name,
                        new DivElement()
                          ..classes = ['memberValue']
                          ..children = <Element>[
                            anyRef(_isolate, field.value, _objects,
                                queue: _r.queue)
                          ]
                      ])
                    .toList()),
          new ViewFooterElement(queue: _r.queue).element
        ]
    ];
  }

  Future _refresh() async {
    _store = null;
    _r.dirty();
    _store = await _stores.get(_isolate);
    _r.dirty();
  }
}

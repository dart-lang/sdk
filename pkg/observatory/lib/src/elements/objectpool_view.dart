// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library objectpool_view;

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'helpers/any_ref.dart';
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/nav_bar.dart';
import 'helpers/nav_menu.dart';
import 'helpers/rendering_scheduler.dart';
import 'nav/isolate_menu.dart';
import 'nav/notify.dart';
import 'nav/refresh.dart';
import 'nav/top_menu.dart';
import 'nav/vm_menu.dart';
import 'object_common.dart';

class ObjectPoolViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<ObjectPoolViewElement> _r;

  Stream<RenderedEvent<ObjectPoolViewElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.ObjectPool _pool;
  late M.ObjectPoolRepository _pools;
  late M.RetainedSizeRepository _retainedSizes;
  late M.ReachableSizeRepository _reachableSizes;
  late M.InboundReferencesRepository _references;
  late M.RetainingPathRepository _retainingPaths;
  late M.ObjectRepository _objects;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.ObjectPoolRef get pool => _pool;

  factory ObjectPoolViewElement(
    M.VM vm,
    M.IsolateRef isolate,
    M.ObjectPool pool,
    M.EventRepository events,
    M.NotificationRepository notifications,
    M.ObjectPoolRepository pools,
    M.RetainedSizeRepository retainedSizes,
    M.ReachableSizeRepository reachableSizes,
    M.InboundReferencesRepository references,
    M.RetainingPathRepository retainingPaths,
    M.ObjectRepository objects, {
    RenderingQueue? queue,
  }) {
    ObjectPoolViewElement e = new ObjectPoolViewElement.created();
    e._r = new RenderingScheduler<ObjectPoolViewElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._pool = pool;
    e._pools = pools;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._references = references;
    e._retainingPaths = retainingPaths;
    e._objects = objects;
    return e;
  }

  ObjectPoolViewElement.created() : super.created('object-pool-view');

  @override
  attached() {
    super.attached();
    _r.enable();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    removeChildren();
  }

  void render() {
    children = <HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu('instance'),
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                _pool = await _pools.get(_isolate, _pool.id!);
                _r.dirty();
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element,
      ]),
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h2()..textContent = 'ObjectPool',
          new HTMLHRElement(),
          new ObjectCommonElement(
            _isolate,
            _pool,
            _retainedSizes,
            _reachableSizes,
            _references,
            _retainingPaths,
            _objects,
            queue: _r.queue,
          ).element,
          new HTMLHRElement(),
          new HTMLHeadingElement.h3()
            ..textContent = 'entries (${_pool.entries!.length})',
          new HTMLDivElement()
            ..className = 'memberList'
            ..appendChildren(
              _pool.entries!.map<HTMLElement>(
                (entry) => new HTMLDivElement()
                  ..className = 'memberItem'
                  ..appendChildren(<HTMLElement>[
                    new HTMLDivElement()
                      ..className = 'memberName hexadecimal'
                      ..textContent =
                          '[PP+0x${entry.offset.toRadixString(16)}]',
                    new HTMLDivElement()
                      ..className = 'memberName'
                      ..appendChildren(_createEntry(entry)),
                  ]),
              ),
            ),
        ]),
    ];
  }

  List<HTMLElement> _createEntry(M.ObjectPoolEntry entry) {
    switch (entry.kind) {
      case M.ObjectPoolEntryKind.nativeEntryData:
      case M.ObjectPoolEntryKind.object:
        return [anyRef(_isolate, entry.asObject, _objects, queue: _r.queue)];
      case M.ObjectPoolEntryKind.immediate:
        return [
          new HTMLSpanElement()
            ..textContent = 'Immediate ${entry.asImmediate!}',
        ];
      case M.ObjectPoolEntryKind.nativeEntry:
        return [
          new HTMLSpanElement()
            ..textContent = 'NativeEntry ${entry.asImmediate!}',
        ];
    }
  }
}

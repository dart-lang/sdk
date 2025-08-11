// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library megamorphiccache_view;

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

class MegamorphicCacheViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<MegamorphicCacheViewElement> _r;

  Stream<RenderedEvent<MegamorphicCacheViewElement>> get onRendered =>
      _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.MegamorphicCache _cache;
  late M.MegamorphicCacheRepository _caches;
  late M.RetainedSizeRepository _retainedSizes;
  late M.ReachableSizeRepository _reachableSizes;
  late M.InboundReferencesRepository _references;
  late M.RetainingPathRepository _retainingPaths;
  late M.ObjectRepository _objects;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.MegamorphicCache get cache => _cache;

  factory MegamorphicCacheViewElement(
    M.VM vm,
    M.IsolateRef isolate,
    M.MegamorphicCache cache,
    M.EventRepository events,
    M.NotificationRepository notifications,
    M.MegamorphicCacheRepository caches,
    M.RetainedSizeRepository retainedSizes,
    M.ReachableSizeRepository reachableSizes,
    M.InboundReferencesRepository references,
    M.RetainingPathRepository retainingPaths,
    M.ObjectRepository objects, {
    RenderingQueue? queue,
  }) {
    MegamorphicCacheViewElement e = new MegamorphicCacheViewElement.created();
    e._r = new RenderingScheduler<MegamorphicCacheViewElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._cache = cache;
    e._caches = caches;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._references = references;
    e._retainingPaths = retainingPaths;
    e._objects = objects;
    return e;
  }

  MegamorphicCacheViewElement.created()
    : super.created('megamorphiccache-view');

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
        navMenu('megamorphic inline cache'),
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                _cache = await _caches.get(_isolate, _cache.id!);
                _r.dirty();
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element,
      ]),
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h2()..textContent = 'Megamorphic Cache',
          new HTMLHRElement(),
          new ObjectCommonElement(
            _isolate,
            _cache,
            _retainedSizes,
            _reachableSizes,
            _references,
            _retainingPaths,
            _objects,
            queue: _r.queue,
          ).element,
          new HTMLBRElement(),
          new HTMLDivElement()
            ..className = 'memberList'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'selector',
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = '${_cache.selector}',
                ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'mask',
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = '${_cache.mask}',
                ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'buckets',
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..appendChildren(<HTMLElement>[
                      anyRef(
                        _isolate,
                        _cache.buckets,
                        _objects,
                        queue: _r.queue,
                      ),
                    ]),
                ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'argumentsDescriptor',
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..appendChildren(<HTMLElement>[
                      anyRef(
                        _isolate,
                        _cache.argumentsDescriptor,
                        _objects,
                        queue: _r.queue,
                      ),
                    ]),
                ]),
            ]),
        ]),
    ];
  }
}

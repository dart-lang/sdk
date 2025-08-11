// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
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
import 'package:observatory/src/elements/object_common.dart';

class SingleTargetCacheViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<SingleTargetCacheViewElement> _r;

  Stream<RenderedEvent<SingleTargetCacheViewElement>> get onRendered =>
      _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.SingleTargetCache _singleTargetCache;
  late M.SingleTargetCacheRepository _singleTargetCaches;
  late M.RetainedSizeRepository _retainedSizes;
  late M.ReachableSizeRepository _reachableSizes;
  late M.InboundReferencesRepository _references;
  late M.RetainingPathRepository _retainingPaths;
  late M.ObjectRepository _objects;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.SingleTargetCache get singleTargetCache => _singleTargetCache;

  factory SingleTargetCacheViewElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.SingleTargetCache singleTargetCache,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.SingleTargetCacheRepository singleTargetCaches,
      M.RetainedSizeRepository retainedSizes,
      M.ReachableSizeRepository reachableSizes,
      M.InboundReferencesRepository references,
      M.RetainingPathRepository retainingPaths,
      M.ObjectRepository objects,
      {RenderingQueue? queue}) {
    SingleTargetCacheViewElement e = new SingleTargetCacheViewElement.created();
    e._r =
        new RenderingScheduler<SingleTargetCacheViewElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._singleTargetCache = singleTargetCache;
    e._singleTargetCaches = singleTargetCaches;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._references = references;
    e._retainingPaths = retainingPaths;
    e._objects = objects;
    return e;
  }

  SingleTargetCacheViewElement.created()
      : super.created(
          'singletargetcache-view',
        );

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
    setChildren(<HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu('singleTargetCache'),
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                _singleTargetCache = await _singleTargetCaches.get(
                    _isolate, _singleTargetCache.id!);
                _r.dirty();
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h2()..textContent = 'SingleTargetCache',
          new HTMLHRElement(),
          new ObjectCommonElement(_isolate, _singleTargetCache, _retainedSizes,
                  _reachableSizes, _references, _retainingPaths, _objects,
                  queue: _r.queue)
              .element,
          new HTMLDivElement()
            ..className = 'memberList'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'target',
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..appendChildren(<HTMLElement>[
                      anyRef(_isolate, _singleTargetCache.target, _objects,
                          queue: _r.queue)
                    ])
                ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'lowerLimit',
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..appendChildren(<HTMLElement>[
                      new HTMLSpanElement()
                        ..textContent = _singleTargetCache.lowerLimit.toString()
                    ])
                ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'upperLimit',
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..appendChildren(<HTMLElement>[
                      new HTMLSpanElement()
                        ..textContent = _singleTargetCache.upperLimit.toString()
                    ])
                ])
            ]),
        ])
    ]);
  }
}

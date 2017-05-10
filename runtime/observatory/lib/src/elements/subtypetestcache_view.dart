// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/object_common.dart';
import 'package:observatory/src/elements/view_footer.dart';

class SubtypeTestCacheViewElement extends HtmlElement implements Renderable {
  static const tag = const Tag<SubtypeTestCacheViewElement>(
      'subtypetestcache-view',
      dependencies: const [
        CurlyBlockElement.tag,
        NavTopMenuElement.tag,
        NavVMMenuElement.tag,
        NavIsolateMenuElement.tag,
        NavRefreshElement.tag,
        NavNotifyElement.tag,
        ObjectCommonElement.tag,
        ViewFooterElement.tag
      ]);

  RenderingScheduler<SubtypeTestCacheViewElement> _r;

  Stream<RenderedEvent<SubtypeTestCacheViewElement>> get onRendered =>
      _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.SubtypeTestCache _subtypeTestCache;
  M.SubtypeTestCacheRepository _subtypeTestCaches;
  M.RetainedSizeRepository _retainedSizes;
  M.ReachableSizeRepository _reachableSizes;
  M.InboundReferencesRepository _references;
  M.RetainingPathRepository _retainingPaths;
  M.ObjectRepository _objects;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.SubtypeTestCache get subtypeTestCache => _subtypeTestCache;

  factory SubtypeTestCacheViewElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.SubtypeTestCache subtypeTestCache,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.SubtypeTestCacheRepository subtypeTestCaches,
      M.RetainedSizeRepository retainedSizes,
      M.ReachableSizeRepository reachableSizes,
      M.InboundReferencesRepository references,
      M.RetainingPathRepository retainingPaths,
      M.ObjectRepository objects,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(subtypeTestCache != null);
    assert(subtypeTestCaches != null);
    assert(retainedSizes != null);
    assert(reachableSizes != null);
    assert(references != null);
    assert(retainingPaths != null);
    assert(objects != null);
    SubtypeTestCacheViewElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._subtypeTestCache = subtypeTestCache;
    e._subtypeTestCaches = subtypeTestCaches;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._references = references;
    e._retainingPaths = retainingPaths;
    e._objects = objects;
    return e;
  }

  SubtypeTestCacheViewElement.created() : super.created();

  @override
  attached() {
    super.attached();
    _r.enable();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  void render() {
    children = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavVMMenuElement(_vm, _events, queue: _r.queue),
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue),
        navMenu('subtypeTestCache'),
        new NavRefreshElement(queue: _r.queue)
          ..onRefresh.listen((e) async {
            e.element.disabled = true;
            _subtypeTestCache =
                await _subtypeTestCaches.get(_isolate, _subtypeTestCache.id);
            _r.dirty();
          }),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new HeadingElement.h2()..text = 'SubtypeTestCache',
          new HRElement(),
          new ObjectCommonElement(_isolate, _subtypeTestCache, _retainedSizes,
              _reachableSizes, _references, _retainingPaths, _objects,
              queue: _r.queue),
          new DivElement()
            ..classes = ['memberList']
            ..children = [
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'cache',
                  new DivElement()
                    ..classes = ['memberName']
                    ..children = [
                      anyRef(_isolate, _subtypeTestCache.cache, _objects,
                          queue: _r.queue)
                    ]
                ]
            ],
          new HRElement(),
          new ViewFooterElement(queue: _r.queue)
        ]
    ];
  }
}

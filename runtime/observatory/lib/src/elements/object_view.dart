// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/context_ref.dart';
import 'package:observatory/src/elements/curly_block.dart';
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

class ObjectViewElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<ObjectViewElement>('object-view', dependencies: const [
    ContextRefElement.tag,
    CurlyBlockElement.tag,
    NavTopMenuElement.tag,
    NavVMMenuElement.tag,
    NavIsolateMenuElement.tag,
    NavRefreshElement.tag,
    NavNotifyElement.tag,
    ObjectCommonElement.tag,
    ViewFooterElement.tag
  ]);

  RenderingScheduler<ObjectViewElement> _r;

  Stream<RenderedEvent<ObjectViewElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.Object _object;
  M.ObjectRepository _objects;
  M.RetainedSizeRepository _retainedSizes;
  M.ReachableSizeRepository _reachableSizes;
  M.InboundReferencesRepository _references;
  M.RetainingPathRepository _retainingPaths;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.Context get object => _object;

  factory ObjectViewElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.Object object,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.ObjectRepository objects,
      M.RetainedSizeRepository retainedSizes,
      M.ReachableSizeRepository reachableSizes,
      M.InboundReferencesRepository references,
      M.RetainingPathRepository retainingPaths,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(object != null);
    assert(objects != null);
    assert(retainedSizes != null);
    assert(reachableSizes != null);
    assert(references != null);
    assert(retainingPaths != null);
    ObjectViewElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._object = object;
    e._objects = objects;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._references = references;
    e._retainingPaths = retainingPaths;
    return e;
  }

  ObjectViewElement.created() : super.created();

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
        navMenu('object'),
        new NavRefreshElement(queue: _r.queue)
          ..onRefresh.listen((e) async {
            e.element.disabled = true;
            _object = await _objects.get(_isolate, _object.id);
            _r.dirty();
          }),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new HeadingElement.h2()..text = 'Object',
          new HRElement(),
          new ObjectCommonElement(_isolate, _object, _retainedSizes,
              _reachableSizes, _references, _retainingPaths, _objects,
              queue: _r.queue),
          new HRElement(),
          new ViewFooterElement(queue: _r.queue)
        ]
    ];
  }
}

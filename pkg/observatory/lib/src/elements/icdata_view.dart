// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

class ICDataViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<ICDataViewElement> _r;

  Stream<RenderedEvent<ICDataViewElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.ICData _icdata;
  late M.ICDataRepository _icdatas;
  late M.RetainedSizeRepository _retainedSizes;
  late M.ReachableSizeRepository _reachableSizes;
  late M.InboundReferencesRepository _references;
  late M.RetainingPathRepository _retainingPaths;
  late M.ObjectRepository _objects;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.ICData get icdata => _icdata;

  factory ICDataViewElement(
    M.VM vm,
    M.IsolateRef isolate,
    M.ICData icdata,
    M.EventRepository events,
    M.NotificationRepository notifications,
    M.ICDataRepository icdatas,
    M.RetainedSizeRepository retainedSizes,
    M.ReachableSizeRepository reachableSizes,
    M.InboundReferencesRepository references,
    M.RetainingPathRepository retainingPaths,
    M.ObjectRepository objects, {
    RenderingQueue? queue,
  }) {
    ICDataViewElement e = new ICDataViewElement.created();
    e._r = new RenderingScheduler<ICDataViewElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._icdata = icdata;
    e._icdatas = icdatas;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._references = references;
    e._retainingPaths = retainingPaths;
    e._objects = objects;
    return e;
  }

  ICDataViewElement.created() : super.created('icdata-view');

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
        navMenu('icdata'),
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                _icdata = await _icdatas.get(_isolate, _icdata.id!);
                _r.dirty();
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element,
      ]),
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h2()..textContent = 'ICData',
          new HTMLHRElement(),
          new ObjectCommonElement(
            _isolate,
            _icdata,
            _retainedSizes,
            _reachableSizes,
            _references,
            _retainingPaths,
            _objects,
            queue: _r.queue,
          ).element,
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
                    ..textContent = _icdata.selector ?? '',
                ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'owner',
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..appendChildren(<HTMLElement>[
                      _icdata.dartOwner == null
                          ? (new HTMLSpanElement()..textContent = '<none>')
                          : anyRef(
                              _isolate,
                              _icdata.dartOwner,
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
                      _icdata.argumentsDescriptor == null
                          ? (new HTMLSpanElement()..textContent = '<none>')
                          : anyRef(
                              _isolate,
                              _icdata.argumentsDescriptor,
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
                    ..textContent = 'entries',
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..appendChildren(<HTMLElement>[
                      _icdata.entries == null
                          ? (new HTMLSpanElement()..textContent = '<none>')
                          : anyRef(
                              _isolate,
                              _icdata.entries,
                              _objects,
                              queue: _r.queue,
                            ),
                    ]),
                ]),
            ]),
          new HTMLHRElement(),
        ]),
    ]);
  }
}

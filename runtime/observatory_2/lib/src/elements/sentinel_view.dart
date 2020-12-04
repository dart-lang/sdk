// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/src/elements/helpers/nav_bar.dart';
import 'package:observatory_2/src/elements/helpers/nav_menu.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/src/elements/nav/isolate_menu.dart';
import 'package:observatory_2/src/elements/nav/notify.dart';
import 'package:observatory_2/src/elements/nav/top_menu.dart';
import 'package:observatory_2/src/elements/nav/vm_menu.dart';
import 'package:observatory_2/src/elements/view_footer.dart';

class SentinelViewElement extends CustomElement implements Renderable {
  RenderingScheduler<SentinelViewElement> _r;

  Stream<RenderedEvent<SentinelViewElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.Sentinel _sentinel;
  M.EventRepository _events;
  M.NotificationRepository _notifications;

  M.Sentinel get sentinel => _sentinel;

  factory SentinelViewElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.Sentinel sentinel,
      M.EventRepository events,
      M.NotificationRepository notifications,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(sentinel != null);
    assert(events != null);
    assert(notifications != null);
    SentinelViewElement e = new SentinelViewElement.created();
    e._r = new RenderingScheduler<SentinelViewElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._sentinel = sentinel;
    e._events = events;
    e._notifications = notifications;
    return e;
  }

  SentinelViewElement.created() : super.created('sentinel-view');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    text = '';
    title = '';
  }

  void render() {
    children = <Element>[
      navBar(<Element>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu('sentinel'),
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = <Element>[
          new HeadingElement.h2()
            ..text = 'Sentinel: #{_sentinel.valueAsString}',
          new HRElement(),
          new DivElement()..text = _sentinelKindToDescription(_sentinel.kind),
          new HRElement(),
          new ViewFooterElement(queue: _r.queue).element
        ]
    ];
  }

  static String _sentinelKindToDescription(M.SentinelKind kind) {
    switch (kind) {
      case M.SentinelKind.collected:
        return 'This object has been reclaimed by the garbage collector.';
      case M.SentinelKind.expired:
        return 'The handle to this object has expired. '
            'Consider refreshing the page.';
      case M.SentinelKind.notInitialized:
        return 'This object will be initialized once it is accessed by '
            'the program.';
      case M.SentinelKind.initializing:
        return 'This object is currently being initialized.';
      case M.SentinelKind.optimizedOut:
        return 'This object is no longer needed and has been removed by the '
            'optimizing compiler.';
      case M.SentinelKind.free:
        return '';
    }
    throw new Exception('Unknown SentinelKind: $kind');
  }
}

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../../../models.dart' as M show IsolateRef, EventRepository;
import '../helpers/custom_element.dart';
import '../helpers/nav_menu.dart';
import '../helpers/rendering_scheduler.dart';
import '../helpers/uris.dart';
import 'menu_item.dart';

class NavIsolateMenuElement extends CustomElement implements Renderable {
  late RenderingScheduler<NavIsolateMenuElement> _r;

  Stream<RenderedEvent<NavIsolateMenuElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  StreamSubscription? _updatesSubscription;
  late Iterable<HTMLElement> _content = const [];

  M.IsolateRef get isolate => _isolate;
  Iterable<HTMLElement> get content => _content;

  set content(Iterable<HTMLElement> value) {
    _content = value.toList();
    _r.dirty();
  }

  factory NavIsolateMenuElement(
    M.IsolateRef isolate,
    M.EventRepository events, {
    RenderingQueue? queue,
  }) {
    NavIsolateMenuElement e = new NavIsolateMenuElement.created();
    e._r = new RenderingScheduler<NavIsolateMenuElement>(e, queue: queue);
    e._isolate = isolate;
    e._events = events;
    return e;
  }

  NavIsolateMenuElement.created() : super.created('nav-isolate-menu');

  @override
  void attached() {
    super.attached();
    _updatesSubscription = _events.onIsolateUpdate
        .where((e) => e.isolate.id == isolate.id)
        .listen((e) {
          _isolate = e.isolate;
          _r.dirty();
        });
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    removeChildren();
    _r.disable(notify: true);
    assert(_updatesSubscription != null);
    _updatesSubscription!.cancel();
    _updatesSubscription = null;
  }

  void render() {
    final content = <HTMLElement>[
      new NavMenuItemElement(
        'debugger',
        queue: _r.queue,
        link: Uris.debugger(isolate),
      ).element,
      new NavMenuItemElement(
        'class hierarchy',
        queue: _r.queue,
        link: Uris.classTree(isolate),
      ).element,
      new NavMenuItemElement(
        'cpu profile',
        queue: _r.queue,
        link: Uris.cpuProfiler(isolate),
      ).element,
      new NavMenuItemElement(
        'cpu profile (table)',
        queue: _r.queue,
        link: Uris.cpuProfilerTable(isolate),
      ).element,
      new NavMenuItemElement(
        'allocation profile',
        queue: _r.queue,
        link: Uris.allocationProfiler(isolate),
      ).element,
      new NavMenuItemElement(
        'heap snapshot',
        queue: _r.queue,
        link: Uris.heapSnapshot(isolate),
      ).element,
      new NavMenuItemElement(
        'heap map',
        queue: _r.queue,
        link: Uris.heapMap(isolate),
      ).element,
      new NavMenuItemElement(
        'metrics',
        queue: _r.queue,
        link: Uris.metrics(isolate),
      ).element,
      new NavMenuItemElement(
        'persistent handles',
        queue: _r.queue,
        link: Uris.persistentHandles(isolate),
      ).element,
      new NavMenuItemElement(
        'ports',
        queue: _r.queue,
        link: Uris.ports(isolate),
      ).element,
      new NavMenuItemElement(
        'logging',
        queue: _r.queue,
        link: Uris.logging(isolate),
      ).element,
    ]..addAll(_content);
    children = <HTMLElement>[
      navMenu(isolate.name!, content: content, link: Uris.inspect(isolate)),
    ];
  }
}

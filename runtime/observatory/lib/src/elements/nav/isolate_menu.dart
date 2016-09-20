// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M show IsolateRef, EventRepository;
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/menu_item.dart';

class NavIsolateMenuElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NavIsolateMenuElement>('nav-isolate-menu',
      dependencies: const [NavMenuItemElement.tag]);

  RenderingScheduler _r;

  Stream<RenderedEvent<NavIsolateMenuElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.EventRepository _events;
  StreamSubscription _updatesSubscription;
  Iterable<Element> _content = const [];

  M.IsolateRef get isolate => _isolate;
  Iterable<Element> get content => _content;

  set content(Iterable<Element> value) {
    _content = value.toList();
    _r.dirty();
  }

  factory NavIsolateMenuElement(M.IsolateRef isolate, M.EventRepository events,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(events != null);
    NavIsolateMenuElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._events = events;
    return e;
  }

  NavIsolateMenuElement.created() : super.created();

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
    children = [];
    _r.disable(notify: true);
    assert(_updatesSubscription != null);
    _updatesSubscription.cancel();
    _updatesSubscription = null;
  }

  void render() {
    final content = [
      new NavMenuItemElement('debugger',
          queue: _r.queue, link: Uris.debugger(isolate)),
      new NavMenuItemElement('class hierarchy',
          queue: _r.queue, link: Uris.classTree(isolate)),
      new NavMenuItemElement('cpu profile',
          queue: _r.queue, link: Uris.cpuProfiler(isolate)),
      new NavMenuItemElement('cpu profile (table)',
          queue: _r.queue, link: Uris.cpuProfilerTable(isolate)),
      new NavMenuItemElement('allocation profile',
          queue: _r.queue, link: Uris.allocationProfiler(isolate)),
      new NavMenuItemElement('heap snapshot',
          queue: _r.queue, link: Uris.heapSnapshot(isolate)),
      new NavMenuItemElement('heap map',
          queue: _r.queue, link: Uris.heapMap(isolate)),
      new NavMenuItemElement('metrics',
          queue: _r.queue, link: Uris.metrics(isolate)),
      new NavMenuItemElement('persistent handles',
          queue: _r.queue, link: Uris.persistentHandles(isolate)),
      new NavMenuItemElement('ports',
          queue: _r.queue, link: Uris.ports(isolate)),
      new NavMenuItemElement('logging',
          queue: _r.queue, link: Uris.logging(isolate)),
    ]..addAll(_content);
    children = [
      navMenu(isolate.name, content: content, link: Uris.inspect(isolate))
    ];
  }
}

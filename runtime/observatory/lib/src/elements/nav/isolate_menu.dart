// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M
  show IsolateRef, IsolateUpdateEvent;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/menu.dart';
import 'package:observatory/src/elements/nav/menu_item.dart';

class NavIsolateMenuElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NavIsolateMenuElement>('nav-isolate-menu',
                     dependencies: const [NavMenuElement.tag,
                                          NavMenuItemElement.tag]);

  RenderingScheduler _r;

  Stream<RenderedEvent<NavIsolateMenuElement>> get onRendered => _r.onRendered;

  Stream<M.IsolateUpdateEvent> _updates;
  StreamSubscription _updatesSubscription;

  bool _last;
  M.IsolateRef _isolate;
  bool get last => _last;
  M.IsolateRef get isolate => _isolate;
  set last(bool value) => _last = _r.checkAndReact(_last, value);

  factory NavIsolateMenuElement(M.IsolateRef isolate,
      Stream<M.IsolateUpdateEvent> updates, {bool last: false,
      RenderingQueue queue}) {
    assert(isolate != null);
    assert(last != null);
    NavIsolateMenuElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._last = last;
    e._updates = updates;
    return e;
  }

  NavIsolateMenuElement.created() : super.created() {
    _r = new RenderingScheduler(this);
    createShadowRoot();
  }

  @override
  void attached() {
    super.attached();
    assert(_isolate != null);
    assert(_updates != null);
    _r.enable();
    _updatesSubscription = _updates
      .where((M.IsolateUpdateEvent e) => e.isolate.id == isolate.id)
      .listen((M.IsolateUpdateEvent e) { _isolate = e.isolate; _r.dirty(); });
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    shadowRoot.children = [];
    assert(_updatesSubscription != null);
    _updatesSubscription.cancel();
    _updatesSubscription = null;
  }

  void render() {
    shadowRoot.children = [
      new NavMenuElement(isolate.name, last: last, queue: _r.queue,
          link: Uris.inspect(isolate))
        ..children = [
          new NavMenuItemElement('debugger', queue: _r.queue,
              link: Uris.debugger(isolate)),
          new NavMenuItemElement('class hierarchy', queue: _r.queue,
              link: Uris.classTree(isolate)),
          new NavMenuItemElement('cpu profile', queue: _r.queue,
              link: Uris.cpuProfiler(isolate)),
          new NavMenuItemElement('cpu profile (table)', queue: _r.queue,
              link: Uris.cpuProfilerTable(isolate)),
          new NavMenuItemElement('allocation profile', queue: _r.queue,
              link: Uris.allocationProfiler(isolate)),
          new NavMenuItemElement('heap map', queue: _r.queue,
              link: Uris.heapMap(isolate)),
          new NavMenuItemElement('metrics', queue: _r.queue,
              link: Uris.metrics(isolate)),
          new NavMenuItemElement('heap snapshot', queue: _r.queue,
              link: Uris.heapSnapshot(isolate)),
          new NavMenuItemElement('persistent handles', queue: _r.queue,
              link: Uris.persistentHandles(isolate)),
          new NavMenuItemElement('ports', queue: _r.queue,
              link: Uris.ports(isolate)),
          new NavMenuItemElement('logging', queue: _r.queue,
              link: Uris.logging(isolate)),
          new ContentElement()
        ]
    ];
  }
}

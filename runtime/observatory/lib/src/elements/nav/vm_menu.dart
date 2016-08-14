// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M
  show VM, EventRepository;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/menu.dart';
import 'package:observatory/src/elements/nav/menu_item.dart';

class NavVMMenuElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NavVMMenuElement>('nav-vm-menu',
                     dependencies: const [NavMenuElement.tag,
                                          NavMenuItemElement.tag]);

  RenderingScheduler _r;

  Stream<RenderedEvent<NavVMMenuElement>> get onRendered => _r.onRendered;

  bool _last;
  M.VM _vm;
  M.EventRepository _events;
  StreamSubscription _updatesSubscription;


  bool get last => _last;
  M.VM get vm => _vm;

  set last(bool value) => _last = _r.checkAndReact(_last, value);

  factory NavVMMenuElement(M.VM vm, M.EventRepository events, {bool last: false,
    RenderingQueue queue}) {
    assert(vm != null);
    assert(events != null);
    assert(last != null);
    NavVMMenuElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._events = events;
    e._last = last;
    return e;
  }

  NavVMMenuElement.created() : super.created() { createShadowRoot(); }

  @override
  void attached() {
    super.attached();
    _updatesSubscription = _events.onVMUpdate
        .listen((e) { _vm = e.vm; _r.dirty(); });
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    shadowRoot.children = [];
    _r.disable(notify: true);
    _updatesSubscription.cancel();
  }

  void render() {
    shadowRoot.children = [
      new NavMenuElement(vm.displayName, link: Uris.vm(), last: last,
          queue: _r.queue)
        ..children = (
          _vm.isolates.map((isolate) {
            return new NavMenuItemElement(isolate.name, queue: _r.queue,
                link: Uris.inspect(isolate));
          }).toList()
          ..add(new ContentElement())
        )
    ];
  }
}

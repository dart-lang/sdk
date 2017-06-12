// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M show VM, EventRepository;
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/menu_item.dart';

class NavVMMenuElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NavVMMenuElement>('nav-vm-menu',
      dependencies: const [NavMenuItemElement.tag]);

  RenderingScheduler _r;

  Stream<RenderedEvent<NavVMMenuElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.EventRepository _events;
  StreamSubscription _updatesSubscription;
  Iterable<Element> _content = const [];

  M.VM get vm => _vm;
  Iterable<Element> get content => _content;

  set content(Iterable<Element> value) {
    _content = value.toList();
    _r.dirty();
  }

  factory NavVMMenuElement(M.VM vm, M.EventRepository events,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(events != null);
    NavVMMenuElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._events = events;
    return e;
  }

  NavVMMenuElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _updatesSubscription = _events.onVMUpdate.listen((e) {
      _vm = e.vm;
      _r.dirty();
    });
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
    _updatesSubscription.cancel();
  }

  void render() {
    final content = (_vm.isolates.map((isolate) {
      return new NavMenuItemElement(isolate.name,
          queue: _r.queue, link: Uris.inspect(isolate));
    }).toList()
      ..addAll(_content));
    children = [navMenu(vm.displayName, link: Uris.vm(), content: content)];
  }
}

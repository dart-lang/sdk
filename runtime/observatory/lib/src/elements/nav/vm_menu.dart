// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M show VM, EventRepository;
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/menu_item.dart';

class NavVMMenuElement extends CustomElement implements Renderable {
  late RenderingScheduler<NavVMMenuElement> _r;

  Stream<RenderedEvent<NavVMMenuElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.EventRepository _events;
  late StreamSubscription _updatesSubscription;
  Iterable<Element> _content = const [];

  M.VM get vm => _vm;
  Iterable<Element> get content => _content;

  set content(Iterable<Element> value) {
    _content = value.toList();
    _r.dirty();
  }

  factory NavVMMenuElement(M.VM vm, M.EventRepository events,
      {RenderingQueue? queue}) {
    assert(vm != null);
    assert(events != null);
    NavVMMenuElement e = new NavVMMenuElement.created();
    e._r = new RenderingScheduler<NavVMMenuElement>(e, queue: queue);
    e._vm = vm;
    e._events = events;
    return e;
  }

  NavVMMenuElement.created() : super.created('nav-vm-menu');

  @override
  void attached() {
    super.attached();
    _updatesSubscription = _events.onVMUpdate.listen((e) {
      _vm = e.vm as M.VM;
      _r.dirty();
    });
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = <Element>[];
    _r.disable(notify: true);
    _updatesSubscription.cancel();
  }

  void render() {
    final content = (_vm.isolates.map<Element>((isolate) {
      return new NavMenuItemElement(isolate.name!,
              queue: _r.queue, link: Uris.inspect(isolate))
          .element;
    }).toList()
      ..addAll(_content));
    children = <Element>[
      navMenu(vm.displayName!, link: Uris.vm(), content: content)
    ];
  }
}

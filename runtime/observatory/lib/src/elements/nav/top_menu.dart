// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/menu.dart';
import 'package:observatory/src/elements/nav/menu_item.dart';

class NavTopMenuElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NavTopMenuElement>('nav-top-menu',
                     dependencies: const [NavMenuElement.tag,
                                          NavMenuItemElement.tag]);

  RenderingScheduler _r;

  Stream<RenderedEvent<NavTopMenuElement>> get onRendered => _r.onRendered;

  bool _last;
  bool get last => _last;
  set last(bool value) => _last = _r.checkAndReact(_last, value);

  factory NavTopMenuElement({bool last: false, RenderingQueue queue}) {
    assert(last != null);
    NavTopMenuElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._last = last;
    return e;
  }

  NavTopMenuElement.created() : super.created() { createShadowRoot(); }

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    shadowRoot.children = [];
  }

  void render() {
    shadowRoot.children = [
      new NavMenuElement('Observatory', link: Uris.vm(), last: last,
                         queue: _r.queue)
        ..children = [
          new NavMenuItemElement('Connect to a VM', link: Uris.vmConnect(),
                                 queue: _r.queue),
          new ContentElement()
        ]
    ];
  }
}

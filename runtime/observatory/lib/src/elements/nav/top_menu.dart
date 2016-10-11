// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/menu_item.dart';

class NavTopMenuElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NavTopMenuElement>('nav-top-menu',
      dependencies: const [NavMenuItemElement.tag]);

  RenderingScheduler _r;

  Stream<RenderedEvent<NavTopMenuElement>> get onRendered => _r.onRendered;

  Iterable<Element> _content = const [];

  Iterable<Element> get content => _content;

  set content(Iterable<Element> value) {
    _content = value.toList();
    _r.dirty();
  }

  factory NavTopMenuElement({RenderingQueue queue}) {
    NavTopMenuElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    return e;
  }

  NavTopMenuElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  void render() {
    final content = ([
      new NavMenuItemElement('Connect to a VM', link: Uris.vmConnect()),
    ]..addAll(_content));
    children = [navMenu('Observatory', link: Uris.vm(), content: content)];
  }
}

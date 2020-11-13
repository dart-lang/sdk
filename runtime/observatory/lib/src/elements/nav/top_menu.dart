// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/menu_item.dart';

class NavTopMenuElement extends CustomElement implements Renderable {
  late RenderingScheduler<NavTopMenuElement> _r;

  Stream<RenderedEvent<NavTopMenuElement>> get onRendered => _r.onRendered;

  Iterable<Element> _content = const <Element>[];

  Iterable<Element> get content => _content;

  set content(Iterable<Element> value) {
    _content = value.toList();
    _r.dirty();
  }

  factory NavTopMenuElement({RenderingQueue? queue}) {
    NavTopMenuElement e = new NavTopMenuElement.created();
    e._r = new RenderingScheduler<NavTopMenuElement>(e, queue: queue);
    return e;
  }

  NavTopMenuElement.created() : super.created('nav-top-menu');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    children = <Element>[];
  }

  void render() {
    final content = (<Element>[
      new NavMenuItemElement('Connect to a VM', link: Uris.vmConnect()).element,
    ]..addAll(_content));
    children = <Element>[
      navMenu('Observatory', link: Uris.vm(), content: content)
    ];
  }
}

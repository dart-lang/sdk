// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';

class NavMenuItemElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NavMenuItemElement>('nav-menu-item');

  RenderingScheduler _r;

  Stream<RenderedEvent<NavMenuItemElement>> get onRendered => _r.onRendered;

  String _label;
  String _link;
  Iterable<Element> _content = const [];

  String get label => _label;
  String get link => _link;
  Iterable<Element> get content => _content;

  set label(String value) => _label = _r.checkAndReact(_label, value);
  set link(String value) => _link = _r.checkAndReact(_link, value);
  set content(Iterable<Element> value) {
    _content = value.toList();
    _r.dirty();
  }

  factory NavMenuItemElement(String label,
      {String link, RenderingQueue queue}) {
    assert(label != null);
    NavMenuItemElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._label = label;
    e._link = link;
    return e;
  }

  NavMenuItemElement.created() : super.created();

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
    children = [
      new LIElement()
        ..classes = ['nav-menu-item']
        ..children = [
          new AnchorElement(href: link)..text = label,
          new UListElement()..children = _content
        ]
    ];
  }
}

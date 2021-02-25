// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';

class NavMenuItemElement extends CustomElement implements Renderable {
  RenderingScheduler<NavMenuItemElement> _r;

  Stream<RenderedEvent<NavMenuItemElement>> get onRendered => _r.onRendered;

  String _label;
  String _link;
  Iterable<Element> _content = const <Element>[];

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
    NavMenuItemElement e = new NavMenuItemElement.created();
    e._r = new RenderingScheduler<NavMenuItemElement>(e, queue: queue);
    e._label = label;
    e._link = link;
    return e;
  }

  NavMenuItemElement.created() : super.created('nav-menu-item');

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
    children = <Element>[
      new LIElement()
        ..classes = ['nav-menu-item']
        ..children = <Element>[
          new AnchorElement(href: link)..text = label,
          new UListElement()..children = _content
        ]
    ];
  }
}

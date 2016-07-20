// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';

class NavMenuItemElement extends HtmlElement implements Renderable {
  static final StyleElement _style = () {
      var style = new StyleElement();
      style.text = '''li.nav-menu-item {
                        float: none;
                        border-top: 1px solid #677;
                        border-bottom: 1px solid #556; position: relative;
                      }
                      li.nav-menu-item:hover {
                        background: #455;
                      }
                      li.nav-menu-item > a {
                        display: block;
                        padding: 12px 12px;
                        color: white;
                        text-decoration: none;
                      }
                      li.nav-menu-item > ul {
                        display: none;
                        position: absolute;
                        top:0;
                        left: 100%;
                        list-style: none;
                        padding: 0;
                        margin-left: 0;
                        width: auto;
                        z-index: 1000;
                        font: 400 16px \'Montserrat\', sans-serif;
                        color: white;
                        background: #567;
                      }
                      li.nav-menu-item > ul:after {
                        content: ""; clear: both; display: block;
                      }
                      li.nav-menu-item:hover > ul {
                        display: block;
                      }''';
      return style;
  }();

  static const tag = const Tag<NavMenuItemElement>('nav-menu-item-wrapped');

  RenderingScheduler _r;

  Stream<RenderedEvent<NavMenuItemElement>> get onRendered => _r.onRendered;

  String _label;
  String _link;
  String get label => _label;
  String get link => _link;
  set label(String value) => _label = _r.checkAndReact(_label, value);
  set link(String value) => _link = _r.checkAndReact(_link, value);


  factory NavMenuItemElement(String label, {String link,
                             RenderingQueue queue}) {
    assert(label != null);
    NavMenuItemElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._label = label;
    e._link = link;
    return e;
  }

  NavMenuItemElement.created() : super.created() { createShadowRoot(); }

  @override
  void attached() { super.attached(); _r.enable(); }

  @override
  void detached() {
    super.detached(); _r.disable(notify: true);
    shadowRoot.children = [];
  }

  void render() {
    shadowRoot.children = [
      _style.clone(true),
      new LIElement()
        ..classes = ['nav-menu-item']
        ..children = [
          new AnchorElement(href: '#$link')
            ..text = label,
          new UListElement()
            ..children = [
              new ContentElement()
            ]
        ]
    ];
  }
}

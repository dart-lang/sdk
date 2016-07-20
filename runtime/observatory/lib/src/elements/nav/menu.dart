// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';

class NavMenuElement extends HtmlElement implements Renderable {
  static final StyleElement _style = () {
      var style = new StyleElement();
      style.text = '''li.nav-menu_label, li.nav-menu_spacer {
                        float: left;
                      }
                      li.nav-menu_label > a, li.nav-menu_spacer {
                        display: block;
                        padding: 12px 8px;
                        color: White;
                        text-decoration: none;
                      }
                      li.nav-menu_label:hover {
                        background: #455;
                      }
                      li.nav-menu_label > ul {
                        display: none;
                        position: absolute;
                        top: 98%;
                        list-style: none;
                        margin: 0;
                        padding: 0;
                        width: auto;
                        z-index: 1000;
                        font: 400 16px \'Montserrat\', sans-serif;
                        color: white;
                        background: #567;
                      }
                      li.nav-menu_label > ul:after {
                        content: ""; clear: both; display: block;
                      }
                      li.nav-menu_label:hover > ul {
                        display: block;
                      }''';
      return style;
  }();

  static const tag = const Tag<NavMenuElement>('nav-menu-wrapped');

  RenderingScheduler _r;

  Stream<RenderedEvent<NavMenuElement>> get onRendered => _r.onRendered;

  String _label;
  String _link;
  bool _last;
  String get label => _label;
  String get link => _link;
  bool get last => _last;
  set label(String value) => _label = _r.checkAndReact(_label, value);
  set link(String value) => _link = _r.checkAndReact(_link, value);
  set last(bool value) => _last = _r.checkAndReact(_link, value);

  factory NavMenuElement(String label, {String link, bool last: false,
                             RenderingQueue queue}) {
    assert(label != null);
    assert(last != null);
    NavMenuElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._label = label;
    e._link = link;
    e._last = last;
    return e;
  }

  NavMenuElement.created() : super.created() { createShadowRoot(); }

  @override
  void attached() { super.attached(); _r.enable(); }

  @override
  void detached() {
    super.detached(); _r.disable(notify: true);
    shadowRoot.children = [];
  }

  void render() {
    List<Element> children = [
      _style.clone(true),
      new LIElement()
        ..classes = ['nav-menu_label']
        ..children = [
          new AnchorElement(href: '#$link')
            ..text = label,
          new UListElement()
            ..children = [
              new ContentElement()
            ]
        ]
    ];
    if (!last) {
      children.add(
        new LIElement()
          ..classes = ['nav-menu_spacer']
          ..innerHtml = '&gt;'
      );
    }
    shadowRoot.children = children;
  }
}

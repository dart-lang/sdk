// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';

class NavBarElement extends HtmlElement implements Renderable {
  static final StyleElement _style = () {
      var style = new StyleElement();
      style.text = 'nav.nav-bar {'
                     'position: fixed;'
                     'top: -56px;'
                     'width: 100%;'
                     'z-index: 1000;'
                     '}'
                   'nav.nav-bar > ul {'
                     'display: inline-table;'
                     'position: relative;'
                     'list-style: none;'
                     'padding-left: 0;'
                     'margin-left: 0;'
                     'width: 100%;'
                     'z-index: 1000;'
                     'font: 400 16px \'Montserrat\', sans-serif;'
                     'color: white;'
                     'background-color: #0489c3;'
                   '}'
                   'nav.nav-bar:after {'
                     'content: ""; clear: both; display: block;'
                   '}'
                   'nav.nav-bar:before {'
                     'height: 40px;'
                     'background-color: #0489c3;'
                     'content: ""; display: block;'
                   '}';
      return style;
  }();

  static const tag = const Tag<NavBarElement>('nav-bar');

  RenderingScheduler _r;

  Stream<RenderedEvent<NavBarElement>> get onRendered => _r.onRendered;

  factory NavBarElement({RenderingQueue queue}) {
    NavBarElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    return e;
  }

  NavBarElement.created() : super.created() {
    // TODO(cbernaschina) remove when no more needed.
    _r = new RenderingScheduler(this);
    createShadowRoot();
  }

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
      document.createElement('nav')
        ..classes = ['nav-bar']
        ..children = [
          new UListElement()
            ..children = [
              new ContentElement()
            ],
        ],
      new DivElement()
    ];
  }
}

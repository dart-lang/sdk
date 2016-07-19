// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';
import 'package:observatory/src/elements/nav/menu_item.dart';

class NavMenuItemElementWrapper extends HtmlElement {
  static final binder = new Binder<NavMenuItemElementWrapper>(
    const [const Binding('anchor'), const Binding('link')]);

  static const tag =
    const Tag<NavMenuItemElementWrapper>('nav-menu-item');

  String _anchor;
  String _link;
  String get anchor => _anchor;
  String get link => _link;
  set anchor(String value) {
    _anchor = value; render();
  }
  set link(String value) {
    _link = value; render();
  }

  NavMenuItemElementWrapper.created() : super.created() {
    binder.registerCallback(this);
    _anchor = getAttribute('anchor');
    _link = getAttribute('link');
    createShadowRoot();
    render();
  }

  @override
  void attached() {
    super.attached();
    render();
  }

  void render() {
    shadowRoot.children = [];
    if (_anchor == null) return;

    shadowRoot.children = [
      new NavMenuItemElement(_anchor, link: _link,
                                 queue: ObservatoryApplication.app.queue)
        ..children = [new ContentElement()]
    ];
  }
}

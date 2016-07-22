// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';

class NavTopMenuElementWrapper extends HtmlElement {
  static final binder = new Binder<NavTopMenuElementWrapper>(
    const [const Binding('last')]);

  static const tag = const Tag<NavTopMenuElementWrapper>('top-nav-menu');

  bool _last = false;
  bool get last => _last;
  set last(bool value) {
    _last = value; render();
  }

  NavTopMenuElementWrapper.created() : super.created() {
    binder.registerCallback(this);
    _last = _getBoolAttribute('last');
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
    if (_last == null) return;

    shadowRoot.children = [
      new NavTopMenuElement(last: last, queue: ObservatoryApplication.app.queue)
        ..children = [new ContentElement()]
    ];
  }

  bool _getBoolAttribute(String name) {
    final String value = getAttribute(name);
    return !(value == null || value == 'false');
  }
}

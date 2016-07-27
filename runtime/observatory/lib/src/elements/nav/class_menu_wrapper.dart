// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';
import 'package:observatory/src/elements/nav/class_menu.dart';

class NavClassMenuElementWrapper extends HtmlElement {
  static final binder = new Binder<NavClassMenuElementWrapper>(
    const [const Binding('last'), const Binding('cls')]);

  static const tag =
    const Tag<NavClassMenuElementWrapper>('class-nav-menu');

  bool _last = false;
  Class _cls;
  bool get last => _last;
  Class get cls => _cls;
  set last(bool value) {
    _last = value; render();
  }
  set cls(Class value) {
    _cls = value; render();
  }

  NavClassMenuElementWrapper.created() : super.created() {
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
    if (_cls == null || _last == null) return;

    shadowRoot.children = [
      new NavClassMenuElement(cls.isolate, cls, last: last,
                                 queue: ObservatoryApplication.app.queue)
        ..children = [new ContentElement()]
    ];
  }

  bool _getBoolAttribute(String name) {
    final String value = getAttribute(name);
    return !(value == null || value == 'false');
  }
}

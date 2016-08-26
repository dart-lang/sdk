// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';

@bindable
class NavIsolateMenuElementWrapper extends HtmlElement {
  static const binder = const Binder<NavIsolateMenuElementWrapper>(const {
      'last':  #last, 'isolate': #isolate
    });

  static const tag =
    const Tag<NavIsolateMenuElementWrapper>('isolate-nav-menu');

  bool _last = false;
  Isolate _isolate;
  
  bool get last => _last;
  Isolate get isolate => _isolate;

  set last(bool value) {
    _last = value;
    render();
  }
  set isolate(Isolate value) {
    _isolate = value;
    render();
  }

  NavIsolateMenuElementWrapper.created() : super.created() {
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
    if (_isolate == null || _last == null) {
      return;
    }

    shadowRoot.children = [
      new NavIsolateMenuElement(_isolate, app.events, last: _last,
          queue: app.queue)
        ..children = [new ContentElement()]
    ];
  }

  ObservatoryApplication get app => ObservatoryApplication.app;

  bool _getBoolAttribute(String name) {
    final String value = getAttribute(name);
    return !(value == null || value == 'false');
  }
}

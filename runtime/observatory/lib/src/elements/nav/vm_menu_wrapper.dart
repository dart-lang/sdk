// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:observatory/service_common.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';

@bindable
class NavVMMenuElementWrapper extends HtmlElement {
  static const binder = const Binder<NavVMMenuElementWrapper>(const {
      'last': #last, 'vm': #vm
    });

  static const tag = const Tag<NavVMMenuElementWrapper>('vm-nav-menu');

  bool _last = false;
  VM _vm;

  bool get last => _last;
  VM get vm => _vm;

  set last(bool value) {
    _last = value;
    render(); }
  set vm(VM value) {
    _vm = value;
    render();
  }

  NavVMMenuElementWrapper.created() : super.created() {
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
    if (_vm == null || _last == null) {
      return;
    }

    shadowRoot.children = [
      new NavVMMenuElement(vm, app.events, last: last,
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

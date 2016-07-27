// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';
import 'package:observatory/src/elements/nav/library_menu.dart';

@bindable
class NavLibraryMenuElementWrapper extends HtmlElement {
  static const binder = const Binder<NavLibraryMenuElementWrapper>(const {
      'last': #last, 'library': #library
    });

  static const tag =
    const Tag<NavLibraryMenuElementWrapper>('library-nav-menu');

  bool _last = false;
  Library _library;
  bool get last => _last;
  Library get library => _library;
  set last(bool value) {
    _last = value; render();
  }
  set library(Library value) {
    _library = value; render();
  }

  NavLibraryMenuElementWrapper.created() : super.created() {
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
    if (_library == null || _last == null) return;

    shadowRoot.children = [
      new NavLibraryMenuElement(library.isolate, library, last: last,
                                 queue: ObservatoryApplication.app.queue)
        ..children = [new ContentElement()]
    ];
  }

  bool _getBoolAttribute(String name) {
    final String value = getAttribute(name);
    return !(value == null || value == 'false');
  }
}

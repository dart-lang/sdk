// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

typedef _callback();
typedef CurlyBlockToggleCallback(bool a, _callback b);

class CurlyBlockElementWrapper extends HtmlElement {

  static final binder = new Binder<CurlyBlockElementWrapper>(
    const [const Binding('expand'), const Binding('busy'),
           const Binding('expandKey'), const Binding('callback')]);

  static const tag = const Tag<CurlyBlockElementWrapper>('curly-block');

  bool _expand;
  bool get expand => _expand;
  set expand(bool expanded) {
    _expand = !(expanded == null || expanded == false);
    render();
  }

  bool _busy;
  bool get busy => _busy;
  set busy(bool busy) {
    _busy = !(busy == null || busy == false);
    render();
  }

  String _expandKey;
  String get expandKey => _expandKey;
  set expandKey(String expandKey) {
    _expandKey = expandKey;
    if (expandKey != null) {
      var value = application.expansions[expandKey];
      if (value != null && expand != value) {

      }
    }
    render();
  }

  CurlyBlockToggleCallback _callback;
  CurlyBlockToggleCallback get callback => _callback;
  set callback(CurlyBlockToggleCallback callback) {
    _callback = callback;
    render();
  }

  CurlyBlockElementWrapper.created() : super.created() {
    binder.registerCallback(this);
    createShadowRoot();
    _expand = !_isFalseOrNull(getAttribute('expand'));
    _busy = !_isFalseOrNull(getAttribute('busy'));
    _expandKey = getAttribute('expandKey');
  }

  @override
  void attached() {
    super.attached();
    render();
  }

  void render() {
    shadowRoot.children = [
      new CurlyBlockElement(expanded: expand, disabled: busy,
                                 queue: ObservatoryApplication.app.queue)
        ..children = [new ContentElement()]
        ..onToggle.listen(_toggle)
    ];
  }

  ObservatoryApplication get application => ObservatoryApplication.app;

  void _toggle(CurlyBlockToggleEvent e) {
    _expand = e.control.expanded;
    if (callback != null) {
      busy = true;
      callback(expand, () {
        if (expandKey != null) {
          application.expansions[expandKey] = expand;
        }
        busy = false;
      });
    } else {
      application.expansions[expandKey] = expand;
    }
  }

  bool _isFalseOrNull(String value) {
    return value == null || value == false;
  }
}

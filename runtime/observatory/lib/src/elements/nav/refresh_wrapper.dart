// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';

import 'package:observatory/app.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';
import 'package:observatory/src/elements/nav/refresh.dart';

@bindable
class NavRefreshElementWrapper extends HtmlElement {
  static const binder = const Binder<NavRefreshElementWrapper>(const {
      'callback': #callback, 'label': #label
    });

  static const tag = const Tag<NavRefreshElementWrapper>('nav-refresh');

  Function _callback;
  String _label;
  
  Function get callback => _callback;
  String get label => _label;

  set callback(Function value) {
    _callback = value;
    render();
  }
  set label(String value) {
    _label = value;
    render();
  }

  NavRefreshElementWrapper.created() : super.created() {
    binder.registerCallback(this);
    _label = getAttribute('label') ?? 'Refresh';
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
    if (_callback == null || _label == null) {
      return;
    }

    shadowRoot.children = [
      new StyleElement()
        ..text = '''nav-refresh-wrapped > li > button {
          color: #000;
          margin: 3px;
          padding: 8px;
          border-width: 2px;
          line-height: 13px;
          font: 400 13px 'Montserrat', sans-serif;
        }
        nav-refresh-wrapped > li > button[disabled] {
          color: #aaa;
          cursor: wait;
        }
        nav-refresh-wrapped > li {
          float: right;
          margin: 0;
        }''',
      new NavRefreshElement(label: _label,
                            queue: ObservatoryApplication.app.queue)
        ..onRefresh.listen((event) async{
          event.element.disabled = true;
          try {
            var future = callback();
            if (future is Future) await future;
          } finally {
            event.element.disabled = false;
          }
        })
    ];
  }
}

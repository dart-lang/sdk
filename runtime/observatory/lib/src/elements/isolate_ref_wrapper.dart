// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/service_html.dart' show Isolate;
import 'package:observatory/src/elements/isolate_ref.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

@bindable
class IsolateRefElementWrapper extends HtmlElement {

  static const binder = const Binder<IsolateRefElementWrapper>(const {
      'ref': #ref
    });

  static const tag = const Tag<IsolateRefElementWrapper>('isolate-ref');

  Isolate _isolate;

  Isolate get ref => _isolate;

  void set ref(Isolate value) {
    _isolate = value;
    render();
  }

  IsolateRefElementWrapper.created() : super.created() {
    binder.registerCallback(this);
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
    if (ref == null) {
      return;
    }

    shadowRoot.children = [
      new StyleElement()
        ..text = '''
        isolate-ref-wrapped > a[href]:hover {
            text-decoration: underline;
        }
        isolate-ref-wrapped > a[href] {
            color: #0489c3;
            text-decoration: none;
        }''',
      new IsolateRefElement(_isolate, app.events, queue: app.queue)
    ];
  }

  ObservatoryApplication get app => ObservatoryApplication.app;
}

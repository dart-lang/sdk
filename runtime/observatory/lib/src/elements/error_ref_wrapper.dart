// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:observatory/src/elements/error_ref.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

class ErrorRefElementWrapper extends HtmlElement {

  static const binder = const Binder<ErrorRefElementWrapper>(const {
      'ref': #ref
    });

  static const tag = const Tag<ErrorRefElementWrapper>('error-ref');

  DartError _error;

  DartError get ref => _error;

  void set ref(DartError value) {
    _error = value;
    render();
  }

  ErrorRefElementWrapper.created() : super.created() {
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
    if (_error == null) {
      return;
    }

    shadowRoot.children = [
      new StyleElement()
        ..text = '''
        error-ref-wrapped > pre {
          background-color: #f5f5f5;
          border: 1px solid #ccc;
          padding-left: 10px;
          padding-right: 10px;
          font-family: consolas, courier, monospace;
          font-size: 1em;
          line-height: 1.2em;
          white-space: pre;
        }
        ''',
      new ErrorRefElement(_error, queue: ObservatoryApplication.app.queue)
    ];
  }
}

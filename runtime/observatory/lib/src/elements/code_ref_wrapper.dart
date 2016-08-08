// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/service_html.dart' show Code;
import 'package:observatory/src/elements/code_ref.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

@bindable
class CodeRefElementWrapper extends HtmlElement {

  static const binder = const Binder<CodeRefElementWrapper>(const {
      'ref': #ref
    });

  static const tag = const Tag<CodeRefElementWrapper>('code-ref');

  Code _code;

  Code get ref => _code;

  void set ref(Code value) {
    _code = value;
    render();
  }

  CodeRefElementWrapper.created() : super.created() {
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
        code-ref-wrapped > a[href]:hover {
            text-decoration: underline;
        }
        code-ref-wrapped > a[href] {
            color: #0489c3;
            text-decoration: none;
        }''',
      new CodeRefElement(_code.isolate, _code,
          queue: ObservatoryApplication.app.queue)
    ];
  }
}

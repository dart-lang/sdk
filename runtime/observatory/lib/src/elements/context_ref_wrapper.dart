// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/service_html.dart' show Context;
import 'package:observatory/src/elements/context_ref.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

@bindable
class ContextRefElementWrapper extends HtmlElement {

  static const binder = const Binder<ContextRefElementWrapper>(const {
      'ref': #ref
    });

  static const tag = const Tag<ContextRefElementWrapper>('context-ref');

  Context _context;
  Context get ref => _context;
  void set ref(Context ref) {
    _context = ref;
    render();
  }

  ContextRefElementWrapper.created() : super.created() {
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
    if (ref == null) return;

    shadowRoot.children = [
      new StyleElement()
        ..text = '''
        context-ref-wrapped > a[href]:hover {
            text-decoration: underline;
        }
        context-ref-wrapped > a[href] {
            color: #0489c3;
            text-decoration: none;
        }
        context-ref-wrapped .empathize {
          font-style: italic;
        }''',
      new ContextRefElement(_context.isolate, _context,
          queue: ObservatoryApplication.app.queue)
    ];
  }
}

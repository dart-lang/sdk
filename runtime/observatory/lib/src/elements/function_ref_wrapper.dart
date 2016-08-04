// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/service.dart' show ServiceFunction;
import 'package:observatory/src/elements/function_ref.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

@bindable
class FunctionRefElementWrapper extends HtmlElement {

  static const binder = const Binder<FunctionRefElementWrapper>(const {
      'ref': #ref, 'qualified': #qualified
    });

  static const tag = const Tag<FunctionRefElementWrapper>('function-ref');

  bool _qualified = true;
  ServiceFunction _function;
  bool get qualified => _qualified;
  ServiceFunction get ref => _function;
  void set qualified(bool qualified) { _qualified = qualified; render(); }
  void set ref(ServiceFunction ref) { _function = ref; render(); }

  FunctionRefElementWrapper.created() : super.created() {
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
        class-ref-wrapped > a[href]:hover,
        function-ref-wrapped > a[href]:hover {
            text-decoration: underline;
        }
        class-ref-wrapped > a[href],
        function-ref-wrapped > a[href] {
            color: #0489c3;
            text-decoration: none;
        }''',
      new FunctionRefElement(_function.isolate, _function, qualified: qualified,
        queue: ObservatoryApplication.app.queue)
    ];
  }
}

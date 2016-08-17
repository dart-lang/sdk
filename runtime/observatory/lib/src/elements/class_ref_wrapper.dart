// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/service_html.dart' show Class;
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

@bindable
class ClassRefElementWrapper extends HtmlElement {

  static const binder = const Binder<ClassRefElementWrapper>(const {
      'ref': #ref
    });

  static const tag = const Tag<ClassRefElementWrapper>('class-ref');

  Class _class;
  Class get ref => _class;
  void set ref(Class ref) {
    _class = ref;
    render();
  }

  ClassRefElementWrapper.created() : super.created() {
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
        class-ref-wrapped > a[href]:hover {
            text-decoration: underline;
        }
        class-ref-wrapped > a[href] {
            color: #0489c3;
            text-decoration: none;
        }''',
      new ClassRefElement(_class.isolate, _class,
          queue: ObservatoryApplication.app.queue)
    ];
  }
}

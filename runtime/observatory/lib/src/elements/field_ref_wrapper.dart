// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/repositories.dart';
import 'package:observatory/service_html.dart' show Field;
import 'package:observatory/src/elements/field_ref.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

@bindable
class FieldRefElementWrapper extends HtmlElement {

  static const binder = const Binder<FieldRefElementWrapper>(const {
      'ref': #ref
    });

  static const tag = const Tag<FieldRefElementWrapper>('field-ref');

  Field _field;
  Field get ref => _field;
  void set ref(Field ref) {
    _field = ref;
    render();
  }

  FieldRefElementWrapper.created() : super.created() {
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
        field-ref-wrapped a[href]:hover {
            text-decoration: underline;
        }
        field-ref-wrapped a[href] {
            color: #0489c3;
            text-decoration: none;
        }''',
      new FieldRefElement(_field.isolate, _field,
                          new InstanceRepository(_field.isolate),
                          queue: ObservatoryApplication.app.queue)
    ];
  }
}

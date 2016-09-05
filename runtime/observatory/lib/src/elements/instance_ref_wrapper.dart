// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/repositories.dart';
import 'package:observatory/service_html.dart' show Instance;
import 'package:observatory/src/elements/instance_ref.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';

@bindable
class InstanceRefElementWrapper extends HtmlElement {

  static const binder = const Binder<InstanceRefElementWrapper>(const {
      'ref': #ref
    });

  static const tag = const Tag<InstanceRefElementWrapper>('instance-ref');

  Instance _instance;
  Instance get ref => _instance;
  void set ref(Instance ref) {
    _instance = ref;
    render();
  }

  InstanceRefElementWrapper.created() : super.created() {
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
        instance-ref-wrapped a[href]:hover {
            text-decoration: underline;
        }
        instance-ref-wrapped a[href] {
            color: #0489c3;
            text-decoration: none;
        }
        instance-ref-wrapped .emphasize {
          font-style: italic;
        }
        instance-ref-wrapped .indent {
          margin-left: 1.5em;
          font: 400 14px 'Montserrat', sans-serif;
          line-height: 150%;
        }
        instance-ref-wrapped .stackTraceBox {
          margin-left: 1.5em;
          background-color: #f5f5f5;
          border: 1px solid #ccc;
          padding: 10px;
          font-family: consolas, courier, monospace;
          font-size: 12px;
          white-space: pre;
          overflow-x: auto;
        }''',
      new InstanceRefElement(_instance.isolate, _instance,
                             new InstanceRepository(),
                             queue: ObservatoryApplication.app.queue)
    ];
  }
}

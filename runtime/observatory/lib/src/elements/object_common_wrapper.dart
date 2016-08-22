// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:observatory/repositories.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/object_common.dart';
import 'package:observatory/src/elements/shims/binding.dart';

class ObjectCommonElementWrapper extends HtmlElement {

  static const binder = const Binder<ObjectCommonElementWrapper>(const {
      'object': #object
    });

  static const tag = const Tag<ObjectCommonElementWrapper>('object-common');

  HeapObject _object;

  HeapObject get object => _object;

  void set object(HeapObject value) {
    _object = value;
    render();
  }

  ObjectCommonElementWrapper.created() : super.created() {
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
    if (_object == null) {
      return;
    }

    shadowRoot.children = [
      new StyleElement()
        ..text = '''
        object-common-wrapped a[href]:hover {
            text-decoration: underline;
        }
        object-common-wrapped a[href] {
            color: #0489c3;
            text-decoration: none;
        }
        object-common-wrapped .memberList {
          display: table;
        }
        object-common-wrapped .memberItem {
          display: table-row;
        }
        object-common-wrapped .memberName,
        object-common-wrapped .memberValue {
          display: table-cell;
          vertical-align: top;
          padding: 3px 0 3px 1em;
          font: 400 14px 'Montserrat', sans-serif;
        }
        object-common-wrapped button:hover {
          background-color: transparent;
          border: none;
          text-decoration: underline;
        }

        object-common-wrapped button {
          background-color: transparent;
          border: none;
          color: #0489c3;
          padding: 0;
          margin: -8px 4px;
          font-size: 20px;
          text-decoration: none;
        }
        object-common-wrapped .indent {
          margin-left: 1.5em;
          font: 400 14px 'Montserrat', sans-serif;
          line-height: 150%;
        }
        object-common-wrapped .stackTraceBox {
          margin-left: 1.5em;
          background-color: #f5f5f5;
          border: 1px solid #ccc;
          padding: 10px;
          font-family: consolas, courier, monospace;
          font-size: 12px;
          white-space: pre;
          overflow-x: auto;
        }''',
      new ObjectCommonElement(_object.isolate, _object,
                          new RetainedSizeRepository(),
                          new ReachableSizeRepository(),
                          new InboundReferencesRepository(),
                          new RetainingPathRepository(),
                          new InstanceRepository(),
                          queue: ObservatoryApplication.app.queue)
    ];
  }
}

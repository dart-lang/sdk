// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M show IsolateRef, UnlinkedCallRef;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class UnlinkedCallRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<UnlinkedCallRefElement> _r;

  Stream<RenderedEvent<UnlinkedCallRefElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.UnlinkedCallRef _unlinkedcall;

  M.IsolateRef get isolate => _isolate;
  M.UnlinkedCallRef get unlinkedcall => _unlinkedcall;

  factory UnlinkedCallRefElement(
      M.IsolateRef isolate, M.UnlinkedCallRef unlinkedcall,
      {RenderingQueue? queue}) {
    assert(isolate != null);
    assert(unlinkedcall != null);
    UnlinkedCallRefElement e = new UnlinkedCallRefElement.created();
    e._r = new RenderingScheduler<UnlinkedCallRefElement>(e, queue: queue);
    e._isolate = isolate;
    e._unlinkedcall = unlinkedcall;
    return e;
  }

  UnlinkedCallRefElement.created() : super.created('unlinkedcall-ref');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    children = <Element>[];
  }

  void render() {
    children = <Element>[
      new AnchorElement(href: Uris.inspect(_isolate, object: _unlinkedcall))
        ..children = <Element>[
          new SpanElement()
            ..classes = ['emphasize']
            ..text = 'UnlinkedCall',
          new SpanElement()..text = ' (${_unlinkedcall.selector})'
        ]
    ];
  }
}

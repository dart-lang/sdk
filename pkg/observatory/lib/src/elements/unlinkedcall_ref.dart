// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M show IsolateRef, UnlinkedCallRef;
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/rendering_scheduler.dart';
import 'helpers/uris.dart';

class UnlinkedCallRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<UnlinkedCallRefElement> _r;

  Stream<RenderedEvent<UnlinkedCallRefElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.UnlinkedCallRef _unlinkedcall;

  M.IsolateRef get isolate => _isolate;
  M.UnlinkedCallRef get unlinkedcall => _unlinkedcall;

  factory UnlinkedCallRefElement(
    M.IsolateRef isolate,
    M.UnlinkedCallRef unlinkedcall, {
    RenderingQueue? queue,
  }) {
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
    removeChildren();
  }

  void render() {
    setChildren(<HTMLElement>[
      new HTMLAnchorElement()
        ..href = Uris.inspect(_isolate, object: _unlinkedcall)
        ..appendChildren(<HTMLElement>[
          new HTMLSpanElement()
            ..className = 'emphasize'
            ..textContent = 'UnlinkedCall',
          new HTMLSpanElement()..textContent = ' (${_unlinkedcall.selector})',
        ]),
    ]);
  }
}

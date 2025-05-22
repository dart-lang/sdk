// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M show IsolateRef, UnknownObjectRef;
import 'helpers/custom_element.dart';
import 'helpers/rendering_scheduler.dart';
import 'helpers/uris.dart';

class UnknownObjectRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<UnknownObjectRefElement> _r;

  Stream<RenderedEvent<UnknownObjectRefElement>> get onRendered =>
      _r.onRendered;

  late M.IsolateRef _isolate;
  late M.UnknownObjectRef _obj;

  M.IsolateRef get isolate => _isolate;
  M.UnknownObjectRef get obj => _obj;

  factory UnknownObjectRefElement(
    M.IsolateRef isolate,
    M.UnknownObjectRef obj, {
    RenderingQueue? queue,
  }) {
    UnknownObjectRefElement e = new UnknownObjectRefElement.created();
    e._r = new RenderingScheduler<UnknownObjectRefElement>(e, queue: queue);
    e._isolate = isolate;
    e._obj = obj;
    return e;
  }

  UnknownObjectRefElement.created() : super.created('unknown-ref');

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
    children = <HTMLElement>[
      new HTMLAnchorElement()
        ..href = Uris.inspect(_isolate, object: _obj)
        ..className = 'emphasize'
        ..text = _obj.vmType ?? '',
    ];
  }
}

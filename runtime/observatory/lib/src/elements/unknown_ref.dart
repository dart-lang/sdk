// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M show IsolateRef, UnknownObjectRef;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class UnknownObjectRefElement extends HtmlElement implements Renderable {
  static const tag = const Tag<UnknownObjectRefElement>('unknown-ref');

  RenderingScheduler<UnknownObjectRefElement> _r;

  Stream<RenderedEvent<UnknownObjectRefElement>> get onRendered =>
      _r.onRendered;

  M.IsolateRef _isolate;
  M.UnknownObjectRef _obj;

  M.IsolateRef get isolate => _isolate;
  M.UnknownObjectRef get obj => _obj;

  factory UnknownObjectRefElement(M.IsolateRef isolate, M.UnknownObjectRef obj,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(obj != null);
    UnknownObjectRefElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._obj = obj;
    return e;
  }

  UnknownObjectRefElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  void render() {
    children = [
      new AnchorElement(href: Uris.inspect(_isolate, object: _obj))
        ..classes = ['emphasize']
        ..text = _obj.vmType
    ];
  }
}

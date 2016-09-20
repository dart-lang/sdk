// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M show IsolateRef, ContextRef;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class ContextRefElement extends HtmlElement implements Renderable {
  static const tag = const Tag<ContextRefElement>('context-ref');

  RenderingScheduler<ContextRefElement> _r;

  Stream<RenderedEvent<ContextRefElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.ContextRef _context;

  M.IsolateRef get isolate => _isolate;
  M.ContextRef get context => _context;

  factory ContextRefElement(M.IsolateRef isolate, M.ContextRef context,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(context != null);
    ContextRefElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._context = context;
    return e;
  }

  ContextRefElement.created() : super.created();

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
      new AnchorElement(href: Uris.inspect(_isolate, object: _context))
        ..children = [
          new SpanElement()
            ..classes = ['emphasize']
            ..text = 'Context',
          new SpanElement()..text = ' (${_context.length})'
        ]
    ];
  }
}

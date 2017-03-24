// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M
    show IsolateRef, SubtypeTestCacheRef;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class SubtypeTestCacheRefElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<SubtypeTestCacheRefElement>('subtypetestcache-ref');

  RenderingScheduler<SubtypeTestCacheRefElement> _r;

  Stream<RenderedEvent<SubtypeTestCacheRefElement>> get onRendered =>
      _r.onRendered;

  M.IsolateRef _isolate;
  M.SubtypeTestCacheRef _subtypeTestCache;

  M.IsolateRef get isolate => _isolate;
  M.SubtypeTestCacheRef get subtypeTestCache => _subtypeTestCache;

  factory SubtypeTestCacheRefElement(
      M.IsolateRef isolate, M.SubtypeTestCacheRef subtypeTestCache,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(subtypeTestCache != null);
    SubtypeTestCacheRefElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._subtypeTestCache = subtypeTestCache;
    return e;
  }

  SubtypeTestCacheRefElement.created() : super.created();

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
      new AnchorElement(href: Uris.inspect(_isolate, object: _subtypeTestCache))
        ..children = [
          new SpanElement()
            ..classes = ['emphasize']
            ..text = 'SubtypeTestCache',
        ]
    ];
  }
}

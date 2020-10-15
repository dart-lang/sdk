// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M
    show IsolateRef, MegamorphicCacheRef;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class MegamorphicCacheRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<MegamorphicCacheRefElement> _r;

  Stream<RenderedEvent<MegamorphicCacheRefElement>> get onRendered =>
      _r.onRendered;

  late M.IsolateRef _isolate;
  late M.MegamorphicCacheRef _cache;

  M.IsolateRef get isolate => _isolate;
  M.MegamorphicCacheRef get cache => _cache;

  factory MegamorphicCacheRefElement(
      M.IsolateRef isolate, M.MegamorphicCacheRef cache,
      {RenderingQueue? queue}) {
    assert(isolate != null);
    assert(cache != null);
    MegamorphicCacheRefElement e = new MegamorphicCacheRefElement.created();
    e._r = new RenderingScheduler<MegamorphicCacheRefElement>(e, queue: queue);
    e._isolate = isolate;
    e._cache = cache;
    return e;
  }

  MegamorphicCacheRefElement.created() : super.created('megamorphic-cache-ref');

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
      new AnchorElement(href: Uris.inspect(_isolate, object: _cache))
        ..children = <Element>[
          new SpanElement()
            ..classes = ['emphasize']
            ..text = 'MegarmorphicCache',
          new SpanElement()..text = ' (${_cache.selector})'
        ]
    ];
  }
}

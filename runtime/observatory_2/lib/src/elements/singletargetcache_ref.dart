// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory_2/models.dart' as M
    show IsolateRef, SingleTargetCacheRef;
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/src/elements/helpers/uris.dart';

class SingleTargetCacheRefElement extends CustomElement implements Renderable {
  RenderingScheduler<SingleTargetCacheRefElement> _r;

  Stream<RenderedEvent<SingleTargetCacheRefElement>> get onRendered =>
      _r.onRendered;

  M.IsolateRef _isolate;
  M.SingleTargetCacheRef _singleTargetCache;

  M.IsolateRef get isolate => _isolate;
  M.SingleTargetCacheRef get singleTargetCache => _singleTargetCache;

  factory SingleTargetCacheRefElement(
      M.IsolateRef isolate, M.SingleTargetCacheRef singleTargetCache,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(singleTargetCache != null);
    SingleTargetCacheRefElement e = new SingleTargetCacheRefElement.created();
    e._r = new RenderingScheduler<SingleTargetCacheRefElement>(e, queue: queue);
    e._isolate = isolate;
    e._singleTargetCache = singleTargetCache;
    return e;
  }

  SingleTargetCacheRefElement.created()
      : super.created('singletargetcache-ref');

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
      new AnchorElement(
          href: Uris.inspect(_isolate, object: _singleTargetCache))
        ..children = <Element>[
          new SpanElement()
            ..classes = ['emphasize']
            ..text = 'SingleTargetCache',
          new SpanElement()..text = ' (${_singleTargetCache.target.name})'
        ]
    ];
  }
}

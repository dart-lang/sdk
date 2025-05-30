// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/rendering_scheduler.dart';
import 'helpers/uris.dart';

import '../../models.dart' as M show IsolateRef, SingleTargetCacheRef;

class SingleTargetCacheRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<SingleTargetCacheRefElement> _r;

  Stream<RenderedEvent<SingleTargetCacheRefElement>> get onRendered =>
      _r.onRendered;

  late M.IsolateRef _isolate;
  late M.SingleTargetCacheRef _singleTargetCache;

  M.IsolateRef get isolate => _isolate;
  M.SingleTargetCacheRef get singleTargetCache => _singleTargetCache;

  factory SingleTargetCacheRefElement(
    M.IsolateRef isolate,
    M.SingleTargetCacheRef singleTargetCache, {
    RenderingQueue? queue,
  }) {
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
    removeChildren();
  }

  void render() {
    children = <HTMLElement>[
      new HTMLAnchorElement()
        ..href = Uris.inspect(_isolate, object: _singleTargetCache)
        ..appendChildren(<HTMLElement>[
          new HTMLSpanElement()
            ..className = 'emphasize'
            ..textContent = 'SingleTargetCache',
          new HTMLSpanElement()
            ..textContent = ' (${_singleTargetCache.target!.name})',
        ]),
    ];
  }
}

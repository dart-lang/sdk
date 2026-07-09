// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M show IsolateRef, ObjectPoolRef;
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/rendering_scheduler.dart';
import 'helpers/uris.dart';

class ObjectPoolRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<ObjectPoolRefElement> _r;

  Stream<RenderedEvent<ObjectPoolRefElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.ObjectPoolRef _pool;

  M.IsolateRef get isolate => _isolate;
  M.ObjectPoolRef get pool => _pool;

  factory ObjectPoolRefElement(
    M.IsolateRef isolate,
    M.ObjectPoolRef pool, {
    RenderingQueue? queue,
  }) {
    ObjectPoolRefElement e = new ObjectPoolRefElement.created();
    e._r = new RenderingScheduler<ObjectPoolRefElement>(e, queue: queue);
    e._isolate = isolate;
    e._pool = pool;
    return e;
  }

  ObjectPoolRefElement.created() : super.created('object-pool-ref');

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
        ..href = Uris.inspect(_isolate, object: _pool)
        ..appendChildren(<HTMLElement>[
          new HTMLSpanElement()
            ..className = 'emphasize'
            ..textContent = 'ObjectPool',
          new HTMLSpanElement()..textContent = ' (${_pool.length})',
        ]),
    ];
  }
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_ref_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M show IsolateRef, EventRepository;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class IsolateRefElement extends CustomElement implements Renderable {
  static const tag = const Tag<IsolateRefElement>('isolate-ref');

  RenderingScheduler<IsolateRefElement> _r;

  Stream<RenderedEvent<IsolateRefElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.EventRepository _events;
  StreamSubscription _updatesSubscription;

  M.IsolateRef get isolate => _isolate;

  factory IsolateRefElement(M.IsolateRef isolate, M.EventRepository events,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(events != null);
    IsolateRefElement e = new IsolateRefElement.created();
    e._r = new RenderingScheduler<IsolateRefElement>(e, queue: queue);
    e._isolate = isolate;
    e._events = events;
    return e;
  }

  IsolateRefElement.created() : super.created(tag);

  @override
  void attached() {
    super.attached();
    _updatesSubscription = _events.onIsolateUpdate
        .where((e) => e.isolate.id == isolate.id)
        .listen((e) {
      _isolate = e.isolate;
      _r.dirty();
    });
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = <Element>[];
    _r.disable(notify: true);
    _updatesSubscription.cancel();
  }

  void render() {
    children = <Element>[
      new AnchorElement(href: Uris.inspect(isolate))
        ..text = 'Isolate ${isolate.number} (${isolate.name})'
        ..classes = ['isolate-ref']
    ];
  }
}

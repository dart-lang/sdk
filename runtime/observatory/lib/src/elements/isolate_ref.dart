// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_ref_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M
  show IsolateRef, IsolateUpdateEvent;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class IsolateRefElement extends HtmlElement implements Renderable {
  static const tag = const Tag<IsolateRefElement>('isolate-ref-wrapped');

  RenderingScheduler<IsolateRefElement> _r;

  Stream<RenderedEvent<IsolateRefElement>> get onRendered => _r.onRendered;

  Stream<M.IsolateUpdateEvent> _updates;
  StreamSubscription _updatesSubscription;
  M.IsolateRef _isolate;

  M.IsolateRef get isolate => _isolate;

  factory IsolateRefElement(M.IsolateRef isolate,
      Stream<M.IsolateUpdateEvent> updates, {RenderingQueue queue}) {
    assert(isolate != null);
    assert(updates != null);
    IsolateRefElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._updates = updates;
    return e;
  }

  IsolateRefElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    assert(_isolate != null);
    assert(_updates != null);
    _r.enable();
    _updatesSubscription = _updates
      .where((M.IsolateUpdateEvent e) => e.isolate.id == isolate.id)
      .listen((M.IsolateUpdateEvent e) { _isolate = e.isolate; _r.dirty(); });
  }

  @override
  void detached() {
    super.detached(); _r.disable(notify: true);
    children = [];
    assert(_updatesSubscription != null);
    _updatesSubscription.cancel();
    _updatesSubscription = null;
  }

  void render() {
    children = [
      new AnchorElement(href: Uris.inspect(isolate))
        ..text = 'Isolate ${isolate.number} (${isolate.name})'
        ..classes = ['isolate-ref']
    ];
  }
}

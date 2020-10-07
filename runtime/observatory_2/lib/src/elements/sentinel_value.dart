// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observatory_2/models.dart' as M show Sentinel, SentinelKind;
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';

class SentinelValueElement extends CustomElement implements Renderable {
  RenderingScheduler<SentinelValueElement> _r;

  Stream<RenderedEvent<SentinelValueElement>> get onRendered => _r.onRendered;

  M.Sentinel _sentinel;

  M.Sentinel get sentinel => _sentinel;

  factory SentinelValueElement(M.Sentinel sentinel, {RenderingQueue queue}) {
    assert(sentinel != null);
    SentinelValueElement e = new SentinelValueElement.created();
    e._r = new RenderingScheduler<SentinelValueElement>(e, queue: queue);
    e._sentinel = sentinel;
    return e;
  }

  SentinelValueElement.created() : super.created('sentinel-value');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    text = '';
    title = '';
  }

  void render() {
    text = _sentinel.valueAsString;
    title = _sentinelKindToDescription(_sentinel.kind);
  }

  static String _sentinelKindToDescription(M.SentinelKind kind) {
    switch (kind) {
      case M.SentinelKind.collected:
        return 'This object has been reclaimed by the garbage collector.';
      case M.SentinelKind.expired:
        return 'The handle to this object has expired. '
            'Consider refreshing the page.';
      case M.SentinelKind.notInitialized:
        return 'This object will be initialized once it is accessed by '
            'the program.';
      case M.SentinelKind.initializing:
        return 'This object is currently being initialized.';
      case M.SentinelKind.optimizedOut:
        return 'This object is no longer needed and has been removed by the '
            'optimizing compiler.';
      case M.SentinelKind.free:
        return '';
    }
    throw new Exception('Unknown SentinelKind: $kind');
  }
}

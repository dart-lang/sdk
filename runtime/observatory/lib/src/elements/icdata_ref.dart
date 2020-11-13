// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M show IsolateRef, ICDataRef;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class ICDataRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<ICDataRefElement> _r;

  Stream<RenderedEvent<ICDataRefElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.ICDataRef _icdata;

  M.IsolateRef get isolate => _isolate;
  M.ICDataRef get icdata => _icdata;

  factory ICDataRefElement(M.IsolateRef isolate, M.ICDataRef icdata,
      {RenderingQueue? queue}) {
    assert(isolate != null);
    assert(icdata != null);
    ICDataRefElement e = new ICDataRefElement.created();
    e._r = new RenderingScheduler<ICDataRefElement>(e, queue: queue);
    e._isolate = isolate;
    e._icdata = icdata;
    return e;
  }

  ICDataRefElement.created() : super.created('icdata-ref');

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
      new AnchorElement(href: Uris.inspect(_isolate, object: _icdata))
        ..children = <Element>[
          new SpanElement()
            ..classes = ['emphasize']
            ..text = 'ICData',
          new SpanElement()..text = ' (${_icdata.selector})'
        ]
    ];
  }
}

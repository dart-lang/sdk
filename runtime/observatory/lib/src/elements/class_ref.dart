// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class ClassRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<ClassRefElement> _r;

  Stream<RenderedEvent<ClassRefElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.ClassRef _class;

  M.IsolateRef get isolate => _isolate;
  M.ClassRef get cls => _class;

  factory ClassRefElement(M.IsolateRef isolate, M.ClassRef cls,
      {RenderingQueue? queue}) {
    assert(cls != null);
    ClassRefElement e = new ClassRefElement.created();
    e._r = new RenderingScheduler<ClassRefElement>(e, queue: queue);
    e._isolate = isolate;
    e._class = cls;
    return e;
  }

  ClassRefElement.created() : super.created('class-ref');

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
          href: (_isolate == null)
              ? null
              : Uris.inspect(_isolate, object: _class))
        ..text = _class.name
    ];
  }
}

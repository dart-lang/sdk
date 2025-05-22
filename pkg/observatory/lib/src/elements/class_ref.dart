// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'helpers/custom_element.dart';
import 'helpers/rendering_scheduler.dart';
import 'helpers/uris.dart';

class ClassRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<ClassRefElement> _r;

  Stream<RenderedEvent<ClassRefElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.ClassRef _class;

  M.IsolateRef get isolate => _isolate;
  M.ClassRef get cls => _class;

  factory ClassRefElement(
    M.IsolateRef isolate,
    M.ClassRef cls, {
    RenderingQueue? queue,
  }) {
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
    removeChildren();
  }

  void render() {
    removeChildren();
    appendChild(
      new HTMLAnchorElement()
        ..href = Uris.inspect(_isolate, object: _class)
        ..text = _class.name ?? '',
    );
  }
}

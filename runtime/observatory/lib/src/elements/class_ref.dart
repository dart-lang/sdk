// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class ClassRefElement extends HtmlElement implements Renderable {
  static const tag = const Tag<ClassRefElement>('class-ref');

  RenderingScheduler<ClassRefElement> _r;

  Stream<RenderedEvent<ClassRefElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.ClassRef _class;

  M.IsolateRef get isolate => _isolate;
  M.ClassRef get cls => _class;

  factory ClassRefElement(M.IsolateRef isolate, M.ClassRef cls,
      {RenderingQueue queue}) {
    assert(cls != null);
    ClassRefElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._class = cls;
    return e;
  }

  ClassRefElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  void render() {
    children = [
      new AnchorElement(
          href: (_isolate == null)
              ? null
              : Uris.inspect(_isolate, object: _class))
        ..text = _class.name
    ];
  }
}

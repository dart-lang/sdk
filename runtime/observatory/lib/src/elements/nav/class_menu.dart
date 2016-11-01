// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M show IsolateRef, ClassRef;
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class NavClassMenuElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NavClassMenuElement>('nav-class-menu');

  RenderingScheduler _r;

  Stream<RenderedEvent<NavClassMenuElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.ClassRef _cls;
  Iterable<Element> _content = const [];

  M.IsolateRef get isolate => _isolate;
  M.ClassRef get cls => _cls;
  Iterable<Element> get content => _content;

  set content(Iterable<Element> value) {
    _content = value.toList();
    _r.dirty();
  }

  factory NavClassMenuElement(M.IsolateRef isolate, M.ClassRef cls,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(cls != null);
    NavClassMenuElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._cls = cls;
    return e;
  }

  NavClassMenuElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
  }

  void render() {
    children = [
      navMenu(cls.name,
          content: _content, link: Uris.inspect(isolate, object: cls))
    ];
  }
}

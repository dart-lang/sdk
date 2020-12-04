// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M show IsolateRef, ClassRef;
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class NavClassMenuElement extends CustomElement implements Renderable {
  late RenderingScheduler<NavClassMenuElement> _r;

  Stream<RenderedEvent<NavClassMenuElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.ClassRef _cls;
  List<Element> _content = const [];

  M.IsolateRef get isolate => _isolate;
  M.ClassRef get cls => _cls;
  List<Element> get content => _content;

  set content(Iterable<Element> value) {
    _content = value.toList();
    _r.dirty();
  }

  factory NavClassMenuElement(M.IsolateRef isolate, M.ClassRef cls,
      {RenderingQueue? queue}) {
    assert(isolate != null);
    assert(cls != null);
    NavClassMenuElement e = new NavClassMenuElement.created();
    e._r = new RenderingScheduler<NavClassMenuElement>(e, queue: queue);
    e._isolate = isolate;
    e._cls = cls;
    return e;
  }

  NavClassMenuElement.created() : super.created('nav-class-menu');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = <Element>[];
    _r.disable(notify: true);
  }

  void render() {
    children = <Element>[
      navMenu(cls.name!,
          content: _content, link: Uris.inspect(isolate, object: cls))
    ];
  }
}

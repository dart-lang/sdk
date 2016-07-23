// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M show IsolateRef, ClassRef;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/menu.dart';

class NavClassMenuElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NavClassMenuElement>('nav-class-menu',
                     dependencies: const [NavMenuElement.tag]);

  RenderingScheduler _r;

  Stream<RenderedEvent<NavClassMenuElement>> get onRendered => _r.onRendered;

  bool _last;
  M.IsolateRef _isolate;
  M.ClassRef _cls;
  bool get last => _last;
  M.IsolateRef get isolate => _isolate;
  M.ClassRef get cls => _cls;
  set last(bool value) => _last = _r.checkAndReact(_last, value);

  factory NavClassMenuElement(M.IsolateRef isolate, M.ClassRef cls,
      {bool last: false, RenderingQueue queue}) {
    assert(isolate != null);
    assert(cls != null);
    assert(last != null);
    NavClassMenuElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._cls = cls;
    e._last = last;
    return e;
  }

  NavClassMenuElement.created() : super.created() { createShadowRoot(); }

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    shadowRoot.children = [];
  }

  void render() {
    shadowRoot.children = [
      new NavMenuElement(cls.name, last: last, queue: _r.queue,
          link: Uris.inspect(isolate, object: cls))
        ..children = [new ContentElement()]
    ];
  }
}

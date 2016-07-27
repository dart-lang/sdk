// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M show IsolateRef, LibraryRef;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/menu.dart';

class NavLibraryMenuElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NavLibraryMenuElement>('nav-library-menu',
                     dependencies: const [NavMenuElement.tag]);

  RenderingScheduler _r;

  Stream<RenderedEvent<NavLibraryMenuElement>> get onRendered => _r.onRendered;

  bool _last;
  M.IsolateRef _isolate;
  M.LibraryRef _library;
  bool get last => _last;
  M.IsolateRef get isolate => _isolate;
  M.LibraryRef get library => _library;
  set last(bool value) => _last = _r.checkAndReact(_last, value);

  factory NavLibraryMenuElement(M.IsolateRef isolate, M.LibraryRef library,
      {bool last: false, RenderingQueue queue}) {
    assert(isolate != null);
    assert(library != null);
    assert(last != null);
    NavLibraryMenuElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._library = library;
    e._last = last;
    return e;
  }

  NavLibraryMenuElement.created() : super.created() { createShadowRoot(); }

  @override
  void attached() { super.attached(); _r.enable(); }

  @override
  void detached() {
    super.detached(); _r.disable(notify: true);
    shadowRoot.children = [];
  }

  void render() {
    shadowRoot.children = [
      new NavMenuElement(library.name, last: last, queue: _r.queue,
                link: Uris.inspect(isolate, object: library).toString())
        ..children = [new ContentElement()]
    ];
  }
}

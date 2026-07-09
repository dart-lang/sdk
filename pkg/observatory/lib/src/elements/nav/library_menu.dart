// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../../../models.dart' as M show IsolateRef, LibraryRef;
import '../helpers/custom_element.dart';
import '../helpers/nav_menu.dart';
import '../helpers/rendering_scheduler.dart';
import '../helpers/uris.dart';

class NavLibraryMenuElement extends CustomElement implements Renderable {
  late RenderingScheduler<NavLibraryMenuElement> _r;

  Stream<RenderedEvent<NavLibraryMenuElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.LibraryRef _library;
  List<HTMLElement> _content = const [];

  M.IsolateRef get isolate => _isolate;
  M.LibraryRef get library => _library;
  List<HTMLElement> get content => _content;

  set content(Iterable<HTMLElement> value) {
    _content = value.toList();
    _r.dirty();
  }

  factory NavLibraryMenuElement(
    M.IsolateRef isolate,
    M.LibraryRef library, {
    RenderingQueue? queue,
  }) {
    NavLibraryMenuElement e = new NavLibraryMenuElement.created();
    e._r = new RenderingScheduler<NavLibraryMenuElement>(e, queue: queue);
    e._isolate = isolate;
    e._library = library;
    return e;
  }

  NavLibraryMenuElement.created() : super.created('nav-library-menu');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    removeChildren();
    _r.disable(notify: true);
  }

  void render() {
    children = <HTMLElement>[
      navMenu(
        library.name!,
        content: _content,
        link: Uris.inspect(isolate, object: library).toString(),
      ),
    ];
  }
}

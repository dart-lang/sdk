// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library library_ref_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M show IsolateRef, LibraryRef;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class LibraryRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<LibraryRefElement> _r;

  Stream<RenderedEvent<LibraryRefElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.LibraryRef _library;

  M.IsolateRef get isolate => _isolate;
  M.LibraryRef get library => _library;

  factory LibraryRefElement(M.IsolateRef isolate, M.LibraryRef library,
      {RenderingQueue? queue}) {
    assert(isolate != null);
    assert(library != null);
    LibraryRefElement e = new LibraryRefElement.created();
    e._r = new RenderingScheduler<LibraryRefElement>(e, queue: queue);
    e._isolate = isolate;
    e._library = library;
    return e;
  }

  LibraryRefElement.created() : super.created('library-ref');

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
    final name = _library.name;
    children = <Element>[
      new AnchorElement(href: Uris.inspect(_isolate, object: _library))
        ..text = (name == null || name.isEmpty) ? 'unnamed' : name
    ];
  }
}

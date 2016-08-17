// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M
  show IsolateRef, InstructionsRef;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class InstructionsRefElement extends HtmlElement implements Renderable {
  static const tag = const Tag<InstructionsRefElement>('instructions-ref');

  RenderingScheduler<InstructionsRefElement> _r;

  Stream<RenderedEvent<InstructionsRefElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.InstructionsRef _instructions;

  M.IsolateRef get isolate => _isolate;
  M.InstructionsRef get instructions => _instructions;

  factory InstructionsRefElement(M.IsolateRef isolate,
      M.InstructionsRef instructions, {RenderingQueue queue}) {
    assert(isolate != null);
    assert(instructions != null);
    InstructionsRefElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._instructions = instructions;
    return e;
  }

  InstructionsRefElement.created() : super.created();

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
      new AnchorElement(href: Uris.inspect(_isolate, object: _instructions))
        ..children = [
          new SpanElement()..classes = ['emphatize']
            ..text = 'Instructions',
          new SpanElement()..text = ' (${_instructions.code.name})'
        ]
    ];
  }
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library function_ref_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M
  show IsolateRef, FunctionRef, isSyntheticFunction, ClassRef, ObjectRef;
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class FunctionRefElement extends HtmlElement implements Renderable {
  static const tag = const Tag<FunctionRefElement>('function-ref-wrapped');

  RenderingScheduler<FunctionRefElement> _r;

  Stream<RenderedEvent<FunctionRefElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.FunctionRef _function;
  bool _qualified;

  M.IsolateRef get isolate => _isolate;
  M.FunctionRef get function => _function;
  bool get qualified => _qualified;

  factory FunctionRefElement(M.IsolateRef isolate, M.FunctionRef function,
      {bool qualified: true, RenderingQueue queue}) {
    assert(isolate != null);
    assert(function != null);
    assert(qualified != null);
    FunctionRefElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._function = function;
    e._qualified = qualified;
    return e;
  }

  FunctionRefElement.created() : super.created();

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
    var content = <Element>[
      new AnchorElement(href: M.isSyntheticFunction(function.kind) ? null
        : Uris.inspect(_isolate, object: _function))
        ..text = _function.name
    ];
    if (qualified) {
      M.ObjectRef owner = _function.dartOwner;
      while (owner is M.FunctionRef) {
        M.FunctionRef function = (owner as M.FunctionRef);
        content.addAll([
          new SpanElement()..text = '.',
          new AnchorElement(href: M.isSyntheticFunction(function.kind) ? null
            : Uris.inspect(_isolate, object: function))
            ..text = function.name
        ]);
        owner = function.dartOwner;
      }
      if (owner is M.ClassRef) {
        content.addAll([
          new SpanElement()..text = '.',
          new ClassRefElement(_isolate, owner, queue: _r.queue)
        ]);
      }
    }
    children = content.reversed.toList(growable: false);
  }
}

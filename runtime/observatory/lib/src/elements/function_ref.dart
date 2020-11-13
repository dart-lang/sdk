// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library function_ref_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M
    show
        IsolateRef,
        FunctionRef,
        isSyntheticFunction,
        ClassRef,
        ObjectRef,
        getFunctionFullName;
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class FunctionRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<FunctionRefElement> _r;

  Stream<RenderedEvent<FunctionRefElement>> get onRendered => _r.onRendered;

  M.IsolateRef? _isolate;
  late M.FunctionRef _function;
  late bool _qualified;

  M.IsolateRef? get isolate => _isolate;
  M.FunctionRef get function => _function;
  bool get qualified => _qualified;

  factory FunctionRefElement(M.IsolateRef? isolate, M.FunctionRef function,
      {bool qualified: true, RenderingQueue? queue}) {
    assert(function != null);
    assert(qualified != null);
    FunctionRefElement e = new FunctionRefElement.created();
    e._r = new RenderingScheduler<FunctionRefElement>(e, queue: queue);
    e._isolate = isolate;
    e._function = function;
    e._qualified = qualified;
    return e;
  }

  FunctionRefElement.created() : super.created('function-ref');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = <Element>[];
    title = '';
    _r.disable(notify: true);
  }

  void render() {
    var content = <Element>[
      new AnchorElement(
          href: (M.isSyntheticFunction(_function.kind) || (_isolate == null))
              ? null
              : Uris.inspect(_isolate!, object: _function))
        ..text = _function.name
    ];
    if (qualified) {
      M.ObjectRef? owner = _function.dartOwner;
      while (owner is M.FunctionRef) {
        M.FunctionRef function = (owner as M.FunctionRef);
        content.addAll([
          new SpanElement()..text = '.',
          new AnchorElement(
              href: (M.isSyntheticFunction(function.kind) || (_isolate == null))
                  ? null
                  : Uris.inspect(_isolate!, object: function))
            ..text = function.name
        ]);
        owner = function.dartOwner;
      }
      if (owner is M.ClassRef) {
        content.addAll([
          new SpanElement()..text = '.',
          new ClassRefElement(_isolate!, owner as M.ClassRef, queue: _r.queue)
              .element
        ]);
      }
    }
    children = content.reversed.toList(growable: false);
    title = M.getFunctionFullName(_function);
  }
}

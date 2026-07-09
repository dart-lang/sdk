// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_ref_element;

import 'dart:async';

import 'package:web/web.dart';

import 'helpers/custom_element.dart';
import 'helpers/rendering_scheduler.dart';
import 'helpers/uris.dart';

import '../../models.dart' as M show IsolateRef, CodeRef, isSyntheticCode;

class CodeRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<CodeRefElement> _r;

  Stream<RenderedEvent<CodeRefElement>> get onRendered => _r.onRendered;

  M.IsolateRef? _isolate;
  late M.CodeRef _code;

  M.IsolateRef get isolate => _isolate!;
  M.CodeRef get code => _code;

  factory CodeRefElement(
    M.IsolateRef? isolate,
    M.CodeRef code, {
    RenderingQueue? queue,
  }) {
    CodeRefElement e = new CodeRefElement.created();
    e._r = new RenderingScheduler<CodeRefElement>(e, queue: queue);
    e._isolate = isolate;
    e._code = code;
    return e;
  }

  CodeRefElement.created() : super.created('code-ref');

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
    setChildren(<HTMLElement>[
      new HTMLAnchorElement()
        ..href = ((M.isSyntheticCode(_code.kind)) || (_isolate == null))
            ? ''
            : Uris.inspect(_isolate!, object: _code)
        ..textContent = _code.name ?? '',
    ]);
  }
}

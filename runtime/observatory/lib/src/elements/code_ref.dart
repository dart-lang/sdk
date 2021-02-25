// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_ref_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M
    show IsolateRef, CodeRef, isSyntheticCode;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class CodeRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<CodeRefElement> _r;

  Stream<RenderedEvent<CodeRefElement>> get onRendered => _r.onRendered;

  M.IsolateRef? _isolate;
  late M.CodeRef _code;

  M.IsolateRef get isolate => _isolate!;
  M.CodeRef get code => _code;

  factory CodeRefElement(M.IsolateRef? isolate, M.CodeRef code,
      {RenderingQueue? queue}) {
    assert(code != null);
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
    children = <Element>[];
    _r.disable(notify: true);
  }

  void render() {
    children = <Element>[
      new AnchorElement(
          href: ((M.isSyntheticCode(_code.kind)) || (_isolate == null))
              ? null
              : Uris.inspect(_isolate!, object: _code))
        ..text = _code.name
    ];
  }
}

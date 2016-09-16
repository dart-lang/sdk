// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M
    show IsolateRef, LocalVarDescriptorsRef;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class LocalVarDescriptorsRefElement extends HtmlElement implements Renderable {
  static const tag = const Tag<LocalVarDescriptorsRefElement>('var-ref');

  RenderingScheduler<LocalVarDescriptorsRefElement> _r;

  Stream<RenderedEvent<LocalVarDescriptorsRefElement>> get onRendered =>
      _r.onRendered;

  M.IsolateRef _isolate;
  M.LocalVarDescriptorsRef _localVar;

  M.IsolateRef get isolate => _isolate;
  M.LocalVarDescriptorsRef get localVar => _localVar;

  factory LocalVarDescriptorsRefElement(
      M.IsolateRef isolate, M.LocalVarDescriptorsRef localVar,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(localVar != null);
    LocalVarDescriptorsRefElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._localVar = localVar;
    return e;
  }

  LocalVarDescriptorsRefElement.created() : super.created();

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
    final text = (_localVar.name == null || _localVar.name == '')
        ? 'LocalVarDescriptors'
        : _localVar.name;
    children = [
      new AnchorElement(href: Uris.inspect(_isolate, object: _localVar))
        ..text = text
    ];
  }
}

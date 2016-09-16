// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_link_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart'
    show IsolateRef, SourceLocation, Script, ScriptRepository;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';

class SourceLinkElement extends HtmlElement implements Renderable {
  static const tag = const Tag<SourceLinkElement>('source-link');

  RenderingScheduler _r;

  Stream<RenderedEvent<SourceLinkElement>> get onRendered => _r.onRendered;

  IsolateRef _isolate;
  SourceLocation _location;
  Script _script;
  ScriptRepository _repository;

  IsolateRef get isolate => _isolate;
  SourceLocation get location => _location;

  factory SourceLinkElement(
      IsolateRef isolate, SourceLocation location, ScriptRepository repository,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(location != null);
    SourceLinkElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._location = location;
    e._repository = repository;
    return e;
  }

  SourceLinkElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _repository.get(_isolate, _location.script.id).then((script) {
      _script = script;
      _r.dirty();
    });
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
  }

  Future render() async {
    if (_script == null) {
      children = [new SpanElement()..text = '<LOADING>'];
    } else {
      String label = _script.uri.split('/').last;
      int token = _location.tokenPos;
      int line = _script.tokenToLine(token);
      int column = _script.tokenToCol(token);
      children = [
        new AnchorElement(
            href: Uris.inspect(isolate, object: _script, pos: token))
          ..title = _script.uri
          ..text = '${label}:${line}:${column}'
      ];
    }
  }
}

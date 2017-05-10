// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_inset_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/script_inset.dart';

class SourceInsetElement extends HtmlElement implements Renderable {
  static const tag = const Tag<SourceInsetElement>('source-inset');

  RenderingScheduler _r;

  Stream<RenderedEvent<SourceInsetElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.SourceLocation _location;
  M.ScriptRepository _scripts;
  M.ObjectRepository _objects;
  M.EventRepository _events;
  int _currentPos;
  bool _inDebuggerContext;
  Iterable _variables;

  M.IsolateRef get isolate => _isolate;
  M.SourceLocation get location => _location;

  factory SourceInsetElement(
      M.IsolateRef isolate,
      M.SourceLocation location,
      M.ScriptRepository scripts,
      M.ObjectRepository objects,
      M.EventRepository events,
      {int currentPos,
      bool inDebuggerContext: false,
      Iterable variables: const [],
      RenderingQueue queue}) {
    assert(isolate != null);
    assert(location != null);
    assert(scripts != null);
    assert(objects != null);
    assert(events != null);
    assert(inDebuggerContext != null);
    assert(variables != null);
    SourceInsetElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._location = location;
    e._scripts = scripts;
    e._objects = objects;
    e._events = events;
    e._currentPos = currentPos;
    e._inDebuggerContext = inDebuggerContext;
    e._variables = variables;
    return e;
  }

  SourceInsetElement.created() : super.created();

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
    children = [
      new ScriptInsetElement(
          _isolate, _location.script, _scripts, _objects, _events,
          startPos: _location.tokenPos,
          endPos: _location.endTokenPos,
          currentPos: _currentPos,
          inDebuggerContext: _inDebuggerContext,
          variables: _variables,
          queue: _r.queue)
    ];
  }
}

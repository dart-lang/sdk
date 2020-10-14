// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/src/elements/curly_block.dart';
import 'package:observatory_2/src/elements/helpers/any_ref.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/src/elements/helpers/uris.dart';

class ContextRefElement extends CustomElement implements Renderable {
  RenderingScheduler<ContextRefElement> _r;

  Stream<RenderedEvent<ContextRefElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.ContextRef _context;
  M.ObjectRepository _objects;
  M.Context _loadedContext;
  bool _expandable;
  bool _expanded = false;

  M.IsolateRef get isolate => _isolate;
  M.ContextRef get context => _context;

  factory ContextRefElement(
      M.IsolateRef isolate, M.ContextRef context, M.ObjectRepository objects,
      {RenderingQueue queue, bool expandable: true}) {
    assert(isolate != null);
    assert(context != null);
    assert(objects != null);
    ContextRefElement e = new ContextRefElement.created();
    e._r = new RenderingScheduler<ContextRefElement>(e, queue: queue);
    e._isolate = isolate;
    e._context = context;
    e._objects = objects;
    e._expandable = expandable;
    return e;
  }

  ContextRefElement.created() : super.created('context-ref');

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

  Future _refresh() async {
    _loadedContext = await _objects.get(_isolate, _context.id);
    _r.dirty();
  }

  void render() {
    var children = <HtmlElement>[
      new AnchorElement(href: Uris.inspect(_isolate, object: _context))
        ..children = <Element>[
          new SpanElement()
            ..classes = ['emphasize']
            ..text = 'Context',
          new SpanElement()..text = ' (${_context.length})',
        ],
    ];
    if (_expandable) {
      children.addAll([
        new SpanElement()..text = ' ',
        (new CurlyBlockElement(expanded: _expanded, queue: _r.queue)
              ..content = <Element>[
                new DivElement()
                  ..classes = ['indent']
                  ..children = _createValue()
              ]
              ..onToggle.listen((e) async {
                _expanded = e.control.expanded;
                if (_expanded) {
                  e.control.disabled = true;
                  await _refresh();
                  e.control.disabled = false;
                }
              }))
            .element
      ]);
    }
    this.children = children;
  }

  List<Element> _createValue() {
    if (_loadedContext == null) {
      return [new SpanElement()..text = 'Loading...'];
    }
    var members = <Element>[];
    if (_loadedContext.parentContext != null) {
      members.add(new DivElement()
        ..classes = ['memberItem']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberName']
            ..text = 'parent context',
          new DivElement()
            ..classes = ['memberName']
            ..children = <Element>[
              new ContextRefElement(
                      _isolate, _loadedContext.parentContext, _objects,
                      queue: _r.queue)
                  .element
            ]
        ]);
    }
    if (_loadedContext.variables.isNotEmpty) {
      var variables = _loadedContext.variables.toList();
      for (var index = 0; index < variables.length; index++) {
        var variable = variables[index];
        members.add(new DivElement()
          ..classes = ['memberItem']
          ..children = <Element>[
            new DivElement()
              ..classes = ['memberName']
              ..text = '[ $index ]',
            new DivElement()
              ..classes = ['memberName']
              ..children = <Element>[
                anyRef(_isolate, variable.value, _objects, queue: _r.queue)
              ]
          ]);
      }
    }
    return [
      new DivElement()
        ..classes = ['memberList']
        ..children = members
    ];
  }
}

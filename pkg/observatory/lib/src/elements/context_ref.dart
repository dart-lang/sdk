// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'curly_block.dart';
import 'helpers/any_ref.dart';
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/rendering_scheduler.dart';
import 'helpers/uris.dart';

class ContextRefElement extends CustomElement implements Renderable {
  late RenderingScheduler<ContextRefElement> _r;

  Stream<RenderedEvent<ContextRefElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.ContextRef _context;
  late M.ObjectRepository _objects;
  M.Context? _loadedContext;
  late bool _expandable;
  bool _expanded = false;

  M.IsolateRef get isolate => _isolate;
  M.ContextRef get context => _context;

  factory ContextRefElement(
    M.IsolateRef isolate,
    M.ContextRef context,
    M.ObjectRepository objects, {
    RenderingQueue? queue,
    bool expandable = true,
  }) {
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
    removeChildren();
  }

  Future _refresh() async {
    _loadedContext = await _objects.get(_isolate, _context.id!) as M.Context;
    _r.dirty();
  }

  void render() {
    final children = <HTMLElement>[
      new HTMLAnchorElement()
        ..href = Uris.inspect(_isolate, object: _context)
        ..appendChildren(<HTMLElement>[
          new HTMLSpanElement()
            ..className = 'emphasize'
            ..textContent = 'Context',
          new HTMLSpanElement()..textContent = ' (${_context.length})',
        ]),
    ];
    if (_expandable) {
      children.addAll([
        new HTMLSpanElement()..textContent = ' ',
        (new CurlyBlockElement(expanded: _expanded, queue: _r.queue)
              ..content = <HTMLElement>[
                new HTMLDivElement()
                  ..className = 'indent'
                  ..appendChildren(_createValue()),
              ]
              ..onToggle.listen((e) async {
                _expanded = e.control.expanded;
                if (_expanded) {
                  e.control.disabled = true;
                  await _refresh();
                  e.control.disabled = false;
                }
              }))
            .element,
      ]);
    }
    setChildren(children);
  }

  List<HTMLElement> _createValue() {
    if (_loadedContext == null) {
      return [new HTMLSpanElement()..textContent = 'Loading...'];
    }
    var members = <HTMLElement>[];
    if (_loadedContext!.parentContext != null) {
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'parent context',
            new HTMLDivElement()
              ..className = 'memberName'
              ..appendChild(
                new ContextRefElement(
                  _isolate,
                  _loadedContext!.parentContext!,
                  _objects,
                  queue: _r.queue,
                ).element,
              ),
          ]),
      );
    }
    if (_loadedContext!.variables!.isNotEmpty) {
      var variables = _loadedContext!.variables!.toList();
      for (var index = 0; index < variables.length; index++) {
        var variable = variables[index];
        members.add(
          new HTMLDivElement()
            ..className = 'memberItem'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = '[ $index ]',
              new HTMLDivElement()
                ..className = 'memberName'
                ..appendChild(
                  anyRef(_isolate, variable.value, _objects, queue: _r.queue),
                ),
            ]),
        );
      }
    }
    return [
      new HTMLDivElement()
        ..className = 'memberList'
        ..appendChildren(members),
    ];
  }
}

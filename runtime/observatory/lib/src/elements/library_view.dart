// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library library_view_element;

import 'dart:async';

import 'package:web/web.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/eval_box.dart';
import 'package:observatory/src/elements/field_ref.dart';
import 'package:observatory/src/elements/function_ref.dart';
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/library_ref.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/library_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/object_common.dart';
import 'package:observatory/src/elements/script_inset.dart';
import 'package:observatory/src/elements/script_ref.dart';

class LibraryViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<LibraryViewElement> _r;

  Stream<RenderedEvent<LibraryViewElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.Library _library;
  late M.LibraryRepository _libraries;
  late M.FieldRepository _fields;
  late M.RetainedSizeRepository _retainedSizes;
  late M.ReachableSizeRepository _reachableSizes;
  late M.InboundReferencesRepository _references;
  late M.RetainingPathRepository _retainingPaths;
  late M.ScriptRepository _scripts;
  late M.ObjectRepository _objects;
  late M.EvalRepository _eval;
  Iterable<M.Field>? _variables;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.Library get library => _library;

  factory LibraryViewElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.Library library,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.LibraryRepository libraries,
      M.FieldRepository fields,
      M.RetainedSizeRepository retainedSizes,
      M.ReachableSizeRepository reachableSizes,
      M.InboundReferencesRepository references,
      M.RetainingPathRepository retainingPaths,
      M.ScriptRepository scripts,
      M.ObjectRepository objects,
      M.EvalRepository eval,
      {RenderingQueue? queue}) {
    LibraryViewElement e = new LibraryViewElement.created();
    e._r = new RenderingScheduler<LibraryViewElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._library = library;
    e._libraries = libraries;
    e._fields = fields;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._references = references;
    e._retainingPaths = retainingPaths;
    e._scripts = scripts;
    e._objects = objects;
    e._eval = eval;
    return e;
  }

  LibraryViewElement.created() : super.created('library-view');

  @override
  attached() {
    super.attached();
    _r.enable();
    _refresh();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    removeChildren();
  }

  void render() {
    final rootScript = library.rootScript;

    children = <HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        new NavLibraryMenuElement(_isolate, _library, queue: _r.queue).element,
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                _refresh();
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h2()..textContent = 'Library',
          new HTMLHRElement(),
          new ObjectCommonElement(_isolate, _library, _retainedSizes,
                  _reachableSizes, _references, _retainingPaths, _objects,
                  queue: _r.queue)
              .element,
          new HTMLDivElement()
            ..className = 'memberList'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'uri',
                  new HTMLDivElement()
                    ..className = 'memberValue'
                    ..textContent = _library.uri ?? ''
                ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'vm name',
                  new HTMLDivElement()
                    ..className = 'memberValue'
                    ..textContent = _library.vmName ?? ''
                ])
            ]),
          new HTMLHRElement(),
          new EvalBoxElement(_isolate, _library, _objects, _eval,
                  queue: _r.queue)
              .element,
          new HTMLHRElement(),
          _createDependencies(),
          new HTMLBRElement(),
          _createScripts(),
          new HTMLBRElement(),
          _createClasses(),
          new HTMLBRElement(),
          _createVariables(),
          new HTMLBRElement(),
          _createFunctions(),
          if (rootScript != null) ...[
            new HTMLHRElement(),
            new ScriptInsetElement(
                    _isolate, rootScript, _scripts, _objects, _events,
                    queue: _r.queue)
                .element
          ],
        ])
    ];
  }

  Future _refresh() async {
    _library = await _libraries.get(_isolate, _library.id!);
    _variables = null;
    _r.dirty();
    _variables = await Future.wait(
        _library.variables!.map((field) => _fields.get(_isolate, field.id!)));
    _r.dirty();
  }

  HTMLElement _createDependencies() {
    if (_library.dependencies!.isEmpty) {
      return new HTMLSpanElement();
    }
    final dependencies = _library.dependencies!.toList();
    return new HTMLDivElement()
      ..appendChildren(<HTMLElement>[
        new HTMLSpanElement()
          ..textContent = 'dependencies (${dependencies.length}) ',
        (new CurlyBlockElement(queue: _r.queue)
              ..content = dependencies
                  .map<HTMLElement>((d) => new HTMLDivElement()
                    ..className = 'indent'
                    ..appendChildren(<HTMLElement>[
                      new HTMLSpanElement()
                        ..textContent = d.isImport ? 'import ' : 'export ',
                      new LibraryRefElement(_isolate, d.target, queue: _r.queue)
                          .element,
                      new HTMLSpanElement()
                        ..textContent =
                            d.prefix == null ? '' : ' as ${d.prefix}',
                      new HTMLSpanElement()
                        ..textContent = d.isDeferred ? ' deferred' : '',
                    ]))
                  .toList())
            .element
      ]);
  }

  HTMLElement _createScripts() {
    if (_library.scripts!.isEmpty) {
      return new HTMLSpanElement();
    }
    final scripts = _library.scripts!.toList();
    return new HTMLDivElement()
      ..appendChildren(<HTMLElement>[
        new HTMLSpanElement()..textContent = 'scripts (${scripts.length}) ',
        (new CurlyBlockElement(queue: _r.queue)
              ..content = scripts
                  .map<HTMLElement>((s) => new HTMLDivElement()
                    ..className = 'indent'
                    ..appendChildren(<HTMLElement>[
                      new ScriptRefElement(_isolate, s, queue: _r.queue).element
                    ]))
                  .toList())
            .element
      ]);
  }

  HTMLElement _createClasses() {
    if (_library.classes!.isEmpty) {
      return new HTMLSpanElement();
    }
    final classes = _library.classes!.toList();
    return new HTMLDivElement()
      ..appendChildren(<HTMLElement>[
        new HTMLSpanElement()..textContent = 'classes (${classes.length}) ',
        (new CurlyBlockElement(queue: _r.queue)
              ..content = classes
                  .map<HTMLElement>((c) => new HTMLDivElement()
                    ..className = 'indent'
                    ..appendChildren(<HTMLElement>[
                      new ClassRefElement(_isolate, c, queue: _r.queue).element
                    ]))
                  .toList())
            .element
      ]);
  }

  HTMLElement _createVariables() {
    if (_library.variables!.isEmpty) {
      return new HTMLSpanElement();
    }
    final variables = _library.variables!.toList();
    return new HTMLDivElement()
      ..appendChildren(<HTMLElement>[
        new HTMLSpanElement()..textContent = 'variables (${variables.length}) ',
        (new CurlyBlockElement(queue: _r.queue)
              ..content = <HTMLElement>[
                _variables == null
                    ? (new HTMLSpanElement()..textContent = 'loading...')
                    : (new HTMLDivElement()
                      ..className = 'indent memberList'
                      ..appendChildren(_variables!
                          .map<HTMLElement>((f) => new HTMLDivElement()
                            ..className = 'memberItem'
                            ..appendChildren(<HTMLElement>[
                              new HTMLDivElement()
                                ..className = 'memberName'
                                ..appendChildren(<HTMLElement>[
                                  new FieldRefElement(_isolate, f, _objects,
                                          queue: _r.queue)
                                      .element
                                ]),
                              new HTMLDivElement()
                                ..className = 'memberValue'
                                ..appendChildren(<HTMLElement>[
                                  new HTMLSpanElement()..textContent = ' = ',
                                  anyRef(_isolate, f.staticValue, _objects,
                                      queue: _r.queue)
                                ])
                            ]))))
              ])
            .element
      ]);
  }

  HTMLElement _createFunctions() {
    if (_library.functions!.isEmpty) {
      return new HTMLSpanElement();
    }
    final functions = _library.functions!.toList();
    return new HTMLDivElement()
      ..appendChildren(<HTMLElement>[
        new HTMLSpanElement()..textContent = 'functions (${functions.length}) ',
        (new CurlyBlockElement(queue: _r.queue)
              ..content = functions
                  .map<HTMLElement>((f) => new HTMLDivElement()
                    ..className = 'indent'
                    ..appendChildren(<HTMLElement>[
                      new FunctionRefElement(_isolate, f, queue: _r.queue)
                          .element
                    ]))
                  .toList())
            .element
      ]);
  }
}

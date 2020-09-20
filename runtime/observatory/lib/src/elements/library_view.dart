// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library library_view_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/class_ref.dart';
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/eval_box.dart';
import 'package:observatory/src/elements/field_ref.dart';
import 'package:observatory/src/elements/function_ref.dart';
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/library_ref.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/library_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/object_common.dart';
import 'package:observatory/src/elements/script_ref.dart';
import 'package:observatory/src/elements/script_inset.dart';
import 'package:observatory/src/elements/view_footer.dart';

class LibraryViewElement extends CustomElement implements Renderable {
  RenderingScheduler<LibraryViewElement> _r;

  Stream<RenderedEvent<LibraryViewElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.Library _library;
  M.LibraryRepository _libraries;
  M.FieldRepository _fields;
  M.RetainedSizeRepository _retainedSizes;
  M.ReachableSizeRepository _reachableSizes;
  M.InboundReferencesRepository _references;
  M.RetainingPathRepository _retainingPaths;
  M.ScriptRepository _scripts;
  M.ObjectRepository _objects;
  M.EvalRepository _eval;
  Iterable<M.Field> _variables;

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
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(library != null);
    assert(libraries != null);
    assert(fields != null);
    assert(retainedSizes != null);
    assert(reachableSizes != null);
    assert(references != null);
    assert(retainingPaths != null);
    assert(scripts != null);
    assert(objects != null);
    assert(eval != null);
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
    children = <Element>[];
  }

  void render() {
    final rootScript = library.rootScript;

    children = <Element>[
      navBar(<Element>[
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
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = <Element>[
          new HeadingElement.h2()..text = 'Library',
          new HRElement(),
          new ObjectCommonElement(_isolate, _library, _retainedSizes,
                  _reachableSizes, _references, _retainingPaths, _objects,
                  queue: _r.queue)
              .element,
          new DivElement()
            ..classes = ['memberList']
            ..children = <Element>[
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'uri',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = _library.uri
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'vm name',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = _library.vmName
                ]
            ],
          new HRElement(),
          new EvalBoxElement(_isolate, _library, _objects, _eval,
                  queue: _r.queue)
              .element,
          new HRElement(),
          _createDependencies(),
          new BRElement(),
          _createScripts(),
          new BRElement(),
          _createClasses(),
          new BRElement(),
          _createVariables(),
          new BRElement(),
          _createFunctions(),
          if (rootScript != null) ...[
            new HRElement(),
            new ScriptInsetElement(
                    _isolate, rootScript, _scripts, _objects, _events,
                    queue: _r.queue)
                .element
          ],
          new HRElement(),
          new ViewFooterElement(queue: _r.queue).element
        ]
    ];
  }

  Future _refresh() async {
    _library = await _libraries.get(_isolate, _library.id);
    _variables = null;
    _r.dirty();
    _variables = await Future.wait(
        _library.variables.map((field) => _fields.get(_isolate, field.id)));
    _r.dirty();
  }

  Element _createDependencies() {
    if (_library.dependencies.isEmpty) {
      return new SpanElement();
    }
    final dependencies = _library.dependencies.toList();
    return new DivElement()
      ..children = <Element>[
        new SpanElement()..text = 'dependencies (${dependencies.length}) ',
        (new CurlyBlockElement(queue: _r.queue)
              ..content = dependencies
                  .map<Element>((d) => new DivElement()
                    ..classes = ['indent']
                    ..children = <Element>[
                      new SpanElement()
                        ..text = d.isImport ? 'import ' : 'export ',
                      new LibraryRefElement(_isolate, d.target, queue: _r.queue)
                          .element,
                      new SpanElement()
                        ..text = d.prefix == null ? '' : ' as ${d.prefix}',
                      new SpanElement()..text = d.isDeferred ? ' deferred' : '',
                    ])
                  .toList())
            .element
      ];
  }

  Element _createScripts() {
    if (_library.scripts.isEmpty) {
      return new SpanElement();
    }
    final scripts = _library.scripts.toList();
    return new DivElement()
      ..children = <Element>[
        new SpanElement()..text = 'scripts (${scripts.length}) ',
        (new CurlyBlockElement(queue: _r.queue)
              ..content = scripts
                  .map<Element>((s) => new DivElement()
                    ..classes = ['indent']
                    ..children = <Element>[
                      new ScriptRefElement(_isolate, s, queue: _r.queue).element
                    ])
                  .toList())
            .element
      ];
  }

  Element _createClasses() {
    if (_library.classes.isEmpty) {
      return new SpanElement();
    }
    final classes = _library.classes.toList();
    return new DivElement()
      ..children = <Element>[
        new SpanElement()..text = 'classes (${classes.length}) ',
        (new CurlyBlockElement(queue: _r.queue)
              ..content = classes
                  .map<Element>((c) => new DivElement()
                    ..classes = ['indent']
                    ..children = <Element>[
                      new ClassRefElement(_isolate, c, queue: _r.queue).element
                    ])
                  .toList())
            .element
      ];
  }

  Element _createVariables() {
    if (_library.variables.isEmpty) {
      return new SpanElement();
    }
    final variables = _library.variables.toList();
    return new DivElement()
      ..children = <Element>[
        new SpanElement()..text = 'variables (${variables.length}) ',
        (new CurlyBlockElement(queue: _r.queue)
              ..content = <Element>[
                _variables == null
                    ? (new SpanElement()..text = 'loading...')
                    : (new DivElement()
                      ..classes = ['indent', 'memberList']
                      ..children = _variables
                          .map<Element>((f) => new DivElement()
                            ..classes = ['memberItem']
                            ..children = <Element>[
                              new DivElement()
                                ..classes = ['memberName']
                                ..children = <Element>[
                                  new FieldRefElement(_isolate, f, _objects,
                                          queue: _r.queue)
                                      .element
                                ],
                              new DivElement()
                                ..classes = ['memberValue']
                                ..children = <Element>[
                                  new SpanElement()..text = ' = ',
                                  anyRef(_isolate, f.staticValue, _objects,
                                      queue: _r.queue)
                                ]
                            ])
                          .toList())
              ])
            .element
      ];
  }

  Element _createFunctions() {
    if (_library.functions.isEmpty) {
      return new SpanElement();
    }
    final functions = _library.functions.toList();
    return new DivElement()
      ..children = <Element>[
        new SpanElement()..text = 'functions (${functions.length}) ',
        (new CurlyBlockElement(queue: _r.queue)
              ..content = functions
                  .map<Element>((f) => new DivElement()
                    ..classes = ['indent']
                    ..children = <Element>[
                      new FunctionRefElement(_isolate, f, queue: _r.queue)
                          .element
                    ])
                  .toList())
            .element
      ];
  }
}

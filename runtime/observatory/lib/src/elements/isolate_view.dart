// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_view_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/eval_box.dart';
import 'package:observatory/src/elements/function_ref.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/isolate/location.dart';
import 'package:observatory/src/elements/isolate/run_state.dart';
import 'package:observatory/src/elements/isolate/shared_summary.dart';
import 'package:observatory/src/elements/library_ref.dart';
import 'package:observatory/src/elements/nav/class_menu.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/reload.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/script_inset.dart';
import 'package:observatory/src/elements/source_inset.dart';
import 'package:observatory/src/elements/view_footer.dart';
import 'package:observatory/utils.dart';

class IsolateViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<IsolateViewElement> _r;

  Stream<RenderedEvent<IsolateViewElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.Isolate _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.IsolateRepository _isolates;
  late M.ScriptRepository _scripts;
  late M.FunctionRepository _functions;
  late M.LibraryRepository _libraries;
  late M.ObjectRepository _objects;
  late M.EvalRepository _eval;
  M.ServiceFunction? _function;
  M.ScriptRef? _rootScript;
  late StreamSubscription _subscription;

  M.VMRef get vm => _vm;
  M.Isolate get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;

  factory IsolateViewElement(
      M.VM vm,
      M.Isolate isolate,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.IsolateRepository isolates,
      M.ScriptRepository scripts,
      M.FunctionRepository functions,
      M.LibraryRepository libraries,
      M.ObjectRepository objects,
      M.EvalRepository eval,
      {RenderingQueue? queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(isolates != null);
    assert(scripts != null);
    assert(functions != null);
    assert(objects != null);
    assert(eval != null);
    assert(libraries != null);
    IsolateViewElement e = new IsolateViewElement.created();
    e._r = new RenderingScheduler<IsolateViewElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._isolates = isolates;
    e._scripts = scripts;
    e._functions = functions;
    e._objects = objects;
    e._eval = eval;
    e._libraries = libraries;
    return e;
  }

  IsolateViewElement.created() : super.created('isolate-view');

  @override
  attached() {
    super.attached();
    _r.enable();
    _loadExtraData();
    _subscription = _events.onIsolateUpdate.listen((e) {
      if (e.isolate.id == _isolate) {
        _isolate = isolate;
        _r.dirty();
      }
    });
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = <Element>[];
    _subscription.cancel();
  }

  void render() {
    final uptime = new DateTime.now().difference(_isolate.startTime!);
    final libraries = _isolate.libraries!.toList();
    children = <Element>[
      navBar(<Element>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        (new NavReloadElement(_isolate, _isolates, _events, queue: _r.queue)
              ..onReload.listen((_) async {
                _isolate = await _isolates.get(_isolate);
                await _loadExtraData();
                _r.dirty();
              }))
            .element,
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                _isolate = await _isolates.get(_isolate);
                await _loadExtraData();
                _r.dirty();
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = <Element>[
          new HeadingElement.h2()..text = 'Isolate ${_isolate.name}',
          new BRElement(),
          new DivElement()
            ..classes = ['flex-row']
            ..children = <Element>[
              new DivElement()..style.flex = '1',
              new DivElement()
                ..children = <Element>[
                  new IsolateRunStateElement(_isolate, _events, queue: _r.queue)
                      .element,
                  new IsolateLocationElement(_isolate, _events, _scripts,
                          queue: _r.queue)
                      .element,
                  new SpanElement()..text = ' [',
                  new AnchorElement(href: Uris.debugger(_isolate))
                    ..text = 'debug',
                  new SpanElement()..text = ']'
                ]
            ],
          new DivElement()
            ..children = _function != null
                ? [
                    new BRElement(),
                    (new SourceInsetElement(_isolate, _function!.location!,
                            _scripts, _objects, _events,
                            currentPos: M
                                .topFrame(isolate.pauseEvent)!
                                .location!
                                .tokenPos,
                            queue: _r.queue)
                          ..classes = ['header_inset'])
                        .element
                  ]
                : const [],
          new HRElement(),
          new IsolateSharedSummaryElement(_isolate, _events, queue: _r.queue)
              .element,
          new HRElement(),
          new DivElement()
            ..classes = ['memberList']
            ..children = <Element>[
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'started at',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '${_isolate.startTime}'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'uptime',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '$uptime'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'root library',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..children = <Element>[
                      _isolate.rootLibrary == null
                          ? (new SpanElement()..text = 'loading...')
                          : new LibraryRefElement(
                                  _isolate, _isolate.rootLibrary!,
                                  queue: _r.queue)
                              .element
                    ]
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = _isolate.entry != null
                    ? [
                        new DivElement()
                          ..classes = ['memberName']
                          ..text = 'entry',
                        new DivElement()
                          ..classes = ['memberValue']
                          ..children = <Element>[
                            new FunctionRefElement(_isolate, _isolate.entry!,
                                    queue: _r.queue)
                                .element
                          ]
                      ]
                    : const [],
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'isolate id',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '${_isolate.number}'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'service protocol extensions',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '${_isolate.extensionRPCs}'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'object store',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..children = <Element>[
                      new AnchorElement(href: Uris.objectStore(_isolate))
                        ..text = 'object store'
                    ]
                ],
              new BRElement(),
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'libraries (${libraries.length})',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..children = <Element>[
                      (new CurlyBlockElement(queue: _r.queue)
                            ..content = libraries
                                .map<Element>((l) => new DivElement()
                                  ..children = <Element>[
                                    new LibraryRefElement(_isolate, l,
                                            queue: _r.queue)
                                        .element
                                  ])
                                .toList())
                          .element
                    ]
                ],
            ],
          new HRElement(),
          new EvalBoxElement(_isolate, _isolate.rootLibrary!, _objects, _eval,
                  queue: _r.queue)
              .element,
          new DivElement()
            ..children = _rootScript != null
                ? [
                    new HRElement(),
                    new ScriptInsetElement(
                            _isolate, _rootScript!, _scripts, _objects, _events,
                            queue: _r.queue)
                        .element
                  ]
                : const [],
          new HRElement(),
          new ViewFooterElement(queue: _r.queue).element
        ]
    ];
  }

  Future _loadExtraData() async {
    _function = null;
    _rootScript = null;
    final frame = M.topFrame(_isolate.pauseEvent);
    if (frame != null) {
      _function = await _functions.get(_isolate, frame.function!.id!);
    }
    if (_isolate.rootLibrary != null) {
      final rootLibrary =
          await _libraries.get(_isolate, _isolate.rootLibrary!.id!);
      _rootScript = rootLibrary.rootScript;
    }
    _r.dirty();
  }
}

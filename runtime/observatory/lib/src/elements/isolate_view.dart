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
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/isolate/location.dart';
import 'package:observatory/src/elements/isolate/run_state.dart';
import 'package:observatory/src/elements/isolate/shared_summary.dart';
import 'package:observatory/src/elements/library_ref.dart';
import 'package:observatory/src/elements/nav/class_menu.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/script_inset.dart';
import 'package:observatory/src/elements/source_inset.dart';
import 'package:observatory/src/elements/view_footer.dart';
import 'package:observatory/utils.dart';

class IsolateViewElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<IsolateViewElement>('isolate-view', dependencies: const [
    CurlyBlockElement.tag,
    EvalBoxElement.tag,
    FunctionRefElement.tag,
    IsolateLocationElement.tag,
    IsolateRunStateElement.tag,
    IsolateSharedSummaryElement.tag,
    LibraryRefElement.tag,
    NavClassMenuElement.tag,
    NavTopMenuElement.tag,
    NavIsolateMenuElement.tag,
    NavRefreshElement.tag,
    NavNotifyElement.tag,
    ScriptInsetElement.tag,
    SourceInsetElement.tag,
    ViewFooterElement.tag
  ]);

  RenderingScheduler<IsolateViewElement> _r;

  Stream<RenderedEvent<IsolateViewElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.Isolate _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.IsolateRepository _isolates;
  M.ScriptRepository _scripts;
  M.FunctionRepository _functions;
  M.LibraryRepository _libraries;
  M.ObjectRepository _objects;
  M.EvalRepository _eval;
  M.Function _function;
  M.ScriptRef _rootScript;
  StreamSubscription _subscription;

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
      {RenderingQueue queue}) {
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
    IsolateViewElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
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

  IsolateViewElement.created() : super.created();

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
    children = [];
    _subscription.cancel();
  }

  void render() {
    final uptime = new DateTime.now().difference(_isolate.startTime);
    final libraries = _isolate.libraries.toList();
    final List<M.Thread> threads = _isolate.threads;
    children = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavVMMenuElement(_vm, _events, queue: _r.queue),
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue),
        new NavRefreshElement(label: 'Reload Source', queue: _r.queue)
          ..onRefresh.listen((e) async {
            e.element.disabled = true;
            await _isolates.reloadSources(_isolate);
            _r.dirty();
          }),
        new NavRefreshElement(queue: _r.queue)
          ..onRefresh.listen((e) async {
            e.element.disabled = true;
            _isolate = await _isolates.get(_isolate);
            await _loadExtraData();
            _r.dirty();
          }),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new HeadingElement.h2()..text = 'Isolate ${_isolate.name}',
          new BRElement(),
          new DivElement()
            ..classes = ['flex-row']
            ..children = [
              new DivElement()..style.flex = '1',
              new DivElement()
                ..children = [
                  new IsolateRunStateElement(_isolate, _events,
                      queue: _r.queue),
                  new IsolateLocationElement(_isolate, _events, _scripts,
                      queue: _r.queue),
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
                    new SourceInsetElement(_isolate, _function.location,
                        _scripts, _objects, _events,
                        currentPos:
                            M.topFrame(isolate.pauseEvent).location.tokenPos,
                        queue: _r.queue)
                      ..classes = ['header_inset']
                  ]
                : const [],
          new HRElement(),
          new IsolateSharedSummaryElement(_isolate, _events, queue: _r.queue),
          new HRElement(),
          new DivElement()
            ..classes = ['memberList']
            ..children = [
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'started at',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '${_isolate.startTime}'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'uptime',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '$uptime'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'root library',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..children = [
                      _isolate.rootLibrary == null
                          ? (new SpanElement()..text = 'loading...')
                          : new LibraryRefElement(
                              _isolate, _isolate.rootLibrary,
                              queue: _r.queue)
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
                          ..children = [
                            new FunctionRefElement(_isolate, _isolate.entry,
                                queue: _r.queue)
                          ]
                      ]
                    : const [],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'isolate id',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '${_isolate.number}'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'service protocol extensions',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '${_isolate.extensionRPCs}'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'allocated zone handle count',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '${_isolate.numZoneHandles}'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'allocated scoped handle count',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '${_isolate.numScopedHandles}'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'object store',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..children = [
                      new AnchorElement(href: Uris.objectStore(_isolate))
                        ..text = 'object store'
                    ]
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'zone capacity high watermark'
                    ..title = '''The maximum amount of native zone memory
                    allocated by the isolate over it\'s life.''',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = Utils.formatSize(_isolate.zoneHighWatermark)
                    ..title = '${_isolate.zoneHighWatermark}B'
                ],
              new BRElement(),
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'libraries (${libraries.length})',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..children = [
                      new CurlyBlockElement(queue: _r.queue)
                        ..content = libraries
                            .map((l) => new DivElement()
                              ..children = [
                                new LibraryRefElement(_isolate, l,
                                    queue: _r.queue)
                              ])
                            .toList()
                    ]
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'threads (${threads.length})',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..children = [
                      new CurlyBlockElement(queue: _r.queue)
                        ..content = threads.map(_populateThreadInfo)
                    ]
                ]
            ],
          new HRElement(),
          new EvalBoxElement(_isolate, _isolate.rootLibrary, _objects, _eval,
              queue: _r.queue),
          new DivElement()
            ..children = _rootScript != null
                ? [
                    new HRElement(),
                    new ScriptInsetElement(
                        _isolate, _rootScript, _scripts, _objects, _events,
                        queue: _r.queue)
                  ]
                : const [],
          new HRElement(),
          new ViewFooterElement(queue: _r.queue)
        ]
    ];
  }

  DivElement _populateThreadInfo(M.Thread t) {
    return new DivElement()
      ..classes = ['indent']
      ..children = [
        new SpanElement()..text = '${t.id} ',
        new CurlyBlockElement(queue: _r.queue)
          ..content = [
            new DivElement()
              ..classes = ['indent']
              ..text = 'kind ${t.kindString}',
            new DivElement()
              ..classes = ['indent']
              ..title = '${t.zoneHighWatermark}B'
              ..text = 'zone capacity high watermark '
                  '${Utils.formatSize(t.zoneHighWatermark)}',
            new DivElement()
              ..classes = ['indent']
              ..title = '${t.zoneCapacity}B'
              ..text = 'current zone capacity ' +
                  '${Utils.formatSize(t.zoneCapacity)}',
          ]
      ];
  }

  Future _loadExtraData() async {
    _function = null;
    _rootScript = null;
    final frame = M.topFrame(_isolate.pauseEvent);
    if (frame != null) {
      _function = await _functions.get(_isolate, frame.function.id);
    }
    if (_isolate.rootLibrary != null) {
      final rootLibrary =
          await _libraries.get(_isolate, _isolate.rootLibrary.id);
      _rootScript = rootLibrary.rootScript;
    }
    _r.dirty();
  }
}

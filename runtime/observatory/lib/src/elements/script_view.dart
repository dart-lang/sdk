// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library script_view;

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/context_ref.dart';
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/library_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/object_common.dart';
import 'package:observatory/src/elements/script_inset.dart';
import 'package:observatory/src/elements/view_footer.dart';

class ScriptViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<ScriptViewElement> _r;

  Stream<RenderedEvent<ScriptViewElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.Script _script;
  late M.ScriptRepository _scripts;
  late M.RetainedSizeRepository _retainedSizes;
  late M.ReachableSizeRepository _reachableSizes;
  late M.InboundReferencesRepository _references;
  late M.RetainingPathRepository _retainingPaths;
  late M.ObjectRepository _objects;
  int? _pos;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;
  M.Script get script => _script;

  factory ScriptViewElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.Script script,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.ScriptRepository scripts,
      M.RetainedSizeRepository retainedSizes,
      M.ReachableSizeRepository reachableSizes,
      M.InboundReferencesRepository references,
      M.RetainingPathRepository retainingPaths,
      M.ObjectRepository objects,
      {int? pos,
      RenderingQueue? queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    assert(script != null);
    assert(scripts != null);
    assert(retainedSizes != null);
    assert(reachableSizes != null);
    assert(references != null);
    assert(retainingPaths != null);
    assert(objects != null);
    ScriptViewElement e = new ScriptViewElement.created();
    e._r = new RenderingScheduler<ScriptViewElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._script = script;
    e._scripts = scripts;
    e._retainedSizes = retainedSizes;
    e._reachableSizes = reachableSizes;
    e._references = references;
    e._retainingPaths = retainingPaths;
    e._objects = objects;
    e._pos = pos;
    return e;
  }

  ScriptViewElement.created() : super.created('script-view');

  @override
  attached() {
    super.attached();
    _r.enable();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = <Element>[];
  }

  void render() {
    children = <Element>[
      navBar(<Element>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        new NavLibraryMenuElement(_isolate, _script.library!, queue: _r.queue)
            .element,
        navMenu('object'),
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                _script = await _scripts.get(_isolate, _script.id!);
                _r.dirty();
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = <Element>[
          new HeadingElement.h2()..text = 'Script',
          new HRElement(),
          new ObjectCommonElement(_isolate, _script, _retainedSizes,
                  _reachableSizes, _references, _retainingPaths, _objects,
                  queue: _r.queue)
              .element,
          new BRElement(),
          new DivElement()
            ..classes = ['memberList']
            ..children = <Element>[
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'load time',
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = '${_script.loadTime}'
                ],
            ],
          new HRElement(),
          new ScriptInsetElement(_isolate, _script, _scripts, _objects, _events,
                  currentPos: _pos, queue: _r.queue)
              .element,
          new ViewFooterElement(queue: _r.queue).element
        ]
    ];
  }
}

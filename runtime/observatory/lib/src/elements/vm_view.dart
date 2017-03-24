// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm_view_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/isolate/summary.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/view_footer.dart';
import 'package:observatory/utils.dart';

class VMViewElement extends HtmlElement implements Renderable {
  static const tag = const Tag<VMViewElement>('vm-view', dependencies: const [
    IsolateSummaryElement.tag,
    NavTopMenuElement.tag,
    NavVMMenuElement.tag,
    NavRefreshElement.tag,
    NavNotifyElement.tag,
    ViewFooterElement.tag
  ]);

  RenderingScheduler<VMViewElement> _r;

  Stream<RenderedEvent<VMViewElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.IsolateRepository _isolates;
  M.ScriptRepository _scripts;
  StreamSubscription _vmSubscription;
  StreamSubscription _startSubscription;
  StreamSubscription _exitSubscription;

  M.VMRef get vm => _vm;
  M.NotificationRepository get notifications => _notifications;

  factory VMViewElement(
      M.VM vm,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.IsolateRepository isolates,
      M.ScriptRepository scripts,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(events != null);
    assert(notifications != null);
    VMViewElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._events = events;
    e._notifications = notifications;
    e._isolates = isolates;
    e._scripts = scripts;
    return e;
  }

  VMViewElement.created() : super.created();

  @override
  attached() {
    super.attached();
    _r.enable();
    _vmSubscription = _events.onVMUpdate.listen((e) {
      _vm = e.vm;
      _r.dirty();
    });
    _startSubscription = _events.onIsolateStart.listen((_) => _r.dirty());
    _exitSubscription = _events.onIsolateExit.listen((_) => _r.dirty());
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
    _vmSubscription.cancel();
    _startSubscription.cancel();
    _exitSubscription.cancel();
  }

  void render() {
    final uptime = new DateTime.now().difference(_vm.startTime);
    final isolates = _vm.isolates.toList();
    children = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavVMMenuElement(_vm, _events, queue: _r.queue),
        new NavRefreshElement(queue: _r.queue)
          ..onRefresh.listen((e) async {
            e.element.disabled = true;
            _r.dirty();
          }),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new HeadingElement.h1()..text = 'VM',
          new HRElement(),
          new DivElement()
            ..classes = ['memberList']
            ..children = [
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'name',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = _vm.displayName
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'version',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = _vm.version
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'started at',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '${_vm.startTime}'
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
                    ..text = 'refreshed at',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '${new DateTime.now()}'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'pid',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '${_vm.pid}'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'peak memory',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = Utils.formatSize(_vm.maxRSS)
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'native zone memory',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = Utils.formatSize(_vm.nativeZoneMemoryUsage)
                    ..title = '${_vm.nativeZoneMemoryUsage} bytes'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'native heap memory',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = Utils.formatSize(_vm.heapAllocatedMemoryUsage)
                    ..title = '${_vm.heapAllocatedMemoryUsage} bytes'
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'native heap allocation count',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '${_vm.heapAllocationCount}'
                ],
              new BRElement(),
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..children = [
                      new SpanElement()..text = 'see ',
                      new AnchorElement(href: Uris.flags())..text = 'flags'
                    ],
                  new DivElement()
                    ..classes = ['memberValue']
                    ..children = [
                      new SpanElement()..text = 'view ',
                      new AnchorElement(href: Uris.timeline())
                        ..text = 'timeline'
                    ]
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..children = [
                      new SpanElement()..text = 'view ',
                      new AnchorElement(href: Uris.nativeMemory())
                        ..text = 'native memory profile'
                    ]
                ]
            ],
          new BRElement(),
          new HeadingElement.h1()..text = 'Isolates (${isolates.length})',
          new HRElement(),
          new UListElement()
            ..classes = ['list-group']
            ..children = isolates
                .expand((i) => [
                      new LIElement()
                        ..classes = ['list-group-item']
                        ..children = [
                          new IsolateSummaryElement(
                              i, _isolates, _events, _scripts,
                              queue: _r.queue)
                        ],
                      new HRElement()
                    ])
                .toList(),
          new ViewFooterElement(queue: _r.queue)
        ]
    ];
  }
}

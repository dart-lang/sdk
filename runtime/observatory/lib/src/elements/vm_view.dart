// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm_view_element;

import 'dart:async';

import 'package:web/web.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/isolate/summary.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/utils.dart';

class VMViewElement extends CustomElement implements Renderable {
  late RenderingScheduler<VMViewElement> _r;

  Stream<RenderedEvent<VMViewElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.VMRepository _vms;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.IsolateRepository _isolates;
  late M.IsolateGroupRepository _isolateGroups;
  late M.ScriptRepository _scripts;
  late StreamSubscription _vmSubscription;
  late StreamSubscription _startSubscription;
  late StreamSubscription _exitSubscription;

  M.VMRef get vm => _vm;
  M.NotificationRepository get notifications => _notifications;

  factory VMViewElement(
      M.VM vm,
      M.VMRepository vms,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.IsolateRepository isolates,
      M.IsolateGroupRepository isolateGroups,
      M.ScriptRepository scripts,
      {RenderingQueue? queue}) {
    VMViewElement e = new VMViewElement.created();
    e._r = new RenderingScheduler<VMViewElement>(e, queue: queue);
    e._vm = vm;
    e._vms = vms;
    e._events = events;
    e._notifications = notifications;
    e._isolates = isolates;
    e._isolateGroups = isolateGroups;
    e._scripts = scripts;
    return e;
  }

  VMViewElement.created() : super.created('vm-view');

  @override
  attached() {
    super.attached();
    _r.enable();
    _vmSubscription = _events.onVMUpdate.listen((e) {
      _vm = e.vm as M.VM;
      _r.dirty();
    });
    _startSubscription = _events.onIsolateStart.listen((_) => _r.dirty());
    _exitSubscription = _events.onIsolateExit.listen((_) => _r.dirty());
    _loadExtraData();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    removeChildren();
    _vmSubscription.cancel();
    _startSubscription.cancel();
    _exitSubscription.cancel();
  }

  Future _loadExtraData() async {
    for (var group in _vm.isolateGroups) {
      await _isolateGroups.get(group);
    }
    for (var group in _vm.systemIsolateGroups) {
      await _isolateGroups.get(group);
    }
    _r.dirty();
  }

  void render() {
    children = <HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                _vm = await _vms.get(_vm);
                _loadExtraData();
                _r.dirty();
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      describeProcess(),
      describeVM(),
      describeIsolateGroups(),
      describeSystemIsolateGroups(),
    ];
  }

  HTMLElement describeProcess() {
    return new HTMLDivElement()
      ..className = 'content-centered-big'
      ..appendChildren(<HTMLElement>[
        new HTMLHeadingElement.h1()..textContent = 'Process',
        new HTMLDivElement()
          ..className = 'memberList'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberItem'
              ..appendChildren(<HTMLElement>[
                new HTMLDivElement()
                  ..className = 'memberName'
                  ..textContent = 'pid',
                new HTMLDivElement()
                  ..className = 'memberValue'
                  ..textContent = '${_vm.pid}'
              ]),
            new HTMLDivElement()
              ..className = 'memberItem'
              ..appendChildren(<HTMLElement>[
                new HTMLDivElement()
                  ..className = 'memberName'
                  ..textContent = 'current memory'
                  ..title =
                      'current value of the resident set size of the process running this VM',
                new HTMLDivElement()
                  ..className = 'memberValue'
                  ..textContent = Utils.formatSize(_vm.currentRSS)
              ]),
            new HTMLDivElement()
              ..className = 'memberItem'
              ..appendChildren(<HTMLElement>[
                new HTMLDivElement()
                  ..className = 'memberName'
                  ..textContent = 'peak memory'
                  ..title =
                      'highest value of the resident set size of the process running this VM',
                new HTMLDivElement()
                  ..className = 'memberValue'
                  ..textContent = Utils.formatSize(_vm.maxRSS)
              ]),
            new HTMLDivElement()
              ..className = 'memberItem'
              ..appendChildren(<HTMLElement>[
                new HTMLDivElement()
                  ..className = 'memberName'
                  ..appendChildren(<HTMLElement>[
                    new HTMLSpanElement()..textContent = 'view ',
                    new HTMLAnchorElement()
                      ..href = Uris.processSnapshot()
                      ..text = 'process memory'
                  ])
              ])
          ]),
        new HTMLBRElement(),
      ]);
  }

  HTMLElement describeVM() {
    final uptime = new DateTime.now().difference(_vm.startTime!);
    return new HTMLDivElement()
      ..className = 'content-centered-big'
      ..appendChildren(<HTMLElement>[
        new HTMLHeadingElement.h1()..textContent = 'VM',
        new HTMLDivElement()
          ..className = 'memberList'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberItem'
              ..appendChildren(<HTMLElement>[
                new HTMLDivElement()
                  ..className = 'memberName'
                  ..textContent = 'name',
                new HTMLDivElement()
                  ..className = 'memberValue'
                  ..textContent = _vm.displayName ?? ''
              ]),
            new HTMLDivElement()
              ..className = 'memberItem'
              ..appendChildren(<HTMLElement>[
                new HTMLDivElement()
                  ..className = 'memberName'
                  ..textContent = 'version',
                new HTMLDivElement()
                  ..className = 'memberValue'
                  ..textContent = _vm.version
              ]),
            new HTMLDivElement()
              ..className = 'memberItem'
              ..appendChildren(<HTMLElement>[
                new HTMLDivElement()
                  ..className = 'memberName'
                  ..textContent = 'features',
                new HTMLDivElement()
                  ..className = 'memberValue'
                  ..textContent = _vm.features
              ]),
            new HTMLDivElement()
              ..className = 'memberItem'
              ..appendChildren(<HTMLElement>[
                new HTMLDivElement()
                  ..className = 'memberName'
                  ..textContent = 'embedder',
                new HTMLDivElement()
                  ..className = 'memberValue'
                  ..textContent = _vm.embedder
              ]),
            new HTMLDivElement()
              ..className = 'memberItem'
              ..appendChildren(<HTMLElement>[
                new HTMLDivElement()
                  ..className = 'memberName'
                  ..textContent = 'current memory'
                  ..title = 'current amount of memory consumed by the Dart VM',
                new HTMLDivElement()
                  ..className = 'memberValue'
                  ..textContent = Utils.formatSize(_vm.currentMemory)
              ]),
            new HTMLDivElement()
              ..className = 'memberItem'
              ..appendChildren(<HTMLElement>[
                new HTMLDivElement()
                  ..className = 'memberName'
                  ..textContent = 'started at',
                new HTMLDivElement()
                  ..className = 'memberValue'
                  ..textContent = '${_vm.startTime}'
              ]),
            new HTMLDivElement()
              ..className = 'memberItem'
              ..appendChildren(<HTMLElement>[
                new HTMLDivElement()
                  ..className = 'memberName'
                  ..textContent = 'uptime',
                new HTMLDivElement()
                  ..className = 'memberValue'
                  ..textContent = '$uptime'
              ]),
            new HTMLDivElement()
              ..className = 'memberItem'
              ..appendChildren(<HTMLElement>[
                new HTMLDivElement()
                  ..className = 'memberName'
                  ..textContent = 'refreshed at',
                new HTMLDivElement()
                  ..className = 'memberValue'
                  ..textContent = '${new DateTime.now()}'
              ]),
            new HTMLBRElement(),
            new HTMLDivElement()
              ..className = 'memberItem'
              ..appendChildren(<HTMLElement>[
                new HTMLDivElement()
                  ..className = 'memberName'
                  ..appendChildren(<HTMLElement>[
                    new HTMLSpanElement()..textContent = 'see ',
                    new HTMLAnchorElement()
                      ..href = Uris.flags()
                      ..text = 'flags'
                  ]),
                new HTMLDivElement()
                  ..className = 'memberValue'
                  ..appendChildren(<HTMLElement>[
                    new HTMLSpanElement()..textContent = 'view ',
                    new HTMLAnchorElement()
                      ..href = Uris.timeline()
                      ..text = 'timeline'
                  ])
              ]),
          ]),
        new HTMLBRElement(),
      ]);
  }

  HTMLElement describeIsolateGroups() {
    final isolateGroups = _vm.isolateGroups.toList();
    return new HTMLDivElement()
      ..appendChildren(isolateGroups.map(describeIsolateGroup));
  }

  HTMLElement describeSystemIsolateGroups() {
    final isolateGroups = _vm.systemIsolateGroups.toList();
    return new HTMLDivElement()
      ..appendChildren(isolateGroups.map(describeIsolateGroup));
  }

  HTMLElement describeIsolateGroup(M.IsolateGroupRef group) {
    final isolateType =
        group.isSystemIsolateGroup! ? 'System Isolate' : 'Isolate';
    final isolates = (group as M.IsolateGroup).isolates;
    return new HTMLDivElement()
      ..className = 'content-centered-big'
      ..appendChildren(<HTMLElement>[
        new HTMLHRElement(),
        new HTMLHeadingElement.h1()
          ..textContent = "$isolateType Group ${group.number} (${group.name})",
        new HTMLLIElement()
          ..className = 'list-group-item'
          ..appendChildren(<HTMLElement>[
            new HTMLUListElement()
              ..className = 'list-group'
              ..appendChildren(isolates!.map(describeIsolate)),
          ]),
      ]);
  }

  HTMLElement describeIsolate(M.IsolateRef isolate) {
    return new HTMLLIElement()
      ..className = 'list-group-item'
      ..appendChildren(<HTMLElement>[
        new IsolateSummaryElement(isolate, _isolates, _events, _scripts,
                queue: _r.queue)
            .element
      ]);
  }
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm_view_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/isolate/summary.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/view_footer.dart';
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
    assert(vm != null);
    assert(vms != null);
    assert(events != null);
    assert(notifications != null);
    assert(isolates != null);
    assert(scripts != null);
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
    children = <Element>[];
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
    children = <Element>[
      navBar(<Element>[
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
      new ViewFooterElement(queue: _r.queue).element
    ];
  }

  Element describeProcess() {
    return new DivElement()
      ..classes = ['content-centered-big']
      ..children = <HtmlElement>[
        new HeadingElement.h1()..text = 'Process',
        new DivElement()
          ..classes = ['memberList']
          ..children = <Element>[
            new DivElement()
              ..classes = ['memberItem']
              ..children = <Element>[
                new DivElement()
                  ..classes = ['memberName']
                  ..text = 'pid',
                new DivElement()
                  ..classes = ['memberValue']
                  ..text = '${_vm.pid}'
              ],
            new DivElement()
              ..classes = ['memberItem']
              ..children = <Element>[
                new DivElement()
                  ..classes = ['memberName']
                  ..text = 'current memory'
                  ..title =
                      'current value of the resident set size of the process running this VM',
                new DivElement()
                  ..classes = ['memberValue']
                  ..text = _vm.currentRSS != null
                      ? Utils.formatSize(_vm.currentRSS)
                      : "unavailable"
              ],
            new DivElement()
              ..classes = ['memberItem']
              ..children = <Element>[
                new DivElement()
                  ..classes = ['memberName']
                  ..text = 'peak memory'
                  ..title =
                      'highest value of the resident set size of the process running this VM',
                new DivElement()
                  ..classes = ['memberValue']
                  ..text = _vm.maxRSS != null
                      ? Utils.formatSize(_vm.maxRSS)
                      : "unavailable"
              ],
            new DivElement()
              ..classes = ['memberItem']
              ..children = <Element>[
                new DivElement()
                  ..classes = ['memberName']
                  ..text = 'malloc memory',
                new DivElement()
                  ..classes = ['memberValue']
                  ..text = _vm.heapAllocatedMemoryUsage != null
                      ? Utils.formatSize(_vm.heapAllocatedMemoryUsage)
                      : 'unavailable'
                  ..title = _vm.heapAllocatedMemoryUsage != null
                      ? '${_vm.heapAllocatedMemoryUsage} bytes'
                      : null
              ],
            new DivElement()
              ..classes = ['memberItem']
              ..children = <Element>[
                new DivElement()
                  ..classes = ['memberName']
                  ..text = 'malloc allocation count',
                new DivElement()
                  ..classes = ['memberValue']
                  ..text = _vm.heapAllocationCount != null
                      ? '${_vm.heapAllocationCount}'
                      : 'unavailable'
              ],
            new DivElement()
              ..classes = ['memberItem']
              ..children = <Element>[
                new DivElement()
                  ..classes = ['memberName']
                  ..children = <Element>[
                    new SpanElement()..text = 'view ',
                    new AnchorElement(href: Uris.nativeMemory())
                      ..text = 'malloc profile'
                  ],
                new DivElement()
                  ..classes = ['memberName']
                  ..children = <Element>[
                    new SpanElement()..text = 'view ',
                    new AnchorElement(href: Uris.processSnapshot())
                      ..text = 'process memory'
                  ]
              ]
          ],
        new BRElement(),
      ];
  }

  Element describeVM() {
    final uptime = new DateTime.now().difference(_vm.startTime!);
    return new DivElement()
      ..classes = ['content-centered-big']
      ..children = <HtmlElement>[
        new HeadingElement.h1()..text = 'VM',
        new DivElement()
          ..classes = ['memberList']
          ..children = <Element>[
            new DivElement()
              ..classes = ['memberItem']
              ..children = <Element>[
                new DivElement()
                  ..classes = ['memberName']
                  ..text = 'name',
                new DivElement()
                  ..classes = ['memberValue']
                  ..text = _vm.displayName
              ],
            new DivElement()
              ..classes = ['memberItem']
              ..children = <Element>[
                new DivElement()
                  ..classes = ['memberName']
                  ..text = 'version',
                new DivElement()
                  ..classes = ['memberValue']
                  ..text = _vm.version
              ],
            new DivElement()
              ..classes = ['memberItem']
              ..children = <Element>[
                new DivElement()
                  ..classes = ['memberName']
                  ..text = 'embedder',
                new DivElement()
                  ..classes = ['memberValue']
                  ..text = _vm.embedder
              ],
            new DivElement()
              ..classes = ['memberItem']
              ..children = <Element>[
                new DivElement()
                  ..classes = ['memberName']
                  ..text = 'current memory'
                  ..title = 'current amount of memory consumed by the Dart VM',
                new DivElement()
                  ..classes = ['memberValue']
                  ..text = _vm.currentMemory != null
                      ? Utils.formatSize(_vm.currentMemory)
                      : "unavailable"
              ],
            new DivElement()
              ..classes = ['memberItem']
              ..children = <Element>[
                new DivElement()
                  ..classes = ['memberName']
                  ..text = 'started at',
                new DivElement()
                  ..classes = ['memberValue']
                  ..text = '${_vm.startTime}'
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
                  ..text = 'refreshed at',
                new DivElement()
                  ..classes = ['memberValue']
                  ..text = '${new DateTime.now()}'
              ],
            new BRElement(),
            new DivElement()
              ..classes = ['memberItem']
              ..children = <Element>[
                new DivElement()
                  ..classes = ['memberName']
                  ..children = <Element>[
                    new SpanElement()..text = 'see ',
                    new AnchorElement(href: Uris.flags())..text = 'flags'
                  ],
                new DivElement()
                  ..classes = ['memberValue']
                  ..children = <Element>[
                    new SpanElement()..text = 'view ',
                    new AnchorElement(href: Uris.timeline())..text = 'timeline'
                  ]
              ],
          ],
        new BRElement(),
      ];
  }

  Element describeIsolateGroups() {
    final isolateGroups = _vm.isolateGroups.toList();
    return new DivElement()
      ..children = isolateGroups.map(describeIsolateGroup).toList();
  }

  Element describeSystemIsolateGroups() {
    final isolateGroups = _vm.systemIsolateGroups.toList();
    return new DivElement()
      ..children = isolateGroups.map(describeIsolateGroup).toList();
  }

  Element describeIsolateGroup(M.IsolateGroupRef group) {
    final isolateType =
        group.isSystemIsolateGroup! ? 'System Isolate' : 'Isolate';
    final isolates = (group as M.IsolateGroup).isolates;
    return new DivElement()
      ..classes = ['content-centered-big']
      ..children = <Element>[
        new HRElement(),
        new HeadingElement.h1()
          ..text = "$isolateType Group ${group.number} (${group.name})",
        new LIElement()
          ..classes = ['list-group-item']
          ..children = <Element>[
            new UListElement()
              ..classes = ['list-group']
              ..children = isolates!.map(describeIsolate).toList(),
          ],
      ];
  }

  Element describeIsolate(M.IsolateRef isolate) {
    return new LIElement()
      ..classes = ['list-group-item']
      ..children = <Element>[
        new IsolateSummaryElement(isolate, _isolates, _events, _scripts,
                queue: _r.queue)
            .element
      ];
  }
}

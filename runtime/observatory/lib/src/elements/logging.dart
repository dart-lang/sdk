// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library logging_page;

import 'dart:async';
import 'dart:html';
import 'package:logging/logging.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/logging_list.dart';
import 'package:observatory/src/elements/nav/class_menu.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';
import 'package:observatory/src/elements/view_footer.dart';

class LoggingPageElement extends CustomElement implements Renderable {
  late RenderingScheduler<LoggingPageElement> _r;

  Stream<RenderedEvent<LoggingPageElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late Level _level = Level.ALL;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;

  factory LoggingPageElement(M.VM vm, M.IsolateRef isolate,
      M.EventRepository events, M.NotificationRepository notifications,
      {RenderingQueue? queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    LoggingPageElement e = new LoggingPageElement.created();
    e._r = new RenderingScheduler<LoggingPageElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    return e;
  }

  LoggingPageElement.created() : super.created('logging-page');

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

  LoggingListElement? _logs;

  void render() {
    _logs = _logs ?? new LoggingListElement(_isolate, _events);
    _logs!.level = _level;
    children = <Element>[
      navBar(<Element>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu('logging'),
        (new NavRefreshElement(label: 'clear', queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                _logs = null;
                _r.dirty();
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = <Element>[
          new HeadingElement.h2()..text = 'Logging',
          new SpanElement()..text = 'Show messages with severity ',
          _createLevelSelector(),
          new HRElement(),
          _logs!.element
        ]
    ];
  }

  Element _createLevelSelector() {
    var s = new SelectElement()
      ..value = _level.name
      ..children = Level.LEVELS.map((level) {
        return new OptionElement(value: level.name, selected: _level == level)
          ..text = level.name;
      }).toList(growable: false);
    s.onChange.listen((_) {
      _level = Level.LEVELS[s.selectedIndex!];
      _r.dirty();
    });
    return s;
  }
}

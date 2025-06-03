// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_reconnect_element;

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/nav_bar.dart';
import 'helpers/rendering_scheduler.dart';
import 'helpers/uris.dart';
import 'nav/notify.dart';
import 'nav/top_menu.dart';

class IsolateReconnectElement extends CustomElement implements Renderable {
  late RenderingScheduler<IsolateReconnectElement> _r;

  Stream<RenderedEvent<IsolateReconnectElement>> get onRendered =>
      _r.onRendered;

  late M.VM _vm;
  late String _missing;
  late Uri _uri;
  late M.EventRepository _events;
  late StreamSubscription _subscription;

  M.VM get vm => _vm;
  String get missing => _missing;
  Uri get uri => _uri;

  late M.NotificationRepository _notifications;
  factory IsolateReconnectElement(
    M.VM vm,
    M.EventRepository events,
    M.NotificationRepository notifications,
    String missing,
    Uri uri, {
    RenderingQueue? queue,
  }) {
    IsolateReconnectElement e = new IsolateReconnectElement.created();
    e._r = new RenderingScheduler<IsolateReconnectElement>(e, queue: queue);
    e._vm = vm;
    e._events = events;
    e._missing = missing;
    e._uri = uri;
    e._notifications = notifications;
    return e;
  }

  IsolateReconnectElement.created() : super.created('isolate-reconnect');

  @override
  void attached() {
    super.attached();
    _subscription = _events.onVMUpdate.listen((e) {
      _vm = e.vm as M.VM;
      _r.dirty();
    });
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    removeChildren();
    _r.disable(notify: true);
    _subscription.cancel();
  }

  void render() {
    children = <HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavNotifyElement(_notifications, queue: _r.queue).element,
      ]),
      new HTMLDivElement()
        ..className = 'content-centered'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h1()
            ..textContent = 'Isolate $_missing no longer exists',
          new HTMLHRElement(),
          new HTMLBRElement(),
          new HTMLDivElement()
            ..className = 'memberList'
            ..appendChildren(
              (_vm.isolates.map<HTMLElement>((isolate) {
                final query = new Map<String, dynamic>.from(
                  _uri.queryParameters,
                );
                query['isolateId'] = isolate.id;
                final href = new Uri(path: _uri.path, queryParameters: query);
                return new HTMLDivElement()
                  ..className = 'memberItem doubleSpaced'
                  ..appendChildren(<HTMLElement>[
                    new HTMLSpanElement()..textContent = 'Continue in ',
                    new HTMLAnchorElement()
                      ..href = '#$href'
                      ..className = 'isolate-link'
                      ..text = '${isolate.id} (${isolate.name})',
                  ]);
              }).toList()..add(
                new HTMLDivElement()
                  ..className = 'memberItem doubleSpaced'
                  ..appendChildren(<HTMLElement>[
                    new HTMLSpanElement()..textContent = 'Go to ',
                    new HTMLAnchorElement()
                      ..href = Uris.vm()
                      ..text = 'isolates summary',
                  ]),
              )),
            ),
        ]),
    ];
  }
}

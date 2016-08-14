// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_reconnect_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/bar.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/view_footer.dart';

class IsolateReconnectElement extends HtmlElement implements Renderable{
  static const tag = const Tag<IsolateReconnectElement>('isolate-reconnect',
                     dependencies: const [NavBarElement.tag,
                                          NavTopMenuElement.tag,
                                          NavNotifyElement.tag,
                                          ViewFooterElement.tag]);

  RenderingScheduler _r;

  Stream<RenderedEvent<IsolateReconnectElement>> get onRendered =>
      _r.onRendered;

  M.VM _vm;
  String _missing;
  Uri _uri;
  M.EventRepository _events;
  StreamSubscription _subscription;

  M.VM get vm  => _vm;
  String get missing => _missing;
  Uri get uri => _uri;

  M.NotificationRepository _notifications;
  factory IsolateReconnectElement(M.VM vm, M.EventRepository events,
      M.NotificationRepository notifications, String missing, Uri uri,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(events != null);
    assert(missing != null);
    assert(uri != null);
    assert(notifications != null);
    IsolateReconnectElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._events = events;
    e._missing = missing;
    e._uri = uri;
    e._notifications = notifications;
    return e;
  }

  IsolateReconnectElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _subscription = _events.onVMUpdate.listen((e) {
      _vm = e.vm;
      _r.dirty();
    });
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
    _subscription.cancel();
  }

  void render() {
    children = [
      new NavBarElement(queue: _r.queue)
        ..children = [
          new NavTopMenuElement(last: true, queue: _r.queue),
          new NavNotifyElement(_notifications, queue: _r.queue)
        ],
      new DivElement()
        ..classes = ['content-centered']
        ..children = [
          new HeadingElement.h1()..text = 'Isolate $_missing no longer exists',
          new BRElement(), new HRElement(),
          new DivElement()..classes = ['memberList']
            ..children = (_vm.isolates.map((isolate) {
              final query = new Map.from(_uri.queryParameters);
              query['isolateId'] = isolate.id;
              final href = new Uri(path: _uri.path, queryParameters: query);
              return new DivElement()..classes = ['memberItem', 'doubleSpaced']
                ..children = [
                  new SpanElement()..text = 'Continue in ',
                  new AnchorElement(href: '#$href')..classes = ['isolate-link']
                    ..text = '${isolate.id} (${isolate.name})'
                ];
            }).toList()..add(
              new DivElement()..classes = ['memberItem', 'doubleSpaced']
                ..children = [
                  new SpanElement()..text = 'Go to ',
                  new AnchorElement(href: Uris.vm())
                    ..text = 'isolates summary',
                ]
            ))
        ],
      new ViewFooterElement(queue: _r.queue)
    ];
  }
}

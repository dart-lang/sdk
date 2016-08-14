// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library general_error_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/nav/bar.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';

class GeneralErrorElement extends HtmlElement implements Renderable {
  static const tag = const Tag<GeneralErrorElement>('general-error',
                     dependencies: const [NavBarElement.tag,
                                          NavTopMenuElement.tag,
                                          NavNotifyElement.tag]);

  RenderingScheduler _r;

  Stream<RenderedEvent<GeneralErrorElement>> get onRendered => _r.onRendered;

  M.NotificationRepository _notifications;
  String _message;

  String get message => _message;

  set message(String value) => _message = _r.checkAndReact(_message, value);


  factory GeneralErrorElement(M.NotificationRepository notifications,
                           {String message: '', RenderingQueue queue}) {
    assert(notifications != null);
    assert(message != null);
    GeneralErrorElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._message = message;
    e._notifications = notifications;
    return e;
  }

  GeneralErrorElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
  }

  void render() {
    children = [
      new NavBarElement(queue: _r.queue)
        ..children = [
          new NavTopMenuElement(last: true, queue: _r.queue),
          new NavNotifyElement(_notifications, queue: _r.queue)
        ],
      new DivElement()..classes = ['content-centered']
        ..children = [
          new HeadingElement.h1()..text = 'Error',
          new BRElement(),
          new DivElement()..classes = ['well']
            ..text = message
        ]
    ];
  }
}

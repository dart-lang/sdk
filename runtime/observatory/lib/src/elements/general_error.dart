// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library general_error_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';

class GeneralErrorElement extends CustomElement implements Renderable {
  late RenderingScheduler<GeneralErrorElement> _r;

  Stream<RenderedEvent<GeneralErrorElement>> get onRendered => _r.onRendered;

  late M.NotificationRepository _notifications;
  late String _message;

  String get message => _message;

  set message(String value) => _message = _r.checkAndReact(_message, value);

  factory GeneralErrorElement(M.NotificationRepository notifications,
      {String message: '', RenderingQueue? queue}) {
    assert(notifications != null);
    assert(message != null);
    GeneralErrorElement e = new GeneralErrorElement.created();
    e._r = new RenderingScheduler<GeneralErrorElement>(e, queue: queue);
    e._message = message;
    e._notifications = notifications;
    return e;
  }

  GeneralErrorElement.created() : super.created('general-error');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = <Element>[];
    _r.disable(notify: true);
  }

  void render() {
    children = <Element>[
      navBar(<Element>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new DivElement()
        ..classes = ['content-centered']
        ..children = <Element>[
          new HeadingElement.h1()..text = 'Error',
          new BRElement(),
          new DivElement()
            ..classes = ['well']
            ..text = message
        ]
    ];
  }
}

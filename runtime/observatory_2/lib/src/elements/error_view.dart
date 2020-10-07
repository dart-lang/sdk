// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library error_view_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/src/elements/helpers/nav_bar.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/src/elements/nav/notify.dart';
import 'package:observatory_2/src/elements/nav/top_menu.dart';
import 'package:observatory_2/src/elements/view_footer.dart';

class ErrorViewElement extends CustomElement implements Renderable {
  RenderingScheduler<ErrorViewElement> _r;

  Stream<RenderedEvent<ErrorViewElement>> get onRendered => _r.onRendered;

  M.Error _error;
  M.NotificationRepository _notifications;

  M.Error get error => _error;

  factory ErrorViewElement(
      M.NotificationRepository notifications, M.Error error,
      {RenderingQueue queue}) {
    assert(error != null);
    assert(notifications != null);
    ErrorViewElement e = new ErrorViewElement.created();
    e._r = new RenderingScheduler<ErrorViewElement>(e, queue: queue);
    e._error = error;
    e._notifications = notifications;
    return e;
  }

  ErrorViewElement.created() : super.created('error-view');

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
          new HeadingElement.h1()
            ..text = 'Error: ${_kindToString(_error.kind)}',
          new BRElement(),
          new DivElement()
            ..classes = ['well']
            ..children = <Element>[new PreElement()..text = error.message]
        ],
      new ViewFooterElement(queue: _r.queue).element
    ];
  }

  static String _kindToString(M.ErrorKind kind) {
    switch (kind) {
      case M.ErrorKind.unhandledException:
        return 'Unhandled Exception';
      case M.ErrorKind.languageError:
        return 'Language Error';
      case M.ErrorKind.internalError:
        return 'Internal Error';
      case M.ErrorKind.terminationError:
        return 'Termination Error';
    }
    throw new Exception('Unknown M.ErrorKind ($kind)');
  }
}

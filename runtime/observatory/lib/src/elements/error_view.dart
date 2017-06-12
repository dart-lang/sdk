// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library error_view_element;

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/view_footer.dart';

class ErrorViewElement extends HtmlElement implements Renderable {
  static const tag = const Tag<ErrorViewElement>('error-view',
      dependencies: const [
        NavTopMenuElement.tag,
        NavNotifyElement.tag,
        ViewFooterElement.tag
      ]);

  RenderingScheduler _r;

  Stream<RenderedEvent<ErrorViewElement>> get onRendered => _r.onRendered;

  M.Error _error;
  M.NotificationRepository _notifications;

  M.Error get error => _error;

  factory ErrorViewElement(
      M.NotificationRepository notifications, M.Error error,
      {RenderingQueue queue}) {
    assert(error != null);
    assert(notifications != null);
    ErrorViewElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._error = error;
    e._notifications = notifications;
    return e;
  }

  ErrorViewElement.created() : super.created();

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
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
      new DivElement()
        ..classes = ['content-centered']
        ..children = [
          new HeadingElement.h1()
            ..text = 'Error: ${_kindToString(_error.kind)}',
          new BRElement(),
          new DivElement()
            ..classes = ['well']
            ..children = [new PreElement()..text = error.message]
        ],
      new ViewFooterElement(queue: _r.queue)
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

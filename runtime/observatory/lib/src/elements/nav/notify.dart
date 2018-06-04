// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/nav/notify_event.dart';
import 'package:observatory/src/elements/nav/notify_exception.dart';

class NavNotifyElement extends HtmlElement implements Renderable {
  static const tag = const Tag<NavNotifyElement>('nav-notify',
      dependencies: const [
        NavNotifyEventElement.tag,
        NavNotifyExceptionElement.tag
      ]);

  RenderingScheduler _r;

  Stream<RenderedEvent<NavNotifyElement>> get onRendered => _r.onRendered;

  M.NotificationRepository _repository;
  StreamSubscription _subscription;

  bool _notifyOnPause;

  bool get notifyOnPause => _notifyOnPause;

  set notifyOnPause(bool value) =>
      _notifyOnPause = _r.checkAndReact(_notifyOnPause, value);

  factory NavNotifyElement(M.NotificationRepository repository,
      {bool notifyOnPause: true, RenderingQueue queue}) {
    assert(repository != null);
    assert(notifyOnPause != null);
    NavNotifyElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._repository = repository;
    e._notifyOnPause = notifyOnPause;
    return e;
  }

  NavNotifyElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _subscription = _repository.onChange.listen((_) => _r.dirty());
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
      new DivElement()
        ..children = [
          new DivElement()
            ..children =
                _repository.list().where(_filter).map(_toElement).toList()
        ]
    ];
  }

  bool _filter(M.Notification notification) {
    if (!_notifyOnPause && notification is M.EventNotification) {
      return notification.event is! M.PauseEvent;
    }
    return true;
  }

  HtmlElement _toElement(M.Notification notification) {
    if (notification is M.EventNotification) {
      return new NavNotifyEventElement(notification.event, queue: _r.queue)
        ..onDelete.listen((_) => _repository.delete(notification));
    } else if (notification is M.ExceptionNotification) {
      return new NavNotifyExceptionElement(notification.exception,
          stacktrace: notification.stacktrace, queue: _r.queue)
        ..onDelete.listen((_) => _repository.delete(notification));
    } else {
      assert(false);
      return new DivElement()..text = 'Invalid Notification Type';
    }
  }
}

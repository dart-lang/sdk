// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of repositories;

class NotificationChangeEvent implements M.NotificationChangeEvent {
  final NotificationRepository repository;
  NotificationChangeEvent(this.repository);
}

class NotificationRepository implements M.NotificationRepository {
  final List<M.Notification> _list = <M.Notification>[];

  final StreamController<M.NotificationChangeEvent> _onChange =
      new StreamController<M.NotificationChangeEvent>.broadcast();
  Stream<M.NotificationChangeEvent> get onChange => _onChange.stream;

  void add(M.Notification notification) {
    assert(notification != null);
    _list.add(notification);
    _notify();
  }

  Iterable<M.Notification> list() => _list;

  void delete(M.Notification notification) {
    if (_list.remove(notification)) _notify();
  }

  void deleteAll() {
    if (_list.isNotEmpty) {
      _list.clear();
      _notify();
    }
  }

  NotificationRepository();

  void _notify() {
    _onChange.add(new NotificationChangeEvent(this));
  }

  void deleteWhere(bool test(M.Notification element)) {
    int length = _list.length;
    _list.removeWhere(test);
    if (_list.length != length) _notify();
  }

  void deletePauseEvents({M.Isolate isolate}) {
    if (isolate == null) {
      deleteWhere((notification) {
        return notification is M.EventNotification &&
            notification.event is M.PauseEvent;
      });
    } else {
      deleteWhere((notification) {
        if (notification is M.EventNotification) {
          var event = notification.event;
          if (event is M.PauseEvent) {
            return event.isolate == isolate;
          }
        }
        return false;
      });
    }
  }

  void deleteDisconnectEvents() {
    deleteWhere((notification) {
      return notification is M.EventNotification &&
          notification.event is M.ConnectionClosedEvent;
    });
  }
}

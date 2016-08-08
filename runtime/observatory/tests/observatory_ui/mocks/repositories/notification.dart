// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class NotificationChangeEventMock implements M.NotificationChangeEvent {
  final NotificationRepositoryMock repository;
  const NotificationChangeEventMock({this.repository});
}

typedef void NotificationRepositoryMockCallback(M.Notification notification);

class NotificationRepositoryMock implements M.NotificationRepository {
  final StreamController<M.NotificationChangeEvent> _onChange =
      new StreamController<M.NotificationChangeEvent>.broadcast();
  Stream<M.NotificationChangeEvent> get onChange => _onChange.stream;

  bool get hasListeners => _onChange.hasListener;

  final Iterable<M.Notification> _list;
  final NotificationRepositoryMockCallback _add;
  final NotificationRepositoryMockCallback _delete;

  bool addInvoked = false;
  bool listInvoked = false;
  bool deleteInvoked = false;
  bool deleteAllInvoked = false;


  void add(M.Notification notification) {
    addInvoked = true;
    if (_add != null) _add(notification);
  }

  Iterable<M.Notification> list() {
    listInvoked = true;
    return _list;
  }

  void delete(M.Notification notification) {
    deleteInvoked = true;
    if (_add != null) _delete(notification);
  }

  void deleteAll() { deleteAllInvoked = true; }

  void triggerChangeEvent() {
    _onChange.add(new NotificationChangeEventMock(repository: this));
  }

  NotificationRepositoryMock({Iterable<M.Notification> list : const [],
      NotificationRepositoryMockCallback add,
      NotificationRepositoryMockCallback delete})
    : _list = list,
      _add = add,
      _delete = delete;
}

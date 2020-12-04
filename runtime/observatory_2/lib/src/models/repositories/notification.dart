// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class NotificationChangeEvent {
  NotificationRepository get repository;
}

abstract class NotificationRepository {
  Stream<NotificationChangeEvent> get onChange;
  Iterable<Notification> list();
  void delete(Notification notification);
  void deleteAll();
}

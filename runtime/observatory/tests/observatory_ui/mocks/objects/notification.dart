// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class ExceptionNotificationMock implements M.ExceptionNotification {
  final Exception exception;
  final StackTrace stacktrace;
  const ExceptionNotificationMock({this.exception, this.stacktrace});
}

class EventNotificationMock implements M.EventNotification {
  final M.Event event;
  const EventNotificationMock({this.event});
}

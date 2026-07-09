// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

class ExceptionNotification implements M.ExceptionNotification {
  final exception;

  /// [optional]
  final StackTrace? stacktrace;
  ExceptionNotification(this.exception, {this.stacktrace});
}

class EventNotification implements M.EventNotification {
  final M.Event event;
  EventNotification(this.event);
}

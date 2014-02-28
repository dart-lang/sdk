// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mocks;

import 'dart:io';
import 'dart:async';

/**
 * A mock [WebSocket] that immediately passes data to the listener.
 */
class MockSocket<T> implements WebSocket {
  var onData;
  StreamSubscription<T> listen(void onData(T event),
                     {Function onError, void onDone(), bool cancelOnError}) {
    this.onData = onData;
    return null;
  }
  void add(T event) => onData(event);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * A mock [WebSocket] for sending invalid JSON data and counting responses.
 */
class InvalidJsonMockSocket<T> implements WebSocket {
  int responseCount = 0;
  var onData;
  StreamSubscription<T> listen(void onData(T event),
                     {Function onError, void onDone(), bool cancelOnError}) {
    this.onData = onData;
    return null;
  }
  void addInvalid(T event) => onData(event);
  void add(T event) { responseCount++; }
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

abstract class Sink<T> {
  void close();
}

abstract class EventSink<T> implements Sink<T> {
  void close();
}

abstract class StreamConsumer<S> {
  Future close();
}

abstract class StreamSink<S> implements EventSink<S>, StreamConsumer<S> {
  Future close();
}

main() {}

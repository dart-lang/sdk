// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart=2.6

/*class: Sink:Object,Sink<T*>*/
abstract class Sink<T> {
  /*member: Sink.close:void Function()**/
  void close();
}

/*class: EventSink:EventSink<T*>,Object,Sink<T*>*/
abstract class EventSink<T> implements Sink<T> {
  /*member: EventSink.close:void Function()**/
  void close();
}

/*class: StreamConsumer:Object,StreamConsumer<S*>*/
abstract class StreamConsumer<S> {
  /*member: StreamConsumer.close:Future<dynamic>* Function()**/
  Future close();
}

/*class: StreamSink:EventSink<S*>,Object,Sink<S*>,StreamConsumer<S*>,StreamSink<S*>*/
abstract class StreamSink<S> implements EventSink<S>, StreamConsumer<S> {
  /*member: StreamSink.close:Future<dynamic>* Function()**/
  Future close();
}

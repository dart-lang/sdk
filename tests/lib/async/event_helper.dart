// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library event_helper;

import 'dart:async';

abstract class Event {
  void replay(EventSink sink);
}

class DataEvent implements Event {
  final data;

  DataEvent(this.data);

  void replay(EventSink sink) { sink.add(data); }

  int get hashCode => data.hashCode;

  bool operator==(Object other) {
    if (other is! DataEvent) return false;
    DataEvent otherEvent = other;
    return data == other.data;
  }

  String toString() => "DataEvent: $data";
}

class ErrorEvent implements Event {
  final error;

  ErrorEvent(this.error);

  void replay(EventSink sink) { sink.addError(error); }

  int get hashCode => error.error.hashCode;

  bool operator==(Object other) {
    if (other is! ErrorEvent) return false;
    ErrorEvent otherEvent = other;
    return error == other.error;
  }

  String toString() => "ErrorEvent: ${error}";
}

class DoneEvent implements Event {
  const DoneEvent();

  void replay(EventSink sink) { sink.close(); }

  int get hashCode => 42;

  bool operator==(Object other) => other is DoneEvent;

  String toString() => "DoneEvent";
}

/** Collector of events. */
class Events implements EventSink {
  final List<Event> events = [];

  Events();
  Events.fromIterable(Iterable iterable) {
    for (var value in iterable) add(value);
    close();
  }

  /** Capture events from a stream into a new [Events] object. */
  factory Events.capture(Stream stream,
                         { bool cancelOnError: false }) = CaptureEvents;

  // EventSink interface.
  void add(var value) {
    events.add(new DataEvent(value));
  }

  void addError(error) {
    events.add(new ErrorEvent(error));
  }

  void close() {
    events.add(const DoneEvent());
  }

  // Error helper for creating errors manually..
  void error(var value) { addError(value); }

  /** Replay the captured events on a sink. */
  void replay(EventSink sink) {
    for (int i = 0; i < events.length; i++) {
      events[i].replay(sink);
    }
  }

  /**
   * Create a new [Events] with the same captured events.
   *
   * This does not copy a subscription.
   */
  Events copy() {
    Events result = new Events();
    replay(result);
    return result;
  }

  // Operations that only work when there is a subscription feeding the Events.

  /**
   * Pauses the subscription that feeds this [Events].
   *
   * Should only be used when there is a subscription. That is, after a
   * call to [subscribeTo].
   */
  void pause([Future resumeSignal]) {
    throw new StateError("Not capturing events.");
  }

  /** Resumes after a call to [pause]. */
  void resume() {
    throw new StateError("Not capturing events.");
  }

  /**
   * Sets an action to be called when this [Events] receives a 'done' event.
   */
  void onDone(void action()) {
     throw new StateError("Not capturing events.");
  }
}

class CaptureEvents extends Events {
  StreamSubscription subscription;
  Completer onDoneSignal;
  bool cancelOnError = false;

  CaptureEvents(Stream stream,
                { bool cancelOnError: false })
      : onDoneSignal = new Completer() {
    this.cancelOnError = cancelOnError;
    subscription = stream.listen(add,
                                 onError: addError,
                                 onDone: close,
                                 cancelOnError: cancelOnError);
  }

  void addError(error) {
    super.addError(error);
    if (cancelOnError) onDoneSignal.complete(null);
  }

  void close() {
    super.close();
    if (onDoneSignal != null) onDoneSignal.complete(null);
  }

  void pause([Future resumeSignal]) {
    subscription.pause(resumeSignal);
  }

  void resume() {
    subscription.resume();
  }

  void onDone(void action()) {
    onDoneSignal.future.whenComplete(action);
  }
}

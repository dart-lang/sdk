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

  void replay(EventSink sink) {
    sink.add(data);
  }

  int get hashCode => data.hashCode;

  bool operator ==(Object other) {
    if (other is! DataEvent) return false;
    DataEvent otherEvent = other;
    return data == otherEvent.data;
  }

  String toString() => "DataEvent: $data";
}

class ErrorEvent implements Event {
  final error;

  ErrorEvent(this.error);

  void replay(EventSink sink) {
    sink.addError(error);
  }

  int get hashCode => error.error.hashCode;

  bool operator ==(Object other) {
    if (other is! ErrorEvent) return false;
    ErrorEvent otherEvent = other;
    return error == otherEvent.error;
  }

  String toString() => "ErrorEvent: ${error}";
}

class DoneEvent implements Event {
  const DoneEvent();

  void replay(EventSink sink) {
    sink.close();
  }

  int get hashCode => 42;

  bool operator ==(Object other) => other is DoneEvent;

  String toString() => "DoneEvent";
}

/** Collector of events. */
class Events implements EventSink {
  final List<Event> events = [];
  bool trace = false;
  Completer onDoneSignal = new Completer();

  Events();

  Events.fromIterable(Iterable iterable) {
    for (var value in iterable) add(value);
    close();
  }

  /** Capture events from a stream into a new [Events] object. */
  factory Events.capture(Stream stream, {bool cancelOnError}) = CaptureEvents;

  // EventSink interface.
  void add(var value) {
    if (trace) print("Events#$hashCode: add($value)");
    events.add(new DataEvent(value));
  }

  void addError(error, [StackTrace stackTrace]) {
    if (trace) print("Events#$hashCode: addError($error)");
    events.add(new ErrorEvent(error));
  }

  void close() {
    if (trace) print("Events#$hashCode: close()");
    events.add(const DoneEvent());
    onDoneSignal.complete();
  }

  /**
   * Error shorthand, for writing events manually.
   */
  void error(var value, [StackTrace stackTrace]) {
    addError(value, stackTrace);
  }

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
   *
   * The action will also be called if capturing events from a stream with
   * `cancelOnError` set to true and receiving an error.
   */
  void onDone(void action()) {
    onDoneSignal.future.whenComplete(action);
  }
}

class CaptureEvents extends Events {
  StreamSubscription subscription;
  bool cancelOnError = false;

  CaptureEvents(Stream stream, {bool cancelOnError: false}) {
    this.cancelOnError = cancelOnError;
    subscription = stream.listen(add,
        onError: addError, onDone: close, cancelOnError: cancelOnError);
  }

  void addError(error, [stackTrace]) {
    super.addError(error, stackTrace);
    if (cancelOnError) {
      onDoneSignal.complete();
    }
  }

  void pause([Future resumeSignal]) {
    if (trace) print("Events#$hashCode: pause");
    subscription.pause(resumeSignal);
  }

  void resume() {
    if (trace) print("Events#$hashCode: resume");
    subscription.resume();
  }

  void onDone(void action()) {
    if (trace) print("Events#$hashCode: onDone");
    super.onDone(action);
  }
}

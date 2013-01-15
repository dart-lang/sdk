// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library event_helper;

import 'dart:async';

class Event {
  void replay(StreamSink sink);
}

class DataEvent implements Event {
  final data;

  DataEvent(this.data);

  void replay(StreamSink sink) { sink.add(data); }

  int get hashCode => data.hashCode;

  bool operator==(Object other) {
    if (other is! DataEvent) return false;
    DataEvent otherEvent = other;
    return data == other.data;
  }

  String toString() => "DataEvent: $data";
}

class ErrorEvent implements Event {
  final AsyncError error;

  ErrorEvent(this.error);

  void replay(StreamSink sink) { sink.signalError(error); }

  int get hashCode => error.error.hashCode;

  bool operator==(Object other) {
    if (other is! ErrorEvent) return false;
    ErrorEvent otherEvent = other;
    return error.error == other.error.error;
  }

  String toString() => "ErrorEvent: ${error.error}";
}

class DoneEvent implements Event {
  const DoneEvent();

  void replay(StreamSink sink) { sink.close(); }

  int get hashCode => 42;

  bool operator==(Object other) => other is DoneEvent;

  String toString() => "DoneEvent";
}

/** Collector of events. */
class Events implements StreamSink {
  final List<Event> events = [];

  Events();
  Events.fromIterable(Iterable iterable) {
    for (var value in iterable) add(value);
    close();
  }

  /** Capture events from a stream into a new [Events] object. */
  factory Events.capture(Stream stream,
                         { bool unsubscribeOnError: false }) = CaptureEvents;

  // Sink interface.
  add(var value) { events.add(new DataEvent(value)); }

  void signalError(AsyncError error) {
    events.add(new ErrorEvent(error));
  }

  void close() {
    events.add(const DoneEvent());
  }

  // Error helper for creating errors manually..
  void error(var value) { signalError(new AsyncError(value, null)); }

  /** Replay the captured events on a sink. */
  void replay(StreamSink sink) {
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

  /** Whether the underlying subscription has been paused. */
  bool get isPaused => false;

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
  bool unsubscribeOnError = false;

  CaptureEvents(Stream stream,
                { bool unsubscribeOnError: false })
      : onDoneSignal = new Completer() {
    this.unsubscribeOnError = unsubscribeOnError;
    subscription = stream.listen(add,
                                 onError: signalError,
                                 onDone: close,
                                 unsubscribeOnError: unsubscribeOnError);
  }

  void signalError(AsyncError error) {
    super.signalError(error);
    if (unsubscribeOnError) onDoneSignal.complete(null);
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

  bool get isPaused => subscription.isPaused;

  void onDone(void action()) {
    onDoneSignal.future.whenComplete(action);
  }
}

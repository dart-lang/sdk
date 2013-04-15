// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stream_state_helper;

import "../../../pkg/unittest/lib/unittest.dart";
import "dart:async";
import "dart:collection";

class StreamProtocolTest {
  StreamController _controller;
  Stream _controllerStream;
  StreamSubscription _subscription;
  List<Event> _expectations = new List<Event>();
  int _nextExpectationIndex = 0;
  Function _onComplete;

  StreamProtocolTest([bool broadcast = false]) {
    _controller = new StreamController(
          onListen: _onSubcription,
          onPause: _onPause,
          onResume: _onPause,
          onCancel: _onSubcription);
    // TODO(lrn): Make it work with multiple subscribers too.
    if (broadcast) {
      _controllerStream = _controller.stream.asBroadcastStream();
    } else {
      _controllerStream = _controller.stream;
    }
    _onComplete = expectAsync0((){
      _onComplete = null;  // Being null marks the test to be complete.
    });
  }

  // Actions on the stream and controller.
  void add(var data) { _controller.add(data); }
  void error(var error) { _controller.addError(error); }
  void close() { _controller.close(); }

  void subscribe({bool cancelOnError : false}) {
    // TODO(lrn): Handle more subscriptions (e.g., a subscription-id
    // per subscription, and an id on event _expectations).
    if (_subscription != null) throw new StateError("Already subscribed");
    _subscription = _controllerStream.listen(_onData,
                                             onError: _onError,
                                             onDone: _onDone,
                                             cancelOnError:
                                                 cancelOnError);
  }

  void pause([Future resumeSignal]) {
    if (_subscription == null) throw new StateError("Not subscribed");
    _subscription.pause(resumeSignal);
  }

  void resume([Future resumeSignal]) {
    if (_subscription == null) throw new StateError("Not subscribed");
    _subscription.resume();
  }

  void cancel() {
    if (_subscription == null) throw new StateError("Not subscribed");
    _subscription.cancel();
    _subscription = null;
  }

  // Handling of stream events.
  void _onData(var data) {
    _withNextExpectation((Event expect) {
      if (!expect.matchData(data)) {
        _fail("Expected: $expect\n"
              "Found   : [Data: $data]");
      }
    });
  }

  void _onError(error) {
    _withNextExpectation((Event expect) {
      if (!expect.matchError(error)) {
        _fail("Expected: $expect\n"
              "Found   : [Data: ${error}]");
      }
    });
  }

  void _onDone() {
    _subscription = null;
    _withNextExpectation((Event expect) {
      if (!expect.matchDone()) {
        _fail("Expected: $expect\n"
              "Found   : [Done]");
      }
    });
  }

  void _onPause() {
    _withNextExpectation((Event expect) {
      if (!expect.matchPauseChange(_controller)) {
        _fail("Expected: $expect\n"
              "Found   : [Paused:${_controller.isPaused}]");
      }
    });
  }

  void _onSubcription() {
    _withNextExpectation((Event expect) {
      if (!expect.matchSubscriptionChange(_controller)) {
        _fail("Expected: $expect\n"
              "Found: [Has listener:${_controller.hasListener}, "
                      "Paused:${_controller.isPaused}]");
      }
    });
  }

  void _withNextExpectation(void action(Event expect)) {
    if (_nextExpectationIndex == _expectations.length) {
      action(new MismatchEvent());
    } else {
      Event next = _expectations[_nextExpectationIndex++];
      action(next);
    }
    _checkDone();
  }

  void _checkDone() {
    if (_nextExpectationIndex == _expectations.length) {
      _onComplete();
    }
  }


  // Adds _expectations.
  void expectAny([void action()]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(new LogAnyEvent(action));
  }
  void expectData(var data, [void action()]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(new DataEvent(data, action));
  }
  void expectError(var error, [void action()]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(new ErrorEvent(error, action));
  }
  void expectDone([void action()]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(new DoneEvent(action));
  }
  void expectPause(bool isPaused, [void action()]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(new PauseCallbackEvent(isPaused, action));
  }
  void expectSubscription(bool hasListener, bool isPaused, [void action()]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(
          new SubscriptionCallbackEvent(hasListener, isPaused, action));
  }

  void _fail(String message) {
    if (_nextExpectationIndex == 0) {
      throw "Unexpected event:\n$message\nNo earlier events matched.";
    }
    throw "Unexpected event:\n$message\nMatched so far:\n"
          " ${_expectations.take(_nextExpectationIndex).join("\n ")}";
  }
}

class EventCollector {
  final Queue<Event> events = new Queue<Event>();

}

class Event {
  Function _action;
  Event(void this._action());

  bool matchData(var data) {
    if (!_testData(data)) return false;
    if (_action != null) _action();
    return true;
  }
  bool matchError(e) {
    if (!_testError(e)) return false;
    if (_action != null) _action();
    return true;
  }
  bool matchDone() {
    if (!_testDone()) return false;
    if (_action != null) _action();
    return true;
  }
  bool matchPauseChange(StreamController c) {
    if (!_testPause(c)) return false;
    if (_action != null) _action();
    return true;
  }
  bool matchSubscriptionChange(StreamController c) {
    if (!_testSubscribe(c)) return false;
    if (_action != null) _action();
    return true;
  }

  bool _testData(_) => false;
  bool _testError(_) => false;
  bool _testDone() => false;
  bool _testPause(_) => false;
  bool _testSubscribe(_) => false;
}

class MismatchEvent extends Event {
  MismatchEvent() : super(null);
  toString() => "[No event expected]";
}

class DataEvent extends Event {
  final data;
  DataEvent(this.data, void action()) : super(action);
  bool _testData(var data) => this.data == data;
  String toString() => "[Data: $data]";
}

class ErrorEvent extends Event {
  final error;
  ErrorEvent(this.error, void action()) : super(action);
  bool _testError(error) => this.error == error;
  String toString() => "[Error: $error]";
}

class DoneEvent extends Event {
  DoneEvent(void action()) : super(action);
  bool _testDone() => true;
  String toString() => "[Done]";
}

class PauseCallbackEvent extends Event {
  final bool isPaused;
  PauseCallbackEvent(this.isPaused, void action())
      : super(action);
  bool _testPause(StreamController c) => isPaused == c.isPaused;
  String toString() => "[Paused:$isPaused]";
}

class SubscriptionCallbackEvent extends Event {
  final bool hasListener;
  final bool isPaused;
  SubscriptionCallbackEvent(this.hasListener, this.isPaused, void action())
      : super(action);
  bool _testSubscribe(StreamController c) {
    return hasListener == c.hasListener && isPaused == c.isPaused;
  }
  String toString() => "[Has listener:$hasListener, Paused:$isPaused]";
}


class LogAnyEvent extends Event {
  String _actual = "*Not matched yet*";
  LogAnyEvent(void action()) : super(action);
  bool _testData(var data) {
    _actual = "*[Data $data]";
    return true;
  }
  bool _testError(error) {
    _actual = "*[Error ${error}]";
    return true;
  }
  bool _testDone() {
    _actual = "*[Done]";
    return true;
  }
  bool _testPause(StreamController c) {
    _actual = "*[Paused:${c.isPaused}]";
    return true;
  }
  bool _testSubcribe(StreamController c) {
    _actual = "*[Has listener:${c.hasListener}, Paused:${c.isPaused}]";
    return true;
  }

  String toString() => _actual;
}

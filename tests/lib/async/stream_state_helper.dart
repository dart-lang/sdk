// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stream_state_helper;

import "../../../pkg/unittest/lib/unittest.dart";
import "dart:async";
import "dart:collection";

class StreamProtocolTest {
  bool trace = false;
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
          onResume: _onResume,
          onCancel: _onCancel);
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

  void resume() {
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
    if (trace) print("[Data : $data]");
    _withNextExpectation((Event expect) {
      if (!expect.matchData(data)) {
        _fail("Expected: $expect\n"
              "Found   : [Data: $data]");
      }
    });
  }

  void _onError(error) {
    if (trace) print("[Error : $error]");
    _withNextExpectation((Event expect) {
      if (!expect.matchError(error)) {
        _fail("Expected: $expect\n"
              "Found   : [Error: ${error}]");
      }
    });
  }

  void _onDone() {
    if (trace) print("[Done]");
    _subscription = null;
    _withNextExpectation((Event expect) {
      if (!expect.matchDone()) {
        _fail("Expected: $expect\n"
              "Found   : [Done]");
      }
    });
  }

  void _onPause() {
    if (trace) print("[Pause]");
    _withNextExpectation((Event expect) {
      if (!expect.matchPause()) {
        _fail("Expected: $expect\n"
              "Found   : [Paused]");
      }
    });
  }

  void _onResume() {
    if (trace) print("[Resumed]");
    _withNextExpectation((Event expect) {
      if (!expect.matchResume()) {
        _fail("Expected: $expect\n"
              "Found   : [Resumed]");
      }
    });
  }

  void _onSubcription() {
    if (trace) print("[Subscribed]");
    _withNextExpectation((Event expect) {
      if (!expect.matchSubscribe()) {
        _fail("Expected: $expect\n"
              "Found: [Subscribed]");
      }
    });
  }

  void _onCancel() {
    if (trace) print("[Cancelled]");
    _withNextExpectation((Event expect) {
      if (!expect.matchCancel()) {
        _fail("Expected: $expect\n"
              "Found: [Cancelled]");
      }
    });
  }

  void _withNextExpectation(void action(Event expect)) {
    if (_nextExpectationIndex == _expectations.length) {
      action(new MismatchEvent());
    } else {
      Event next = _expectations[_nextExpectationIndex];
      action(next);
    }
    _nextExpectationIndex++;
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
  void expectPause([void action()]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(new PauseCallbackEvent(action));
  }
  void expectResume([void action()]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(new ResumeCallbackEvent(action));
  }
  void expectSubscription([void action()]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(
          new SubscriptionCallbackEvent(action));
  }
  void expectCancel([void action()]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(
          new CancelCallbackEvent(action));
  }

  void _fail(String message) {
    if (_nextExpectationIndex == 0) {
      throw "Unexpected event:\n$message\nNo earlier events matched.";
    }
    throw "Unexpected event:\n$message\nMatched so far:\n"
          " ${_expectations.take(_nextExpectationIndex).join("\n ")}";
  }
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
  bool matchPause() {
    if (!_testPause()) return false;
    if (_action != null) _action();
    return true;
  }
  bool matchResume() {
    if (!_testResume()) return false;
    if (_action != null) _action();
    return true;
  }
  bool matchSubscribe() {
    if (!_testSubscribe()) return false;
    if (_action != null) _action();
    return true;
  }
  bool matchCancel() {
    if (!_testCancel()) return false;
    if (_action != null) _action();
    return true;
  }

  bool _testData(_) => false;
  bool _testError(_) => false;
  bool _testDone() => false;
  bool _testPause() => false;
  bool _testResume() => false;
  bool _testSubscribe() => false;
  bool _testCancel() => false;
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
  PauseCallbackEvent(void action()) : super(action);
  bool _testPause() => true;
  String toString() => "[Paused]";
}

class ResumeCallbackEvent extends Event {
  ResumeCallbackEvent(void action()) : super(action);
  bool _testResume() => true;
  String toString() => "[Resumed]";
}

class SubscriptionCallbackEvent extends Event {
  SubscriptionCallbackEvent(void action()) : super(action);
  bool _testSubscribe() => true;
  String toString() => "[Subscribed]";
}

class CancelCallbackEvent extends Event {
  CancelCallbackEvent(void action()) : super(action);
  bool _testCancel() => true;
  String toString() => "[Cancelled]";
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
  bool _testPause() {
    _actual = "*[Paused]";
    return true;
  }
  bool _testResume() {
    _actual = "*[Resumed]";
    return true;
  }
  bool _testSubcribe() {
    _actual = "*[Subscribed]";
    return true;
  }
  bool _testCancel() {
    _actual = "*[Cancelled]";
    return true;
  }

  String toString() => _actual;
}

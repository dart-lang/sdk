// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the event/callback protocol of the stream implementations.

import "../../../pkg/unittest/lib/unittest.dart";
import "dart:collection";
import "dart:async";

const ms5 = const Duration(milliseconds: 5);

main() {
  mainTest(false);
  mainTest(true);
}

mainTest(bool broadcast) {
  var p = broadcast ? "BC" : "SC";
  test("$p-sub-data-done", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42)
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()..add(42)..close();
  });

  test("$p-data-done-sub", () {
    var t = new StreamProtocolTest(broadcast);
    if (broadcast) {
      t..expectDone();
    } else {
      t..expectSubscription(true, false)
       ..expectData(42)
       ..expectDone()
       ..expectSubscription(false, false);
    }
    t..add(42)..close()..subscribe();
  });

  test("$p-sub-data/pause-done", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
         t.pause(new Future.delayed(ms5, () => null));
       })
     ..expectPause(true)
     ..expectDone()
     ..expectSubscription(false, false);
     // We are calling "close" while the controller is actually paused,
     // and it will stay paused until the pending events are sent.
    t..subscribe()..add(42)..close();
  });

  test("$p-sub-data/pause-resume/done", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
         t.pause(new Future.delayed(ms5, () => null));
       })
     ..expectPause(true)
     ..expectPause(false, () { t.close(); })
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()..add(42);
  });

  test("$p-sub-data/pause/resume/pause/resume-done", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
         t.pause();
       })
     ..expectPause(true, () { t.resume(); })
     ..expectPause(false, () { t.pause(); })
     ..expectPause(true, () { t.resume(); })
     ..expectPause(false, () { t.close(); })
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()..add(42);
  });

  test("$p-sub-data/pause+resume-done", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
         t.pause();
         t.resume();
         t.close();
       })
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()..add(42);
  });

  test("$p-sub-data/data+pause-data-resume-done", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
         t.add(43);
         t.pause(new Future.delayed(ms5, () => null));
         // Should now be paused until the future finishes.
         // After that, the controller stays paused until the pending queue
         // is empty.
       })
     ..expectPause(true)
     ..expectData(43)
     ..expectPause(false, () { t.close(); })
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()..add(42);
  });

  test("$p-sub-data-unsubonerror", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42)
     ..expectError("bad")
     ..expectSubscription(false, !broadcast);
    t..subscribe(unsubscribeOnError: true)
     ..add(42)
     ..error("bad")
     ..add(43)
     ..close();
  });

  test("$p-sub-data-no-unsubonerror", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42)
     ..expectError("bad")
     ..expectData(43)
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe(unsubscribeOnError: false)
     ..add(42)
     ..error("bad")
     ..add(43)
     ..close();
  });

 test("$p-pause-during-callback", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
       t.pause();
     })
     ..expectPause(true, () {
       t.resume();
     })
     ..expectPause(false, () {
       t.pause();
       t.resume();
       t.close();
     })
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()
     ..add(42);
  });

  test("$p-pause-resume-during-event", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
       t.pause();
       t.resume();
     })
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()
     ..add(42)
     ..close();
  });

  test("$p-cancel-sub-during-event", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
       t.cancel();
       t.subscribe();
     })
     ..expectData(43)
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()
     ..add(42)
     ..add(43)
     ..close();
  });

  test("$p-cancel-sub-during-callback", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
       t.pause();
     })
     ..expectPause(true, () {
       t.cancel();  // Cancels pause
       t.subscribe();
     })
     ..expectPause(false)
     ..expectData(43)
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()
     ..add(42)
     ..add(43)
     ..close();
  });

  test("$p-sub-after-done-is-done", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectDone()
     ..expectSubscription(false, false)
     ..expectDone();
    t..subscribe()
     ..close()
     ..subscribe();  // Subscribe after done does not cause callbacks at all.
  });
}

// --------------------------------------------------------------------
// Utility classes.

class StreamProtocolTest {
  StreamController _controller;
  StreamSubscription _subscription;
  List<Event> _expectations = new List<Event>();
  int _nextExpectationIndex = 0;
  Function _onComplete;

  StreamProtocolTest([bool broadcast = false]) {
    if (broadcast) {
     _controller = new StreamController.broadcast(
          onPauseStateChange: _onPause,
          onSubscriptionStateChange: _onSubcription);
     // TODO(lrn): Make it work with multiple subscribers too.
    } else {
     _controller = new StreamController(
          onPauseStateChange: _onPause,
          onSubscriptionStateChange: _onSubcription);
    }
    _onComplete = expectAsync0((){
      _onComplete = null;  // Being null marks the test to be complete.
    });
  }

  // Actions on the stream and controller.
  void add(var data) { _controller.add(data); }
  void error(var error) { _controller.signalError(error); }
  void close() { _controller.close(); }

  void subscribe({bool unsubscribeOnError : false}) {
    // TODO(lrn): Handle more subscriptions (e.g., a subscription-id
    // per subscription, and an id on event _expectations).
    if (_subscription != null) throw new StateError("Already subscribed");
    _subscription = _controller.stream.listen(_onData,
                                              onError: _onError,
                                              onDone: _onDone,
                                              unsubscribeOnError:
                                                  unsubscribeOnError);
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

  void _onError(AsyncError error) {
    _withNextExpectation((Event expect) {
      if (!expect.matchError(error)) {
        _fail("Expected: $expect\n"
              "Found   : [Data: ${error.error}]");
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
              "Found: [Subscribed:${_controller.hasSubscribers}, "
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
  void expectSubscription(bool hasSubscribers, bool isPaused, [void action()]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(
          new SubscriptionCallbackEvent(hasSubscribers, isPaused, action));
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
  bool matchError(AsyncError e) {
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
  bool _testError(AsyncError error) => this.error == error.error;
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
  final bool hasSubscribers;
  final bool isPaused;
  SubscriptionCallbackEvent(this.hasSubscribers, this.isPaused, void action())
      : super(action);
  bool _testSubscribe(StreamController c) {
    return hasSubscribers == c.hasSubscribers && isPaused == c.isPaused;
  }
  String toString() => "[Subscribers:$hasSubscribers, Paused:$isPaused]";
}


class LogAnyEvent extends Event {
  String _actual = "*Not matched yet*";
  LogAnyEvent(void action()) : super(action);
  bool _testData(var data) {
    _actual = "*[Data $data]";
    return true;
  }
  bool _testError(AsyncError error) {
    _actual = "*[Error ${error.error}]";
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
    _actual = "*[Subscribers:${c.hasSubscribers}, Paused:${c.isPaused}]";
    return true;
  }

  String toString() => _actual;
}

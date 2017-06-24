// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stream_state_helper;

import "package:unittest/unittest.dart";
import "dart:async";
import "dart:collection";

class SubscriptionProtocolTest {
  final StreamProtocolTest _streamTest;
  final int id;
  StreamSubscription _subscription;

  SubscriptionProtocolTest(this.id, this._subscription, this._streamTest);

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

  void expectData(var data, [void action()]) {
    _streamTest._expectData(this, data, action);
  }

  void expectError(var error, [void action()]) {
    _streamTest._expectError(this, error, action);
  }

  void expectDone([void action()]) {
    _streamTest._expectDone(this, action);
  }
}

class StreamProtocolTest {
  bool trace = false;
  final bool isBroadcast;
  final bool isAsBroadcast;
  StreamController _controller;
  Stream _controllerStream;
  // Most recent subscription created. Used as default for pause/resume.
  SubscriptionProtocolTest _latestSubscription;
  List<Event> _expectations = new List<Event>();
  int _nextExpectationIndex = 0;
  int _subscriptionIdCounter = 0;
  Function _onComplete;

  StreamProtocolTest.broadcast({bool sync: false})
      : isBroadcast = true,
        isAsBroadcast = false {
    _controller = new StreamController.broadcast(
        sync: sync, onListen: _onListen, onCancel: _onCancel);
    _controllerStream = _controller.stream;
    _onComplete = expectAsync(() {
      _onComplete = null; // Being null marks the test as being complete.
    });
  }

  StreamProtocolTest({bool sync: false})
      : isBroadcast = false,
        isAsBroadcast = false {
    _controller = new StreamController(
        sync: sync,
        onListen: _onListen,
        onPause: _onPause,
        onResume: _onResume,
        onCancel: _onCancel);
    _controllerStream = _controller.stream;
    _onComplete = expectAsync(() {
      _onComplete = null; // Being null marks the test as being complete.
    });
  }

  StreamProtocolTest.asBroadcast({bool sync: false})
      : isBroadcast = false,
        isAsBroadcast = true {
    _controller = new StreamController(
        sync: sync,
        onListen: _onListen,
        onPause: _onPause,
        onResume: _onResume,
        onCancel: _onCancel);
    _controllerStream = _controller.stream.asBroadcastStream(
        onListen: _onBroadcastListen, onCancel: _onBroadcastCancel);
    _onComplete = expectAsync(() {
      _onComplete = null; // Being null marks the test as being complete.
    });
  }

  // Actions on the stream and controller.
  void add(var data) {
    _controller.add(data);
  }

  void error(var error) {
    _controller.addError(error);
  }

  void close() {
    _controller.close();
  }

  SubscriptionProtocolTest listen({bool cancelOnError: false}) {
    int subscriptionId = _subscriptionIdCounter++;

    StreamSubscription subscription = _controllerStream.listen((var data) {
      _onData(subscriptionId, data);
    }, onError: (Object error) {
      _onError(subscriptionId, error);
    }, onDone: () {
      _onDone(subscriptionId);
    }, cancelOnError: cancelOnError);
    _latestSubscription =
        new SubscriptionProtocolTest(subscriptionId, subscription, this);
    if (trace) {
      print("[Listen #$subscriptionId(#${_latestSubscription.hashCode})]");
    }
    return _latestSubscription;
  }

  // Actions on the most recently created subscription.
  void pause([Future resumeSignal]) {
    _latestSubscription.pause(resumeSignal);
  }

  void resume() {
    _latestSubscription.resume();
  }

  void cancel() {
    _latestSubscription.cancel();
    _latestSubscription = null;
  }

  // End the test now. There must be no open expectations, and no further
  // expectations will be allowed.
  // Called automatically by an onCancel event on a non-broadcast stream.
  void terminate() {
    if (_nextExpectationIndex != _expectations.length) {
      _withNextExpectation((Event expect) {
        _fail("Expected: $expect\n"
            "Found   : Early termination.\n${expect._stackTrace}");
      });
    }
    _onComplete();
  }

  // Handling of stream events.
  void _onData(int id, var data) {
    if (trace) print("[Data#$id : $data]");
    _withNextExpectation((Event expect) {
      if (!expect.matchData(id, data)) {
        _fail("Expected: $expect\n"
            "Found   : [Data#$id: $data]\n${expect._stackTrace}");
      }
    });
  }

  void _onError(int id, Object error) {
    if (trace) print("[Error#$id : $error]");
    _withNextExpectation((Event expect) {
      if (!expect.matchError(id, error)) {
        _fail("Expected: $expect\n"
            "Found   : [Error#$id: ${error}]\n${expect._stackTrace}");
      }
    });
  }

  void _onDone(int id) {
    if (trace) print("[Done#$id]");
    _withNextExpectation((Event expect) {
      if (!expect.matchDone(id)) {
        _fail("Expected: $expect\n"
            "Found   : [Done#$id]\n${expect._stackTrace}");
      }
    });
  }

  void _onPause() {
    if (trace) print("[Pause]");
    _withNextExpectation((Event expect) {
      if (!expect.matchPause()) {
        _fail("Expected: $expect\n"
            "Found   : [Paused]\n${expect._stackTrace}");
      }
    });
  }

  void _onResume() {
    if (trace) print("[Resumed]");
    _withNextExpectation((Event expect) {
      if (!expect.matchResume()) {
        _fail("Expected: $expect\n"
            "Found   : [Resumed]\n${expect._stackTrace}");
      }
    });
  }

  void _onListen() {
    if (trace) print("[Subscribed]");
    _withNextExpectation((Event expect) {
      if (!expect.matchSubscribe()) {
        _fail("Expected: $expect\n"
            "Found: [Subscribed]\n${expect._stackTrace}");
      }
    });
  }

  void _onCancel() {
    if (trace) print("[Cancelled]");
    _withNextExpectation((Event expect) {
      if (!expect.matchCancel()) {
        _fail("Expected: $expect\n"
            "Found: [Cancelled]\n${expect._stackTrace}");
      }
    });
  }

  void _onBroadcastListen(StreamSubscription sub) {
    if (trace) print("[BroadcastListen]");
    _withNextExpectation((Event expect) {
      if (!expect.matchBroadcastListen(sub)) {
        _fail("Expected: $expect\n"
            "Found: [BroadcastListen]\n${expect._stackTrace}");
      }
    });
  }

  void _onBroadcastCancel(StreamSubscription sub) {
    if (trace) print("[BroadcastCancel]");
    _withNextExpectation((Event expect) {
      if (!expect.matchBroadcastCancel(sub)) {
        _fail("Expected: $expect\n"
            "Found: [BroadcastCancel]\n${expect._stackTrace}");
      }
    });
  }

  void _withNextExpectation(void action(Event expect)) {
    if (_nextExpectationIndex == _expectations.length) {
      _nextExpectationIndex++;
      action(new MismatchEvent());
    } else {
      Event next = _expectations[_nextExpectationIndex++];
      action(next);
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
    _expectData(null, data, action);
  }

  void _expectData(SubscriptionProtocolTest sub, var data, void action()) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(new DataEvent(sub, data, action));
  }

  void expectError(var error, [void action()]) {
    _expectError(null, error, action);
  }

  void _expectError(SubscriptionProtocolTest sub, var error, void action()) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(new ErrorEvent(sub, error, action));
  }

  void expectDone([void action()]) {
    _expectDone(null, action);
  }

  void _expectDone(SubscriptionProtocolTest sub, [void action()]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(new DoneEvent(sub, action));
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

  void expectListen([void action()]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(new SubscriptionCallbackEvent(action));
  }

  void expectCancel([void action()]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    _expectations.add(new CancelCallbackEvent(action));
  }

  void expectBroadcastListen([void action(StreamSubscription sub)]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    if (!isAsBroadcast) throw new StateError("Not an asBroadcast stream");
    _expectations.add(new BroadcastListenCallbackEvent(action));
  }

  void expectBroadcastCancel([void action(StreamSubscription sub)]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    if (!isAsBroadcast) throw new StateError("Not an asBroadcast stream");
    _expectations.add(new BroadcastCancelCallbackEvent(action));
  }

  void expectBroadcastListenOpt([void action(StreamSubscription sub)]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    if (!isAsBroadcast) return;
    _expectations.add(new BroadcastListenCallbackEvent(action));
  }

  void expectBroadcastCancelOpt([void action(StreamSubscription sub)]) {
    if (_onComplete == null) {
      _fail("Adding expectation after completing");
    }
    if (!isAsBroadcast) return;
    _expectations.add(new BroadcastCancelCallbackEvent(action));
  }

  void _fail(String message) {
    if (_nextExpectationIndex == 0) {
      throw "Unexpected event:\n$message\nNo earlier events matched.";
    }
    StringBuffer buf = new StringBuffer();
    for (int i = 0; i < _expectations.length; i++) {
      if (i == _nextExpectationIndex - 1) {
        buf.write("->");
      } else {
        buf.write("  ");
      }
      buf.write(_expectations[i]);
      buf.write("\n");
    }
    throw "Unexpected event:\n$message\nAll expectations:\n$buf";
  }
}

class Event {
  Function _action;
  StackTrace _stackTrace;
  Event(void action())
      : _action = (action == null) ? null : expectAsync(action) {
    try {
      throw 0;
    } catch (_, s) {
      _stackTrace = s;
    }
  }
  Event.broadcast(void action(StreamSubscription sub))
      : _action = (action == null) ? null : expectAsync(action) {
    try {
      throw 0;
    } catch (_, s) {
      _stackTrace = s;
    }
  }

  bool matchData(int id, var data) {
    return false;
  }

  bool matchError(int id, e) {
    return false;
  }

  bool matchDone(int id) {
    return false;
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

  bool matchBroadcastListen(StreamSubscription sub) {
    if (!_testBroadcastListen()) return false;
    if (_action != null) _action(sub);
    return true;
  }

  bool matchBroadcastCancel(StreamSubscription sub) {
    if (!_testBroadcastCancel()) return false;
    if (_action != null) _action(sub);
    return true;
  }

  bool _testData(_) => false;
  bool _testError(_) => false;
  bool _testDone() => false;
  bool _testPause() => false;
  bool _testResume() => false;
  bool _testSubscribe() => false;
  bool _testCancel() => false;
  bool _testBroadcastListen() => false;
  bool _testBroadcastCancel() => false;
}

class SubscriptionEvent extends Event {
  SubscriptionProtocolTest subscription;
  SubscriptionEvent(this.subscription, void action()) : super(action);

  bool matchData(int id, var data) {
    if (subscription != null && subscription.id != id) return false;
    if (!_testData(data)) return false;
    if (_action != null) _action();
    return true;
  }

  bool matchError(int id, e) {
    if (subscription != null && subscription.id != id) return false;
    if (!_testError(e)) return false;
    if (_action != null) _action();
    return true;
  }

  bool matchDone(int id) {
    if (subscription != null && subscription.id != id) return false;
    if (!_testDone()) return false;
    if (_action != null) _action();
    return true;
  }

  String get _id => (subscription == null) ? "" : "#${subscription.id}";
}

class MismatchEvent extends Event {
  MismatchEvent() : super(null);
  toString() => "[No event expected]";
}

class DataEvent extends SubscriptionEvent {
  final data;
  DataEvent(SubscriptionProtocolTest sub, this.data, void action())
      : super(sub, action);
  bool _testData(var data) => this.data == data;
  String toString() => "[Data$_id: $data]";
}

class ErrorEvent extends SubscriptionEvent {
  final error;
  ErrorEvent(SubscriptionProtocolTest sub, this.error, void action())
      : super(sub, action);
  bool _testError(error) => this.error == error;
  String toString() => "[Error$_id: $error]";
}

class DoneEvent extends SubscriptionEvent {
  DoneEvent(SubscriptionProtocolTest sub, void action()) : super(sub, action);
  bool _testDone() => true;
  String toString() => "[Done$_id]";
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

class BroadcastCancelCallbackEvent extends Event {
  BroadcastCancelCallbackEvent(void action(StreamSubscription sub))
      : super.broadcast(action);
  bool _testBroadcastCancel() => true;
  String toString() => "[BroadcastCancel]";
}

class BroadcastListenCallbackEvent extends Event {
  BroadcastListenCallbackEvent(void action(StreamSubscription sub))
      : super.broadcast(action);
  bool _testBroadcastListen() => true;
  String toString() => "[BroadcastListen]";
}

/** Event matcher that matches any other event. */
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

  bool _testBroadcastListen() {
    _actual = "*[BroadcastListen]";
    return true;
  }

  bool _testBroadcastCancel() {
    _actual = "*[BroadcastCancel]";
    return true;
  }

  /** Returns a representation of the event it was tested against. */
  String toString() => _actual;
}

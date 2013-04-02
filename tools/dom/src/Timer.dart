// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

// TODO(antonm): support not DOM isolates too.
class _Timer implements Timer {
  final canceller;

  _Timer(this.canceller);

  void cancel() { canceller(); }
}

get _timerFactoryClosure => (int milliSeconds, void callback(Timer timer), bool repeating) {
  var maker;
  var canceller;
  if (repeating) {
    maker = window._setInterval;
    canceller = window._clearInterval;
  } else {
    maker = window._setTimeout;
    canceller = window._clearTimeout;
  }
  Timer timer;
  final int id = maker(() { callback(timer); }, milliSeconds);
  timer = new _Timer(() { canceller(id); });
  return timer;
};

class _PureIsolateTimer implements Timer {
  final ReceivePort _port = new ReceivePort();
  SendPort _sendPort; // Effectively final.

  static SendPort _SEND_PORT;

  _PureIsolateTimer(int milliSeconds, callback, repeating) {
    _sendPort = _port.toSendPort();
    _port.receive((msg, replyTo) {
      assert(msg == _TIMER_PING);
      callback(this);
      if (!repeating) _cancel();
    });

    _send([_NEW_TIMER, milliSeconds, repeating]);
  }

  void cancel() {
    _cancel();
    _send([_CANCEL_TIMER]);
  }

  void _cancel() {
    _port.close();
  }

  // Tricky part.
  // Once _HELPER_ISOLATE_PORT gets resolved, it will still delay in .then
  // and to delay Timer.run is used. However, Timer.run will try to register
  // another Timer and here we got stuck: event cannot be posted as then
  // callback is not executed because it's delayed with timer.
  // Therefore once future is resolved, it's unsafe to call .then on it
  // in Timer code.
  _send(msg) {
    if (_SEND_PORT != null) {
      _SEND_PORT.send(msg, _sendPort);
    } else {
      _HELPER_ISOLATE_PORT.then((port) {
        _SEND_PORT = port;
        _SEND_PORT.send(msg, _sendPort);
      });
    }
  }
}

get _pureIsolateTimerFactoryClosure =>
    ((int milliSeconds, void callback(Timer time), bool repeating) =>
        new _PureIsolateTimer(milliSeconds, callback, repeating));

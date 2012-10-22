// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String _DART_SESSION_ID = "DARTSESSID";

// A _HttpSession is a node in a double-linked list, with _next and _prev being
// the previous and next pointers.
class _HttpSession implements HttpSession {
  _HttpSession(_HttpSessionManager this._sessionManager, String this.id)
    : _lastSeen = new Date.now();

  void destroy() {
    _destroyed = true;
    _sessionManager._removeFromTimeoutQueue(this);
    _sessionManager._sessions.remove(id);
  }

  // Mark the session as seen. This will reset the timeout and move the node to
  // the end of the timeout queue.
  void _markSeen() {
    _lastSeen = new Date.now();
    _sessionManager._bumpToEnd(this);
  }

  Dynamic data;

  Date get lastSeen => _lastSeen;

  final String id;

  void set onTimeout(void callback()) {
    _timeoutCallback = callback;
  }

  // Destroyed marked. Used by the http connection to see if a session is valid.
  bool _destroyed = false;
  Date _lastSeen;
  Function _timeoutCallback;
  _HttpSessionManager _sessionManager;
  // Pointers in timeout queue.
  _HttpSession _prev;
  _HttpSession _next;
}

// Private class used to manage all the active sessions. The sessions are stored
// in two ways:
//
//  * In a map, mapping from ID to HttpSession.
//  * In a linked list, used as a timeout queue.
class _HttpSessionManager {
  _HttpSessionManager() : _sessions = {};

  String createSessionId() {
    const int _KEY_LENGTH = 16;  // 128 bits.
    var data = _getRandomBytes(_KEY_LENGTH);
    return CryptoUtils.bytesToHex(data);
  }

  _HttpSession getSession(String id) {
    return _sessions[id];
  }

  _HttpSession createSession(init(HttpSession session)) {
    var id = createSessionId();
    // TODO(ajohnsen): Consider adding a limit and throwing an exception.
    // Should be very unlikely however.
    while (_sessions.containsKey(id)) {
      id = createSessionId();
    }
    var session = _sessions[id] = new _HttpSession(this, id);
    if (init != null) init(session);
    _addToTimeoutQueue(session);
    return session;
  }

  void set sessionTimeout(int timeout) {
    _sessionTimeout = timeout;
    _stopTimer();
    _startTimer();
  }

  void close() {
    _stopTimer();
  }

  void _bumpToEnd(_HttpSession session) {
    _removeFromTimeoutQueue(session);
    _addToTimeoutQueue(session);
  }

  void _addToTimeoutQueue(_HttpSession session) {
    if (_head == null) {
      assert(_tail == null);
      _tail = _head = session;
      _startTimer();
    } else {
      assert(_timer != null);
      assert(_tail != null);
      // Add to end.
      _tail._next = session;
      session._prev = _tail;
      _tail = session;
    }
  }

  void _removeFromTimeoutQueue(_HttpSession session) {
    if (session._next != null) {
      session._next._prev = session._prev;
    }
    if (session._prev != null) {
      session._prev._next = session._next;
    }
    if (_head == session) {
      // We removed the head element, start new timer.
      _head = session._next;
      _stopTimer();
      _startTimer();
    }
    if (_tail == session) {
      _tail = session._prev;
    }
    session._next = session._prev = null;
  }

  void _timerTimeout(_) {
    _stopTimer();  // Clear timer.
    assert(_head != null);
    var session = _head;
    session.destroy();  // Will remove the session from timeout queue and map.
    if (session._timeoutCallback != null) {
      session._timeoutCallback();
    }
  }

  void _startTimer() {
    assert(_timer == null);
    if (_head != null) {
      int seconds = new Date.now().difference(_head.lastSeen).inSeconds;
      _timer = new Timer((_sessionTimeout - seconds) * 1000, _timerTimeout);
    }
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  Map<String, _HttpSession> _sessions;
  int _sessionTimeout = 20 * 60;  // 20 mins.
  _HttpSession _head;
  _HttpSession _tail;
  Timer _timer;

  static Uint8List _getRandomBytes(int count)
      native "Crypto_GetRandomBytes";
}


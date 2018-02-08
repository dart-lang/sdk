// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._http;

const String _DART_SESSION_ID = "DARTSESSID";

// A _HttpSession is a node in a double-linked list, with _next and _prev being
// the previous and next pointers.
class _HttpSession implements HttpSession {
  // Destroyed marked. Used by the http connection to see if a session is valid.
  bool _destroyed = false;
  bool _isNew = true;
  DateTime _lastSeen;
  Function _timeoutCallback;
  _HttpSessionManager _sessionManager;
  // Pointers in timeout queue.
  _HttpSession _prev;
  _HttpSession _next;
  final String id;

  final Map _data = new HashMap();

  _HttpSession(this._sessionManager, this.id) : _lastSeen = new DateTime.now();

  void destroy() {
    _destroyed = true;
    _sessionManager._removeFromTimeoutQueue(this);
    _sessionManager._sessions.remove(id);
  }

  // Mark the session as seen. This will reset the timeout and move the node to
  // the end of the timeout queue.
  void _markSeen() {
    _lastSeen = new DateTime.now();
    _sessionManager._bumpToEnd(this);
  }

  DateTime get lastSeen => _lastSeen;

  bool get isNew => _isNew;

  void set onTimeout(void callback()) {
    _timeoutCallback = callback;
  }

  // Map implementation:
  bool containsValue(value) => _data.containsValue(value);
  bool containsKey(key) => _data.containsKey(key);
  operator [](key) => _data[key];
  void operator []=(key, value) {
    _data[key] = value;
  }

  putIfAbsent(key, ifAbsent) => _data.putIfAbsent(key, ifAbsent);
  addAll(Map other) => _data.addAll(other);
  remove(key) => _data.remove(key);
  void clear() {
    _data.clear();
  }

  void forEach(void f(key, value)) {
    _data.forEach(f);
  }

  Iterable<MapEntry> get entries => _data.entries;

  void addEntries(Iterable<MapEntry> entries) {
    _data.addEntries(entries);
  }

  Map<K, V> map<K, V>(MapEntry<K, V> transform(key, value)) =>
      _data.map(transform);

  void removeWhere(bool test(key, value)) {
    _data.removeWhere(test);
  }

  Map<K, V> cast<K, V>() => _data.cast<K, V>();

  Map<K, V> retype<K, V>() => _data.retype<K, V>();

  update(key, update(value), {ifAbsent()}) =>
      _data.update(key, update, ifAbsent: ifAbsent);

  void updateAll(update(key, value)) {
    _data.updateAll(update);
  }

  Iterable get keys => _data.keys;
  Iterable get values => _data.values;
  int get length => _data.length;
  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;

  String toString() => 'HttpSession id:$id $_data';
}

// Private class used to manage all the active sessions. The sessions are stored
// in two ways:
//
//  * In a map, mapping from ID to HttpSession.
//  * In a linked list, used as a timeout queue.
class _HttpSessionManager {
  Map<String, _HttpSession> _sessions;
  int _sessionTimeout = 20 * 60; // 20 mins.
  _HttpSession _head;
  _HttpSession _tail;
  Timer _timer;

  _HttpSessionManager() : _sessions = {};

  String createSessionId() {
    const int _KEY_LENGTH = 16; // 128 bits.
    var data = _CryptoUtils.getRandomBytes(_KEY_LENGTH);
    return _CryptoUtils.bytesToHex(data);
  }

  _HttpSession getSession(String id) => _sessions[id];

  _HttpSession createSession() {
    var id = createSessionId();
    // TODO(ajohnsen): Consider adding a limit and throwing an exception.
    // Should be very unlikely however.
    while (_sessions.containsKey(id)) {
      id = createSessionId();
    }
    var session = _sessions[id] = new _HttpSession(this, id);
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

  void _timerTimeout() {
    _stopTimer(); // Clear timer.
    assert(_head != null);
    var session = _head;
    session.destroy(); // Will remove the session from timeout queue and map.
    if (session._timeoutCallback != null) {
      session._timeoutCallback();
    }
  }

  void _startTimer() {
    assert(_timer == null);
    if (_head != null) {
      int seconds = new DateTime.now().difference(_head.lastSeen).inSeconds;
      _timer = new Timer(
          new Duration(seconds: _sessionTimeout - seconds), _timerTimeout);
    }
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }
}

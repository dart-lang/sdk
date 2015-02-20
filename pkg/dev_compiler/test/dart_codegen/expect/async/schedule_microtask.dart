part of dart.async;

typedef void _AsyncCallback();
class _AsyncCallbackEntry {
  final _AsyncCallback callback;
  _AsyncCallbackEntry next;
  _AsyncCallbackEntry(this.callback);
}
_AsyncCallbackEntry _nextCallback;
_AsyncCallbackEntry _lastCallback;
_AsyncCallbackEntry _lastPriorityCallback;
bool _isInCallbackLoop = false;
void _asyncRunCallbackLoop() {
  while (_nextCallback != null) {
    _lastPriorityCallback = null;
    _AsyncCallbackEntry entry = _nextCallback;
    _nextCallback = entry.next;
    if (_nextCallback == null) _lastCallback = null;
    entry.callback();
  }
}
void _asyncRunCallback() {
  _isInCallbackLoop = true;
  try {
    _asyncRunCallbackLoop();
  } finally {
    _lastPriorityCallback = null;
    _isInCallbackLoop = false;
    if (_nextCallback != null) _AsyncRun._scheduleImmediate(_asyncRunCallback);
  }
}
void _scheduleAsyncCallback(callback) {
  if (_nextCallback == null) {
    _nextCallback = _lastCallback = new _AsyncCallbackEntry(callback);
    if (!_isInCallbackLoop) {
      _AsyncRun._scheduleImmediate(_asyncRunCallback);
    }
  } else {
    _AsyncCallbackEntry newEntry = new _AsyncCallbackEntry(callback);
    _lastCallback.next = newEntry;
    _lastCallback = newEntry;
  }
}
void _schedulePriorityAsyncCallback(callback) {
  _AsyncCallbackEntry entry = new _AsyncCallbackEntry(callback);
  if (_nextCallback == null) {
    _scheduleAsyncCallback(callback);
    _lastPriorityCallback = _lastCallback;
  } else if (_lastPriorityCallback == null) {
    entry.next = _nextCallback;
    _nextCallback = _lastPriorityCallback = entry;
  } else {
    entry.next = _lastPriorityCallback.next;
    _lastPriorityCallback.next = entry;
    _lastPriorityCallback = entry;
    if (entry.next == null) {
      _lastCallback = entry;
    }
  }
}
void scheduleMicrotask(void callback()) {
  if (identical(_ROOT_ZONE, Zone.current)) {
    _rootScheduleMicrotask(null, null, DDC$RT.cast(_ROOT_ZONE, dynamic, Zone,
        "CastGeneral",
        """line 130, column 40 of dart:async/schedule_microtask.dart: """,
        _ROOT_ZONE is Zone, true), callback);
    return;
  }
  Zone.current
      .scheduleMicrotask(Zone.current.bindCallback(callback, runGuarded: true));
}
class _AsyncRun {
  @patch static void _scheduleImmediate(void callback()) {
    scheduleImmediateClosure(callback);
  }
}

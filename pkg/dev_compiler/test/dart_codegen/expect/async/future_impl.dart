part of dart.async;

typedef dynamic _FutureOnValue<T>(T value);
typedef bool _FutureErrorTest(var error);
typedef _FutureAction();
abstract class _Completer<T> implements Completer<T> {
  final _Future<T> future = new _Future<T>();
  void complete([value]);
  void completeError(Object error, [StackTrace stackTrace]) {
    error = _nonNullError(error);
    if (!future._mayComplete) throw new StateError("Future already completed");
    AsyncError replacement = Zone.current.errorCallback(error, stackTrace);
    if (replacement != null) {
      error = _nonNullError(replacement.error);
      stackTrace = replacement.stackTrace;
    }
    _completeError(error, stackTrace);
  }
  void _completeError(Object error, StackTrace stackTrace);
  bool get isCompleted => !future._mayComplete;
}
class _AsyncCompleter<T> extends _Completer<T> {
  void complete([value]) {
    if (!future._mayComplete) throw new StateError("Future already completed");
    future._asyncComplete(value);
  }
  void _completeError(Object error, StackTrace stackTrace) {
    future._asyncCompleteError(error, stackTrace);
  }
}
class _SyncCompleter<T> extends _Completer<T> {
  void complete([value]) {
    if (!future._mayComplete) throw new StateError("Future already completed");
    future._complete(value);
  }
  void _completeError(Object error, StackTrace stackTrace) {
    future._completeError(error, stackTrace);
  }
}
class _FutureListener {
  static const int MASK_VALUE = 1;
  static const int MASK_ERROR = 2;
  static const int MASK_TEST_ERROR = 4;
  static const int MASK_WHENCOMPLETE = 8;
  static const int STATE_CHAIN = 0;
  static const int STATE_THEN = MASK_VALUE;
  static const int STATE_THEN_ONERROR = MASK_VALUE | MASK_ERROR;
  static const int STATE_CATCHERROR = MASK_ERROR;
  static const int STATE_CATCHERROR_TEST = MASK_ERROR | MASK_TEST_ERROR;
  static const int STATE_WHENCOMPLETE = MASK_WHENCOMPLETE;
  _FutureListener _nextListener = null;
  final _Future result;
  final int state;
  final Function callback;
  final Function errorCallback;
  _FutureListener.then(
      this.result, _FutureOnValue onValue, Function errorCallback)
      : callback = onValue,
        errorCallback = errorCallback,
        state = (errorCallback == null) ? STATE_THEN : STATE_THEN_ONERROR;
  _FutureListener.catchError(
      this.result, this.errorCallback, _FutureErrorTest test)
      : callback = test,
        state = (test == null) ? STATE_CATCHERROR : STATE_CATCHERROR_TEST;
  _FutureListener.whenComplete(this.result, _FutureAction onComplete)
      : callback = onComplete,
        errorCallback = null,
        state = STATE_WHENCOMPLETE;
  _FutureListener.chain(this.result)
      : callback = null,
        errorCallback = null,
        state = STATE_CHAIN;
  Zone get _zone => result._zone;
  bool get handlesValue => (state & MASK_VALUE != 0);
  bool get handlesError => (state & MASK_ERROR != 0);
  bool get hasErrorTest => (state == STATE_CATCHERROR_TEST);
  bool get handlesComplete => (state == STATE_WHENCOMPLETE);
  _FutureOnValue get _onValue {
    assert(handlesValue);
    return DDC$RT.cast(callback, Function, __t22, "CastGeneral",
        """line 112, column 12 of dart:async/future_impl.dart: """,
        callback is __t22, false);
  }
  Function get _onError => errorCallback;
  _FutureErrorTest get _errorTest {
    assert(hasErrorTest);
    return DDC$RT.cast(callback, Function, __t24, "CastGeneral",
        """line 117, column 12 of dart:async/future_impl.dart: """,
        callback is __t24, false);
  }
  _FutureAction get _whenCompleteAction {
    assert(handlesComplete);
    return DDC$RT.cast(callback, Function, __t26, "CastGeneral",
        """line 121, column 12 of dart:async/future_impl.dart: """,
        callback is __t26, false);
  }
}
class _Future<T> implements Future<T> {
  static const int _INCOMPLETE = 0;
  static const int _PENDING_COMPLETE = 1;
  static const int _CHAINED = 2;
  static const int _VALUE = 4;
  static const int _ERROR = 8;
  int _state = _INCOMPLETE;
  final Zone _zone = Zone.current;
  var _resultOrListeners;
  _Future();
  _Future.immediate(value) {
    _asyncComplete(value);
  }
  _Future.immediateError(var error, [StackTrace stackTrace]) {
    _asyncCompleteError(error, stackTrace);
  }
  bool get _mayComplete => _state == _INCOMPLETE;
  bool get _isChained => _state == _CHAINED;
  bool get _isComplete => _state >= _VALUE;
  bool get _hasValue => _state == _VALUE;
  bool get _hasError => _state == _ERROR;
  set _isChained(bool value) {
    if (value) {
      assert(!_isComplete);
      _state = _CHAINED;
    } else {
      assert(_isChained);
      _state = _INCOMPLETE;
    }
  }
  Future then(f(T value), {Function onError}) {
    _Future result = new _Future();
    if (!identical(result._zone, _ROOT_ZONE)) {
      f = result._zone.registerUnaryCallback(DDC$RT.wrap((dynamic f(T __u27)) {
        dynamic c(T x0) => f(DDC$RT.cast(x0, dynamic, T, "CastParam",
            """line 208, column 46 of dart:async/future_impl.dart: """, x0 is T,
            false));
        return f == null ? null : c;
      }, f, DDC$RT.type((__t28<T> _) {}), __t22, "Wrap",
          """line 208, column 46 of dart:async/future_impl.dart: """,
          f is __t22));
      if (onError != null) {
        onError = _registerErrorHandler(onError, result._zone);
      }
    }
    _addListener(new _FutureListener.then(result, f, onError));
    return result;
  }
  Future catchError(Function onError, {bool test(error)}) {
    _Future result = new _Future();
    if (!identical(result._zone, _ROOT_ZONE)) {
      onError = _registerErrorHandler(onError, result._zone);
      if (test != null) test = ((__x32) => DDC$RT.wrap(
          (dynamic f(dynamic __u31)) {
        dynamic c(dynamic x0) => ((__x30) => DDC$RT.cast(__x30, dynamic, bool,
            "CastResult",
            """line 221, column 32 of dart:async/future_impl.dart: """,
            __x30 is bool, true))(f(x0));
        return f == null ? null : c;
      }, __x32, __t22, __t24, "Wrap",
          """line 221, column 32 of dart:async/future_impl.dart: """,
          __x32 is __t24))(result._zone.registerUnaryCallback(test));
    }
    _addListener(new _FutureListener.catchError(result, onError, test));
    return result;
  }
  Future<T> whenComplete(action()) {
    _Future result = new _Future<T>();
    if (!identical(result._zone, _ROOT_ZONE)) {
      action = result._zone.registerCallback(action);
    }
    _addListener(new _FutureListener.whenComplete(result, action));
    return DDC$RT.cast(result, DDC$RT.type((_Future<dynamic> _) {}),
        DDC$RT.type((Future<T> _) {}), "CastDynamic",
        """line 233, column 12 of dart:async/future_impl.dart: """,
        result is Future<T>, false);
  }
  Stream<T> asStream() => ((__x33) => DDC$RT.cast(__x33,
      DDC$RT.type((Stream<dynamic> _) {}), DDC$RT.type((Stream<T> _) {}),
      "CastExact", """line 236, column 27 of dart:async/future_impl.dart: """,
      __x33 is Stream<T>, false))(new Stream.fromFuture(this));
  void _markPendingCompletion() {
    if (!_mayComplete) throw new StateError("Future already completed");
    _state = _PENDING_COMPLETE;
  }
  T get _value {
    assert(_isComplete && _hasValue);
    return DDC$RT.cast(_resultOrListeners, dynamic, T, "CastGeneral",
        """line 245, column 12 of dart:async/future_impl.dart: """,
        _resultOrListeners is T, false);
  }
  AsyncError get _error {
    assert(_isComplete && _hasError);
    return DDC$RT.cast(_resultOrListeners, dynamic, AsyncError, "CastGeneral",
        """line 250, column 12 of dart:async/future_impl.dart: """,
        _resultOrListeners is AsyncError, true);
  }
  void _setValue(T value) {
    assert(!_isComplete);
    _state = _VALUE;
    _resultOrListeners = value;
  }
  void _setErrorObject(AsyncError error) {
    assert(!_isComplete);
    _state = _ERROR;
    _resultOrListeners = error;
  }
  void _setError(Object error, StackTrace stackTrace) {
    _setErrorObject(new AsyncError(error, stackTrace));
  }
  void _addListener(_FutureListener listener) {
    assert(listener._nextListener == null);
    if (_isComplete) {
      _zone.scheduleMicrotask(() {
        _propagateToListeners(this, listener);
      });
    } else {
      listener._nextListener = DDC$RT.cast(_resultOrListeners, dynamic,
          _FutureListener, "CastGeneral",
          """line 277, column 32 of dart:async/future_impl.dart: """,
          _resultOrListeners is _FutureListener, true);
      _resultOrListeners = listener;
    }
  }
  _FutureListener _removeListeners() {
    assert(!_isComplete);
    _FutureListener current = DDC$RT.cast(_resultOrListeners, dynamic,
        _FutureListener, "CastGeneral",
        """line 286, column 31 of dart:async/future_impl.dart: """,
        _resultOrListeners is _FutureListener, true);
    _resultOrListeners = null;
    _FutureListener prev = null;
    while (current != null) {
      _FutureListener next = current._nextListener;
      current._nextListener = prev;
      prev = current;
      current = next;
    }
    return prev;
  }
  static void _chainForeignFuture(Future source, _Future target) {
    assert(!target._isComplete);
    assert(source is! _Future);
    target._isChained = true;
    source.then((value) {
      assert(target._isChained);
      target._completeWithValue(value);
    }, onError: (error, [stackTrace]) {
      assert(target._isChained);
      target._completeError(error, DDC$RT.cast(stackTrace, dynamic, StackTrace,
          "CastGeneral",
          """line 317, column 38 of dart:async/future_impl.dart: """,
          stackTrace is StackTrace, true));
    });
  }
  static void _chainCoreFuture(_Future source, _Future target) {
    assert(!target._isComplete);
    assert(source is _Future);
    target._isChained = true;
    _FutureListener listener = new _FutureListener.chain(target);
    if (source._isComplete) {
      _propagateToListeners(source, listener);
    } else {
      source._addListener(listener);
    }
  }
  void _complete(value) {
    assert(!_isComplete);
    if (value is Future) {
      if (value is _Future) {
        _chainCoreFuture(DDC$RT.cast(value, dynamic,
            DDC$RT.type((_Future<dynamic> _) {}), "CastGeneral",
            """line 341, column 26 of dart:async/future_impl.dart: """,
            value is _Future<dynamic>, true), this);
      } else {
        _chainForeignFuture(DDC$RT.cast(value, dynamic,
            DDC$RT.type((Future<dynamic> _) {}), "CastGeneral",
            """line 343, column 29 of dart:async/future_impl.dart: """,
            value is Future<dynamic>, true), this);
      }
    } else {
      _FutureListener listeners = _removeListeners();
      _setValue(DDC$RT.cast(value, dynamic, T, "CastGeneral",
          """line 347, column 17 of dart:async/future_impl.dart: """,
          value is T, false));
      _propagateToListeners(this, listeners);
    }
  }
  void _completeWithValue(value) {
    assert(!_isComplete);
    assert(value is! Future);
    _FutureListener listeners = _removeListeners();
    _setValue(DDC$RT.cast(value, dynamic, T, "CastGeneral",
        """line 357, column 15 of dart:async/future_impl.dart: """, value is T,
        false));
    _propagateToListeners(this, listeners);
  }
  void _completeError(error, [StackTrace stackTrace]) {
    assert(!_isComplete);
    _FutureListener listeners = _removeListeners();
    _setError(error, stackTrace);
    _propagateToListeners(this, listeners);
  }
  void _asyncComplete(value) {
    assert(!_isComplete);
    if (value == null) {} else if (value is Future) {
      Future<T> typedFuture = DDC$RT.cast(value, dynamic,
          DDC$RT.type((Future<T> _) {}), "CastGeneral",
          """line 386, column 31 of dart:async/future_impl.dart: """,
          value is Future<T>, false);
      if (typedFuture is _Future) {
        _Future<T> coreFuture = DDC$RT.cast(typedFuture,
            DDC$RT.type((Future<T> _) {}), DDC$RT.type((_Future<T> _) {}),
            "CastGeneral",
            """line 388, column 33 of dart:async/future_impl.dart: """,
            typedFuture is _Future<T>, false);
        if (coreFuture._isComplete && coreFuture._hasError) {
          _markPendingCompletion();
          _zone.scheduleMicrotask(() {
            _chainCoreFuture(coreFuture, this);
          });
        } else {
          _chainCoreFuture(coreFuture, this);
        }
      } else {
        _chainForeignFuture(typedFuture, this);
      }
      return;
    } else {
      T typedValue = DDC$RT.cast(value, dynamic, T, "CastGeneral",
          """line 407, column 22 of dart:async/future_impl.dart: """,
          value is T, false);
    }
    _markPendingCompletion();
    _zone.scheduleMicrotask(() {
      _completeWithValue(value);
    });
  }
  void _asyncCompleteError(error, StackTrace stackTrace) {
    assert(!_isComplete);
    _markPendingCompletion();
    _zone.scheduleMicrotask(() {
      _completeError(error, stackTrace);
    });
  }
  static void _propagateToListeners(_Future source, _FutureListener listeners) {
    while (true) {
      assert(source._isComplete);
      bool hasError = source._hasError;
      if (listeners == null) {
        if (hasError) {
          AsyncError asyncError = source._error;
          source._zone.handleUncaughtError(
              asyncError.error, asyncError.stackTrace);
        }
        return;
      }
      while (listeners._nextListener != null) {
        _FutureListener listener = listeners;
        listeners = listener._nextListener;
        listener._nextListener = null;
        _propagateToListeners(source, listener);
      }
      _FutureListener listener = listeners;
      bool listenerHasValue = true;
      final sourceValue = hasError ? null : source._value;
      var listenerValueOrError = sourceValue;
      bool isPropagationAborted = false;
      if (hasError || (listener.handlesValue || listener.handlesComplete)) {
        Zone zone = listener._zone;
        if (hasError && !source._zone.inSameErrorZone(zone)) {
          AsyncError asyncError = source._error;
          source._zone.handleUncaughtError(
              asyncError.error, asyncError.stackTrace);
          return;
        }
        Zone oldZone;
        if (!identical(Zone.current, zone)) {
          oldZone = Zone._enter(zone);
        }
        bool handleValueCallback() {
          try {
            listenerValueOrError =
                zone.runUnary(listener._onValue, sourceValue);
            return true;
          } catch (e, s) {
            listenerValueOrError = new AsyncError(e, s);
            return false;
          }
        }
        void handleError() {
          AsyncError asyncError = source._error;
          bool matchesTest = true;
          if (listener.hasErrorTest) {
            _FutureErrorTest test = listener._errorTest;
            try {
              matchesTest = ((__x34) => DDC$RT.cast(__x34, dynamic, bool,
                  "CastGeneral",
                  """line 499, column 29 of dart:async/future_impl.dart: """,
                  __x34 is bool, true))(zone.runUnary(test, asyncError.error));
            } catch (e, s) {
              listenerValueOrError = identical(asyncError.error, e)
                  ? asyncError
                  : new AsyncError(e, s);
              listenerHasValue = false;
              return;
            }
          }
          Function errorCallback = listener._onError;
          if (matchesTest && errorCallback != null) {
            try {
              if (errorCallback is ZoneBinaryCallback) {
                listenerValueOrError = zone.runBinary(
                    errorCallback, asyncError.error, asyncError.stackTrace);
              } else {
                listenerValueOrError = zone.runUnary(DDC$RT.cast(errorCallback,
                    Function, __t22, "CastGeneral",
                    """line 515, column 54 of dart:async/future_impl.dart: """,
                    errorCallback is __t22, false), asyncError.error);
              }
            } catch (e, s) {
              listenerValueOrError = identical(asyncError.error, e)
                  ? asyncError
                  : new AsyncError(e, s);
              listenerHasValue = false;
              return;
            }
            listenerHasValue = true;
          } else {
            listenerValueOrError = asyncError;
            listenerHasValue = false;
          }
        }
        void handleWhenCompleteCallback() {
          var completeResult;
          try {
            completeResult = zone.run(listener._whenCompleteAction);
          } catch (e, s) {
            if (hasError && identical(source._error.error, e)) {
              listenerValueOrError = source._error;
            } else {
              listenerValueOrError = new AsyncError(e, s);
            }
            listenerHasValue = false;
            return;
          }
          if (completeResult is Future) {
            _Future result = listener.result;
            result._isChained = true;
            isPropagationAborted = true;
            completeResult.then((ignored) {
              _propagateToListeners(source, new _FutureListener.chain(result));
            }, onError: (error, [stackTrace]) {
              if (completeResult is! _Future) {
                completeResult = new _Future();
                completeResult._setError(error, stackTrace);
              }
              _propagateToListeners(DDC$RT.cast(completeResult, dynamic,
                  DDC$RT.type((_Future<dynamic> _) {}), "CastGeneral",
                  """line 559, column 37 of dart:async/future_impl.dart: """,
                  completeResult is _Future<dynamic>,
                  true), new _FutureListener.chain(result));
            });
          }
        }
        if (!hasError) {
          if (listener.handlesValue) {
            listenerHasValue = handleValueCallback();
          }
        } else {
          handleError();
        }
        if (listener.handlesComplete) {
          handleWhenCompleteCallback();
        }
        if (oldZone != null) Zone._leave(oldZone);
        if (isPropagationAborted) return;
        if (listenerHasValue &&
            !identical(sourceValue, listenerValueOrError) &&
            listenerValueOrError is Future) {
          Future chainSource = DDC$RT.cast(listenerValueOrError, dynamic,
              DDC$RT.type((Future<dynamic> _) {}), "CastGeneral",
              """line 585, column 32 of dart:async/future_impl.dart: """,
              listenerValueOrError is Future<dynamic>, true);
          _Future result = listener.result;
          if (chainSource is _Future) {
            if (chainSource._isComplete) {
              result._isChained = true;
              source = chainSource;
              listeners = new _FutureListener.chain(result);
              continue;
            } else {
              _chainCoreFuture(chainSource, result);
            }
          } else {
            _chainForeignFuture(chainSource, result);
          }
          return;
        }
      }
      _Future result = listener.result;
      listeners = result._removeListeners();
      if (listenerHasValue) {
        result._setValue(listenerValueOrError);
      } else {
        AsyncError asyncError = DDC$RT.cast(listenerValueOrError, dynamic,
            AsyncError, "CastGeneral",
            """line 610, column 33 of dart:async/future_impl.dart: """,
            listenerValueOrError is AsyncError, true);
        result._setErrorObject(asyncError);
      }
      source = result;
    }
  }
  Future timeout(Duration timeLimit, {onTimeout()}) {
    if (_isComplete) return new _Future.immediate(this);
    _Future result = new _Future();
    Timer timer;
    if (onTimeout == null) {
      timer = new Timer(timeLimit, () {
        result._completeError(
            new TimeoutException("Future not completed", timeLimit));
      });
    } else {
      Zone zone = Zone.current;
      onTimeout = zone.registerCallback(onTimeout);
      timer = new Timer(timeLimit, () {
        try {
          result._complete(zone.run(onTimeout));
        } catch (e, s) {
          result._completeError(e, s);
        }
      });
    }
    this.then((T v) {
      if (timer.isActive) {
        timer.cancel();
        result._completeWithValue(v);
      }
    }, onError: (e, s) {
      if (timer.isActive) {
        timer.cancel();
        result._completeError(e, DDC$RT.cast(s, dynamic, StackTrace,
            "CastGeneral",
            """line 646, column 34 of dart:async/future_impl.dart: """,
            s is StackTrace, true));
      }
    });
    return result;
  }
}
typedef dynamic __t22(dynamic __u23);
typedef bool __t24(dynamic __u25);
typedef dynamic __t26();
typedef dynamic __t28<T>(T __u29);

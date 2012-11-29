// Copyright 2012 Google Inc. All Rights Reserved.
// Dart core library.

part of dart_core;

class _FutureImpl<T> implements Future<T> {

  bool _isComplete = false;

  /**
   * Value that was provided to this Future by the Completer
   */
  T _value;

  /**
   * Exception that occured, if there was a problem providing
   * Value.
   */
  Object _exception;

  /**
   * Stack trace associated with [_exception], if one was provided.
   */
  Object _stackTrace;

  /**
   * true, if any onException handler handled the exception.
   */
  bool _exceptionHandled = false;

  /**
   * true if an exception in this future should be thrown to the top level.
   */
  bool _throwOnException = false;

  /**
   * Listeners waiting to receive the value of this future.
   */
  final List<Function> _successListeners;

  /**
   * Exception handlers waiting for exceptions.
   */
  final List<Function> _exceptionHandlers;

  /**
   * Listeners waiting to be called when the future completes.
   */
  final List<Function> _completionListeners;

  _FutureImpl()
    : _successListeners = [],
      _exceptionHandlers = [],
      _completionListeners = [];

  factory _FutureImpl.immediate(T value) {
    final res = new _FutureImpl();
    res._setValue(value);
    return res;
  }

  T get value {
    if (!isComplete) {
      throw new FutureNotCompleteException();
    }
    if (_exception != null) {
      throw new FutureUnhandledException(_exception, stackTrace);
    }
    return _value;
  }

  Object get exception {
    if (!isComplete) {
      throw new FutureNotCompleteException();
    }
    return _exception;
  }

  Object get stackTrace {
    if (!isComplete) {
      throw new FutureNotCompleteException();
    }
    return _stackTrace;
  }

  bool get isComplete {
    return _isComplete;
  }

  bool get hasValue {
    return isComplete && _exception == null;
  }

  void then(void onSuccess(T value)) {
    if (hasValue) {
      onSuccess(value);
    } else if (!isComplete) {
      _throwOnException = true;
      _successListeners.add(onSuccess);
    } else if (!_exceptionHandled) {
      throw new FutureUnhandledException(_exception, stackTrace);
    }
  }

  void _handleSuccess(void onSuccess(T value)) {
    if (hasValue) {
      onSuccess(value);
    } else if (!isComplete) {
      _successListeners.add(onSuccess);
    }
  }

  void handleException(bool onException(Object exception)) {
    if (_exceptionHandled) return;
    if (_isComplete) {
       if (_exception != null) {
         _exceptionHandled = onException(_exception);
       }
    } else {
      _exceptionHandlers.add(onException);
    }
  }

  void onComplete(void complete(Future<T> future)) {
    if (_isComplete) {
      try {
        complete(this);
      } catch (e) {}
    } else {
      _completionListeners.add(complete);
    }
  }

  void _complete() {
    _isComplete = true;

    try {
      if (_exception != null) {
        for (Function handler in _exceptionHandlers) {
          // Explicitly check for true here so that if the handler returns null,
          // we don't get an exception in checked mode.
          if (handler(_exception) == true) {
            _exceptionHandled = true;
            break;
          }
        }
      }

      if (hasValue) {
        for (Function listener in _successListeners) {
          listener(value);
        }
      } else {
        if (!_exceptionHandled && _throwOnException) {
          throw new FutureUnhandledException(_exception, stackTrace);
        }
      }
    } finally {
      for (Function listener in _completionListeners) {
        try {
          listener(this);
        } catch (e) {}
      }
    }
  }

  void _setValue(T value) {
    if (_isComplete) {
      throw new FutureAlreadyCompleteException();
    }
    _value = value;
    _complete();
  }

  void _setException(Object exception, Object stackTrace) {
    if (exception == null) {
      // null is not a legal value for the exception of a Future.
      throw new ArgumentError(null);
    }
    if (_isComplete) {
      throw new FutureAlreadyCompleteException();
    }
    _exception = exception;
    _stackTrace = stackTrace;
    _complete();
  }

  Future transform(Function transformation) {
    final completer = new Completer();

    _forwardException(this, completer);

    _handleSuccess((v) {
      var transformed = null;
      try {
        transformed = transformation(v);
      } catch (e, stackTrace) {
        completer.completeException(e, stackTrace);
        return;
      }
      completer.complete(transformed);
    });

    return completer.future;
  }

  Future chain(Function transformation) {
    final completer = new Completer();

    _forwardException(this, completer);
    _handleSuccess((v) {
      var future = null;
      try {
        future = transformation(v);
      } catch (ex, stackTrace) {
        completer.completeException(ex, stackTrace);
        return;
      }

      _forward(future, completer);
    });
    return completer.future;
  }

  Future transformException(transformation(Object exception)) {
    final completer = new Completer();

    handleException((ex) {
      try {
        final result = transformation(ex);

        // If the transformation itself returns a future, then we will
        // complete to what that completes to.
        if (result is Future) {
          _forward(result, completer);
        } else {
          completer.complete(result);
        }
      } catch (innerException, stackTrace) {
        completer.completeException(innerException, stackTrace);
      }
      return false;
    });

    _handleSuccess(completer.complete);

    return completer.future;
  }

  /**
   * Forwards the success or error completion from [future] to [completer].
   */
  _forward(Future future, Completer completer) {
    _forwardException(future, completer);
    future._handleSuccess(completer.complete);
  }

  /**
   * Forwards the exception completion from [future] to [completer].
   */
  _forwardException(Future future, Completer completer) {
    future.handleException((e) {
      completer.completeException(e, future.stackTrace);
      return false;
    });
  }
}

class _CompleterImpl<T> implements Completer<T> {

  final _FutureImpl<T> _futureImpl;

  _CompleterImpl() : _futureImpl = new _FutureImpl() {}

  Future<T> get future {
    return _futureImpl;
  }

  void complete(T value) {
    _futureImpl._setValue(value);
  }

  void completeException(Object exception, [Object stackTrace]) {
    _futureImpl._setException(exception, stackTrace);
  }
}


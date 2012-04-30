// Copyright 2012 Google Inc. All Rights Reserved.
// Dart core library.

class FutureImpl<T> implements Future<T> {

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
   * true, if any onException handler handled the exception.
   */
  bool _exceptionHandled = false;

  /**
   * Listeners waiting to receive the value of this future.
   */
  final List<Function> _listeners;

  /**
   * Exception handlers waiting for exceptions.
   */
  final List<Function> _exceptionHandlers;

  FutureImpl()
    : _listeners = [],
      _exceptionHandlers = [];

  factory FutureImpl.immediate(T value) {
    final res = new FutureImpl();
    res._setValue(value);
    return res;
  }

  T get value() {
    if (!isComplete) {
      throw new FutureNotCompleteException();
    }
    if (_exception !== null) {
      throw _exception;
    }
    return _value;
  }

  Object get exception() {
    if (!isComplete) {
      throw new FutureNotCompleteException();
    }
    return _exception;
  }

  bool get isComplete() {
    return _isComplete;
  }

  bool get hasValue() {
    return isComplete && _exception === null;
  }

  void then(void onComplete(T value)) {
    if (hasValue) {
      onComplete(value);
    } else if (!isComplete) {
      _listeners.add(onComplete);
    } else if (!_exceptionHandled) {
      throw _exception;
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

  void _complete() {
    _isComplete = true;
    if (_exception !== null) {
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
      for (Function listener in _listeners) {
        listener(value);
      }
    } else {
      if (!_exceptionHandled && _listeners.length > 0) {
        throw _exception;
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

  void _setException(var exception) {
    if (exception === null) {
      // null is not a legal value for the exception of a Future
      throw new IllegalArgumentException(null);
    }
    if (_isComplete) {
      throw new FutureAlreadyCompleteException();
    }
    _exception = exception;
    _complete();
  }

  Future transform(Function transformation) {
    final completer = new Completer();
    handleException((e) {
      completer.completeException(e);
      return true;
    });
    then((v) {
      var transformed = null;
      try {
        transformed = transformation(v);
      } catch (final e) {
        completer.completeException(e);
        return;
      }
      completer.complete(transformed);
    });
    return completer.future;
  }

  Future chain(Function transformation) {
    final completer = new Completer();
    handleException((e) {
      completer.completeException(e);
      return true;
    });
    then((v) {
      var future = null;
      try {
        future = transformation(v);
      } catch (final e) {
        completer.completeException(e);
        return;
      }
      future.handleException((e) {
        completer.completeException(e);
        return true;
      });
      future.then((b) => completer.complete(b));
    });
    return completer.future;
  }
}

class CompleterImpl<T> implements Completer<T> {

  final FutureImpl<T> _futureImpl;

  CompleterImpl() : _futureImpl = new FutureImpl() {}

  Future<T> get future() {
    return _futureImpl;
  }

  void complete(T value) {
    _futureImpl._setValue(value);
  }

  void completeException(var exception) {
    _futureImpl._setException(exception);
  }
}

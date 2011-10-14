// Copyright 2011 Google Inc. All Rights Reserved.
// Dart core library.

/**
 * Thrown if client tries to obtain value or exception
 * before a future has completed.
 */
class FutureNotCompleteException implements Exception {
  FutureNotCompleteException() {}
}

/**
 * Thrown if a completer tries to set the value on
 * a future that is already complete.
 */
class FutureAlreadyCompleteException implements Exception {
  FutureAlreadyCompleteException() {}
}


class FutureImpl<T> implements Future<T> {

  bool _isComplete;

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
  bool _exceptionHandled;

  /**
   * Listeners waiting to receive the value of this future.
   */
  final Array<Function> _listeners;

  /**
   * Exception handlers waiting for exceptions.
   */
  final Array<Function> _exceptionHandlers;

  FutureImpl() : _listeners = new Array(), _exceptionHandlers = new Array() {
    _isComplete = false;
  }

  T get value() {
    if (!isComplete) {
      throw new FutureNotCompleteException();
    }
    if (_exception != null) {
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
    return isComplete && exception == null;
  }

  void then(void onComplete(T value)) {
    if (hasValue) {
      onComplete(value);
    } else {
      _listeners.add(onComplete);
    }
  }

  void handleException(void onException(Object exception)) {
    _exceptionHandlers.add(onException);
  }

  void _complete() {
    _isComplete = true;
    if (_exception != null) {
      for (Function handler in _exceptionHandlers) {
        if (handler(_exception)) {
          _exceptionHandled = true;
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
    if (exception == null) {
      // null is not a legal value for the exception of a Future
      throw new IllegalArgumentException(null);
    }
    if (_isComplete) {
      throw new FutureAlreadyCompleteException();
    }
    _exception = exception;
    _complete();
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

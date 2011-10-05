// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

class PromiseImpl<T> implements Promise<T> {

  // Enumeration of possible states:
  static final int CREATED = 0;
  static final int RUNNING = 1;
  static final int COMPLETE_NORMAL = 2;
  static final int COMPLETE_ERROR = 3;
  static final int CANCELLED = 4;

  // TODO(sigmund): consider whether this is what people want, or if we should
  // discard values/errors after cancellation.
  static final int COMPLETE_NORMAL_AFTER_CANCELLED = 5;
  static final int COMPLETE_ERROR_AFTER_CANCELLED = 6;


  /** Internal state, one of the above constants. */
  int _state;

  /** Value that was provided, if any. */
  T _value;

  /** Error that was provided, if any. */
  var _error;

  /** Listeners waiting for a normal completion of this promise. */
  Queue<Function> _normalListeners;

  /** Error listeners. */
  Queue<Function> _errorListeners;

  /** Cancellation listeners. */
  Queue<Function> _cancelListeners;

  PromiseImpl()
      : _state = CREATED,
        _value = null,
        _error = null,
        _normalListeners = null,
        _errorListeners = null,
        _cancelListeners = null {}

  PromiseImpl.fromValue(val)
      : _state = COMPLETE_NORMAL,
        _value = val,
        _error = null,
        _normalListeners = null,
        _errorListeners = null,
        _cancelListeners = null {}

  // Properties and methods from Promise:

  T get value() {
    if (!isDone()) {
      // TODO(kasperl): Turn this into a proper exception object.
      throw "Attempted to get the value of an uncompleted promise.";
    }
    if (hasError()) {
      throw _error;
    } else {
      return _value;
    }
  }

  get error() {
    if (!isDone()) {
      // TODO(kasperl): Turn this into a proper exception object.
      throw "Attempted to examine the state of an uncompleted promise.";
    }
    return _error;
  }

  bool isDone() {
    return _state != CREATED && _state != RUNNING;
  }

  bool isCancelled() {
    return _state == CANCELLED
      || _state == COMPLETE_NORMAL_AFTER_CANCELLED
      || _state == COMPLETE_ERROR_AFTER_CANCELLED;
  }

  bool hasValue() {
    return _state == COMPLETE_NORMAL
        || _state == COMPLETE_NORMAL_AFTER_CANCELLED;
  }

  bool hasError() {
    return _state == COMPLETE_ERROR
        || _state == COMPLETE_ERROR_AFTER_CANCELLED;
  }

  void complete(T newVal) {
    if (_state == CANCELLED) {
      _value = newVal;
      _state = COMPLETE_NORMAL_AFTER_CANCELLED;
      return;
    }

    if (isDone()) {
      throw "Attempted to complete an already completed promise.";
    }

    _value = newVal;
    _state = COMPLETE_NORMAL;
    if (_normalListeners !== null) {
      _normalListeners.forEach((listener) {
        listener(newVal);
      });
    }
    _clearListeners();
  }

  void _clearListeners() {
    _normalListeners = null;
    _errorListeners = null;
    _cancelListeners = null;
  }

  void fail(var err) {
    if (_state == CANCELLED) {
      _error = err;
      _state = COMPLETE_ERROR_AFTER_CANCELLED;
      return;
    }

    if (isDone()) {
      throw "Can't fail an already completed promise.";
    }

    _error = err;
    _state = COMPLETE_ERROR;
    if (_errorListeners !== null) {
      _errorListeners.forEach((listener) {
        listener(err);
      });
    }
    _clearListeners();
  }

  bool cancel() {
    if (!isDone()) {
      _state = CANCELLED;
      if (_cancelListeners !== null) {
        _cancelListeners.forEach((listener) {
          listener();
        });
      }
      _clearListeners();
      return true;
    }
    return false;
  }

  void addCompleteHandler(void completeHandler(T result)) {
    if (_state == COMPLETE_NORMAL) {
      completeHandler(_value);
    } else if (!isDone()) {
      if (_normalListeners == null) {
        _normalListeners = new Queue<Function>();
      }
      _normalListeners.addLast(completeHandler);
    }
  }

  void addErrorHandler(void errorHandler(err)) {
    if (_state == COMPLETE_ERROR) {
      errorHandler(_error);
    } else if (!isDone()) {
      if (_errorListeners == null) {
        _errorListeners = new Queue<Function>();
      }
      _errorListeners.addLast(errorHandler);
    }
  }

  void addCancelHandler(void cancelHandler()) {
    if (isCancelled()) {
      cancelHandler();
    } else if (!isDone()) {
      if (_cancelListeners == null) {
        _cancelListeners = new Queue<Function>();
      }
      _cancelListeners.addLast(cancelHandler);
    }
  }

  // TODO(sigmund): consider adding to the API a method that does the following:
  // Promise chain(callback(T r)) {
  //   return then(callback).flatten();
  // }

  Promise then(callback(T result)) {
    Promise promise = new Promise();
    addCompleteHandler((T val) {
      promise.complete(callback(val));
    });
    addErrorHandler((err) { promise.fail(err); });
    addCancelHandler(() {
      promise.fail("Source promise was cancelled");
    });
    return promise;
  }

  // TODO(sigmund): consider adding to the API a method to represent
  // containment. For instance, promiseA spawns internally promiseB, where
  // promiseB is not visible to the user. Like [then] this creates a relation
  // between A, and B:
  //  - b.complete -> a.complete (as above)
  //  - b.error -> a.error (as above)
  //  - b.cancel -> a.error (as above)
  //  - a.cancel -> b.cancel (unlike [then])

  Promise flatten() {
    Promise res = new Promise();
    then((T thisVal) {
      if (thisVal is Promise) {
        Promise thisPromise = thisVal.dynamic;
        thisPromise.flatten().then((lastVal) {
          res.complete(lastVal);
        });
      } else {
        res.complete(thisVal);
      }
    });
    return res;
  }

  void join(Collection<Promise> promises, bool joinDone(Promise completed)) {
    promises.forEach((promise) {
      promise.addCompleteHandler((value) {
        if (joinDone(promise)) {
          complete(value);
        }
      });
      promise.addErrorHandler((err) {
        fail(err);
      });
    });
    addCancelHandler(() {
      promises.forEach((promise) {
        promise.cancel();
      });
    });
  }

  void waitFor(Collection<Promise> promises, int n) {
    int counter = 0;
    join(promises, (p) => (++counter == n));
    addCompleteHandler((val) {
      promises.forEach((promise) {
        if (!promise.isDone()) {
          promise.cancel();
        }
      });
    });
  }
}

class ProxyImpl {

  ProxyImpl.forPort(SendPort port) {
    _promise = new Promise<SendPort>();
    _promise.complete(port);
  }

  // Construct a proxy for a message reply; see the [Proxy.forReply]
  // documentation for more details.
  ProxyImpl.forReply(Promise<SendPort> port) {
    _promise = port;
  }

  static ReceivePort register(Dispatcher dispatcher) {
    if (_dispatchers === null) {
      _dispatchers = new Map<SendPort, Dispatcher>();
    }
    ReceivePort result = new ReceivePort();
    _dispatchers[result.toSendPort()] = dispatcher;
    return result;
  }

  get local() {
    if (_dispatchers !== null) {
      Dispatcher dispatcher = _dispatchers[_promise.value];
      if (dispatcher !== null) return dispatcher.target;
    }
    throw "Cannot access object of non-local proxy.";
  }

  void send(List message) {
    _marshal(message, (List marshalled) {
      SendPortImpl port = _promise.value;
      port._sendNow(marshalled, null);
    });
  }

  Promise call(List message) {
    return _marshal(message, (List marshalled) {
      // TODO(kasperl): For now, the [Promise.then] implementation allows
      // me to return a promise and it will do the promise chaining.
      final result = new Promise();
      // The promise queue implementation guarantees that promise is
      // resolved at this point.
      SendPortImpl outgoing = _promise.value;
      ReceivePort incoming  = outgoing._callNow(marshalled);
      incoming.receive((List message, replyTo) {
        result.complete(message[0]);
      });
      return result;
    });
  }

  bool operator ==(var other) {
    return (other is ProxyImpl) &&
        _promise.value == other._promise.value;
  }

  int hashCode() {
    return _promise.value.hashCode();
  }

  // Marshal the [message] and pass it to the [process] callback
  // function once this proxy and all proxies in the message are
  // resolved.
  Promise _marshal(List message, process(List marshalled)) {
    final promises = new List<Promise>();
    promises.add(_promise);

    var marshalled = new List(message.length);
    for (int i = 0; i < marshalled.length; i++) {
      var entry = message[i];
      marshalled[i] = entry;  // TODO(kasperl): We probably have to copy here.
      if (entry is Proxy) {
        promises.add(entry._promise);
      } else if (entry is Promise) {
        promises.add(entry);
      }
    }

    return PromiseQueue.enqueue(promises).then((ignored) {
      for (int i = 0; i < marshalled.length; i++) {
        var entry = marshalled[i];
        if (entry is Proxy) {
          marshalled[i] = entry._promise.value;
        } else if (entry is Promise) {
          marshalled[i] = entry.value;
        }
      }
      return process(marshalled);
    }).flatten();
  }

  Promise<SendPort> _promise;
  static Map<SendPort, Dispatcher> _dispatchers;

}


class PromiseQueue {

  // Enqueue an element that depends on a list of promises. The
  // returned promise is resolved when all the input promises have
  // been resolved.
  static Promise enqueue(List<Promise> dependencies) {
    if (_queue === null) {
      _queue = new Queue<Function>();
    }

    // Keep track of how many unresolved promises we're waiting for.
    int unresolved = dependencies.length;
    void notifyResolved(ignored) {
      assert(unresolved > 0);
      unresolved--;
    }

    // Register a callback on each of the dependencies.
    for (Promise promise in dependencies) {
      promise.then(notifyResolved);
    }

    final Promise result = new Promise();
    _queue.addLast(() {
      if (unresolved > 0) return false;
      // TODO(kasperl): It seems a bit weird to pass back null. Maybe
      // the resulting promise should be a Promise<bool> that
      // indicates whether or not we successfully got the enqueued
      // element through the queue?
      result.complete(null);
      return true;
    });

    // Before returning the resulting promise, we make sure to process
    // any fully resolved enqueued elements.
    process();
    return result;
  }

  static bool isEmpty() {
    return (_queue === null) ? true : _queue.isEmpty();
  }

  static void process() {
    if (_queue === null) {
      return;
    }
    while (!_queue.isEmpty() && (_queue.first())()) {
      _queue.removeFirst();
    }
  }

  static Queue<Function> _queue;

}

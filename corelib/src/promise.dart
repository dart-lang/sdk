// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

/** A promise to value of type [T] that may be computed asynchronously. */
interface Promise<T> factory PromiseImpl<T> {

  Promise();

  /** A promise that already has a computed value. */
  Promise.fromValue(T value);

  /**
   * The value once it is computed. It will be null when the promise is in
   * progress ([:!isDone():]), when it was cancelled ([:isCancelled():]), or
   * when the computed value is actually null.
   */
  T get value();

  /**
   * Provide the computed value; throws an exception if a value has already been
   * provided or the promise previously completed with an error; ignored if the
   * promise was cancelled.
   */
  void complete(T value);

  /** Error that occurred while computing the value, if any; null otherwise. */
  get error();

  /** Indicate that an error was found while computing this value. */
  void fail(var error);

  /** Whether the asynchronous work is done (normally or with errors). */
  bool isDone();

  /** Whether the work represented by this promise has been cancelled. */
  bool isCancelled();

  /** Whether the work represented by this promise has computed a value. */
  bool hasValue();

  /** Whether the work represented by this promise has finished in an error. */
  bool hasError();

  /** Cancel the asynchronous work of this promise, if possible. */
  bool cancel();

  /** Register a normal continuation to execute when the value is available. */
  void addCompleteHandler(void completeHandler(T result));

  /** Register an error continuation to execute if an error is found. */
  void addErrorHandler(void errorHandler(var error));

  /** Register a handler to execute when [cancel] is called. */
  void addCancelHandler(void cancelHandler());

  /**
   * When this promise completes, execute [callback]. The result of [callback]
   * will be exposed through the returned promise. This promise, and the
   * resulting promise (r) are connected as follows:
   *  - this.complete --> r.complete (with the result of [callback])
   *  - this.error    --> r.error (the same error is propagated to r)
   *  - this.cancel   --> r.error (the cancellation is shown as an error to r)
   *  - r.cancel      --> this continues executing regardless
   */
  Promise then(callback(T value));

  /**
   * Converts this promise so that its result is a non-promise value. For
   * instance, if this promise is of type Promise<Promise<Promise<T>>>,
   * flatten returns a Promise<T>.
   */
  Promise flatten();

  /**
   * Mark this promise as complete when some or all values in [arr] are
   * computed. Every time one of the promises is computed, it is passed to
   * [joinDone]. When [joinDone] returns true, this instance is marked as
   * complete with the last value that was computed.
   */
  void join(Collection<Promise<T>> arr, bool joinDone(Promise<T> completed));

  /**
   * Mark this promise as complete when [n] promises in [arr] complete, then
   * cancel the rest of the promises in [arr] that didn't complete.
   */
  void waitFor(Collection<Promise> arr, int n);
}


interface Proxy factory ProxyImpl {

  Proxy.forPort(SendPort port);
  Proxy.forIsolate(Isolate isolate);
  Proxy._forIsolateWithPromise(Isolate isolate, Promise<SendPort> promise);
  /*
   * The [Proxy.forReply] constructor is used to create a proxy for
   * the object that will be the reply to a message send.
   */
  Proxy.forReply(Promise<SendPort> port);

}


class ProxyImpl extends ProxyBase implements Proxy {

  ProxyImpl.forPort(SendPort port)
      : super.forPort(port) { }

  ProxyImpl.forIsolate(Isolate isolate)
      : this._forIsolateWithPromise(isolate, new Promise<SendPort>());

  ProxyImpl._forIsolateWithPromise(Isolate isolate, Promise<SendPort> promise)
      // TODO(floitsch): it seems wrong to call super.forReply here.
      : super.forReply(promise) {
    isolate.spawn().then((SendPort port) {
      promise.complete(port);
    });
  }

  /*
   * The [Proxy.forReply] constructor is used to create a proxy for
   * the object that will be the reply to a message send.
   */
  ProxyImpl.forReply(Promise<SendPort> port)
      : super.forReply(port) { }

}


class Dispatcher<T> {

  Dispatcher(this.target) { }

  void _serve(ReceivePort port) {
    port.receive((var message, SendPort replyTo) {
      this.process(message, void reply(var response) {
        Proxy proxy = new Proxy.forPort(replyTo);
        proxy.send([response]);
      });
    });
  }

  static SendPort serve(Dispatcher dispatcher) {
    ReceivePort port = ProxyBase.register(dispatcher);
    dispatcher._serve(port);
    return port.toSendPort();
  }

  // BUG(5015671): DartC doesn't support 'abstract' yet.
  /* abstract */ void process(var message, void reply(var response)) {
    throw "Abstract method called";
  }

  T target;

}

// When a promise is sent across a port, it is converted to a
// Promise<SendPort> down which we must send a port to receive the
// completion value. Hand the Promise<SendPort> to this class to deal
// with it.

class PromiseProxy<T> extends PromiseImpl<T> {
  PromiseProxy(Promise<SendPort> sendCompleter) {
    ReceivePort completer = new ReceivePort.singleShot();
    completer.receive((var msg, SendPort _) {
      complete(msg[0]);
    });
    sendCompleter.addCompleteHandler((SendPort port) {
      port.send([completer.toSendPort()], null);
    });
  }
}

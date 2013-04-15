// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

// -------------------------------------------------------------------
// Core Stream types
// -------------------------------------------------------------------

/**
 * A source of asynchronous data events.
 *
 * A Stream provides a sequence of events. Each event is either a data event or
 * an error event, representing the result of a single computation. When the
 * Stream is exhausted, it may send a single "done" event.
 *
 * You can [listen] on a stream to receive the events it sends. When you listen,
 * you receive a [StreamSubscription] object that can be used to stop listening,
 * or to temporarily pause events from the stream.
 *
 * When an event is fired, the listeners at that time are informed.
 * If a listener is added while an event is being fired, the change
 * will only take effect after the event is completely fired. If a listener
 * is canceled, it immediately stops receiving events.
 *
 * When the "done" event is fired, subscribers are unsubscribed before
 * receiving the event. After the event has been sent, the stream has no
 * subscribers. Adding new subscribers after this point is allowed, but
 * they will just receive a new "done" event as soon as possible.
 *
 * Streams always respect "pause" requests. If necessary they need to buffer
 * their input, but often, and preferably, they can simply request their input
 * to pause too.
 *
 * There are two kinds of streams: The normal "single-subscription" streams and
 * "broadcast" streams.
 *
 * A single-subscription stream allows only a single listener at a time.
 * It holds back events until it gets a listener, and it may exhaust
 * itself when the listener is unsubscribed, even if the stream wasn't done.
 *
 * Single-subscription streams are generally used for streaming parts of
 * contiguous data like file I/O.
 *
 * A broadcast stream allows any number of listeners, and it fires
 * its events when they are ready, whether there are listeners or not.
 *
 * Broadcast streams are used for independent events/observers.
 *
 * The default implementation of [isBroadcast] returns false.
 * A broadcast stream inheriting from [Stream] must override [isBroadcast]
 * to return [:true:].
 */
abstract class Stream<T> {
  Stream();

  /**
   * Creates a new single-subscription stream from the future.
   *
   * When the future completes, the stream will fire one event, either
   * data or error, and then close with a done-event.
   */
  factory Stream.fromFuture(Future<T> future) {
    _StreamImpl<T> stream = new _SingleStreamImpl<T>();
    future.then((value) {
        stream._add(value);
        stream._close();
      },
      onError: (error) {
        stream._addError(error);
        stream._close();
      });
    return stream;
  }

  /**
   * Creates a single-subscription stream that gets its data from [data].
   */
  factory Stream.fromIterable(Iterable<T> data) {
    _PendingEvents iterableEvents = new _IterablePendingEvents<T>(data);
    return new _GeneratedSingleStreamImpl<T>(iterableEvents);
  }

  /**
   * Creates a stream that repeatedly emits events at [period] intervals.
   *
   * The event values are computed by invoking [computation]. The argument to
   * this callback is an integer that starts with 0 and is incremented for
   * every event.
   *
   * If [computation] is omitted the event values will all be `null`.
   */
  factory Stream.periodic(Duration period,
                          [T computation(int computationCount)]) {
    if (computation == null) computation = ((i) => null);

    Timer timer;
    int computationCount = 0;
    StreamController<T> controller;
    // Counts the time that the Stream was running (and not paused).
    Stopwatch watch = new Stopwatch();

    void sendEvent() {
      watch.reset();
      T data = computation(computationCount++);
      controller.add(data);
    }

    void startPeriodicTimer() {
      assert(timer == null);
      timer = new Timer.periodic(period, (Timer timer) {
        sendEvent();
      });
    }

    controller = new StreamController<T>(
        onListen: () {
          watch.start();
          startPeriodicTimer();
        },
        onPause: () {
          timer.cancel();
          timer = null;
          watch.stop();
        },
        onResume: () {
          assert(timer == null);
          Duration elapsed = watch.elapsed;
          watch.start();
          timer = new Timer(period - elapsed, () {
            timer = null;
            startPeriodicTimer();
            sendEvent();
          });
        },
        onCancel: () {
          if (timer != null) timer.cancel();
          timer = null;
        });
    return controller.stream;
  }

  /**
   * Reports whether this stream is a broadcast stream.
   */
  bool get isBroadcast => false;

  /**
   * Returns a multi-subscription stream that produces the same events as this.
   *
   * If this stream is single-subscription, return a new stream that allows
   * multiple subscribers. It will subscribe to this stream when its first
   * subscriber is added, and unsubscribe again when the last subscription is
   * cancelled.
   *
   * If this stream is already a broadcast stream, it is returned unmodified.
   */
  Stream<T> asBroadcastStream() {
    if (isBroadcast) return this;
    return new _SingleStreamMultiplexer<T>(this);
  }

  /**
   * Adds a subscription to this stream.
   *
   * On each data event from this stream, the subscriber's [onData] handler
   * is called. If [onData] is null, nothing happens.
   *
   * On errors from this stream, the [onError] handler is given a
   * object describing the error.
   *
   * If this stream closes, the [onDone] handler is called.
   *
   * If [cancelOnError] is true, the subscription is ended when
   * the first error is reported. The default is false.
   */
  StreamSubscription<T> listen(void onData(T event),
                               { void onError(error),
                                 void onDone(),
                                 bool cancelOnError});

  /**
   * Creates a new stream from this stream that discards some data events.
   *
   * The new stream sends the same error and done events as this stream,
   * but it only sends the data events that satisfy the [test].
   */
  Stream<T> where(bool test(T event)) {
    return new _WhereStream<T>(this, test);
  }

  /**
   * Creates a new stream that converts each element of this stream
   * to a new value using the [convert] function.
   */
  Stream map(convert(T event)) {
    return new _MapStream<T, dynamic>(this, convert);
  }

  /**
   * Creates a wrapper Stream that intercepts some errors from this stream.
   *
   * If this stream sends an error that matches [test], then it is intercepted
   * by the [handle] function.
   *
   * An [AsyncError] [:e:] is matched by a test function if [:test(e):] returns
   * true. If [test] is omitted, every error is considered matching.
   *
   * If the error is intercepted, the [handle] function can decide what to do
   * with it. It can throw if it wants to raise a new (or the same) error,
   * or simply return to make the stream forget the error.
   *
   * If you need to transform an error into a data event, use the more generic
   * [Stream.transformEvent] to handle the event by writing a data event to
   * the output sink
   */
  Stream<T> handleError(void handle( error), { bool test(error) }) {
    return new _HandleErrorStream<T>(this, handle, test);
  }

  /**
   * Creates a new stream from this stream that converts each element
   * into zero or more events.
   *
   * Each incoming event is converted to an [Iterable] of new events,
   * and each of these new events are then sent by the returned stream
   * in order.
   */
  Stream expand(Iterable convert(T value)) {
    return new _ExpandStream<T, dynamic>(this, convert);
  }

  /**
   * Binds this stream as the input of the provided [StreamConsumer].
   */
  Future pipe(StreamConsumer<T> streamConsumer) {
    return streamConsumer.addStream(this).then((_) => streamConsumer.close());
  }

  /**
   * Chains this stream as the input of the provided [StreamTransformer].
   *
   * Returns the result of [:streamTransformer.bind:] itself.
   */
  Stream transform(StreamTransformer<T, dynamic> streamTransformer) {
    return streamTransformer.bind(this);
  }

  /**
   * Reduces a sequence of values by repeatedly applying [combine].
   */
  Future<T> reduce(T combine(T previous, T element)) {
    _FutureImpl<T> result = new _FutureImpl<T>();
    bool seenFirst = false;
    T value;
    StreamSubscription subscription;
    subscription = this.listen(
      // TODO(ahe): Restore type when feature is implemented in dart2js
      // checked mode. http://dartbug.com/7733
      (/* T */ element) {
        if (seenFirst) {
          _runUserCode(() => combine(value, element),
                       (T newValue) { value = newValue; },
                       _cancelAndError(subscription, result));
        } else {
          value = element;
          seenFirst = true;
        }
      },
      onError: result._setError,
      onDone: () {
        if (!seenFirst) {
          result._setError(new StateError("No elements"));
        } else {
          result._setValue(value);
        }
      },
      cancelOnError: true
    );
    return result;
  }

  /** Reduces a sequence of values by repeatedly applying [combine]. */
  Future fold(var initialValue, combine(var previous, T element)) {
    _FutureImpl result = new _FutureImpl();
    var value = initialValue;
    StreamSubscription subscription;
    subscription = this.listen(
      // TODO(ahe): Restore type when feature is implemented in dart2js
      // checked mode. http://dartbug.com/7733
      (/*T*/ element) {
        _runUserCode(
          () => combine(value, element),
          (newValue) { value = newValue; },
          _cancelAndError(subscription, result)
        );
      },
      onError: (e) {
        result._setError(e);
      },
      onDone: () {
        result._setValue(value);
      },
      cancelOnError: true);
    return result;
  }

  /**
   * Checks whether [match] occurs in the elements provided by this stream.
   *
   * Completes the [Future] when the answer is known.
   * If this stream reports an error, the [Future] will report that error.
   */
  Future<bool> contains(T match) {
    _FutureImpl<bool> future = new _FutureImpl<bool>();
    StreamSubscription subscription;
    subscription = this.listen(
        // TODO(ahe): Restore type when feature is implemented in dart2js
        // checked mode. http://dartbug.com/7733
        (/*T*/ element) {
          _runUserCode(
            () => (element == match),
            (bool isMatch) {
              if (isMatch) {
                subscription.cancel();
                future._setValue(true);
              }
            },
            _cancelAndError(subscription, future)
          );
        },
        onError: future._setError,
        onDone: () {
          future._setValue(false);
        },
        cancelOnError: true);
    return future;
  }

  /**
   * Checks whether [test] accepts all elements provided by this stream.
   *
   * Completes the [Future] when the answer is known.
   * If this stream reports an error, the [Future] will report that error.
   */
  Future<bool> every(bool test(T element)) {
    _FutureImpl<bool> future = new _FutureImpl<bool>();
    StreamSubscription subscription;
    subscription = this.listen(
        // TODO(ahe): Restore type when feature is implemented in dart2js
        // checked mode. http://dartbug.com/7733
        (/*T*/ element) {
          _runUserCode(
            () => test(element),
            (bool isMatch) {
              if (!isMatch) {
                subscription.cancel();
                future._setValue(false);
              }
            },
            _cancelAndError(subscription, future)
          );
        },
        onError: future._setError,
        onDone: () {
          future._setValue(true);
        },
        cancelOnError: true);
    return future;
  }

  /**
   * Checks whether [test] accepts any element provided by this stream.
   *
   * Completes the [Future] when the answer is known.
   * If this stream reports an error, the [Future] will report that error.
   */
  Future<bool> any(bool test(T element)) {
    _FutureImpl<bool> future = new _FutureImpl<bool>();
    StreamSubscription subscription;
    subscription = this.listen(
        // TODO(ahe): Restore type when feature is implemented in dart2js
        // checked mode. http://dartbug.com/7733
        (/*T*/ element) {
          _runUserCode(
            () => test(element),
            (bool isMatch) {
              if (isMatch) {
                subscription.cancel();
                future._setValue(true);
              }
            },
            _cancelAndError(subscription, future)
          );
        },
        onError: future._setError,
        onDone: () {
          future._setValue(false);
        },
        cancelOnError: true);
    return future;
  }


  /** Counts the elements in the stream. */
  Future<int> get length {
    _FutureImpl<int> future = new _FutureImpl<int>();
    int count = 0;
    this.listen(
      (_) { count++; },
      onError: future._setError,
      onDone: () {
        future._setValue(count);
      },
      cancelOnError: true);
    return future;
  }

  /** Reports whether this stream contains any elements. */
  Future<bool> get isEmpty {
    _FutureImpl<bool> future = new _FutureImpl<bool>();
    StreamSubscription subscription;
    subscription = this.listen(
      (_) {
        subscription.cancel();
        future._setValue(false);
      },
      onError: future._setError,
      onDone: () {
        future._setValue(true);
      },
      cancelOnError: true);
    return future;
  }

  /** Collects the data of this stream in a [List]. */
  Future<List<T>> toList() {
    List<T> result = <T>[];
    _FutureImpl<List<T>> future = new _FutureImpl<List<T>>();
    this.listen(
      // TODO(ahe): Restore type when feature is implemented in dart2js
      // checked mode. http://dartbug.com/7733
      (/*T*/ data) {
        result.add(data);
      },
      onError: future._setError,
      onDone: () {
        future._setValue(result);
      },
      cancelOnError: true);
    return future;
  }

  /** Collects the data of this stream in a [Set]. */
  Future<Set<T>> toSet() {
    Set<T> result = new Set<T>();
    _FutureImpl<Set<T>> future = new _FutureImpl<Set<T>>();
    this.listen(
      // TODO(ahe): Restore type when feature is implemented in dart2js
      // checked mode. http://dartbug.com/7733
      (/*T*/ data) {
        result.add(data);
      },
      onError: future._setError,
      onDone: () {
        future._setValue(result);
      },
      cancelOnError: true);
    return future;
  }

  /**
   * Provides at most the first [n] values of this stream.
   *
   * Forwards the first [n] data events of this stream, and all error
   * events, to the returned stream, and ends with a done event.
   *
   * If this stream produces fewer than [count] values before it's done,
   * so will the returned stream.
   */
  Stream<T> take(int count) {
    return new _TakeStream(this, count);
  }

  /**
   * Forwards data events while [test] is successful.
   *
   * The returned stream provides the same events as this stream as long
   * as [test] returns [:true:] for the event data. The stream is done
   * when either this stream is done, or when this stream first provides
   * a value that [test] doesn't accept.
   */
  Stream<T> takeWhile(bool test(T value)) {
    return new _TakeWhileStream(this, test);
  }

  /**
   * Skips the first [count] data events from this stream.
   */
  Stream<T> skip(int count) {
    return new _SkipStream(this, count);
  }

  /**
   * Skip data events from this stream while they are matched by [test].
   *
   * Error and done events are provided by the returned stream unmodified.
   *
   * Starting with the first data event where [test] returns true for the
   * event data, the returned stream will have the same events as this stream.
   */
  Stream<T> skipWhile(bool test(T value)) {
    return new _SkipWhileStream(this, test);
  }

  /**
   * Skips data events if they are equal to the previous data event.
   *
   * The returned stream provides the same events as this stream, except
   * that it never provides two consequtive data events that are equal.
   *
   * Equality is determined by the provided [equals] method. If that is
   * omitted, the '==' operator on the last provided data element is used.
   */
  Stream<T> distinct([bool equals(T previous, T next)]) {
    return new _DistinctStream(this, equals);
  }

  /**
   * Returns the first element.
   *
   * If [this] is empty throws a [StateError]. Otherwise this method is
   * equivalent to [:this.elementAt(0):]
   */
  Future<T> get first {
    _FutureImpl<T> future = new _FutureImpl<T>();
    StreamSubscription subscription;
    subscription = this.listen(
      // TODO(ahe): Restore type when feature is implemented in dart2js
      // checked mode. http://dartbug.com/7733
      (/*T*/ value) {
        subscription.cancel();
        future._setValue(value);
        return;
      },
      onError: future._setError,
      onDone: () {
        future._setError(new StateError("No elements"));
      },
      cancelOnError: true);
    return future;
  }

  /**
   * Returns the last element.
   *
   * If [this] is empty throws a [StateError].
   */
  Future<T> get last {
    _FutureImpl<T> future = new _FutureImpl<T>();
    T result = null;
    bool foundResult = false;
    StreamSubscription subscription;
    subscription = this.listen(
      // TODO(ahe): Restore type when feature is implemented in dart2js
      // checked mode. http://dartbug.com/7733
      (/*T*/ value) {
        foundResult = true;
        result = value;
      },
      onError: future._setError,
      onDone: () {
        if (foundResult) {
          future._setValue(result);
          return;
        }
        future._setError(new StateError("No elements"));
      },
      cancelOnError: true);
    return future;
  }

  /**
   * Returns the single element.
   *
   * If [this] is empty or has more than one element throws a [StateError].
   */
  Future<T> get single {
    _FutureImpl<T> future = new _FutureImpl<T>();
    T result = null;
    bool foundResult = false;
    StreamSubscription subscription;
    subscription = this.listen(
      // TODO(ahe): Restore type when feature is implemented in dart2js
      // checked mode. http://dartbug.com/7733
      (/*T*/ value) {
        if (foundResult) {
          subscription.cancel();
          // This is the second element we get.
          Error error = new StateError("More than one element");
          future._setError(error);
          return;
        }
        foundResult = true;
        result = value;
      },
      onError: future._setError,
      onDone: () {
        if (foundResult) {
          future._setValue(result);
          return;
        }
        future._setError(new StateError("No elements"));
      },
      cancelOnError: true);
    return future;
  }

  /**
   * Finds the first element of this stream matching [test].
   *
   * Returns a future that is filled with the first element of this stream
   * that [test] returns true for.
   *
   * If no such element is found before this stream is done, and a
   * [defaultValue] function is provided, the result of calling [defaultValue]
   * becomes the value of the future.
   *
   * If an error occurs, or if this stream ends without finding a match and
   * with no [defaultValue] function provided, the future will receive an
   * error.
   */
  Future<T> firstWhere(bool test(T value), {T defaultValue()}) {
    _FutureImpl<T> future = new _FutureImpl<T>();
    StreamSubscription subscription;
    subscription = this.listen(
      // TODO(ahe): Restore type when feature is implemented in dart2js
      // checked mode. http://dartbug.com/7733
      (/*T*/ value) {
        _runUserCode(
          () => test(value),
          (bool isMatch) {
            if (isMatch) {
              subscription.cancel();
              future._setValue(value);
            }
          },
          _cancelAndError(subscription, future)
        );
      },
      onError: future._setError,
      onDone: () {
        if (defaultValue != null) {
          _runUserCode(defaultValue, future._setValue, future._setError);
          return;
        }
        future._setError(new StateError("firstMatch ended without match"));
      },
      cancelOnError: true);
    return future;
  }

  /**
   * Finds the last element in this stream matching [test].
   *
   * As [firstWhere], except that the last matching element is found.
   * That means that the result cannot be provided before this stream
   * is done.
   */
  Future<T> lastWhere(bool test(T value), {T defaultValue()}) {
    _FutureImpl<T> future = new _FutureImpl<T>();
    T result = null;
    bool foundResult = false;
    StreamSubscription subscription;
    subscription = this.listen(
      // TODO(ahe): Restore type when feature is implemented in dart2js
      // checked mode. http://dartbug.com/7733
      (/*T*/ value) {
        _runUserCode(
          () => true == test(value),
          (bool isMatch) {
            if (isMatch) {
              foundResult = true;
              result = value;
            }
          },
          _cancelAndError(subscription, future)
        );
      },
      onError: future._setError,
      onDone: () {
        if (foundResult) {
          future._setValue(result);
          return;
        }
        if (defaultValue != null) {
          _runUserCode(defaultValue, future._setValue, future._setError);
          return;
        }
        future._setError(new StateError("lastMatch ended without match"));
      },
      cancelOnError: true);
    return future;
  }

  /**
   * Finds the single element in this stream matching [test].
   *
   * Like [lastMatch], except that it is an error if more than one
   * matching element occurs in the stream.
   */
  Future<T> singleWhere(bool test(T value)) {
    _FutureImpl<T> future = new _FutureImpl<T>();
    T result = null;
    bool foundResult = false;
    StreamSubscription subscription;
    subscription = this.listen(
      // TODO(ahe): Restore type when feature is implemented in dart2js
      // checked mode. http://dartbug.com/7733
      (/*T*/ value) {
        _runUserCode(
          () => true == test(value),
          (bool isMatch) {
            if (isMatch) {
              if (foundResult) {
                subscription.cancel();
                future._setError(
                    new StateError('Multiple matches for "single"'));
                return;
              }
              foundResult = true;
              result = value;
            }
          },
          _cancelAndError(subscription, future)
        );
      },
      onError: future._setError,
      onDone: () {
        if (foundResult) {
          future._setValue(result);
          return;
        }
        future._setError(new StateError("single ended without match"));
      },
      cancelOnError: true);
    return future;
  }

  /**
   * Returns the value of the [index]th data event of this stream.
   *
   * If an error event occurs, the future will end with this error.
   *
   * If this stream provides fewer than [index] elements before closing,
   * an error is reported.
   */
  Future<T> elementAt(int index) {
    if (index is! int || index < 0) throw new ArgumentError(index);
    _FutureImpl<T> future = new _FutureImpl<T>();
    StreamSubscription subscription;
    subscription = this.listen(
      // TODO(ahe): Restore type when feature is implemented in dart2js
      // checked mode. http://dartbug.com/7733
      (/*T*/ value) {
        if (index == 0) {
          subscription.cancel();
          future._setValue(value);
          return;
        }
        index -= 1;
      },
      onError: future._setError,
      onDone: () {
        future._setError(new StateError("Not enough elements for elementAt"));
      },
      cancelOnError: true);
    return future;
  }
}

/**
 * A control object for the subscription on a [Stream].
 *
 * When you subscribe on a [Stream] using [Stream.listen],
 * a [StreamSubscription] object is returned. This object
 * is used to later unsubscribe again, or to temporarily pause
 * the stream's events.
 */
abstract class StreamSubscription<T> {
  /**
   * Cancels this subscription. It will no longer receive events.
   *
   * If an event is currently firing, this unsubscription will only
   * take effect after all subscribers have received the current event.
   */
  void cancel();

  /** Set or override the data event handler of this subscription. */
  void onData(void handleData(T data));

  /** Set or override the error event handler of this subscription. */
  void onError(void handleError(error));

  /** Set or override the done event handler of this subscription. */
  void onDone(void handleDone());

  /**
   * Request that the stream pauses events until further notice.
   *
   * If [resumeSignal] is provided, the stream will undo the pause
   * when the future completes. If the future completes with an error,
   * it will not be handled!
   *
   * A call to [resume] will also undo a pause.
   *
   * If the subscription is paused more than once, an equal number
   * of resumes must be performed to resume the stream.
   */
  void pause([Future resumeSignal]);

  /**
   * Resume after a pause.
   */
  void resume();

  /**
   * Returns a future that handles the [onDone] and [onError] callbacks.
   *
   * This method *overwrites* the existing [onDone] and [onError] callbacks
   * with new ones that complete the returned future.
   *
   * In case of an error the subscription will automatically cancel (even
   * when it was listening with `cancelOnError` set to `false`).
   *
   * In case of a `done` event the future completes with the given
   * [futureValue].
   */
  Future asFuture([var futureValue]);
}


/**
 * An interface that abstracts creation or handling of [Stream] events.
 */
abstract class EventSink<T> {
  /** Create a data event */
  void add(T event);
  /** Create an async error. */
  void addError(errorEvent);
  /** Request a stream to close. */
  void close();
}


/** [Stream] wrapper that only exposes the [Stream] interface. */
class StreamView<T> extends Stream<T> {
  Stream<T> _stream;

  StreamView(this._stream);

  bool get isBroadcast => _stream.isBroadcast;

  Stream<T> asBroadcastStream() => _stream.asBroadcastStream();

  StreamSubscription<T> listen(void onData(T value),
                               { void onError(error),
                                 void onDone(),
                                 bool cancelOnError }) {
    return _stream.listen(onData, onError: onError, onDone: onDone,
                          cancelOnError: cancelOnError);
  }
}

/**
 * [EventSink] wrapper that only exposes the [EventSink] interface.
 */
class _EventSinkView<T> extends EventSink<T> {
  final EventSink<T> _sink;

  _EventSinkView(this._sink);

  void add(T value) { _sink.add(value); }
  void addError(error) { _sink.addError(error); }
  void close() { _sink.close(); }
}


/**
 * The target of a [Stream.pipe] call.
 *
 * The [Stream.pipe] call will pass itself to this object, and then return
 * the resulting [Future]. The pipe should complete the future when it's
 * done.
 */
abstract class StreamConsumer<S> {
  Future addStream(Stream<S> stream);
  Future close();
}


/**
 * A [StreamSink] unifies the asynchronous methods from [StreamConsumer<S>] and
 * the synchronous methods from [EventSink<S>].
 *
 * The [EventSink<S>] methods can't be used while the [addStream] is called.
 * As soon as the [addStream]'s [Future] completes with a value, the
 * [EventSink<S>] methods can be used again.
 *
 * If [addStream] is called after any of the [EventSink<S>] methods, it'll
 * be delayed until the underlying system has consumed the data added by the
 * [EventSink<S>] methods.
 *
 * When [EventSink<S>] methods are used, the [done] [Future] can be used to
 * catch any errors.
 *
 * When [close] is called, it will return the [done] [Future].
 */
abstract class StreamSink<S> implements StreamConsumer<S>, EventSink<S> {
  /**
   * Close the [StreamSink<S>]. It'll return the [done] Future.
   */
  Future close();

  /**
   * The [done] Future completes with the same values as [close], except
   * for the following case:
   *
   * * The synchronous methods of [EventSink<S>] were called, resulting in an
   *   error. If there is no active future (like from an addStream call), the
   *   [done] future will complete with that error
   */
  Future get done;
}


/**
 * The target of a [Stream.transform] call.
 *
 * The [Stream.transform] call will pass itself to this object and then return
 * the resulting stream.
 */
abstract class StreamTransformer<S, T> {
  /**
   * Create a [StreamTransformer] that delegates events to the given functions.
   *
   * This is actually a [StreamEventTransformer] where the event handling is
   * performed by the function arguments.
   * If an argument is omitted, it acts as the corresponding default method from
   * [StreamEventTransformer].
   *
   * Example use:
   *
   *     stringStream.transform(new StreamTransformer<String, String>(
   *         handleData: (Strung value, EventSink<String> sink) {
   *           sink.add(value);
   *           sink.add(value);  // Duplicate the incoming events.
   *         }));
   *
   */
  factory StreamTransformer({
      void handleData(S data, EventSink<T> sink),
      void handleError(error, EventSink<T> sink),
      void handleDone(EventSink<T> sink)}) {
    return new _StreamTransformerImpl<S, T>(handleData,
                                            handleError,
                                            handleDone);
  }

  Stream<T> bind(Stream<S> stream);
}


/**
 * Base class for transformers that modifies stream events.
 *
 * A [StreamEventTransformer] transforms incoming Stream
 * events of one kind into outgoing events of (possibly) another kind.
 *
 * Subscribing on the stream returned by [bind] is the same as subscribing on
 * the source stream, except that events are passed through the [transformer]
 * before being emitted. The transformer may generate any number and
 * types of events for each incoming event. Pauses on the returned
 * subscription are forwarded to this stream.
 *
 * An example that duplicates all data events:
 *
 *     class DoubleTransformer<T> extends StreamEventTransformerBase<T, T> {
 *       void handleData(T data, EventSink<T> sink) {
 *         sink.add(value);
 *         sink.add(value);
 *       }
 *     }
 *     someTypeStream.transform(new DoubleTransformer<Type>());
 *
 * The default implementations of the "handle" methods forward
 * the events unmodified. If using the default [handleData] the generic type [T]
 * needs to be assignable to [S].
 */
abstract class StreamEventTransformer<S, T> implements StreamTransformer<S, T> {
  const StreamEventTransformer();

  Stream<T> bind(Stream<S> source) {
    // Hackish way of buffering data that goes out of the event-transformer.
    // TODO(floitsch): replace this with a correct solution.
    Stream transformingStream = new EventTransformStream<S, T>(source, this);
    StreamController controller;
    StreamSubscription subscription;
    controller = new StreamController<T>(
        onListen: () {
          subscription = transformingStream.listen(
              controller.add,
              onError: controller.addError,
              onDone: controller.close);
        },
        onPause: () => subscription.pause(),
        onResume: () => subscription.resume(),
        onCancel: () => subscription.cancel());
    return controller.stream;
  }

  /**
   * Act on incoming data event.
   *
   * The method may generate any number of events on the sink, but should
   * not throw.
   */
  void handleData(S event, EventSink<T> sink) {
    var data = event;
    sink.add(data);
  }

  /**
   * Act on incoming error event.
   *
   * The method may generate any number of events on the sink, but should
   * not throw.
   */
  void handleError(error, EventSink<T> sink) {
    sink.addError(error);
  }

  /**
   * Act on incoming done event.
   *
   * The method may generate any number of events on the sink, but should
   * not throw.
   */
  void handleDone(EventSink<T> sink){
    sink.close();
  }
}


/**
 * Stream that transforms another stream by intercepting and replacing events.
 *
 * This [Stream] is a transformation of a source stream. Listening on this
 * stream is the same as listening on the source stream, except that events
 * are intercepted and modified by a [StreamEventTransformer] before becoming
 * events on this stream.
 */
class EventTransformStream<S, T> extends Stream<T> {
  final Stream<S> _source;
  final StreamEventTransformer _transformer;
  EventTransformStream(Stream<S> source,
                       StreamEventTransformer<S, T> transformer)
      : _source = source, _transformer = transformer;

  StreamSubscription<T> listen(void onData(T data),
                               { void onError(error),
                                 void onDone(),
                                 bool cancelOnError }) {
    cancelOnError = identical(true, cancelOnError);
    return new _EventTransformStreamSubscription(_source, _transformer,
                                                 onData, onError, onDone,
                                                 cancelOnError);
  }
}

class _EventTransformStreamSubscription<S, T>
    extends _BaseStreamSubscription<T>
    implements _EventOutputSink<T> {
  /** The transformer used to transform events. */
  final StreamEventTransformer<S, T> _transformer;
  /** Whether to unsubscribe when emitting an error. */
  final bool _cancelOnError;
  /** Whether this stream has sent a done event. */
  bool _isClosed = false;
  /** Source of incoming events. */
  StreamSubscription<S> _subscription;
  /** Cached EventSink wrapper for this class. */
  EventSink<T> _sink;

  _EventTransformStreamSubscription(Stream<S> source,
                                    this._transformer,
                                    void onData(T data),
                                    void onError(error),
                                    void onDone(),
                                    this._cancelOnError)
      : super(onData, onError, onDone) {
    _sink = new _EventOutputSinkWrapper<T>(this);
    _subscription = source.listen(_handleData,
                                  onError: _handleError,
                                  onDone: _handleDone);
  }

  /** Whether this subscription is still subscribed to its source. */
  bool get _isSubscribed => _subscription != null;

  void pause([Future pauseSignal]) {
    if (_isSubscribed) _subscription.pause(pauseSignal);
  }

  void resume() {
    if (_isSubscribed) _subscription.resume();
  }

  void cancel() {
    if (_isSubscribed) {
      StreamSubscription subscription = _subscription;
      _subscription = null;
      subscription.cancel();
    }
    _isClosed = true;
  }

  void _handleData(S data) {
    try {
      _transformer.handleData(data, _sink);
    } catch (e, s) {
      _sendError(_asyncError(e, s));
    }
  }

  void _handleError(error) {
    try {
      _transformer.handleError(error, _sink);
    } catch (e, s) {
      _sendError(_asyncError(e, s));
    }
  }

  void _handleDone() {
    try {
      _subscription = null;
      _transformer.handleDone(_sink);
    } catch (e, s) {
      _sendError(_asyncError(e, s));
    }
  }

  // EventOutputSink interface.
  void _sendData(T data) {
    if (_isClosed) return;
    _onData(data);
  }

  void _sendError(error) {
    if (_isClosed) return;
    _onError(error);
    if (_cancelOnError) {
      cancel();
    }
  }

  void _sendDone() {
    if (_isClosed) throw new StateError("Already closed.");
    _isClosed = true;
    if (_isSubscribed) {
      _subscription.cancel();
      _subscription = null;
    }
    _onDone();
  }
}

class _EventOutputSinkWrapper<T> extends EventSink<T> {
  _EventOutputSink _sink;
  _EventOutputSinkWrapper(this._sink);

  void add(T data) { _sink._sendData(data); }
  void addError(error) { _sink._sendError(error); }
  void close() { _sink._sendDone(); }
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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
 * If a listener is added or removed while an event is being fired, the change
 * will only take effect after the event is completely fired.
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
        stream._signalError(error);
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
   * Whether the stream is a broadcast stream.
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
   * Add a subscription to this stream.
   *
   * On each data event from this stream, the subscribers [onData] handler
   * is called. If [onData] is null, nothing happens.
   *
   * On errors from this stream, the [onError] handler is given a
   * [AsyncError] object describing the error.
   *
   * If this stream closes, the [onDone] handler is called.
   *
   * If [unsubscribeOnError] is true, the subscription is ended when
   * the first error is reported. The default is false.
   */
  StreamSubscription<T> listen(void onData(T event),
                               { void onError(AsyncError error),
                                 void onDone(),
                                 bool unsubscribeOnError});

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
   * Create a new stream that converts each element of this stream
   * to a new value using the [convert] function.
   */
  Stream map(convert(T event)) {
    return new _MapStream<T, dynamic>(this, convert);
  }

  /**
   * Deprecated alias for [map].
   *
   * @deprecated
   */
  Stream mappedBy(f(T element)) => map(f);

  /**
   * Create a wrapper Stream that intercepts some errors from this stream.
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
  Stream<T> handleError(void handle(AsyncError error), { bool test(error) }) {
    return new _HandleErrorStream<T>(this, handle, test);
  }

  /**
   * Create a new stream from this stream that converts each element
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
   * Bind this stream as the input of the provided [StreamConsumer].
   */
  Future pipe(StreamConsumer<T, dynamic> streamConsumer) {
    return streamConsumer.consume(this);
  }

  /**
   * Chain this stream as the input of the provided [StreamTransformer].
   *
   * Returns the result of [:streamTransformer.bind:] itself.
   */
  Stream transform(StreamTransformer<T, dynamic> streamTransformer) {
    return streamTransformer.bind(this);
  }

  /** Reduces a sequence of values by repeatedly applying [combine]. */
  Future reduce(var initialValue, combine(var previous, T element)) {
    _FutureImpl result = new _FutureImpl();
    var value = initialValue;
    StreamSubscription subscription;
    subscription = this.listen(
      // TODO(ahe): Restore type when feature is implemented in dart2js
      // checked mode. http://dartbug.com/7733
      (/*T*/ element) {
        _runUserCode(
          () => combine(value, element),
          (result) { value = result; },
          _cancelAndError(subscription, result)
        );
      },
      onError: (AsyncError e) {
        result._setError(e);
      },
      onDone: () {
        result._setValue(value);
      },
      unsubscribeOnError: true);
    return result;
  }

  // Deprecated method, previously called 'pipe', retained for compatibility.
  Future pipeInto(Sink<T> sink,
                  {void onError(AsyncError error),
                   bool unsubscribeOnError}) {
    _FutureImpl<T> result = new _FutureImpl<T>();
    this.listen(
        sink.add,
        onError: onError,
        onDone: () {
          sink.close();
          result._setValue(null);
        },
        unsubscribeOnError: unsubscribeOnError);
    return result;
  }


  /**
   * Check whether [match] occurs in the elements provided by this stream.
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
        unsubscribeOnError: true);
    return future;
  }

  /**
   * Check whether [test] accepts all elements provided by this stream.
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
        unsubscribeOnError: true);
    return future;
  }

  /**
   * Check whether [test] accepts any element provided by this stream.
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
        unsubscribeOnError: true);
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
      unsubscribeOnError: true);
    return future;
  }

  /**
   * Finds the least element in the stream.
   *
   * If the stream is empty, the result is [:null:].
   * Otherwise the result is a value from the stream that is not greater
   * than any other value from the stream (according to [compare], which must
   * be a [Comparator]).
   *
   * If [compare] is omitted, it defaults to [Comparable.compare].
   */
  Future<T> min([int compare(T a, T b)]) {
    if (compare == null) {
      var defaultCompare = Comparable.compare;
      compare = defaultCompare;
    }
    _FutureImpl<T> future = new _FutureImpl<T>();
    StreamSubscription subscription;
    T min = null;
    subscription = this.listen(
      // TODO(ahe): Restore type when feature is implemented in dart2js
      // checked mode. http://dartbug.com/7733
      (/*T*/ value) {
        min = value;
        subscription.onData((T value) {
          _runUserCode(
            () => compare(min, value) > 0,
            (bool foundSmaller) {
              if (foundSmaller) {
                min = value;
              }
            },
            _cancelAndError(subscription, future)
          );
        });
      },
      onError: future._setError,
      onDone: () {
        future._setValue(min);
      },
      unsubscribeOnError: true
    );
    return future;
  }

  /**
   * Finds the largest element in the stream.
   *
   * If the stream is empty, the result is [:null:].
   * Otherwise the result is an value from the stream that is not smaller
   * than any other value from the stream (according to [compare], which must
   * be a [Comparator]).
   *
   * If [compare] is omitted, it defaults to [Comparable.compare].
   */
  Future<T> max([int compare(T a, T b)]) {
    if (compare == null)  {
      var defaultCompare = Comparable.compare;
      compare = defaultCompare;
    }
    _FutureImpl<T> future = new _FutureImpl<T>();
    StreamSubscription subscription;
    T max = null;
    subscription = this.listen(
      // TODO(ahe): Restore type when feature is implemented in dart2js
      // checked mode. http://dartbug.com/7733
      (/*T*/ value) {
        max = value;
        subscription.onData((T value) {
          _runUserCode(
            () => compare(max, value) < 0,
            (bool foundGreater) {
              if (foundGreater) {
                max = value;
              }
            },
            _cancelAndError(subscription, future)
          );
        });
      },
      onError: future._setError,
      onDone: () {
        future._setValue(max);
      },
      unsubscribeOnError: true
    );
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
      unsubscribeOnError: true);
    return future;
  }

  /** Collect the data of this stream in a [List]. */
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
      unsubscribeOnError: true);
    return future;
  }

  /** Collect the data of this stream in a [Set]. */
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
      unsubscribeOnError: true);
    return future;
  }

  /**
   * Provide at most the first [n] values of this stream.
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
   * Skip data events if they are equal to the previous data event.
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
        future._setValue(value);
        subscription.cancel();
        return;
      },
      onError: future._setError,
      onDone: () {
        future._setError(new AsyncError(new StateError("No elements")));
      },
      unsubscribeOnError: true);
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
        future._setError(new AsyncError(new StateError("No elements")));
      },
      unsubscribeOnError: true);
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
          // This is the second element we get.
          Error error = new StateError("More than one element");
          future._setError(new AsyncError(error));
          subscription.cancel();
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
        future._setError(new AsyncError(new StateError("No elements")));
      },
      unsubscribeOnError: true);
    return future;
  }

  /**
   * Find the first element of this stream matching [test].
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
  Future<T> firstMatching(bool test(T value), {T defaultValue()}) {
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
        future._setError(
            new AsyncError(new StateError("firstMatch ended without match")));
      },
      unsubscribeOnError: true);
    return future;
  }

  /**
   * Finds the last element in this stream matching [test].
   *
   * As [firstMatching], except that the last matching element is found.
   * That means that the result cannot be provided before this stream
   * is done.
   */
  Future<T> lastMatching(bool test(T value), {T defaultValue()}) {
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
        future._setError(
            new AsyncError(new StateError("lastMatch ended without match")));
      },
      unsubscribeOnError: true);
    return future;
  }

  /**
   * Finds the single element in this stream matching [test].
   *
   * Like [lastMatch], except that it is an error if more than one
   * matching element occurs in the stream.
   */
  Future<T> singleMatching(bool test(T value)) {
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
                future._setError(new AsyncError(
                    new StateError('Multiple matches for "single"')));
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
        future._setError(
            new AsyncError(new StateError("single ended without match")));
      },
      unsubscribeOnError: true);
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
          future._setValue(value);
          subscription.cancel();
          return;
        }
        index -= 1;
      },
      onError: future._setError,
      onDone: () {
        future._setError(new AsyncError(
            new StateError("Not enough elements for elementAt")));
      },
      unsubscribeOnError: true);
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
  void onError(void handleError(AsyncError error));

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
}


/**
 * An interface that abstracts sending events into a [Stream].
 */
abstract class StreamSink<T> implements Sink<T> {
  void add(T event);
  /** Signal an async error to the receivers of this sink's values. */
  void signalError(AsyncError errorEvent);
  void close();
}

/** [Stream] wrapper that only exposes the [Stream] interface. */
class StreamView<T> extends Stream<T> {
  Stream<T> _stream;

  StreamView(this._stream);

  bool get isBroadcast => _stream.isBroadcast;

  Stream<T> asBroadcastStream() => _stream.asBroadcastStream();

  StreamSubscription<T> listen(void onData(T value),
                               { void onError(AsyncError error),
                                 void onDone(),
                                 bool unsubscribeOnError }) {
    return _stream.listen(onData, onError: onError, onDone: onDone,
                          unsubscribeOnError: unsubscribeOnError);
  }
}

/**
 * [StreamSink] wrapper that only exposes the [StreamSink] interface.
 */
class StreamSinkView<T> implements StreamSink<T> {
  final StreamSink<T> _sink;

  StreamSinkView(this._sink);

  void add(T value) { _sink.add(value); }
  void signalError(AsyncError error) { _sink.signalError(error); }
  void close() { _sink.close(); }
}


/**
 * The target of a [Stream.pipe] call.
 *
 * The [Stream.pipe] call will pass itself to this object, and then return
 * the resulting [Future]. The pipe should complete the future when it's
 * done.
 */
abstract class StreamConsumer<S, T> {
  Future<T> consume(Stream<S> stream);
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
   *         handleData: (Strung value, StreamSink<String> sink) {
   *           sink.add(value);
   *           sink.add(value);  // Duplicate the incoming events.
   *         }));
   *
   */
  factory StreamTransformer({
      void handleData(S data, StreamSink<T> sink),
      void handleError(AsyncError error, StreamSink<T> sink),
      void handleDone(StreamSink<T> sink)}) {
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
 *       void handleData(T data, StreamSink<T> sink) {
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
    return new EventTransformStream<S, T>(source, this);
  }

  /**
   * Act on incoming data event.
   *
   * The method may generate any number of events on the sink, but should
   * not throw.
   */
  void handleData(S event, StreamSink<T> sink) {
    var data = event;
    sink.add(data);
  }

  /**
   * Act on incoming error event.
   *
   * The method may generate any number of events on the sink, but should
   * not throw.
   */
  void handleError(AsyncError error, StreamSink<T> sink) {
    sink.signalError(error);
  }

  /**
   * Act on incoming done event.
   *
   * The method may generate any number of events on the sink, but should
   * not throw.
   */
  void handleDone(StreamSink<T> sink){
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
                               { void onError(AsyncError error),
                                 void onDone(),
                                 bool unsubscribeOnError }) {
    return new _EventTransformStreamSubscription(_source, _transformer,
                                                 onData, onError, onDone,
                                                 unsubscribeOnError);
  }
}

class _EventTransformStreamSubscription<S, T>
    extends _BaseStreamSubscription<T>
    implements _StreamOutputSink<T> {
  /** The transformer used to transform events. */
  final StreamEventTransformer<S, T> _transformer;
  /** Whether to unsubscribe when emitting an error. */
  final bool _unsubscribeOnError;
  /** Source of incoming events. */
  StreamSubscription<S> _subscription;
  /** Cached StreamSink wrapper for this class. */
  StreamSink<T> _sink;

  _EventTransformStreamSubscription(Stream<S> source,
                                    this._transformer,
                                    void onData(T data),
                                    void onError(AsyncError error),
                                    void onDone(),
                                    this._unsubscribeOnError)
      : super(onData, onError, onDone) {
    _sink = new _StreamOutputSinkWrapper<T>(this);
    _subscription = source.listen(_handleData,
                                  onError: _handleError,
                                  onDone: _handleDone);
  }

  void pause([Future pauseSignal]) {
    if (_subscription != null) _subscription.pause(pauseSignal);
  }

  void resume() {
    if (_subscription != null) _subscription.resume();
  }

  void cancel() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
  }

  void _handleData(S data) {
    try {
      _transformer.handleData(data, _sink);
    } catch (e, s) {
      _sendError(_asyncError(e, s));
    }
  }

  void _handleError(AsyncError error) {
    try {
      _transformer.handleError(error, _sink);
    } catch (e, s) {
      _sendError(_asyncError(e, s, error));
    }
  }

  void _handleDone() {
    try {
      _transformer.handleDone(_sink);
    } catch (e, s) {
      _sendError(_asyncError(e, s));
    }
  }

  // StreamOutputSink interface.
  void _sendData(T data) {
    _onData(data);
  }

  void _sendError(AsyncError error) {
    _onError(error);
    if (_unsubscribeOnError) {
      cancel();
    }
  }

  void _sendDone() {
    // It's ok to cancel even if we have been unsubscribed already.
    cancel();
    _onDone();
  }
}

class _StreamOutputSinkWrapper<T> implements StreamSink<T> {
  _StreamOutputSink _sink;
  _StreamOutputSinkWrapper(this._sink);

  void add(T data) => _sink._sendData(data);
  void signalError(AsyncError error) => _sink._sendError(error);
  void close() => _sink._sendDone();
}

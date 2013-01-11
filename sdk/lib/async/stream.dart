// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

// -------------------------------------------------------------------
// Core Stream types
// -------------------------------------------------------------------

abstract class Stream<T> {
  Stream();

  factory Stream.fromFuture(Future<T> future) {
    _StreamImpl<T> stream = new _MultiStreamImpl<T>();
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
    return new _IterableSingleStreamImpl<T>(data);
  }

  /**
   * Returns a multi-subscription stream that produces the same events as this.
   *
   * If this stream is single-subscription, return a new stream that allows
   * multiple subscribers. It will subscribe to this stream when its first
   * subscriber is added, and unsubscribe again when the last subscription is
   * cancelled.
   *
   * If this stream is already multi-subscriber, it is returned unmodified.
   */
  Stream<T> asMultiSubscriberStream();

  /**
   * Stream that outputs events from the [sources] in cyclic order.
   *
   * The merged streams are paused and resumed in order to ensure the proper
   * order of output events.
   */
  factory Stream.cyclic(Iterable<Stream> sources) {
    return new CyclicScheduleStream<T>(sources);
  }

 /**
   * Create a stream that forwards data from the highest priority active source.
   *
   * Sources are provided in order of increasing priority, and only data from
   * the highest priority source stream that has provided data are output
   * on the created stream.
   *
   * Errors from the most recent active stream, and any higher priority stream,
   * are forwarded to the created stream.
   *
   * If a higher priority source stream completes without providing data,
   * it will have no effect on lower priority streams.
   */
  factory Stream.superceding(Iterable<Stream<T>> sources) {
    return new SupercedeStream<T>(sources);
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
    return this.transform(new WhereStream<T>(test));
  }

  /**
   * Create a new stream that converts each element of this stream
   * to a new value using the [convert] function.
   */
  Stream mappedBy(convert(T event)) {
    return this.transform(new MapStream<T, dynamic>(convert));
  }

  /**
   * Create a wrapper Stream that intercepts some errors from this stream.
   *
   * If the handler returns null, the error is considered handled.
   * Otherwise the returned [AsyncError] is passed to the subscribers
   * of the stream.
   */
  Stream handleError(AsyncError handle(AsyncError error)) {
    return this.transform(new HandleErrorStream<T>(handle));
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
    return this.transform(new ExpandStream<T, dynamic>(convert));
  }

  /**
   * Bind this stream as the input of the provided [StreamConsumer].
   */
  Future pipe(StreamConsumer<dynamic, T> streamConsumer) {
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
      (T element) {
        try {
          value = combine(value, element);
        } catch (e, s) {
          subscription.cancel();
          result._setError(new AsyncError(e, s));
        }
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
          result.setValue(null);
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
        (T element) {
          if (element == match) {
            subscription.cancel();
            future._setValue(true);
          }
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
        (T element) {
          if (!test(element)) {
            subscription.cancel();
            future._setValue(false);
          }
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
        (T element) {
          if (test(element)) {
            subscription.cancel();
            future._setValue(true);
          }
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
    if (compare == null) compare = Comparable.compare;
    _FutureImpl<T> future = new _FutureImpl<T>();
    StreamSubscription subscription;
    T min = null;
    subscription = this.listen(
      (T value) {
        min = value;
        subscription.onData((T value) {
          if (compare(min, value) > 0) min = value;
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
   * Finds the least element in the stream.
   *
   * If the stream is empty, the result is [:null:].
   * Otherwise the result is an value from the stream that is not greater
   * than any other value from the stream (according to [compare], which must
   * be a [Comparator]).
   *
   * If [compare] is omitted, it defaults to [Comparable.compare].
   */
  Future<T> max([int compare(T a, T b)]) {
    if (compare == null) compare = Comparable.compare;
    _FutureImpl<T> future = new _FutureImpl<T>();
    StreamSubscription subscription;
    T max = null;
    subscription = this.listen(
      (T value) {
        max = value;
        subscription.onData((T value) {
          if (compare(max, value) < 0) max = value;
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
      (T data) {
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
      (T data) {
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
    return this.transform(new TakeStream(count));
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
    return this.transform(new TakeWhileStream(test));
  }

  /**
   * Skips the first [count] data events from this stream.
   */
  Stream<T> skip(int count) {
    return this.transform(new SkipStream(count));
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
    return this.transform(new SkipWhileStream(test));
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
    return this.transform(new DistinctStream(equals));
  }

  /**
   * Returns the first element.
   *
   * If [this] is empty throws a [StateError]. Otherwise this method is
   * equivalent to [:this.elementAt(0):]
   */
  Future<T> get first {
    _FutureImpl<T> future = new _FutureImpl();
    StreamSubscription subscription;
    subscription = this.listen(
      (T value) {
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
      (T value) {
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
      (T value) {
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
      (T value) {
        bool matches;
        try {
          matches = (true == test(value));
        } catch (e, s) {
          future._setError(new AsyncError(e, s));
          subscription.cancel();
          return;
        }
        if (matches) {
          future._setValue(value);
          subscription.cancel();
        }
      },
      onError: future._setError,
      onDone: () {
        if (defaultValue != null) {
          T value;
          try {
            value = defaultValue();
          } catch (e, s) {
            future._setError(new AsyncError(e, s));
            return;
          }
          future._setValue(value);
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
      (T value) {
        bool matches;
        try {
          matches = (true == test(value));
        } catch (e, s) {
          future._setError(new AsyncError(e, s));
          subscription.cancel();
          return;
        }
        if (matches) {
          foundResult = true;
          result = value;
        }
      },
      onError: future._setError,
      onDone: () {
        if (foundResult) {
          future._setValue(result);
          return;
        }
        if (defaultValue != null) {
          T value;
          try {
            value = defaultValue();
          } catch (e, s) {
            future._setError(new AsyncError(e, s));
            return;
          }
          future._setValue(value);
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
      (T value) {
        bool matches;
        try {
          matches = (true == test(value));
        } catch (e, s) {
          future._setError(new AsyncError(e, s));
          subscription.cancel();
          return;
        }
        if (matches) {
          if (foundResult) {
            future._setError(new AsyncError(
                new StateError('Multiple matches for "single"')));
            subscription.cancel();
            return;
          }
          foundResult = true;
          result = value;
        }
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
    _FutureImpl<T> future = new _FutureImpl();
    StreamSubscription subscription;
    subscription = this.listen(
      (T value) {
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
 * When you subscribe on a [Stream] using [Stream.subscribe],
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
   * when the future completes in any way.
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
   * If a parameter is omitted, a default handler is used that forwards the
   * event directly to the sink.
   *
   * Pauses on the are forwarded to the input stream as well.
   */
  factory StreamTransformer.from({
      void onData(S data, StreamSink<T> sink),
      void onError(AsyncError error, StreamSink<T> sink),
      void onDone(StreamSink<T> sink)}) = _StreamTransformerFunctionWrapper;

  Stream<T> bind(Stream<S> stream);
}


// TODO(lrn): Remove this class.
/**
 * A base class for configuration objects for [TransformStream].
 *
 * A default implementation forwards all incoming events to the output sink.
 */
abstract class _StreamTransformer<S, T> implements StreamTransformer<S, T> {
  const _StreamTransformer();

  Stream<T> bind(Stream<S> input) {
    return input.transform(new TransformStream<S, T>(this));
  }

  /**
   * Handle an incoming data event.
   */
  void handleData(S data, StreamSink<T> sink) {
    var outData = data;
    return sink.add(outData);
  }

  /**
   * Handle an incoming error event.
   */
  void handleError(AsyncError error, StreamSink<T> sink) {
    sink.signalError(error);
  }

  /**
   * Handle an incoming done event.
   */
  void handleDone(StreamSink<T> sink) {
    sink.close();
  }
}

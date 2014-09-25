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
 * A Stream provides a way to receive a sequence of events.
 * Each event is either a data event or an error event,
 * representing the result of a single computation.
 * When the events provided by a Stream have all been sent,
 * a single "done" event will mark the end.
 *
 * You can [listen] on a stream to make it start generating events,
 * and to set up listeners that receive the events.
 * When you listen, you receive a [StreamSubscription] object
 * which is the active object providing the events,
 * and which can be used to stop listening again,
 * or to temporarily pause events from the subscription.
 *
 * There are two kinds of streams: "Single-subscription" streams and
 * "broadcast" streams.
 *
 * *A single-subscription stream* allows only a single listener during the whole
 * lifetime of the stream.
 * It doesn't start generating events until it has a listener,
 * and it stops sending events when the listener is unsubscribed,
 * even if the source of events could still provide more.
 *
 * Listening twice on a single-subscription stream is not allowed, even after
 * the first subscription has been canceled.
 *
 * Single-subscription streams are generally used for streaming chunks of
 * larger contiguous data like file I/O.
 *
 * *A broadcast stream* allows any number of listeners, and it fires
 * its events when they are ready, whether there are listeners or not.
 *
 * Broadcast streams are used for independent events/observers.
 *
 * If several listeners want to listen to a single subscription stream,
 * use [asBroadcastStream] to create a broadcast stream on top of the
 * non-broadcast stream.
 *
 * On either kind of stream, stream transformationss, such as [where] and
 * [skip], return the same type of stream as the one the method was called on,
 * unless otherwise noted.
 *
 * When an event is fired, the listener(s) at that time will receive the event.
 * If a listener is added to a broadcast stream while an event is being fired,
 * that listener will not receive the event currently being fired.
 * If a listener is canceled, it immediately stops receiving events.
 *
 * When the "done" event is fired, subscribers are unsubscribed before
 * receiving the event. After the event has been sent, the stream has no
 * subscribers. Adding new subscribers to a broadcast stream after this point
 * is allowed, but they will just receive a new "done" event as soon
 * as possible.
 *
 * Stream subscriptions always respect "pause" requests. If necessary they need
 * to buffer their input, but often, and preferably, they can simply request
 * their input to pause too.
 *
 * The default implementation of [isBroadcast] returns false.
 * A broadcast stream inheriting from [Stream] must override [isBroadcast]
 * to return `true`.
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
    // Use the controller's buffering to fill in the value even before
    // the stream has a listener. For a single value, it's not worth it
    // to wait for a listener before doing the `then` on the future.
    _StreamController<T> controller = new StreamController<T>(sync: true);
    future.then((value) {
        controller._add(value);
        controller._closeUnchecked();
      },
      onError: (error, stackTrace) {
        controller._addError(error, stackTrace);
        controller._closeUnchecked();
      });
    return controller.stream;
  }

  /**
   * Creates a single-subscription stream that gets its data from [data].
   *
   * The iterable is iterated when the stream receives a listener, and stops
   * iterating if the listener cancels the subscription.
   *
   * If iterating [data] throws an error, the stream ends immediately with
   * that error. No done event will be sent (iteration is not complete), but no
   * further data events will be generated either, since iteration cannot
   * continue.
   */
  factory Stream.fromIterable(Iterable<T> data) {
    return new _GeneratedStreamImpl<T>(
        () => new _IterablePendingEvents<T>(data));
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

    controller = new StreamController<T>(sync: true,
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
   * Creates a stream where all events of an existing stream are piped through
   * a sink-transformation.
   *
   * The given [mapSink] closure is invoked when the returned stream is
   * listened to. All events from the [source] are added into the event sink
   * that is returned from the invocation. The transformation puts all
   * transformed events into the sink the [mapSink] closure received during
   * its invocation. Conceptually the [mapSink] creates a transformation pipe
   * with the input sink being the returned [EventSink] and the output sink
   * being the sink it received.
   *
   * This constructor is frequently used to build transformers.
   *
   * Example use for a duplicating transformer:
   *
   *     class DuplicationSink implements EventSink<String> {
   *       final EventSink<String> _outputSink;
   *       DuplicationSink(this._outputSink);
   *
   *       void add(String data) {
   *         _outputSink.add(data);
   *         _outputSink.add(data);
   *       }
   *
   *       void addError(e, [st]) => _outputSink(e, st);
   *       void close() => _outputSink.close();
   *     }
   *
   *     class DuplicationTransformer implements StreamTransformer<String, String> {
   *       // Some generic types ommitted for brevety.
   *       Stream bind(Stream stream) => new Stream<String>.eventTransform(
   *           stream,
   *           (EventSink sink) => new DuplicationSink(sink));
   *     }
   *
   *     stringStream.transform(new DuplicationTransformer());
   *
   * The resulting stream is a broadcast stream if [source] is.
   */
  factory Stream.eventTransformed(Stream source,
                                  EventSink mapSink(EventSink<T> sink)) {
    return new _BoundSinkStream(source, mapSink);
  }

  /**
   * Reports whether this stream is a broadcast stream.
   */
  bool get isBroadcast => false;

  /**
   * Returns a multi-subscription stream that produces the same events as this.
   *
   * The returned stream will subscribe to this stream when its first
   * subscriber is added, and will stay subscribed until this stream ends,
   * or a callback cancels the subscription.
   *
   * If [onListen] is provided, it is called with a subscription-like object
   * that represents the underlying subscription to this stream. It is
   * possible to pause, resume or cancel the subscription during the call
   * to [onListen]. It is not possible to change the event handlers, including
   * using [StreamSubscription.asFuture].
   *
   * If [onCancel] is provided, it is called in a similar way to [onListen]
   * when the returned stream stops having listener. If it later gets
   * a new listener, the [onListen] function is called again.
   *
   * Use the callbacks, for example, for pausing the underlying subscription
   * while having no subscribers to prevent losing events, or canceling the
   * subscription when there are no listeners.
   */
  Stream<T> asBroadcastStream({
      void onListen(StreamSubscription<T> subscription),
      void onCancel(StreamSubscription<T> subscription) }) {
    return new _AsBroadcastStream<T>(this, onListen, onCancel);
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
   * The [onError] callback must be of type `void onError(error)` or
   * `void onError(error, StackTrace stackTrace)`. If [onError] accepts
   * two arguments it is called with the stack trace (which could be `null` if
   * the stream itself received an error without stack trace).
   * Otherwise it is called with just the error object.
   *
   * If this stream closes, the [onDone] handler is called.
   *
   * If [cancelOnError] is true, the subscription is ended when
   * the first error is reported. The default is false.
   */
  StreamSubscription<T> listen(void onData(T event),
                               { Function onError,
                                 void onDone(),
                                 bool cancelOnError});

  /**
   * Creates a new stream from this stream that discards some data events.
   *
   * The new stream sends the same error and done events as this stream,
   * but it only sends the data events that satisfy the [test].
   *
   * The returned stream is a broadcast stream if this stream is.
   * If a broadcast stream is listened to more than once, each subscription
   * will individually perform the `test`.
   */
  Stream<T> where(bool test(T event)) {
    return new _WhereStream<T>(this, test);
  }

  /**
   * Creates a new stream that converts each element of this stream
   * to a new value using the [convert] function.
   *
   * The returned stream is a broadcast stream if this stream is.
   * If a broadcast stream is listened to more than once, each subscription
   * will individually execute `map` for each event.
   */
  Stream map(convert(T event)) {
    return new _MapStream<T, dynamic>(this, convert);
  }

  /**
   * Creates a new stream with each data event of this stream asynchronously
   * mapped to a new event.
   *
   * This acts like [map], except that [convert] may return a [Future],
   * and in that case, the stream waits for that future to complete before
   * continuing with its result.
   *
   * The returned stream is a broadcast stream if this stream is.
   */
  Stream asyncMap(convert(T event)) {
    StreamController controller;
    StreamSubscription subscription;
    void onListen () {
      final add = controller.add;
      assert(controller is _StreamController ||
             controller is _BroadcastStreamController);
      final eventSink = controller;
      final addError = eventSink._addError;
      subscription = this.listen(
          (T event) {
            var newValue;
            try {
              newValue = convert(event);
            } catch (e, s) {
              controller.addError(e, s);
              return;
            }
            if (newValue is Future) {
              subscription.pause();
              newValue.then(add, onError: addError)
                      .whenComplete(subscription.resume);
            } else {
              controller.add(newValue);
            }
          },
          onError: addError,
          onDone: controller.close
      );
    }
    if (this.isBroadcast) {
      controller = new StreamController.broadcast(
        onListen: onListen,
        onCancel: () { subscription.cancel(); },
        sync: true
      );
    } else {
      controller = new StreamController(
        onListen: onListen,
        onPause: () { subscription.pause(); },
        onResume: () { subscription.resume(); },
        onCancel: () { subscription.cancel(); },
        sync: true
      );
    }
    return controller.stream;
  }

  /**
   * Creates a new stream with the events of a stream per original event.
   *
   * This acts like [expand], except that [convert] returns a [Stream]
   * instead of an [Iterable].
   * The events of the returned stream becomes the events of the returned
   * stream, in the order they are produced.
   *
   * If [convert] returns `null`, no value is put on the output stream,
   * just as if it returned an empty stream.
   *
   * The returned stream is a broadcast stream if this stream is.
   */
  Stream asyncExpand(Stream convert(T event)) {
    StreamController controller;
    StreamSubscription subscription;
    void onListen() {
      assert(controller is _StreamController ||
             controller is _BroadcastStreamController);
      final eventSink = controller;
      subscription = this.listen(
          (T event) {
            Stream newStream;
            try {
              newStream = convert(event);
            } catch (e, s) {
              controller.addError(e, s);
              return;
            }
            if (newStream != null) {
              subscription.pause();
              controller.addStream(newStream)
                        .whenComplete(subscription.resume);
            }
          },
          onError: eventSink._addError,  // Avoid Zone error replacement.
          onDone: controller.close
      );
    }
    if (this.isBroadcast) {
      controller = new StreamController.broadcast(
        onListen: onListen,
        onCancel: () { subscription.cancel(); },
        sync: true
      );
    } else {
      controller = new StreamController(
        onListen: onListen,
        onPause: () { subscription.pause(); },
        onResume: () { subscription.resume(); },
        onCancel: () { subscription.cancel(); },
        sync: true
      );
    }
    return controller.stream;
  }

  /**
   * Creates a wrapper Stream that intercepts some errors from this stream.
   *
   * If this stream sends an error that matches [test], then it is intercepted
   * by the [handle] function.
   *
   * The [onError] callback must be of type `void onError(error)` or
   * `void onError(error, StackTrace stackTrace)`. Depending on the function
   * type the the stream either invokes [onError] with or without a stack
   * trace. The stack trace argument might be `null` if the stream itself
   * received an error without stack trace.
   *
   * An asynchronous error [:e:] is matched by a test function if [:test(e):]
   * returns true. If [test] is omitted, every error is considered matching.
   *
   * If the error is intercepted, the [handle] function can decide what to do
   * with it. It can throw if it wants to raise a new (or the same) error,
   * or simply return to make the stream forget the error.
   *
   * If you need to transform an error into a data event, use the more generic
   * [Stream.transform] to handle the event by writing a data event to
   * the output sink.
   *
   * The returned stream is a broadcast stream if this stream is.
   * If a broadcast stream is listened to more than once, each subscription
   * will individually perform the `test` and handle the error.
   */
  Stream<T> handleError(Function onError, { bool test(error) }) {
    return new _HandleErrorStream<T>(this, onError, test);
  }

  /**
   * Creates a new stream from this stream that converts each element
   * into zero or more events.
   *
   * Each incoming event is converted to an [Iterable] of new events,
   * and each of these new events are then sent by the returned stream
   * in order.
   *
   * The returned stream is a broadcast stream if this stream is.
   * If a broadcast stream is listened to more than once, each subscription
   * will individually call `convert` and expand the events.
   */
  Stream expand(Iterable convert(T value)) {
    return new _ExpandStream<T, dynamic>(this, convert);
  }

  /**
   * Binds this stream as the input of the provided [StreamConsumer].
   *
   * The `streamConsumer` is closed when the stream has been added to it.
   *
   * Returns a future which completes when the stream has been consumed
   * and the consumer has been closed.
   */
  Future pipe(StreamConsumer<T> streamConsumer) {
    return streamConsumer.addStream(this).then((_) => streamConsumer.close());
  }

  /**
   * Chains this stream as the input of the provided [StreamTransformer].
   *
   * Returns the result of [:streamTransformer.bind:] itself.
   *
   * The `streamTransformer` can decide whether it wants to return a
   * broadcast stream or not.
   */
  Stream transform(StreamTransformer<T, dynamic> streamTransformer) {
    return streamTransformer.bind(this);
  }

  /**
   * Reduces a sequence of values by repeatedly applying [combine].
   */
  Future<T> reduce(T combine(T previous, T element)) {
    _Future<T> result = new _Future<T>();
    bool seenFirst = false;
    T value;
    StreamSubscription subscription;
    subscription = this.listen(
      (T element) {
        if (seenFirst) {
          _runUserCode(() => combine(value, element),
                       (T newValue) { value = newValue; },
                       _cancelAndErrorClosure(subscription, result));
        } else {
          value = element;
          seenFirst = true;
        }
      },
      onError: result._completeError,
      onDone: () {
        if (!seenFirst) {
          try {
            throw IterableElementError.noElement();
          } catch (e, s) {
            _completeWithErrorCallback(result, e,  s);
          }
        } else {
          result._complete(value);
        }
      },
      cancelOnError: true
    );
    return result;
  }

  /** Reduces a sequence of values by repeatedly applying [combine]. */
  Future fold(var initialValue, combine(var previous, T element)) {
    _Future result = new _Future();
    var value = initialValue;
    StreamSubscription subscription;
    subscription = this.listen(
      (T element) {
        _runUserCode(
          () => combine(value, element),
          (newValue) { value = newValue; },
          _cancelAndErrorClosure(subscription, result)
        );
      },
      onError: (e, st) {
        result._completeError(e, st);
      },
      onDone: () {
        result._complete(value);
      },
      cancelOnError: true);
    return result;
  }

  /**
   * Collects string of data events' string representations.
   *
   * If [separator] is provided, it is inserted between any two
   * elements.
   *
   * Any error in the stream causes the future to complete with that
   * error. Otherwise it completes with the collected string when
   * the "done" event arrives.
   */
  Future<String> join([String separator = ""]) {
    _Future<String> result = new _Future<String>();
    StringBuffer buffer = new StringBuffer();
    StreamSubscription subscription;
    bool first = true;
    subscription = this.listen(
      (T element) {
        if (!first) {
          buffer.write(separator);
        }
        first = false;
        try {
          buffer.write(element);
        } catch (e, s) {
          _cancelAndErrorWithReplacement(subscription, result, e, s);
        }
      },
      onError: (e) {
        result._completeError(e);
      },
      onDone: () {
        result._complete(buffer.toString());
      },
      cancelOnError: true);
    return result;
  }

  /**
   * Checks whether [needle] occurs in the elements provided by this stream.
   *
   * Completes the [Future] when the answer is known.
   * If this stream reports an error, the [Future] will report that error.
   */
  Future<bool> contains(Object needle) {
    _Future<bool> future = new _Future<bool>();
    StreamSubscription subscription;
    subscription = this.listen(
        (T element) {
          _runUserCode(
            () => (element == needle),
            (bool isMatch) {
              if (isMatch) {
                _cancelAndValue(subscription, future, true);
              }
            },
            _cancelAndErrorClosure(subscription, future)
          );
        },
        onError: future._completeError,
        onDone: () {
          future._complete(false);
        },
        cancelOnError: true);
    return future;
  }

  /**
   * Executes [action] on each data event of the stream.
   *
   * Completes the returned [Future] when all events of the stream
   * have been processed. Completes the future with an error if the
   * stream has an error event, or if [action] throws.
   */
  Future forEach(void action(T element)) {
    _Future future = new _Future();
    StreamSubscription subscription;
    subscription = this.listen(
        (T element) {
          _runUserCode(
            () => action(element),
            (_) {},
            _cancelAndErrorClosure(subscription, future)
          );
        },
        onError: future._completeError,
        onDone: () {
          future._complete(null);
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
    _Future<bool> future = new _Future<bool>();
    StreamSubscription subscription;
    subscription = this.listen(
        (T element) {
          _runUserCode(
            () => test(element),
            (bool isMatch) {
              if (!isMatch) {
                _cancelAndValue(subscription, future, false);
              }
            },
            _cancelAndErrorClosure(subscription, future)
          );
        },
        onError: future._completeError,
        onDone: () {
          future._complete(true);
        },
        cancelOnError: true);
    return future;
  }

  /**
   * Checks whether [test] accepts any element provided by this stream.
   *
   * Completes the [Future] when the answer is known.
   *
   * If this stream reports an error, the [Future] reports that error.
   *
   * Stops listening to the stream after the first matching element has been
   * found.
   *
   * Internally the method cancels its subscription after this element. This
   * means that single-subscription (non-broadcast) streams are closed and
   * cannot be reused after a call to this method.
   */
  Future<bool> any(bool test(T element)) {
    _Future<bool> future = new _Future<bool>();
    StreamSubscription subscription;
    subscription = this.listen(
        (T element) {
          _runUserCode(
            () => test(element),
            (bool isMatch) {
              if (isMatch) {
                _cancelAndValue(subscription, future, true);
              }
            },
            _cancelAndErrorClosure(subscription, future)
          );
        },
        onError: future._completeError,
        onDone: () {
          future._complete(false);
        },
        cancelOnError: true);
    return future;
  }


  /** Counts the elements in the stream. */
  Future<int> get length {
    _Future<int> future = new _Future<int>();
    int count = 0;
    this.listen(
      (_) { count++; },
      onError: future._completeError,
      onDone: () {
        future._complete(count);
      },
      cancelOnError: true);
    return future;
  }

  /**
   * Reports whether this stream contains any elements.
   *
   * Stops listening to the stream after the first element has been received.
   *
   * Internally the method cancels its subscription after the first element.
   * This means that single-subscription (non-broadcast) streams are closed and
   * cannot be reused after a call to this getter.
   */
  Future<bool> get isEmpty {
    _Future<bool> future = new _Future<bool>();
    StreamSubscription subscription;
    subscription = this.listen(
      (_) {
        _cancelAndValue(subscription, future, false);
      },
      onError: future._completeError,
      onDone: () {
        future._complete(true);
      },
      cancelOnError: true);
    return future;
  }

  /** Collects the data of this stream in a [List]. */
  Future<List<T>> toList() {
    List<T> result = <T>[];
    _Future<List<T>> future = new _Future<List<T>>();
    this.listen(
      (T data) {
        result.add(data);
      },
      onError: future._completeError,
      onDone: () {
        future._complete(result);
      },
      cancelOnError: true);
    return future;
  }

  /**
   * Collects the data of this stream in a [Set].
   *
   * The returned set is the same type as returned by `new Set<T>()`.
   * If another type of set is needed, either use [forEach] to add each
   * element to the set, or use
   * `toList().then((list) => new SomeOtherSet.from(list))`
   * to create the set.
   */
  Future<Set<T>> toSet() {
    Set<T> result = new Set<T>();
    _Future<Set<T>> future = new _Future<Set<T>>();
    this.listen(
      (T data) {
        result.add(data);
      },
      onError: future._completeError,
      onDone: () {
        future._complete(result);
      },
      cancelOnError: true);
    return future;
  }

  /**
   * Discards all data on the stream, but signals when it's done or an error
   * occured.
   *
   * When subscribing using [drain], cancelOnError will be true. This means
   * that the future will complete with the first error on the stream and then
   * cancel the subscription.
   *
   * In case of a `done` event the future completes with the given
   * [futureValue].
   */
  Future drain([var futureValue]) => listen(null, cancelOnError: true)
      .asFuture(futureValue);

  /**
   * Provides at most the first [n] values of this stream.
   *
   * Forwards the first [n] data events of this stream, and all error
   * events, to the returned stream, and ends with a done event.
   *
   * If this stream produces fewer than [count] values before it's done,
   * so will the returned stream.
   *
   * Stops listening to the stream after the first [n] elements have been
   * received.
   *
   * Internally the method cancels its subscription after these elements. This
   * means that single-subscription (non-broadcast) streams are closed and
   * cannot be reused after a call to this method.
   *
   * The returned stream is a broadcast stream if this stream is.
   * For a broadcast stream, the events are only counted from the time
   * the returned stream is listened to.
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
   *
   * Stops listening to the stream after the accepted elements.
   *
   * Internally the method cancels its subscription after these elements. This
   * means that single-subscription (non-broadcast) streams are closed and
   * cannot be reused after a call to this method.
   *
   * The returned stream is a broadcast stream if this stream is.
   * For a broadcast stream, the events are only tested from the time
   * the returned stream is listened to.
   */
  Stream<T> takeWhile(bool test(T element)) {
    return new _TakeWhileStream(this, test);
  }

  /**
   * Skips the first [count] data events from this stream.
   *
   * The returned stream is a broadcast stream if this stream is.
   * For a broadcast stream, the events are only counted from the time
   * the returned stream is listened to.
   */
  Stream<T> skip(int count) {
    return new _SkipStream(this, count);
  }

  /**
   * Skip data events from this stream while they are matched by [test].
   *
   * Error and done events are provided by the returned stream unmodified.
   *
   * Starting with the first data event where [test] returns false for the
   * event data, the returned stream will have the same events as this stream.
   *
   * The returned stream is a broadcast stream if this stream is.
   * For a broadcast stream, the events are only tested from the time
   * the returned stream is listened to.
   */
  Stream<T> skipWhile(bool test(T element)) {
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
   *
   * The returned stream is a broadcast stream if this stream is.
   * If a broadcast stream is listened to more than once, each subscription
   * will individually perform the `equals` test.
   */
  Stream<T> distinct([bool equals(T previous, T next)]) {
    return new _DistinctStream(this, equals);
  }

  /**
   * Returns the first element of the stream.
   *
   * Stops listening to the stream after the first element has been received.
   *
   * Internally the method cancels its subscription after the first element.
   * This means that single-subscription (non-broadcast) streams are closed
   * and cannot be reused after a call to this getter.
   *
   * If an error event occurs before the first data event, the resulting future
   * is completed with that error.
   *
   * If this stream is empty (a done event occurs before the first data event),
   * the resulting future completes with a [StateError].
   *
   * Except for the type of the error, this method is equivalent to
   * [:this.elementAt(0):].
   */
  Future<T> get first {
    _Future<T> future = new _Future<T>();
    StreamSubscription subscription;
    subscription = this.listen(
      (T value) {
        _cancelAndValue(subscription, future, value);
      },
      onError: future._completeError,
      onDone: () {
        try {
          throw IterableElementError.noElement();
        } catch (e, s) {
          _completeWithErrorCallback(future, e, s);
        }
      },
      cancelOnError: true);
    return future;
  }

  /**
   * Returns the last element of the stream.
   *
   * If an error event occurs before the first data event, the resulting future
   * is completed with that error.
   *
   * If this stream is empty (a done event occurs before the first data event),
   * the resulting future completes with a [StateError].
   */
  Future<T> get last {
    _Future<T> future = new _Future<T>();
    T result = null;
    bool foundResult = false;
    StreamSubscription subscription;
    subscription = this.listen(
      (T value) {
        foundResult = true;
        result = value;
      },
      onError: future._completeError,
      onDone: () {
        if (foundResult) {
          future._complete(result);
          return;
        }
        try {
          throw IterableElementError.noElement();
        } catch (e, s) {
          _completeWithErrorCallback(future, e, s);
        }
      },
      cancelOnError: true);
    return future;
  }

  /**
   * Returns the single element.
   *
   * If an error event occurs before or after the first data event, the
   * resulting future is completed with that error.
   *
   * If [this] is empty or has more than one element throws a [StateError].
   */
  Future<T> get single {
    _Future<T> future = new _Future<T>();
    T result = null;
    bool foundResult = false;
    StreamSubscription subscription;
    subscription = this.listen(
      (T value) {
        if (foundResult) {
          // This is the second element we get.
          try {
            throw IterableElementError.tooMany();
          } catch (e, s) {
            _cancelAndErrorWithReplacement(subscription, future, e, s);
          }
          return;
        }
        foundResult = true;
        result = value;
      },
      onError: future._completeError,
      onDone: () {
        if (foundResult) {
          future._complete(result);
          return;
        }
        try {
          throw IterableElementError.noElement();
        } catch (e, s) {
          _completeWithErrorCallback(future, e, s);
        }
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
   * Stops listening to the stream after the first matching element has been
   * received.
   *
   * Internally the method cancels its subscription after the first element that
   * matches the predicate. This means that single-subscription (non-broadcast)
   * streams are closed and cannot be reused after a call to this method.
   *
   * If an error occurs, or if this stream ends without finding a match and
   * with no [defaultValue] function provided, the future will receive an
   * error.
   */
  Future<dynamic> firstWhere(bool test(T element), {Object defaultValue()}) {
    _Future<dynamic> future = new _Future();
    StreamSubscription subscription;
    subscription = this.listen(
      (T value) {
        _runUserCode(
          () => test(value),
          (bool isMatch) {
            if (isMatch) {
              _cancelAndValue(subscription, future, value);
            }
          },
          _cancelAndErrorClosure(subscription, future)
        );
      },
      onError: future._completeError,
      onDone: () {
        if (defaultValue != null) {
          _runUserCode(defaultValue, future._complete, future._completeError);
          return;
        }
        try {
          throw IterableElementError.noElement();
        } catch (e, s) {
          _completeWithErrorCallback(future, e, s);
        }
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
  Future<dynamic> lastWhere(bool test(T element), {Object defaultValue()}) {
    _Future<dynamic> future = new _Future();
    T result = null;
    bool foundResult = false;
    StreamSubscription subscription;
    subscription = this.listen(
      (T value) {
        _runUserCode(
          () => true == test(value),
          (bool isMatch) {
            if (isMatch) {
              foundResult = true;
              result = value;
            }
          },
          _cancelAndErrorClosure(subscription, future)
        );
      },
      onError: future._completeError,
      onDone: () {
        if (foundResult) {
          future._complete(result);
          return;
        }
        if (defaultValue != null) {
          _runUserCode(defaultValue, future._complete, future._completeError);
          return;
        }
        try {
          throw IterableElementError.noElement();
        } catch (e, s) {
          _completeWithErrorCallback(future, e, s);
        }
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
  Future<T> singleWhere(bool test(T element)) {
    _Future<T> future = new _Future<T>();
    T result = null;
    bool foundResult = false;
    StreamSubscription subscription;
    subscription = this.listen(
      (T value) {
        _runUserCode(
          () => true == test(value),
          (bool isMatch) {
            if (isMatch) {
              if (foundResult) {
                try {
                  throw IterableElementError.tooMany();
                } catch (e, s) {
                  _cancelAndErrorWithReplacement(subscription, future, e, s);
                }
                return;
              }
              foundResult = true;
              result = value;
            }
          },
          _cancelAndErrorClosure(subscription, future)
        );
      },
      onError: future._completeError,
      onDone: () {
        if (foundResult) {
          future._complete(result);
          return;
        }
        try {
          throw IterableElementError.noElement();
        } catch (e, s) {
          _completeWithErrorCallback(future, e, s);
        }
      },
      cancelOnError: true);
    return future;
  }

  /**
   * Returns the value of the [index]th data event of this stream.
   *
   * Stops listening to the stream after the [index]th data event has been
   * received.
   *
   * Internally the method cancels its subscription after these elements. This
   * means that single-subscription (non-broadcast) streams are closed and
   * cannot be reused after a call to this method.
   *
   * If an error event occurs before the value is found, the future completes
   * with this error.
   *
   * If a done event occurs before the value is found, the future completes
   * with a [RangeError].
   */
  Future<T> elementAt(int index) {
    if (index is! int || index < 0) throw new ArgumentError(index);
    _Future<T> future = new _Future<T>();
    StreamSubscription subscription;
    subscription = this.listen(
      (T value) {
        if (index == 0) {
          _cancelAndValue(subscription, future, value);
          return;
        }
        index -= 1;
      },
      onError: future._completeError,
      onDone: () {
        future._completeError(new RangeError.value(index));
      },
      cancelOnError: true);
    return future;
  }

  /**
   * Creates a new stream with the same events as this stream.
   *
   * Whenever more than [timeLimit] passes between two events from this stream,
   * the [onTimeout] function is called.
   *
   * The countdown doesn't start until the returned stream is listened to.
   * The countdown is reset every time an event is forwarded from this stream,
   * or when the stream is paused and resumed.
   *
   * The [onTimeout] function is called with one argument: an
   * [EventSink] that allows putting events into the returned stream.
   * This `EventSink` is only valid during the call to `onTimeout`.
   *
   * If `onTimeout` is omitted, a timeout will just put a [TimeoutException]
   * into the error channel of the returned stream.
   *
   * The returned stream is a broadcast stream if this stream is.
   * If a broadcast stream is listened to more than once, each subscription
   * will have its individually timer that starts counting on listen,
   * and the subscriptions' timers can be paused individually.
   */
  Stream timeout(Duration timeLimit, {void onTimeout(EventSink sink)}) {
    StreamController controller;
    // The following variables are set on listen.
    StreamSubscription<T> subscription;
    Timer timer;
    Zone zone;
    Function timeout;

    void onData(T event) {
      timer.cancel();
      controller.add(event);
      timer = zone.createTimer(timeLimit, timeout);
    }
    void onError(error, StackTrace stackTrace) {
      timer.cancel();
      assert(controller is _StreamController ||
             controller is _BroadcastStreamController);
      var eventSink = controller;
      eventSink._addError(error, stackTrace);  // Avoid Zone error replacement.
      timer = zone.createTimer(timeLimit, timeout);
    }
    void onDone() {
      timer.cancel();
      controller.close();
    }
    void onListen() {
      // This is the onListen callback for of controller.
      // It runs in the same zone that the subscription was created in.
      // Use that zone for creating timers and running the onTimeout
      // callback.
      zone = Zone.current;
      if (onTimeout == null) {
        timeout = () {
          controller.addError(new TimeoutException("No stream event",
                                                   timeLimit), null);
        };
      } else {
        onTimeout = zone.registerUnaryCallback(onTimeout);
        _ControllerEventSinkWrapper wrapper =
            new _ControllerEventSinkWrapper(null);
        timeout = () {
          wrapper._sink = controller;  // Only valid during call.
          zone.runUnaryGuarded(onTimeout, wrapper);
          wrapper._sink = null;
        };
      }

      subscription = this.listen(onData, onError: onError, onDone: onDone);
      timer = zone.createTimer(timeLimit, timeout);
    }
    Future onCancel() {
      timer.cancel();
      Future result = subscription.cancel();
      subscription = null;
      return result;
    }
    controller = isBroadcast
        ? new _SyncBroadcastStreamController(onListen, onCancel)
        : new _SyncStreamController(
              onListen,
              () {
                // Don't null the timer, onCancel may call cancel again.
                timer.cancel();
                subscription.pause();
              },
              () {
                subscription.resume();
                timer = zone.createTimer(timeLimit, timeout);
              },
              onCancel);
    return controller.stream;
  }
}

/**
 * A subscritption on events from a [Stream].
 *
 * When you listen on a [Stream] using [Stream.listen],
 * a [StreamSubscription] object is returned.
 *
 * The subscription provides events to the listener,
 * and holds the callbacks used to handle the events.
 * The subscription can also be used to unsubscribe from the events,
 * or to temporarily pause the events from the stream.
 */
abstract class StreamSubscription<T> {
  /**
   * Cancels this subscription. It will no longer receive events.
   *
   * May return a future which completes when the stream is done cleaning up.
   * This can be used if the stream needs to release some resources
   * that are needed for a following operation,
   * for example a file being read, that should be deleted afterwards.
   * In that case, the file may not be able to be deleted successfully
   * until the returned future has completed.
   *
   * The future will be completed with a `null` value.
   * If the cleanup throws, which it really shouldn't, the returned future
   * will be completed with that error.
   *
   * Returns `null` if there is no need to wait.
   */
  Future cancel();

  /**
   * Set or override the data event handler of this subscription.
   *
   * This method overrides the handler that has been set at the invocation of
   * [Stream.listen].
   */
  void onData(void handleData(T data));

  /**
   * Set or override the error event handler of this subscription.
   *
   * This method overrides the handler that has been set at the invocation of
   * [Stream.listen] or by calling [asFuture].
   */
  void onError(Function handleError);

  /**
   * Set or override the done event handler of this subscription.
   *
   * This method overrides the handler that has been set at the invocation of
   * [Stream.listen] or by calling [asFuture].
   */
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
   *
   * Currently DOM streams silently drop events when the stream is paused. This
   * is a bug and will be fixed.
   */
  void pause([Future resumeSignal]);

  /**
   * Resume after a pause.
   */
  void resume();

  /**
   * Returns true if the [StreamSubscription] is paused.
   */
  bool get isPaused;

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
abstract class EventSink<T> implements Sink<T> {
  /** Send a data event to a stream. */
  void add(T event);
  /** Send an async error to a stream. */
  void addError(errorEvent, [StackTrace stackTrace]);
  /** Send a done event to a stream.*/
  void close();
}


/** [Stream] wrapper that only exposes the [Stream] interface. */
class StreamView<T> extends Stream<T> {
  Stream<T> _stream;

  StreamView(this._stream);

  bool get isBroadcast => _stream.isBroadcast;

  Stream<T> asBroadcastStream({void onListen(StreamSubscription subscription),
                               void onCancel(StreamSubscription subscription)})
      => _stream.asBroadcastStream(onListen: onListen, onCancel: onCancel);

  StreamSubscription<T> listen(void onData(T value),
                               { Function onError,
                                 void onDone(),
                                 bool cancelOnError }) {
    return _stream.listen(onData, onError: onError, onDone: onDone,
                          cancelOnError: cancelOnError);
  }
}


/**
 * The target of a [Stream.pipe] call.
 *
 * The [Stream.pipe] call will pass itself to this object, and then return
 * the resulting [Future]. The pipe should complete the future when it's
 * done.
 */
abstract class StreamConsumer<S> {
  /**
   * Consumes the elements of [stream].
   *
   * Listens on [stream] and does something for each event.
   *
   * The consumer may stop listening after an error, or it may consume
   * all the errors and only stop at a done event.
   */
  Future addStream(Stream<S> stream);

  /**
   * Tell the consumer that no futher streams will be added.
   *
   * Returns a future that is completed when the consumer is done handling
   * events.
   */
  Future close();
}


/**
 * A [StreamSink] unifies the asynchronous methods from [StreamConsumer] and
 * the synchronous methods from [EventSink].
 *
 * The [EventSink] methods can't be used while the [addStream] is called.
 * As soon as the [addStream]'s [Future] completes with a value, the
 * [EventSink] methods can be used again.
 *
 * If [addStream] is called after any of the [EventSink] methods, it'll
 * be delayed until the underlying system has consumed the data added by the
 * [EventSink] methods.
 *
 * When [EventSink] methods are used, the [done] [Future] can be used to
 * catch any errors.
 *
 * When [close] is called, it will return the [done] [Future].
 */
abstract class StreamSink<S> implements StreamConsumer<S>, EventSink<S> {
  /**
   * As [EventSink.close], but returns a future.
   *
   * Returns the same future as [done].
   */
  Future close();

  /**
   * Return a future which is completed when the [StreamSink] is finished.
   *
   * If the `StreamSink` fails with an error,
   * perhaps in response to adding events using [add], [addError] or [close],
   * the [done] future will complete with that error.
   *
   * Otherwise, the returned future will complete when either:
   *
   * * all events have been processed and the sink has been closed, or
   * * the sink has otherwise been stopped from handling more events
   *   (for example by cancelling a stream subscription).
   */
  Future get done;
}


/**
 * The target of a [Stream.transform] call.
 *
 * The [Stream.transform] call will pass itself to this object and then return
 * the resulting stream.
 *
 * It is good practice to write transformers that can be used multiple times.
 */
abstract class StreamTransformer<S, T> {

  /**
   * Creates a [StreamTransformer].
   *
   * The returned instance takes responsibility of implementing ([bind]).
   * When the user invokes `bind` it returns a new "bound" stream. Only when
   * the user starts listening to the bound stream, the `listen` method
   * invokes the given closure [transformer].
   *
   * The [transformer] closure receives the stream, that was bound, as argument
   * and returns a [StreamSubscription]. In almost all cases the closure
   * listens itself to the stream that is given as argument.
   *
   * The result of invoking the [transformer] closure is a [StreamSubscription].
   * The bound stream-transformer (created by the `bind` method above) then sets
   * the handlers it received as part of the `listen` call.
   *
   * Conceptually this can be summarized as follows:
   *
   * 1. `var transformer = new StreamTransformer(transformerClosure);`
   *   creates a `StreamTransformer` that supports the `bind` method.
   * 2. `var boundStream = stream.transform(transformer);` binds the `stream`
   *   and returns a bound stream that has a pointer to `stream`.
   * 3. `boundStream.listen(f1, onError: f2, onDone: f3, cancelOnError: b)`
   *   starts the listening and transformation. This is accomplished
   *   in 2 steps: first the `boundStream` invokes the `transformerClosure` with
   *   the `stream` it captured: `transformerClosure(stream, b)`.
   *   The result `subscription`, a [StreamSubscription], is then
   *   updated to receive its handlers: `subscription.onData(f1)`,
   *   `subscription.onError(f2)`, `subscription(f3)`. Finally the subscription
   *   is returned as result of the `listen` call.
   *
   * There are two common ways to create a StreamSubscription:
   *
   * 1. by creating a new class that implements [StreamSubscription].
   *    Note that the subscription should run callbacks in the [Zone] the
   *    stream was listened to.
   * 2. by allocating a [StreamController] and to return the result of
   *    listening to its stream.
   *
   * Example use of a duplicating transformer:
   *
   *     stringStream.transform(new StreamTransformer<String, String>(
   *         (Stream<String> input, bool cancelOnError) {
   *           StreamController<String> controller;
   *           StreamSubscription<String> subscription;
   *           controller = new StreamController<String>(
   *             onListen: () {
   *               subscription = input.listen((data) {
   *                   // Duplicate the data.
   *                   controller.add(data);
   *                   controller.add(data);
   *                 },
   *                 onError: controller.addError,
   *                 onDone: controller.close,
   *                 cancelOnError: cancelOnError);
   *             },
   *             onPause: subscription.pause,
   *             onResume: subscription.resume,
   *             onCancel: subscription.cancel,
   *             sync: true);
   *           return controller.stream.listen(null);
   *         });
   */
  const factory StreamTransformer(
      StreamSubscription<T> transformer(Stream<S> stream, bool cancelOnError))
      = _StreamSubscriptionTransformer;

  /**
   * Creates a [StreamTransformer] that delegates events to the given functions.
   *
   * Example use of a duplicating transformer:
   *
   *     stringStream.transform(new StreamTransformer<String, String>.fromHandlers(
   *         handleData: (String value, EventSink<String> sink) {
   *           sink.add(value);
   *           sink.add(value);  // Duplicate the incoming events.
   *         }));
   */
  factory StreamTransformer.fromHandlers({
      void handleData(S data, EventSink<T> sink),
      void handleError(Object error, StackTrace stackTrace, EventSink<T> sink),
      void handleDone(EventSink<T> sink)})
          = _StreamHandlerTransformer;

  Stream<T> bind(Stream<S> stream);
}

/**
 * An [Iterable] like interface for the values of a [Stream].
 *
 * This wraps a [Stream] and a subscription on the stream. It listens
 * on the stream, and completes the future returned by [moveNext] when the
 * next value becomes available.
 */
abstract class StreamIterator<T> {

  /** Create a [StreamIterator] on [stream]. */
  factory StreamIterator(Stream<T> stream)
      // TODO(lrn): use redirecting factory constructor when type
      // arguments are supported.
      => new _StreamIteratorImpl<T>(stream);

  /**
   * Wait for the next stream value to be available.
   *
   * It is not allowed to call this function again until the future has
   * completed. If the returned future completes with anything except `true`,
   * the iterator is done, and no new value will ever be available.
   *
   * The future may complete with an error, if the stream produces an error.
   */
  Future<bool> moveNext();

  /**
   * The current value of the stream.
   *
   * Only valid when the future returned by [moveNext] completes with `true`
   * as value, and only until the next call to [moveNext].
   */
  T get current;

  /**
   * Cancels the stream iterator (and the underlying stream subscription) early.
   *
   * The stream iterator is automatically canceled if the [moveNext] future
   * completes with either `false` or an error.
   *
   * If a [moveNext] call has been made, it will complete with `false` as value,
   * as will all further calls to [moveNext].
   *
   * If you need to stop listening for values before the stream iterator is
   * automatically closed, you must call [cancel] to ensure that the stream
   * is properly closed.
   *
   * Returns a future if the cancel-operation is not completed synchronously.
   * Otherwise returns `null`.
   */
  Future cancel();
}


/**
 * Wraps an [_EventSink] so it exposes only the [EventSink] interface.
 */
class _ControllerEventSinkWrapper<T> implements EventSink<T> {
  EventSink _sink;
  _ControllerEventSinkWrapper(this._sink);

  void add(T data) { _sink.add(data); }
  void addError(error, [StackTrace stackTrace]) {
    _sink.addError(error, stackTrace);
  }
  void close() { _sink.close(); }
}

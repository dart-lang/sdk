// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Capture asynchronous results into synchronous values, and release them again.
 *
 * Capturing a result (either a returned value or a thrown error)
 * means converting it into a [Result] -
 * either a [ValueResult] or an [ErrorResult].
 *
 * This value can release itself by writing itself either to a
 * [EventSink] or a [Completer], or by becoming a [Future].
 */
library dart.pkg.async.results;

import "dart:async";

/**
 * The result of a computation.
 */
abstract class Result<T> {
  /**
   * Create a `Result` with the result of calling [computation].
   *
   * This generates either a [ValueResult] with the value returned by
   * calling `computation`, or an [ErrorResult] with an error thrown by
   * the call.
   */
  factory Result(T computation()) {
    try {
      return new ValueResult(computation());
    } catch (e, s) {
      return new ErrorResult(e, s);
    }
  }

  /**
   * Create a `Result` holding a value.
   *
   * Alias for [ValueResult.ValueResult].
   */
  factory Result.value(T value) = ValueResult<T>;

  /**
   * Create a `Result` holding an error.
   *
   * Alias for [ErrorResult.ErrorResult].
   */
  factory Result.error(Object error, [StackTrace stackTrace]) =>
      new ErrorResult(error, stackTrace);

  // Helper functions.
  static _captureValue(value) => new ValueResult(value);
  static _captureError(error, stack) => new ErrorResult(error, stack);
  static _release(Result v) {
    if (v.isValue) return v.asValue.value;  // Avoid wrapping in future.
    return v.asFuture;
  }

  /**
   * Capture the result of a future into a `Result` future.
   *
   * The resulting future will never have an error.
   * Errors have been converted to an [ErrorResult] value.
   */
  static Future<Result> capture(Future future) {
    return future.then(_captureValue, onError: _captureError);
  }

  /**
   * Release the result of a captured future.
   *
   * Converts the [Result] value of the given [future] to a value or error
   * completion of the returned future.
   *
   * If [future] completes with an error, the returned future completes with
   * the same error.
   */
  static Future release(Future<Result> future) {
    return future.then(_release);
  }

  /**
   * Capture the results of a stream into a stream of [Result] values.
   *
   * The returned stream will not have any error events.
   * Errors from the source stream have been converted to [ErrorResult]s.
   *
   * Shorthand for transforming the stream using [CaptureStreamTransformer].
   */
  static Stream<Result> captureStream(Stream source) {
    return source.transform(const CaptureStreamTransformer());
  }

  /**
   * Release a stream of [result] values into a stream of the results.
   *
   * `Result` values of the source stream become value or error events in
   * the retuned stream as appropriate.
   * Errors from the source stream become errors in the returned stream.
   *
   * Shorthand for transforming the stream using [ReleaseStreamTransformer].
   */
  static Stream releaseStream(Stream<Result> source) {
    return source.transform(const ReleaseStreamTransformer());
  }

  /**
   * Converts a result of a result to a single result.
   *
   * If the result is an error, or it is a `Result` value
   * which is then an error, then a result with that error is returned.
   * Otherwise both levels of results are value results, and a single
   * result with the value is returned.
   */
  static Result flatten(Result<Result> result) {
    if (result.isError) return result;
    return result.asValue.value;
  }

  /**
   * Whether this result is a value result.
   *
   * Always the opposite of [isError].
   */
  bool get isValue;

  /**
   * Whether this result is an error result.
   *
   * Always the opposite of [isValue].
   */
  bool get isError;

  /**
   * If this is a value result, return itself.
   *
   * Otherwise return `null`.
   */
  ValueResult<T> get asValue;

  /**
   * If this is an error result, return itself.
   *
   * Otherwise return `null`.
   */
  ErrorResult get asError;

  /**
   * Complete a completer with this result.
   */
  void complete(Completer<T> completer);

  /**
   * Add this result to a [StreamSink].
   */
  void addTo(EventSink<T> sink);

  /**
   * Creates a future completed with this result as a value or an error.
   */
  Future<T> get asFuture;
}

/**
 * A result representing a returned value.
 */
class ValueResult<T> implements Result<T> {
  /** The returned value that this result represents. */
  final T value;
  /** Create a value result with the given [value]. */
  ValueResult(this.value);
  bool get isValue => true;
  bool get isError => false;
  ValueResult<T> get asValue => this;
  ErrorResult get asError => null;
  void complete(Completer<T> completer) {
    completer.complete(value);
  }
  void addTo(EventSink<T> sink) {
    sink.add(value);
  }
  Future<T> get asFuture => new Future.value(value);
}

/**
 * A result representing a thrown error.
 */
class ErrorResult implements Result {
  /** The thrown object that this result represents. */
  final error;
  /** The stack trace, if any, associated with the throw. */
  final StackTrace stackTrace;
  /** Create an error result with the given [error] and [stackTrace]. */
  ErrorResult(this.error, this.stackTrace);
  bool get isValue => false;
  bool get isError => true;
  ValueResult get asValue => null;
  ErrorResult get asError => this;
  void complete(Completer completer) {
    completer.completeError(error, stackTrace);
  }
  void addTo(EventSink sink) {
    sink.addError(error, stackTrace);
  }
  Future get asFuture => new Future.error(error, stackTrace);
}

/**
 * A stream transformer that captures a stream of events into [Result]s.
 *
 * The result of the transformation is a stream of [Result] values and
 * no error events.
 */
class CaptureStreamTransformer<T> implements StreamTransformer<T, Result<T>> {
  const CaptureStreamTransformer();

  Stream<Result<T>> bind(Stream<T> source) {
    return new Stream<Result<T>>.eventTransformed(source, _createSink);
  }

  static EventSink _createSink(EventSink<Result> sink) {
    return new CaptureSink(sink);
  }
}

/**
 * A stream transformer that releases a stream of result events.
 *
 * The result of the transformation is a stream of values and
 * error events.
 */
class ReleaseStreamTransformer<T> implements StreamTransformer<Result<T>, T> {
  const ReleaseStreamTransformer();

  Stream<T> bind(Stream<Result<T>> source) {
    return new Stream<T>.eventTransformed(source, _createSink);
  }

  static EventSink<Result> _createSink(EventSink sink) {
    return new ReleaseSink(sink);
  }
}

/**
 * An event sink wrapper that captures the incoming events.
 *
 * Wraps an [EventSink] that expects [Result] values.
 * Accepts any value and error result,
 * and passes them to the wrapped sink as [Result] values.
 *
 * The wrapped sink will never receive an error event.
 */
class CaptureSink<T> implements EventSink<T> {
  final EventSink _sink;

  CaptureSink(EventSink<Result<T>> sink) : _sink = sink;
  void add(T value) { _sink.add(new ValueResult(value)); }
  void addError(Object error, [StackTrace stackTrace]) {
    _sink.add(new ErrorResult(error, stackTrace));
  }
  void close() { _sink.close(); }
}

/**
 * An event sink wrapper that releases the incoming result events.
 *
 * Wraps an output [EventSink] that expects any result.
 * Accepts [Result] values, and puts the result value or error into the
 * corresponding output sink add method.
 */
class ReleaseSink<T> implements EventSink<Result<T>> {
  final EventSink _sink;
  ReleaseSink(EventSink<T> sink) : _sink = sink;
  void add(Result<T> result) {
    if (result.isValue) {
      _sink.add(result.asValue.value);
    } else {
      ErrorResult error = result.asError;
      _sink.addError(error.error, error.stackTrace);
    }
  }
  void addError(Object error, [StackTrace stackTrace]) {
    // Errors may be added by intermediate processing, even if it is never
    // added by CaptureSink.
    _sink.addError(error, stackTrace);
  }

  void close() { _sink.close(); }
}

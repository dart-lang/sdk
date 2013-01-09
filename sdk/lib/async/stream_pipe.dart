// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/**
 * A wrapper around a stream that allows independent subscribers.
 *
 * By default [this] subscribes to [_source] and forwards all events to its own
 * subscribers. It does not subscribe until there is a subscriber, and
 * unsubscribes again when there are no subscribers left.
 *
 * The events are passed through the [_handleData], [_handleError] and
 * [_handleDone] methods. Subclasses are supposed to add handling of some of
 * the events by overriding these methods.
 *
 * This class is intended for internal use only.
 */
class _ForwardingMultiStream<S, T> extends _MultiStreamImpl<T> {
  Stream<S> _source = null;
  StreamSubscription _subscription = null;

  void _subscribeToSource() {
    _subscription = _source.listen(this._handleData,
                                   onError: this._handleError,
                                   onDone: this._handleDone);
    if (_isPaused) {
      _subscription.pause();
    }
  }

  /**
    * Subscribe or unsubscribe on [source] depending on whether
    * [stream] has subscribers.
    */
  void _onSubscriptionStateChange() {
    if (_hasSubscribers) {
      assert(_subscription == null);
      if (_source != null) {
        _subscribeToSource();
      }
    } else {
      if (_subscription != null) {
        _subscription.cancel();
        _subscription = null;
      }
    }
  }

  void _onPauseStateChange() {
    if (_subscription == null) return;
    if (isPaused) {
      _subscription.pause();
    } else {
      _subscription.resume();
    }
  }

  void _handleData(S inputEvent) {
    var outputEvent = inputEvent;
    _add(outputEvent);
  }

  void _handleError(AsyncError error) {
    _signalError(error);
  }

  void _handleDone() {
    _close();
  }
}


abstract class _ForwardingTransformer<S, T> extends _ForwardingMultiStream<S, T>
                                            implements StreamTransformer<S, T> {
  Stream<T> bind(Stream<S> source) {
    assert(_source == null);
    _source = source;
    if (_hasSubscribers) {
      _subscribeToSource();
    }
    return this;
  }
}

// -------------------------------------------------------------------
// Stream transformers used by the default Stream implementation.
// -------------------------------------------------------------------

typedef bool _Predicate<T>(T value);

class WhereStream<T> extends _ForwardingTransformer<T, T> {
  final _Predicate<T> _test;

  WhereStream(bool test(T value))
      : this._test = test;

  void _handleData(T inputEvent) {
    bool satisfies;
    try {
      satisfies = _test(inputEvent);
    } catch (e, s) {
      _signalError(new AsyncError(e, s));
      return;
    }
    if (satisfies) {
      _add(inputEvent);
    }
  }
}


typedef T _Transformation<S, T>(S value);

/**
 * A stream pipe that converts data events before passing them on.
 */
class MapStream<S, T> extends _ForwardingTransformer<S, T> {
  final _Transformation _transform;

  MapStream(T transform(S event))
      : this._transform = transform;

  void _handleData(S inputEvent) {
    T outputEvent;
    try {
      outputEvent = _transform(inputEvent);
    } catch (e, s) {
      _signalError(new AsyncError(e, s));
      return;
    }
    _add(outputEvent);
  }
}

/**
 * A stream pipe that converts data events before passing them on.
 */
class ExpandStream<S, T> extends _ForwardingTransformer<S, T> {
  final _Transformation<S, Iterable<T>> _expand;

  ExpandStream(Iterable<T> expand(S event))
      : this._expand = expand;

  void _handleData(S inputEvent) {
    try {
      for (T value in _expand(inputEvent)) {
        _add(value);
      }
    } catch (e, s) {
      // If either _expand or iterating the generated iterator throws,
      // we abort the iteration.
      _signalError(new AsyncError(e, s));
    }
  }
}


typedef AsyncError _ErrorTransformation(AsyncError error);

/**
 * A stream pipe that converts or disposes error events
 * before passing them on.
 */
class HandleErrorStream<T> extends _ForwardingTransformer<T, T> {
  final _ErrorTransformation _transform;

  HandleErrorStream(AsyncError transform(AsyncError event))
      : this._transform = transform;

  void _handleError(AsyncError error) {
    try {
      error = _transform(error);
      if (error == null) return;
    } catch (e, s) {
      error = new AsyncError.withCause(e, s, error);
    }
    _signalError(error);
  }
}


typedef void _TransformDataHandler<S, T>(S data, StreamSink<T> sink);
typedef void _TransformErrorHandler<T>(AsyncError data, StreamSink<T> sink);
typedef void _TransformDoneHandler<T>(StreamSink<T> sink);

/**
 * A stream pipe that intercepts all events and can generate any event as
 * output.
 *
 * Each incoming event on this [StreamSink] is passed to the corresponding
 * provided event handler, along with a [StreamSink] linked to the [output] of
 * this pipe.
 * The handler can then decide which events to send to the output
 */
class PipeStream<S, T> extends _ForwardingTransformer<S, T> {
  final _TransformDataHandler<S, T> _onData;
  final _TransformErrorHandler<T> _onError;
  final _TransformDoneHandler<T> _onDone;
  StreamSink<T> _sink;

  PipeStream({void onData(S data, StreamSink<T> sink),
              void onError(AsyncError data, StreamSink<T> sink),
              void onDone(StreamSink<T> sink)})
      : this._onData = (onData == null ? _defaultHandleData : onData),
        this._onError = (onError == null ? _defaultHandleError : onError),
        this._onDone = (onDone == null ? _defaultHandleDone : onDone) {
    // Cache the sink wrapper to avoid creating a new one for each event.
    this._sink = new _StreamImplSink(this);
  }

  void _handleData(S data) {
    try {
      return _onData(data, _sink);
    } catch (e, s) {
      _signalError(new AsyncError(e, s));
    }
  }

  void _handleError(AsyncError error) {
    try {
      _onError(error, _sink);
    } catch (e, s) {
      _signalError(new AsyncError.withCause(e, s, error));
    }
  }

  void _handleDone() {
    try {
      _onDone(_sink);
    } catch (e, s) {
      _signalError(new AsyncError(e, s));
    }
  }

  /** Default data handler forwards all data. */
  static void _defaultHandleData(dynamic data, StreamSink sink) {
    sink.add(data);
  }
  /** Default error handler forwards all errors. */
  static void _defaultHandleError(AsyncError error, StreamSink sink) {
    sink.signalError(error);
  }
  /** Default done handler forwards done. */
  static void _defaultHandleDone(StreamSink sink) {
    sink.close();
  }
}

/** Creates a [StreamSink] from a [_StreamImpl]'s input methods. */
class _StreamImplSink<T> implements StreamSink<T> {
  _StreamImpl<T> _target;
  _StreamImplSink(this._target);
  void add(T data) { _target._add(data); }
  void signalError(AsyncError error) { _target._signalError(error); }
  void close() { _target._close(); }
}

/**
 * A stream pipe that intercepts all events and can generate any event as
 * output.
 *
 * Each incoming event on this [StreamSink] is passed to the corresponding
 * method on [transform], along with a [StreamSink] linked to the [output] of
 * this pipe.
 * The handler can then decide which events to send to the output
 */
class TransformStream<S, T> extends _ForwardingTransformer<S, T> {
  final StreamTransformer<S, T> _transform;
  StreamSink<T> _sink;

  TransformStream(StreamTransformer<S, T> transform)
      : this._transform = transform {
    // Cache the sink wrapper to avoid creating a new one for each event.
    this._sink = new _StreamImplSink(this);
  }

  void _handleData(S data) {
    try {
      return _transform.handleData(data, _sink);
    } catch (e, s) {
      _controller.signalError(new AsyncError(e, s));
    }
  }

  void _handleError(AsyncError error) {
    try {
      _transform.handleError(error, _sink);
    } catch (e, s) {
      _controller.signalError(new AsyncError.withCause(e, s, error));
    }
  }

  void _handleDone() {
    try {
      _transform.handleDone(_sink);
    } catch (e, s) {
      _controller.signalError(new AsyncError(e, s));
    }
  }
}


/** Helper class for transforming three functions into a StreamTransformer. */
class _StreamTransformerFunctionWrapper<S, T>
    extends _StreamTransformer<S, T> {
  final _TransformDataHandler<S, T> _handleData;
  final _TransformErrorHandler<T> _handleError;
  final _TransformDoneHandler<T> _handleDone;

  _StreamTransformerFunctionWrapper({
      void onData(S data, StreamSink<T> sink),
      void onError(AsyncError data, StreamSink<T> sink),
      void onDone(StreamSink<T> sink)})
      : _handleData = onData != null ? onData : PipeStream._defaultHandleData,
        _handleError = onError != null ? onError
                                       : PipeStream._defaultHandleError,
        _handleDone = onDone != null ? onDone : PipeStream._defaultHandleDone;

  void handleData(S data, StreamSink<T> sink) {
    return _handleData(data, sink);
  }

  void handleError(AsyncError error, StreamSink<T> sink) {
    _handleError(error, sink);
  }

  void handleDone(StreamSink<T> sink) {
    _handleDone(sink);
  }
}


class TakeStream<T> extends _ForwardingTransformer<T, T> {
  int _remaining;

  TakeStream(int count)
      : this._remaining = count {
    if (count is! int) throw new ArgumentError(count);
  }

  void _handleData(T inputEvent) {
    if (_remaining > 0) {
      _add(inputEvent);
      _remaining -= 1;
      if (_remaining == 0) {
        // Closing also unsubscribes all subscribers, which unsubscribes
        // this from source.
        _close();
      }
    }
  }
}


class TakeWhileStream<T> extends _ForwardingTransformer<T, T> {
  final _Predicate<T> _test;

  TakeWhileStream(bool test(T value))
      : this._test = test;

  void _handleData(T inputEvent) {
    bool satisfies;
    try {
      satisfies = _test(inputEvent);
    } catch (e, s) {
      _signalError(new AsyncError(e, s));
      // The test didn't say true. Didn't say false either, but we stop anyway.
      _close();
      return;
    }
    if (satisfies) {
      _add(inputEvent);
    } else {
      _close();
    }
  }
}

class SkipStream<T> extends _ForwardingTransformer<T, T> {
  int _remaining;

  SkipStream(int count)
      : this._remaining = count{
    if (count is! int) throw new ArgumentError(count);
  }

  void _handleData(T inputEvent) {
    if (_remaining > 0) {
      _remaining--;
      return;
    }
    return _add(inputEvent);
  }
}

class SkipWhileStream<T> extends _ForwardingTransformer<T, T> {
  final _Predicate<T> _test;
  bool _hasFailed = false;

  SkipWhileStream(bool test(T value))
      : this._test = test;

  void _handleData(T inputEvent) {
    if (_hasFailed) {
      _add(inputEvent);
    }
    bool satisfies;
    try {
      satisfies = _test(inputEvent);
    } catch (e, s) {
      _signalError(new AsyncError(e, s));
      // A failure to return a boolean is considered "not matching".
      _hasFailed = true;
      return;
    }
    if (!satisfies) {
      _hasFailed = true;
      _add(inputEvent);
    }
  }
}

typedef bool _Equality<T>(T a, T b);

class DistinctStream<T> extends _ForwardingTransformer<T, T> {
  static var _SENTINEL = new Object();

  _Equality<T> _equals;
  var _previous = _SENTINEL;

  DistinctStream(bool equals(T a, T b))
      : _equals = equals;

  void _handleData(T inputEvent) {
    if (identical(_previous, _SENTINEL)) {
      _previous = inputEvent;
      return _add(inputEvent);
    } else {
      bool isEqual;
      try {
        if (_equals == null) {
          isEqual = (_previous == inputEvent);
        } else {
          isEqual = _equals(_previous, inputEvent);
        }
      } catch (e, s) {
        _signalError(new AsyncError(e, s));
        return null;
      }
      if (!isEqual) {
        _add(inputEvent);
        _previous = inputEvent;
      }
    }
  }
}

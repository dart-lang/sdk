// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * Helper class to wrap a [StreamConsumer<List<int>, T>] and provide utility
 * functions for writing to the StreamConsumer directly. The [IOSink]
 * buffers the input given by [add] and [addString] and will delay a [consume]
 * or [addStream] until the buffer is flushed.
 *
 * When the [IOSink] is bound to a stream (through either [consume]
 * or [addStream]) any call to the [IOSink] will throw a
 * [StateError].
 */
abstract class IOSink<T> implements StreamConsumer<List<int>, T> {
  factory IOSink(StreamConsumer<List<int>, T> target)
      => new _IOSinkImpl(target);

  /**
   * Provide functionality for piping to the [IOSink].
   */
  Future<T> consume(Stream<List<int>> stream);

  /**
   * Like [consume], but will not close the target when done.
   */
  Future<T> addStream(Stream<List<int>> stream);

  /**
   * Write a list of bytes to the target.
   */
  void add(List<int> data);

  /**
   * Write a String to the target.
   */
  void addString(String string, [Encoding encoding = Encoding.UTF_8]);

  /**
   * Close the target.
   */
  void close();

  /**
   * Get future that will complete when all data has been written to
   * the IOSink and it has been closed.
   */
  Future<T> get done;
}


class _IOSinkImpl<T> implements IOSink<T> {
  final StreamConsumer<List<int>, T> _target;

  StreamController<List<int>> _controllerInstance;
  Future<T> _pipeFuture;
  StreamSubscription<List<int>> _bindSubscription;
  bool _paused = true;

  _IOSinkImpl(StreamConsumer<List<int>, T> target) : _target = target;

  Future<T> consume(Stream<List<int>> stream) {
    if (_isBound) {
      throw new StateError("IOSink is already bound to a stream");
    }
    return _fillFromStream(stream);
  }

  Future<T> addStream(Stream<List<int>> stream) {
    if (_isBound) {
      throw new StateError("IOSink is already bound to a stream");
    }
    return _fillFromStream(stream, unbind: true);
  }

  void add(List<int> data) {
    if (_isBound) {
      throw new StateError("IOSink is already bound to a stream");
    }
    _controller.add(data);
  }

  void addString(String string, [Encoding encoding = Encoding.UTF_8]) {
    add(_encodeString(string, encoding));
  }

  void close() {
    if (_isBound) {
      throw new StateError("IOSink is already bound to a stream");
    }
    _controller.close();
  }

  Future<T> get done {
    _controller;
    return _pipeFuture.then((_) => this);
  }

  StreamController<List<int>> get _controller {
    if (_controllerInstance == null) {
      _controllerInstance = new StreamController<List<int>>(
          onPauseStateChange: _onPauseStateChange,
          onSubscriptionStateChange: _onSubscriptionStateChange);
      _pipeFuture = _controller.stream.pipe(_target).then((_) => this);
    }
    return _controllerInstance;
  }

  bool get _isBound => _bindSubscription != null;

  void _onPauseStateChange() {
    _paused = _controller.isPaused;
    if (_controller.isPaused) {
      _pause();
    } else {
      _resume();
    }
  }

  void _pause() {
    if (_bindSubscription != null) {
      try {
        // The subscription can be canceled at this point.
        _bindSubscription.pause();
      } catch (e) {
      }
    }
  }

  void _resume() {
    if (_bindSubscription != null) {
      try {
        // The subscription can be canceled at this point.
        _bindSubscription.resume();
      } catch (e) {
      }
    }
  }

  void _onSubscriptionStateChange() {
    if (_controller.hasSubscribers) {
      _paused = false;
      _resume();
    } else {
      if (_bindSubscription != null) {
        _bindSubscription.cancel();
        _bindSubscription = null;
      }
    }
  }

  Future<T> _fillFromStream(Stream<List<int>> stream, {unbind: false}) {
    _controller;
    Completer<T> unbindCompleter;
    if (unbind) {
      unbindCompleter = new Completer<T>();
    }
    completeUnbind([error]) {
      if (unbindCompleter == null) return;
      var tmp = unbindCompleter;
      unbindCompleter = null;
      if (error == null) {
        _bindSubscription = null;
        tmp.complete();
      } else {
        tmp.completeError(error);
      }
    }
    _bindSubscription = stream.listen(
        _controller.add,
        onDone: () {
          if (unbind) {
            completeUnbind();
          } else {
            _controller.close();
          }
        },
        onError: _controller.signalError);
    if (_paused) _pause();
    if (unbind) {
      _pipeFuture
          .then((_) => completeUnbind(),
                onError: (error) => completeUnbind(error));
      return unbindCompleter.future;
    } else {
      return _pipeFuture.then((_) => this);
    }
  }
}

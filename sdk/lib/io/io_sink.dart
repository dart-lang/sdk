// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * Helper class to wrap a [StreamConsumer<List<int>, T>] and provide
 * utility functions for writing to the StreamConsumer directly. The
 * [IOSink] buffers the input given by [write], [writeAll], [writeln],
 * [writeCharCode] and [add] and will delay a [consume] or
 * [writeStream] until the buffer is flushed.
 *
 * When the [IOSink] is bound to a stream (through either [consume]
 * or [writeStream]) any call to the [IOSink] will throw a
 * [StateError].
 */
abstract class IOSink<T>
    implements StreamConsumer<List<int>, T>, StringSink, EventSink<List<int>> {
  factory IOSink(StreamConsumer<List<int>, T> target,
                 {Encoding encoding: Encoding.UTF_8})
      => new _IOSinkImpl(target, encoding);

  /**
   * The [Encoding] used when writing strings. Depending on the
   * underlying consumer this property might be mutable.
   */
  Encoding encoding;

  /**
   * Writes the bytes uninterpreted to the consumer.
   */
  void add(List<int> data);

  /**
   * Writes an error to the consumer.
   */
  void addError(AsyncError error);

  /**
   * Provide functionality for piping to the [IOSink].
   */
  Future<T> consume(Stream<List<int>> stream);

  /**
   * Adds all elements of the given [stream] to `this`.
   */
  Future<T> addStream(Stream<List<int>> stream);

  /**
   * Like [consume], but will not close the target when done.
   *
   * *Deprecated*: use [addStream] instead.
   */
  Future<T> writeStream(Stream<List<int>> stream);

  /**
   * Close the target.
   */
  // TODO(floitsch): Currently the future cannot be typed because it has
  // hardcoded type Future<HttpClientResponse> in subclass HttpClientRequest.
  Future close();

  /**
   * Get future that will complete when all data has been written to
   * the IOSink and it has been closed.
   */
  Future<T> get done;
}


class _IOSinkImpl<T> implements IOSink<T> {
  final StreamConsumer<List<int>, T> _target;

  Completer _writeStreamCompleter;
  StreamController<List<int>> _controllerInstance;
  Future<T> _pipeFuture;
  StreamSubscription<List<int>> _bindSubscription;
  bool _paused = true;
  bool _encodingMutable = true;

  _IOSinkImpl(StreamConsumer<List<int>, T> this._target, this._encoding);

  Encoding _encoding;

  Encoding get encoding => _encoding;

  void set encoding(Encoding value) {
    if (!_encodingMutable) {
      throw new StateError("IOSink encoding is not mutable");
    }
    _encoding = value;
  }

  void write(Object obj) {
    // This comment is copied from runtime/lib/string_buffer_patch.dart.
    // TODO(srdjan): The following four lines could be replaced by
    // '$obj', but apparently this is too slow on the Dart VM.
    String string;
    if (obj is String) {
      string = obj;
    } else {
      string = obj.toString();
      if (string is! String) {
        throw new ArgumentError('toString() did not return a string');
      }
    }
    if (string.isEmpty) return;
    add(_encodeString(string, _encoding));
  }

  void writeAll(Iterable objects, [String separator = ""]) {
    Iterator iterator = objects.iterator;
    if (!iterator.moveNext()) return;
    if (separator.isEmpty) {
      do {
        write(iterator.current);
      } while (iterator.moveNext());
    } else {
      write(iterator.current);
      while (iterator.moveNext()) {
        write(separator);
        write(iterator.current);
      }
    }
  }

  void writeln([Object obj = ""]) {
    write(obj);
    write("\n");
  }

  void writeCharCode(int charCode) {
    write(new String.fromCharCode(charCode));
  }

  void add(List<int> data) {
    if (_isBound) {
      throw new StateError("IOSink is already bound to a stream");
    }
    _controller.add(data);
  }

  void addError(AsyncError error) {
    if (_isBound) {
      throw new StateError("IOSink is already bound to a stream");
    }
    _controller.addError(error);
  }

  Future<T> consume(Stream<List<int>> stream) {
    if (_isBound) {
      throw new StateError("IOSink is already bound to a stream");
    }
    return _fillFromStream(stream);
  }

  Future<T> writeStream(Stream<List<int>> stream) {
    return addStream(stream);
  }

  Future<T> addStream(Stream<List<int>> stream) {
    if (_isBound) {
      throw new StateError("IOSink is already bound to a stream");
    }
    return _fillFromStream(stream, unbind: true);
  }

  Future close() {
    if (_isBound) {
      throw new StateError("IOSink is already bound to a stream");
    }
    _controller.close();
    return _pipeFuture;
  }

  Future<T> get done {
    _controller;
    return _pipeFuture;
  }

  void _completeWriteStreamCompleter([error]) {
    if (_writeStreamCompleter == null) return;
    var tmp = _writeStreamCompleter;
    _writeStreamCompleter = null;
    if (error == null) {
      _bindSubscription = null;
      tmp.complete();
    } else {
      tmp.completeError(error);
    }
  }

  StreamController<List<int>> get _controller {
    if (_controllerInstance == null) {
      _controllerInstance = new StreamController<List<int>>(
          onPauseStateChange: _onPauseStateChange,
          onSubscriptionStateChange: _onSubscriptionStateChange);
      var future = _controller.stream.pipe(_target);
      future.then((_) => _completeWriteStreamCompleter(),
                  onError: (error) => _completeWriteStreamCompleter(error));
      _pipeFuture = future.then((value) => value);
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
    assert(_writeStreamCompleter == null);
    if (unbind) {
      _writeStreamCompleter = new Completer<T>();
    }
    _bindSubscription = stream.listen(
        _controller.add,
        onDone: () {
          if (unbind) {
            _completeWriteStreamCompleter();
          } else {
            _controller.close();
          }
        },
        onError: _controller.addError);
    if (_paused) _pause();
    if (unbind) {
      return _writeStreamCompleter.future;
    } else {
      return _pipeFuture;
    }
  }
}

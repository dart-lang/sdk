// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * Helper class to wrap a [StreamConsumer<List<int>>] and provide
 * utility functions for writing to the StreamConsumer directly. The
 * [IOSink] buffers the input given by all [StringSink] methods and will delay
 * a [addStream] until the buffer is flushed.
 *
 * When the [IOSink] is bound to a stream (through [addStream]) any call
 * to the [IOSink] will throw a [StateError]. When the [addStream] completes,
 * the [IOSink] will again be open for all calls.
 *
 * If data is added to the [IOSink] after the sink is closed, the data will be
 * ignored. Use the [done] future to be notified when the [IOSink] is closed.
 */
abstract class IOSink implements StreamSink<List<int>>, StringSink {
  factory IOSink(StreamConsumer<List<int>> target,
                 {Encoding encoding: UTF8})
      => new _IOSinkImpl(target, encoding);

  /**
   * The [Encoding] used when writing strings. Depending on the
   * underlying consumer this property might be mutable.
   */
  Encoding encoding;

  /**
   * Writes the bytes uninterpreted to the consumer. While the call is
   * synchronous, the data may be buffered until the underlying resource is
   * ready. The data should not be modified after a call to [add].
   */
  void add(List<int> data);

  /**
   * Writes an error to the consumer.
   */
  void addError(error, [StackTrace stackTrace]);

  /**
   * Adds all elements of the given [stream] to `this`.
   */
  Future addStream(Stream<List<int>> stream);

  /**
   * Returns a [Future] that completes once all buffered data is accepted by the
   * to underlying [StreamConsumer].
   *
   * It's an error to call this method, while an [addStream] is incomplete.
   *
   * NOTE: This is not necessarily the same as the data being flushed by the
   * operating system.
   */
  Future flush();

  /**
   * Close the target.
   */
  Future close();

  /**
   * Get a future that will complete when all synchronous have completed, or an
   * error happened. This future is identical to the future returned from close.
   */
  Future get done;
}

class _StreamSinkImpl<T> implements StreamSink<T> {
  final StreamConsumer<T> _target;
  Completer _doneCompleter = new Completer();
  Future _doneFuture;
  StreamController<T> _controllerInstance;
  Completer _controllerCompleter;
  bool _isClosed = false;
  bool _isBound = false;
  bool _hasError = false;

  _StreamSinkImpl(StreamConsumer<T> this._target) {
    _doneFuture = _doneCompleter.future;
  }

  void add(T data) {
    if (_isClosed) return;
    _controller.add(data);
  }

  void addError(error, [StackTrace stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  Future addStream(Stream<T> stream) {
    if (_isBound) {
      throw new StateError("StreamSink is already bound to a stream");
    }
    _isBound = true;
    if (_hasError) return done;
    // Wait for any sync operations to complete.
    Future targetAddStream() {
      return _target.addStream(stream)
          .whenComplete(() {
            _isBound = false;
          });
    }
    if (_controllerInstance == null) return targetAddStream();
    var future = _controllerCompleter.future;
    _controllerInstance.close();
    return future.then((_) => targetAddStream());
  }

  Future flush() {
    // Adding an empty stream-controller will return a future that will complete
    // when all data is done.
    var controller = new StreamController()..close();
    return addStream(controller.stream).then((_) => this);
  }

  Future close() {
    if (_isBound) {
      throw new StateError("StreamSink is bound to a stream");
    }
    if (!_isClosed) {
      _isClosed = true;
      if (_controllerInstance != null) {
        _controllerInstance.close();
      } else {
        _closeTarget();
      }
    }
    return done;
  }

  void _closeTarget() {
    _target.close()
        .then((value) => _completeDone(value: value),
              onError: (error) => _completeDone(error: error));
  }

  Future get done => _doneFuture;

  void _completeDone({value, error}) {
    if (_doneCompleter == null) return;
    if (error == null) {
      _doneCompleter.complete(value);
    } else {
      _hasError = true;
      _doneCompleter.completeError(error);
    }
    _doneCompleter = null;
  }

  StreamController<T> get _controller {
    if (_isBound) {
      throw new StateError("StreamSink is bound to a stream");
    }
    if (_isClosed) {
      throw new StateError("StreamSink is closed");
    }
    if (_controllerInstance == null) {
      _controllerInstance = new StreamController<T>(sync: true);
      _controllerCompleter = new Completer();
      _target.addStream(_controller.stream)
          .then(
              (_) {
                if (_isBound) {
                  // A new stream takes over - forward values to that stream.
                  _controllerCompleter.complete();
                  _controllerCompleter = null;
                  _controllerInstance = null;
                } else {
                  // No new stream, .close was called. Close _target.
                  _closeTarget();
                }
              },
              onError: (error) {
                if (_isBound) {
                  // A new stream takes over - forward errors to that stream.
                  _controllerCompleter.completeError(error);
                  _controllerCompleter = null;
                  _controllerInstance = null;
                } else {
                  // No new stream. No need to close target, as it have already
                  // failed.
                  _completeDone(error: error);
                }
              });
    }
    return _controllerInstance;
  }
}


class _IOSinkImpl extends _StreamSinkImpl<List<int>> implements IOSink {
  Encoding _encoding;
  bool _encodingMutable = true;

  _IOSinkImpl(StreamConsumer<List<int>> target, this._encoding)
      : super(target);

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
    add(_encoding.encode(string));
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
}

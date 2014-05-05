// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.utils.stream_replayer;

import 'dart:async';
import 'dart:collection';

import '../utils.dart';

/// Records the values and errors that are sent through a stream and allows them
/// to be replayed arbitrarily many times.
///
/// This only listens to the wrapped stream when a replayed stream gets a
/// listener.
class StreamReplayer<T> {
  /// The wrapped stream.
  final Stream<T> _stream;

  /// Whether or not [this] has started listening to [_stream].
  bool _isSubscribed = false;

  /// Whether or not [_stream] has been closed.
  bool _isClosed = false;

  /// The buffer of events or errors that have already been emitted by
  /// [_stream].
  ///
  /// Each element is a [Fallible] that's either a value or an error sent
  /// through the stream.
  final _buffer = new Queue<Fallible<T>>();

  /// The controllers that are listening for future events from [_stream].
  final _controllers = new Set<StreamController<T>>();

  StreamReplayer(this._stream);

  /// Returns a stream that replays the values and errors of the input stream.
  ///
  /// This stream is a buffered stream.
  Stream<T> getReplay() {
    var controller = new StreamController<T>(onListen: _subscribe);

    for (var eventOrError in _buffer) {
      if (eventOrError.hasValue) {
        controller.add(eventOrError.value);
      } else {
        controller.addError(eventOrError.error, eventOrError.stackTrace);
      }
    }
    if (_isClosed) {
      controller.close();
    } else {
      _controllers.add(controller);
    }
    return controller.stream;
  }

  /// Subscribe to [_stream] if we haven't yet done so.
  void _subscribe() {
    if (_isSubscribed || _isClosed) return;
    _isSubscribed = true;

    _stream.listen((data) {
      _buffer.add(new Fallible<T>.withValue(data));
      for (var controller in _controllers) {
        controller.add(data);
      }
    }, onError: (error, [stackTrace]) {
      _buffer.add(new Fallible<T>.withError(error, stackTrace));
      for (var controller in _controllers) {
        controller.addError(error, stackTrace);
      }
    }, onDone: () {
      _isClosed = true;
      for (var controller in _controllers) {
        controller.close();
      }
      _controllers.clear();
    });
  }
}

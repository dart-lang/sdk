// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_rpc_2.two_way_stream;

import 'dart:async';
import 'dart:convert';

import 'utils.dart';

/// A class for managing a stream of input messages and a sink for output
/// messages.
///
/// This contains stream logic that's shared between [Server] and [Client].
class TwoWayStream {
  /// The name of the component whose streams are being managed (e.g. "Server").
  ///
  /// Used for error reporting.
  final String _name;

  /// The input stream.
  ///
  /// This is a stream of decoded JSON objects.
  final Stream _input;

  /// The subscription to [_input].
  StreamSubscription _inputSubscription;

  /// The output sink.
  ///
  /// This takes decoded JSON objects.
  final StreamSink _output;

  /// The completer for [listen].
  ///
  /// This is non-`null` after [listen] has been called.
  Completer _listenCompleter;

  /// Creates a two-way stream.
  ///
  /// [input] and [output] should emit and take (respectively) JSON-encoded
  /// strings.
  ///
  /// [inputName] is used in error messages as the name of the input parameter.
  /// [outputName] is likewise used as the name of the output parameter.
  ///
  /// If [onInvalidInput] is passed, any errors parsing messages from [input]
  /// are passed to it. Otherwise, they're ignored and the input is discarded.
  factory TwoWayStream(String name, Stream<String> input, String inputName,
      StreamSink<String> output, String outputName,
      {void onInvalidInput(String message, FormatException error)}) {
    if (output == null) {
      if (input is! StreamSink) {
        throw new ArgumentError("Either `$inputName` must be a StreamSink or "
            "`$outputName` must be passed.");
      }
      output = input as StreamSink;
    }

    var wrappedOutput = mapStreamSink(output, JSON.encode);
    return new TwoWayStream.withoutJson(name, input.expand((message) {
      var decodedMessage;
      try {
        decodedMessage = JSON.decode(message);
      } on FormatException catch (error) {
        if (onInvalidInput != null) onInvalidInput(message, error);
        return [];
      }

      return [decodedMessage];
    }), inputName, wrappedOutput, outputName);
  }

  /// Creates a two-way stream that reads decoded input and writes decoded
  /// responses.
  ///
  /// [input] and [output] should emit and take (respectively) decoded JSON
  /// objects.
  ///
  /// [inputName] is used in error messages as the name of the input parameter.
  /// [outputName] is likewise used as the name of the output parameter.
  TwoWayStream.withoutJson(this._name, Stream input, String inputName,
          StreamSink output, String outputName)
      : _input = input,
        _output = output == null && input is StreamSink ? input : output {
    if (_output == null) {
      throw new ArgumentError("Either `$inputName` must be a StreamSink or "
          "`$outputName` must be passed.");
    }
  }

  /// Starts listening to the input stream.
  ///
  /// The returned Future will complete when the input stream is closed. If the
  /// input stream emits an error, that will be piped to the returned Future.
  Future listen(void handleInput(input)) {
    if (_listenCompleter != null) {
      throw new StateError("Can only call $_name.listen once.");
    }

    _listenCompleter = new Completer();
    _inputSubscription = _input.listen(handleInput,
        onError: (error, stackTrace) {
      if (_listenCompleter.isCompleted) return;
      _output.close();
      _listenCompleter.completeError(error, stackTrace);
    }, onDone: () {
      if (_listenCompleter.isCompleted) return;
      _output.close();
      _listenCompleter.complete();
    }, cancelOnError: true);

    return _listenCompleter.future;
  }

  /// Emit [event] on the output stream.
  void add(event) => _output.add(event);

  /// Stops listening to the input stream and closes the output stream.
  Future close() {
    if (_listenCompleter == null) {
      throw new StateError("Can't call $_name.close before $_name.listen.");
    }

    if (!_listenCompleter.isCompleted) _listenCompleter.complete();

    var inputFuture = _inputSubscription.cancel();
    // TODO(nweiz): include the output future in the return value when issue
    // 19095 is fixed.
    _output.close();
    return inputFuture == null ? new Future.value() : inputFuture;
  }
}

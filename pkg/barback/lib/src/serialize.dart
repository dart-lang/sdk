// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.serialize;

import 'dart:async';
import 'dart:isolate';

import 'package:stack_trace/stack_trace.dart';

import 'asset_id.dart';
import 'utils.dart';

/// Converts [id] into a serializable map.
Map serializeId(AssetId id) => {'package': id.package, 'path': id.path};

/// Converts [stream] into a [SendPort] with which another isolate can request
/// the data from [stream].
SendPort serializeStream(Stream stream) {
  var receivePort = new ReceivePort();
  receivePort.first.then((sendPort) {
    stream.listen((data) => sendPort.send({'type': 'data', 'data': data}),
        onDone: () => sendPort.send({'type': 'done'}),
        onError: (error, stackTrace) {
      sendPort.send({
        'type': 'error',
        'error': CrossIsolateException.serialize(error, stackTrace)
      });
    });
  });

  return receivePort.sendPort;
}

/// Converts a serializable map into an [AssetId].
AssetId deserializeId(Map id) => new AssetId(id['package'], id['path']);

/// Convert a [SendPort] whose opposite is waiting to send us a stream into a
/// [Stream].
///
/// No stream data will actually be sent across the isolate boundary until
/// someone subscribes to the returned stream.
Stream deserializeStream(SendPort sendPort) {
  return callbackStream(() {
    var receivePort = new ReceivePort();
    sendPort.send(receivePort.sendPort);
    // TODO(nweiz): use a const constructor for StreamTransformer when issue
    // 14971 is fixed.
    return receivePort.transform(
        new StreamTransformer(_deserializeTransformer));
  });
}

/// The body of a [StreamTransformer] that deserializes the values in a stream
/// sent by [serializeStream].
StreamSubscription _deserializeTransformer(Stream input, bool cancelOnError) {
  var subscription;
  var transformed = input.transform(new StreamTransformer.fromHandlers(
      handleData: (data, sink) {
    if (data['type'] == 'data') {
      sink.add(data['data']);
    } else if (data['type'] == 'error') {
      var exception = new CrossIsolateException.deserialize(data['error']);
      sink.addError(exception, exception.stackTrace);
    } else {
      assert(data['type'] == 'done');
      sink.close();
      subscription.cancel();
    }
  }));
  subscription = transformed.listen(null, cancelOnError: cancelOnError);
  return subscription;
}

/// An exception that was originally raised in another isolate.
///
/// Exception objects can't cross isolate boundaries in general, so this class
/// wraps as much information as can be consistently serialized.
class CrossIsolateException implements Exception {
  /// The name of the type of exception thrown.
  ///
  /// This is the return value of [error.runtimeType.toString()]. Keep in mind
  /// that objects in different libraries may have the same type name.
  final String type;

  /// The exception's message, or its [toString] if it didn't expose a `message`
  /// property.
  final String message;

  /// The exception's stack chain, or `null` if no stack chain was available.
  final Chain stackTrace;

  /// Loads a [CrossIsolateException] from a serialized representation.
  ///
  /// [error] should be the result of [CrossIsolateException.serialize].
  CrossIsolateException.deserialize(Map error)
      : type = error['type'],
        message = error['message'],
        stackTrace = error['stack'] == null ? null :
            new Chain.parse(error['stack']);

  /// Serializes [error] to an object that can safely be passed across isolate
  /// boundaries.
  static Map serialize(error, [StackTrace stack]) {
    if (stack == null && error is Error) stack = error.stackTrace;
    return {
      'type': error.runtimeType.toString(),
      'message': _getErrorMessage(error),
      'stack': stack == null ? null : new Chain.forTrace(stack).toString()
    };
  }

  String toString() => "$message\n$stackTrace";
}

/// A regular expression to match the exception prefix that some exceptions'
/// [Object.toString] values contain.
final _exceptionPrefix = new RegExp(r'^([A-Z][a-zA-Z]*)?(Exception|Error): ');

/// Get a string description of an exception.
///
/// Many exceptions include the exception class name at the beginning of their
/// [toString], so we remove that if it exists.
String _getErrorMessage(error) =>
  error.toString().replaceFirst(_exceptionPrefix, '');

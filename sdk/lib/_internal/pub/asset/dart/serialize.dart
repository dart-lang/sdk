// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.asset.serialize;

import 'dart:async';
import 'dart:isolate';

import 'package:barback/barback.dart';
import 'package:source_maps/span.dart';

import 'serialize/exception.dart';
import 'utils.dart';

export 'serialize/aggregate_transform.dart';
export 'serialize/exception.dart';
export 'serialize/transform.dart';
export 'serialize/transformer.dart';

/// Converts [id] into a serializable map.
Map serializeId(AssetId id) => {'package': id.package, 'path': id.path};

/// Converts a serializable map into an [AssetId].
AssetId deserializeId(Map id) => new AssetId(id['package'], id['path']);

/// Converts [span] into a serializable map.
Map serializeSpan(Span span) {
  // TODO(nweiz): convert FileSpans to FileSpans.
  return {
    'type': 'fixed',
    'sourceUrl': span.sourceUrl,
    'start': serializeLocation(span.start),
    'text': span.text,
    'isIdentifier': span.isIdentifier
  };
}

/// Converts a serializable map into a [Span].
Span deserializeSpan(Map span) {
  assert(span['type'] == 'fixed');
  var location = deserializeLocation(span['start']);
  return new FixedSpan(span['sourceUrl'], location.offset, location.line,
      location.column, text: span['text'], isIdentifier: span['isIdentifier']);
}

/// Converts [location] into a serializable map.
Map serializeLocation(Location location) {
  // TODO(nweiz): convert FileLocations to FileLocations.
  return {
    'type': 'fixed',
    'sourceUrl': location.sourceUrl,
    'offset': location.offset,
    'line': location.line,
    'column': location.column
  };
}

/// Converts a serializable map into a [Location].
Location deserializeLocation(Map location) {
  assert(location['type'] == 'fixed');
  return new FixedLocation(location['offset'], location['sourceUrl'],
      location['line'], location['column']);
}

/// Converts [stream] into a serializable map.
///
/// [serializeEvent] is used to serialize each event from the stream.
Map serializeStream(Stream stream, serializeEvent(event)) {
  var receivePort = new ReceivePort();
  var map = {'replyTo': receivePort.sendPort};

  receivePort.first.then((message) {
    var sendPort = message['replyTo'];
    stream.listen((event) {
      sendPort.send({
        'type': 'event',
        'value': serializeEvent(event)
      });
    }, onError: (error, stackTrace) {
      sendPort.send({
        'type': 'error',
        'error': serializeException(error, stackTrace)
      });
    }, onDone: () => sendPort.send({'type': 'done'}));
  });

  return map;
}

/// Converts a serializable map into a [Stream].
///
/// [deserializeEvent] is used to deserialize each event from the stream.
Stream deserializeStream(Map stream, deserializeEvent(event)) {
  return callbackStream(() {
    var receivePort = new ReceivePort();
    stream['replyTo'].send({'replyTo': receivePort.sendPort});

    var controller = new StreamController(sync: true);
    receivePort.listen((event) {
      switch (event['type']) {
        case 'event':
          controller.add(deserializeEvent(event['value']));
          break;
        case 'error':
          var exception = deserializeException(event['error']);
          controller.addError(exception, exception.stackTrace);
          break;
        case 'done':
          controller.close();
          receivePort.close();
          break;
      }
    });

    return controller.stream;
  });
}

/// Wraps [message] and sends it across [port], then waits for a response which
/// should be sent using [respond].
///
/// The returned Future will complete to the value or error returned by
/// [respond].
Future call(SendPort port, message) {
  var receivePort = new ReceivePort();
  port.send({
    'message': message,
    'replyTo': receivePort.sendPort
  });

  return receivePort.first.then((response) {
    if (response['type'] == 'success') return response['value'];
    assert(response['type'] == 'error');
    var exception = deserializeException(response['error']);
    return new Future.error(exception, exception.stackTrace);
  });
}

/// Responds to a message sent by [call].
///
/// [wrappedMessage] is the raw message sent by [call]. This unwraps it and
/// passes the contents of the message to [callback], then sends the return
/// value of [callback] back to [call]. If [callback] returns a Future or
/// throws an error, that will also be sent.
void respond(wrappedMessage, callback(message)) {
  var replyTo = wrappedMessage['replyTo'];
  new Future.sync(() => callback(wrappedMessage['message']))
      .then((result) => replyTo.send({'type': 'success', 'value': result}))
      .catchError((error, stackTrace) {
    replyTo.send({
      'type': 'error',
      'error': serializeException(error, stackTrace)
    });
  });
}

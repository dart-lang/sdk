// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.asset.serialize;

import 'dart:async';
import 'dart:isolate';

import 'package:barback/barback.dart';

//# if source_maps >=0.9.0 <0.10.0
//> import 'package:source_maps/span.dart';
//# end

//# if source_span
import 'package:source_span/source_span.dart';
//# end

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
///
/// [span] may be a [SourceSpan] or a [Span].
Map serializeSpan(span) {
  // TODO(nweiz): convert FileSpans to FileSpans.
  // Handily, this code works for both source_map and source_span spans.
  return {
    'sourceUrl': span.sourceUrl.toString(),
    'start': serializeLocation(span.start),
    'end': serializeLocation(span.end),
    'text': span.text,
  };
}

/// Converts a serializable map into a [SourceSpan].
SourceSpan deserializeSpan(Map span) {
  return new SourceSpan(
      deserializeLocation(span['start']),
      deserializeLocation(span['end']),
      span['text']);
}

/// Converts [location] into a serializable map.
///
/// [location] may be a [SourceLocation] or a [SourceLocation].
Map serializeLocation(location) {
//# if source_maps >=0.9.0 <0.10.0
//>  if (location is Location) {
//>    return {
//>      'sourceUrl': location.sourceUrl,
//>      'offset': location.offset,
//>      'line': location.line,
//>      'column': location.column
//>    };
//>  }
//# end

//# if source_span
  // TODO(nweiz): convert FileLocations to FileLocations.
  if (location is SourceLocation) {
    return {
      'sourceUrl': location.sourceUrl.toString(),
      'offset': location.offset,
      'line': location.line,
      'column': location.column
    };
  }
//# end

  throw new ArgumentError("Unknown type ${location.runtimeType} for location.");
}

/// Converts a serializable map into a [Location].
SourceLocation deserializeLocation(Map location) {
  return new SourceLocation(location['offset'],
      sourceUrl: location['sourceUrl'],
      line: location['line'],
      column: location['column']);
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

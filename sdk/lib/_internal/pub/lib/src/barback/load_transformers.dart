// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.load_transformers;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:barback/barback.dart';
// TODO(nweiz): don't import from "src" once issue 14966 is fixed.
import 'package:barback/src/internal_asset.dart';
import 'package:path/path.dart' as p;
import 'package:source_maps/source_maps.dart';
import 'package:stack_trace/stack_trace.dart';

import '../barback.dart';
import '../dart.dart' as dart;
import '../io.dart';
import '../log.dart' as log;
import '../utils.dart';
import 'build_environment.dart';
import 'excluding_transformer.dart';
import 'server.dart';

/// Load and return all transformers and groups from the library identified by
/// [id].
Future<Set> loadTransformers(BuildEnvironment environment,
    BarbackServer transformerServer, TransformerId id) {
  return id.getAssetId(environment.barback).then((assetId) {
    var path = assetId.path.replaceFirst('lib/', '');
    // TODO(nweiz): load from a "package:" URI when issue 12474 is fixed.

    var baseUrl = transformerServer.url;
    var uri = '$baseUrl/packages/${id.package}/$path';
    var code = 'import "$uri";\n' +
        readAsset(p.join("dart", "transformer_isolate.dart"))
            .replaceAll('<<URL_BASE>>', baseUrl);
    log.fine("Loading transformers from $assetId");

    var port = new ReceivePort();
    return dart.runInIsolate(code, port.sendPort)
        .then((_) => port.first)
        .then((sendPort) {
      return _call(sendPort, {
        'library': uri,
        'mode': environment.mode.name,
        // TODO(nweiz): support non-JSON-encodable configuration maps.
        'configuration': JSON.encode(id.configuration)
      }).then((transformers) {
        transformers = transformers.map(
            (transformer) => _deserializeTransformerOrGroup(transformer, id))
            .toSet();
        log.fine("Transformers from $assetId: $transformers");
        return transformers;
      });
    }).catchError((error, stackTrace) {
      if (error is! dart.CrossIsolateException) throw error;
      if (error.type != 'IsolateSpawnException') throw error;
      // TODO(nweiz): don't parse this as a string once issues 12617 and 12689
      // are fixed.
      if (!error.message.split('\n')[1].startsWith('import "$uri";')) {
        throw error;
      }

      // If there was an IsolateSpawnException and the import that actually
      // failed was the one we were loading transformers from, throw an
      // application exception with a more user-friendly message.
      fail('Transformer library "package:${id.package}/$path" not found.',
          error, stackTrace);
    });
  });
}

/// A wrapper for a transformer that's in a different isolate.
class _ForeignTransformer extends Transformer {
  /// The port with which we communicate with the child isolate.
  ///
  /// This port and all messages sent across it are specific to this
  /// transformer.
  final SendPort _port;

  /// The result of calling [toString] on the transformer in the isolate.
  final String _toString;

  _ForeignTransformer(Map map)
      : _port = map['port'],
        _toString = map['toString'];

  Future<bool> isPrimary(Asset asset) {
    return _call(_port, {
      'type': 'isPrimary',
      'asset': serializeAsset(asset)
    });
  }

  Future apply(Transform transform) {
    return _call(_port, {
      'type': 'apply',
      'transform': _serializeTransform(transform)
    });
  }

  String toString() => _toString;
}

/// A wrapper for a transformer group that's in a different isolate.
class _ForeignGroup implements TransformerGroup {
  final Iterable<Iterable> phases;

  /// The result of calling [toString] on the transformer group in the isolate.
  final String _toString;

  _ForeignGroup(TransformerId id, Map map)
      : phases = map['phases'].map((phase) {
          return phase.map((transformer) => _deserializeTransformerOrGroup(
              transformer, id)).toList();
        }).toList(),
        _toString = map['toString'];

  String toString() => _toString;
}

/// Converts a serializable map into a [Transformer] or a [TransformerGroup].
_deserializeTransformerOrGroup(Map map, TransformerId id) {
  if (map['type'] == 'Transformer') {
    var transformer = new _ForeignTransformer(map);
    return ExcludingTransformer.wrap(transformer, id.includes, id.excludes);
  }

  assert(map['type'] == 'TransformerGroup');
  return new _ForeignGroup(id, map);
}

/// Converts [transform] into a serializable map.
Map _serializeTransform(Transform transform) {
  var receivePort = new ReceivePort();
  receivePort.listen((wrappedMessage) {
    _respond(wrappedMessage, (message) {
      if (message['type'] == 'getInput') {
        return transform.getInput(_deserializeId(message['id']))
            .then((asset) => serializeAsset(asset));
      }

      if (message['type'] == 'addOutput') {
        transform.addOutput(deserializeAsset(message['output']));
        return null;
      }

      if (message['type'] == 'consumePrimary') {
        transform.consumePrimary();
        return null;
      }

      assert(message['type'] == 'log');
      var method;
      if (message['level'] == 'Info') {
        method = transform.logger.info;
      } else if (message['level'] == 'Fine') {
        method = transform.logger.fine;
      } else if (message['level'] == 'Warning') {
        method = transform.logger.warning;
      } else {
        assert(message['level'] == 'Error');
        method = transform.logger.error;
      }

      var assetId = message['assetId'] == null ? null :
        _deserializeId(message['assetId']);
      var span = message['span'] == null ? null :
        _deserializeSpan(message['span']);
      method(message['message'], asset: assetId, span: span);
    });
  });

  return {
    'port': receivePort.sendPort,
    'primaryInput': serializeAsset(transform.primaryInput)
  };
}

/// Converts a serializable map into an [AssetId].
AssetId _deserializeId(Map id) => new AssetId(id['package'], id['path']);

/// Converts a serializable map into a [Span].
Span _deserializeSpan(Map span) {
  assert(span['type'] == 'fixed');
  var location = _deserializeLocation(span['start']);
  return new FixedSpan(span['sourceUrl'], location.offset, location.line,
      location.column, text: span['text'], isIdentifier: span['isIdentifier']);
}

/// Converts a serializable map into a [Location].
Location _deserializeLocation(Map location) {
  assert(location['type'] == 'fixed');
  return new FixedLocation(location['offset'], location['sourceUrl'],
      location['line'], location['column']);
}

/// Converts [id] into a serializable map.
Map _serializeId(AssetId id) => {'package': id.package, 'path': id.path};

/// Responds to a message sent by [_call].
///
/// [wrappedMessage] is the raw message sent by [_call]. This unwraps it and
/// passes the contents of the message to [callback], then sends the return
/// value of [callback] back to [_call]. If [callback] returns a Future or
/// throws an error, that will also be sent.
void _respond(wrappedMessage, callback(message)) {
  var replyTo = wrappedMessage['replyTo'];
  syncFuture(() => callback(wrappedMessage['message']))
      .then((result) => replyTo.send({'type': 'success', 'value': result}))
      .catchError((error, stackTrace) {
    replyTo.send({
      'type': 'error',
      'error': _serializeException(error, stackTrace)
    });
  });
}

/// Wraps [message] and sends it across [port], then waits for a response which
/// should be sent using [_respond].
///
/// The returned Future will complete to the value or error returned by
/// [_respond].
Future _call(SendPort port, message) {
  var receivePort = new ReceivePort();
  port.send({
    'message': message,
    'replyTo': receivePort.sendPort
  });

  return Chain.track(receivePort.first).then((response) {
    if (response['type'] == 'success') return response['value'];
    assert(response['type'] == 'error');
    var exception = _deserializeException(response['error']);
    return new Future.error(exception, exception.stackTrace);
  });
}

/// An [AssetNotFoundException] that was originally raised in another isolate. 
class _CrossIsolateAssetNotFoundException extends dart.CrossIsolateException
    implements AssetNotFoundException {
  final AssetId id;

  String get message => "Could not find asset $id.";

  /// Loads a [_CrossIsolateAssetNotFoundException] from a serialized
  /// representation.
  ///
  /// [error] should be the result of
  /// [_CrossIsolateAssetNotFoundException.serialize].
  _CrossIsolateAssetNotFoundException.deserialize(Map error)
      : id = new AssetId(error['package'], error['path']),
        super.deserialize(error);

  /// Serializes [error] to an object that can safely be passed across isolate
  /// boundaries.
  static Map serialize(AssetNotFoundException error, [StackTrace stack]) {
    var map = dart.CrossIsolateException.serialize(error);
    map['package'] = error.id.package;
    map['path'] = error.id.path;
    return map;
  }
}

/// Serializes [error] to an object that can safely be passed across isolate
/// boundaries.
///
/// This handles [AssetNotFoundException]s specially, ensuring that their
/// metadata is preserved.
Map _serializeException(error, [StackTrace stack]) {
  if (error is AssetNotFoundException) {
    return _CrossIsolateAssetNotFoundException.serialize(error, stack);
  } else {
    return dart.CrossIsolateException.serialize(error, stack);
  }
}

/// Loads an exception from a serialized representation.
///
/// This handles [AssetNotFoundException]s specially, ensuring that their
/// metadata is preserved.
dart.CrossIsolateException _deserializeException(Map error) {
  if (error['type'] == 'AssetNotFoundException') {
    return new _CrossIsolateAssetNotFoundException.deserialize(error);
  } else {
    return new dart.CrossIsolateException.deserialize(error);
  }
}

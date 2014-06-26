// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.asset.serialize.aggregate_transform;

import 'dart:async';
import 'dart:isolate';

import 'package:barback/barback.dart';
// TODO(nweiz): don't import from "src" once issue 14966 is fixed.
import 'package:barback/src/internal_asset.dart';

import '../serialize.dart';
import 'get_input_transform.dart';

/// Serialize the methods shared between [AggregateTransform] and
/// [DeclaringAggregateTransform].
///
/// [additionalFields] contains additional serialized fields to add to the
/// serialized transform. [methodHandlers] is a set of additional methods. Each
/// value should take a JSON message and return the response (which may be a
/// Future).
Map _serializeBaseAggregateTransform(transform, Map additionalFields,
    Map<String, Function> methodHandlers) {
  var receivePort = new ReceivePort();
  receivePort.listen((wrappedMessage) {
    respond(wrappedMessage, (message) {
      var handler = methodHandlers[message['type']];
      if (handler != null) return handler(message);

      if (message['type'] == 'consumePrimary') {
        transform.consumePrimary(deserializeId(message['assetId']));
        return null;
      }

      assert(message['type'] == 'log');
      var method = {
        'Info': transform.logger.info,
        'Fine': transform.logger.fine,
        'Warning': transform.logger.warning,
        'Error': transform.logger.error
      }[message['level']];
      assert(method != null);

      var assetId = message['assetId'] == null ? null :
        deserializeId(message['assetId']);
      var span = message['span'] == null ? null :
        deserializeSpan(message['span']);
      method(message['message'], asset: assetId, span: span);
    });
  });

  return {
    'port': receivePort.sendPort,
    'key': transform.key,
    'package': transform.package
  }..addAll(additionalFields);
}

/// Converts [transform] into a serializable map.
Map serializeAggregateTransform(AggregateTransform transform) {
  return _serializeBaseAggregateTransform(transform, {
    'primaryInputs': serializeStream(transform.primaryInputs, serializeAsset)
  }, {
    'getInput': (message) => transform.getInput(deserializeId(message['id']))
        .then((asset) => serializeAsset(asset)),
    'addOutput': (message) =>
        transform.addOutput(deserializeAsset(message['output']))
  });
}

/// Converts [transform] into a serializable map.
Map serializeDeclaringAggregateTransform(
    DeclaringAggregateTransform transform) {
  return _serializeBaseAggregateTransform(transform, {
    'primaryIds': serializeStream(transform.primaryIds, serializeId)
  }, {
    'declareOutput': (message) =>
        transform.declareOutput(deserializeId(message['output']))
  });
}

/// The base class for wrappers for [AggregateTransform]s that are in the host
/// isolate.
class _ForeignBaseAggregateTransform {
  /// The port with which we communicate with the host isolate.
  ///
  /// This port and all messages sent across it are specific to this transform.
  final SendPort _port;

  final String key;

  final String package;

  TransformLogger get logger => _logger;
  TransformLogger _logger;

  _ForeignBaseAggregateTransform(Map transform)
      : _port = transform['port'],
        key = transform['key'],
        package = transform['package'] {
    _logger = new TransformLogger((assetId, level, message, span) {
      call(_port, {
        'type': 'log',
        'level': level.name,
        'message': message,
        'assetId': assetId == null ? null : serializeId(assetId),
        'span': span == null ? null : serializeSpan(span)
      });
    });
  }

  void consumePrimary(AssetId id) {
    call(_port, {'type': 'consumePrimary', 'assetId': serializeId(id)});
  }
}

// We can get away with only removing the class declarations in incompatible
// barback versions because merely referencing undefined types in type
// annotations isn't a static error. Only implementing an undefined interface is
// a static error.
//# if barback >=0.14.1

/// A wrapper for an [AggregateTransform] that's in the host isolate.
///
/// This retrieves inputs from and sends outputs and logs to the host isolate.
class ForeignAggregateTransform extends _ForeignBaseAggregateTransform
    with GetInputTransform implements AggregateTransform {
  final Stream<Asset> primaryInputs;

  /// Creates a transform from a serialized map sent from the host isolate.
  ForeignAggregateTransform(Map transform)
      : primaryInputs = deserializeStream(
            transform['primaryInputs'], deserializeAsset),
        super(transform);

  Future<Asset> getInput(AssetId id) {
    return call(_port, {
      'type': 'getInput',
      'id': serializeId(id)
    }).then(deserializeAsset);
  }

  void addOutput(Asset output) {
    call(_port, {
      'type': 'addOutput',
      'output': serializeAsset(output)
    });
  }
}

/// A wrapper for a [DeclaringAggregateTransform] that's in the host isolate.
class ForeignDeclaringAggregateTransform
    extends _ForeignBaseAggregateTransform
    implements DeclaringAggregateTransform {
  final Stream<AssetId> primaryIds;

  /// Creates a transform from a serializable map sent from the host isolate.
  ForeignDeclaringAggregateTransform(Map transform)
      : primaryIds = deserializeStream(
            transform['primaryIds'], deserializeId),
        super(transform);

  void declareOutput(AssetId id) {
    call(_port, {
      'type': 'declareOutput',
      'output': serializeId(id)
    });
  }
}

//# end

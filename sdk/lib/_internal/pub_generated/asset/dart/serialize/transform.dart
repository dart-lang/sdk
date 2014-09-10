// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.asset.serialize.transform;

import 'dart:async';
import 'dart:isolate';

import 'package:barback/barback.dart';
// TODO(nweiz): don't import from "src" once issue 14966 is fixed.
import 'package:barback/src/internal_asset.dart';

import '../serialize.dart';
import 'get_input_transform.dart';

/// Serialize the methods shared between [Transform] and [DeclaringTransform].
///
/// [additionalFields] contains additional serialized fields to add to the
/// serialized transform. [methodHandlers] is a set of additional methods. Each
/// value should take a JSON message and return the response (which may be a
/// Future).
Map _serializeBaseTransform(transform, Map additionalFields,
    Map<String, Function> methodHandlers) {
  var receivePort = new ReceivePort();
  receivePort.listen((wrappedMessage) {
    respond(wrappedMessage, (message) {
      var handler = methodHandlers[message['type']];
      if (handler != null) return handler(message);

      if (message['type'] == 'consumePrimary') {
        transform.consumePrimary();
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

  return {'port': receivePort.sendPort}..addAll(additionalFields);
}

/// Converts [transform] into a serializable map.
Map serializeTransform(Transform transform) {
  return _serializeBaseTransform(transform, {
    'primaryInput': serializeAsset(transform.primaryInput)
  }, {
    'getInput': (message) => transform.getInput(deserializeId(message['id']))
        .then((asset) => serializeAsset(asset)),
    'addOutput': (message) =>
        transform.addOutput(deserializeAsset(message['output']))
  });
}

/// Converts [transform] into a serializable map.
Map serializeDeclaringTransform(DeclaringTransform transform) {
  return _serializeBaseTransform(transform, {
    'primaryId': serializeId(transform.primaryId)
  }, {
    'declareOutput': (message) =>
        transform.declareOutput(deserializeId(message['output']))
  });
}

/// The base class for wrappers for [Transform]s that are in the host isolate.
class _ForeignBaseTransform {
  /// The port with which we communicate with the host isolate.
  ///
  /// This port and all messages sent across it are specific to this transform.
  final SendPort _port;

  TransformLogger get logger => _logger;
  TransformLogger _logger;

  _ForeignBaseTransform(Map transform)
      : _port = transform['port'] {
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

  void consumePrimary() {
    call(_port, {'type': 'consumePrimary'});
  }
}

/// A wrapper for a [Transform] that's in the host isolate.
///
/// This retrieves inputs from and sends outputs and logs to the host isolate.
class ForeignTransform extends _ForeignBaseTransform
    with GetInputTransform implements Transform {
  final Asset primaryInput;

  /// Creates a transform from a serialized map sent from the host isolate.
  ForeignTransform(Map transform)
      : primaryInput = deserializeAsset(transform['primaryInput']),
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

/// A wrapper for a [DeclaringTransform] that's in the host isolate.
class ForeignDeclaringTransform extends _ForeignBaseTransform
    implements DeclaringTransform {
  final AssetId primaryId;

  /// Creates a transform from a serializable map sent from the host isolate.
  ForeignDeclaringTransform(Map transform)
      : primaryId = deserializeId(transform['primaryId']),
        super(transform);

  void declareOutput(AssetId id) {
    call(_port, {
      'type': 'declareOutput',
      'output': serializeId(id)
    });
  }
}

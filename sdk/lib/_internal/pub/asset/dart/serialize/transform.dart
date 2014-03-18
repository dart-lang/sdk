// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.asset.serialize.transform;

import 'dart:async';
import 'dart:isolate';
import 'dart:convert';

import 'package:barback/barback.dart';
// TODO(nweiz): don't import from "src" once issue 14966 is fixed.
import 'package:barback/src/internal_asset.dart';

import '../serialize.dart';
import '../utils.dart';

/// Converts [transform] into a serializable map.
Map serializeTransform(Transform transform) {
  var receivePort = new ReceivePort();
  receivePort.listen((wrappedMessage) {
    respond(wrappedMessage, (message) {
      if (message['type'] == 'getInput') {
        return transform.getInput(deserializeId(message['id']))
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
        deserializeId(message['assetId']);
      var span = message['span'] == null ? null :
        deserializeSpan(message['span']);
      method(message['message'], asset: assetId, span: span);
    });
  });

  return {
    'port': receivePort.sendPort,
    'primaryInput': serializeAsset(transform.primaryInput)
  };
}

/// A wrapper for a [Transform] that's in the host isolate.
///
/// This retrieves inputs from and sends outputs and logs to the host isolate.
class ForeignTransform implements Transform {
  /// The port with which we communicate with the host isolate.
  ///
  /// This port and all messages sent across it are specific to this transform.
  final SendPort _port;

  final Asset primaryInput;

  TransformLogger get logger => _logger;
  TransformLogger _logger;

  /// Creates a transform from a serializable map sent from the host isolate.
  ForeignTransform(Map transform)
      : _port = transform['port'],
        primaryInput = deserializeAsset(transform['primaryInput']) {
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

  Future<Asset> getInput(AssetId id) {
    return call(_port, {
      'type': 'getInput',
      'id': serializeId(id)
    }).then(deserializeAsset);
  }

  Future<String> readInputAsString(AssetId id, {Encoding encoding}) {
    if (encoding == null) encoding = UTF8;
    return getInput(id).then((input) => input.readAsString(encoding: encoding));
  }

  Stream<List<int>> readInput(AssetId id) =>
      futureStream(getInput(id).then((input) => input.read()));

  Future<bool> hasInput(AssetId id) {
    return getInput(id).then((_) => true).catchError((error) {
      if (error is AssetNotFoundException && error.id == id) return false;
      throw error;
    });
  }

  void addOutput(Asset output) {
    call(_port, {
      'type': 'addOutput',
      'output': serializeAsset(output)
    });
  }

  void consumePrimary() {
    call(_port, {'type': 'consumePrimary'});
  }
}

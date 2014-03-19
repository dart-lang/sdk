// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.asset.serialize.transformer;

import 'dart:isolate';

import 'package:barback/barback.dart';
// TODO(nweiz): don't import from "src" once issue 14966 is fixed.
import 'package:barback/src/internal_asset.dart';

import '../serialize.dart';
import 'transform.dart';

/// Converts [transformer] into a serializable map.
Map serializeTransformer(Transformer transformer) {
  var port = new ReceivePort();
  port.listen((wrappedMessage) {
    respond(wrappedMessage, (message) {
      if (message['type'] == 'isPrimary') {
        return transformer.isPrimary(deserializeAsset(message['asset']));
      } else {
        assert(message['type'] == 'apply');

        // Make sure we return null so that if the transformer's [apply] returns
        // a non-serializable value it doesn't cause problems.
        return transformer.apply(
            new ForeignTransform(message['transform'])).then((_) => null);
      }
    });
  });

  return {
    'type': 'Transformer',
    'toString': transformer.toString(),
    'port': port.sendPort
  };
}

// Converts [group] into a serializable map.
Map serializeTransformerGroup(TransformerGroup group) {
  return {
    'type': 'TransformerGroup',
    'toString': group.toString(),
    'phases': group.phases.map((phase) {
      return phase.map(serializeTransformerOrGroup).toList();
    }).toList()
  };
}

/// Converts [transformerOrGroup] into a serializable map.
Map serializeTransformerOrGroup(transformerOrGroup) {
  if (transformerOrGroup is Transformer) {
    return serializeTransformer(transformerOrGroup);
  } else {
    assert(transformerOrGroup is TransformerGroup);
    return serializeTransformerGroup(transformerOrGroup);
  }
}

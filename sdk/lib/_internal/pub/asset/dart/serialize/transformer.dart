// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.asset.serialize.transformer;

import 'dart:async';
import 'dart:isolate';

import 'package:barback/barback.dart';

import '../serialize.dart';
import '../utils.dart';
import 'transform.dart';

/// Converts [transformer] into a serializable map.
Map _serializeTransformer(Transformer transformer) {
  var port = new ReceivePort();
  port.listen((wrappedMessage) {
    respond(wrappedMessage, (message) {
      if (message['type'] == 'isPrimary') {
        return transformer.isPrimary(deserializeId(message['id']));
      } else if (message['type'] == 'declareOutputs') {
        return new Future.sync(() {
          return (transformer as DeclaringTransformer).declareOutputs(
              new ForeignDeclaringTransform(message['transform']));
        }).then((_) => null);
      } else {
        assert(message['type'] == 'apply');

        // Make sure we return null so that if the transformer's [apply] returns
        // a non-serializable value it doesn't cause problems.
        return new Future.sync(() {
          return transformer.apply(new ForeignTransform(message['transform']));
        }).then((_) => null);
      }
    });
  });

  var type;
  if (transformer is LazyTransformer) {
    type = 'LazyTransformer';
  } else if (transformer is DeclaringTransformer) {
    type = 'DeclaringTransformer';
  } else {
    type = 'Transformer';
  }

  return {
    'type': type,
    'toString': transformer.toString(),
    'port': port.sendPort
  };
}

// Converts [group] into a serializable map.
Map _serializeTransformerGroup(TransformerGroup group) {
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
    return _serializeTransformer(transformerOrGroup);
  } else {
    assert(transformerOrGroup is TransformerGroup);
    return _serializeTransformerGroup(transformerOrGroup);
  }
}

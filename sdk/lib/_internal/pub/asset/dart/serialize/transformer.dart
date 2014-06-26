// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.asset.serialize.transformer;

import 'dart:async';
import 'dart:isolate';

import 'package:barback/barback.dart';

import '../serialize.dart';
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

/// Converts [transformer] into a serializable map.
Map _serializeAggregateTransformer(AggregateTransformer transformer) {
  var port = new ReceivePort();
  port.listen((wrappedMessage) {
    respond(wrappedMessage, (message) {
      if (message['type'] == 'classifyPrimary') {
        return transformer.classifyPrimary(deserializeId(message['id']));
      } else if (message['type'] == 'declareOutputs') {
        return new Future.sync(() {
          return (transformer as DeclaringAggregateTransformer).declareOutputs(
              new ForeignDeclaringAggregateTransform(message['transform']));
        }).then((_) => null);
      } else {
        assert(message['type'] == 'apply');

        // Make sure we return null so that if the transformer's [apply] returns
        // a non-serializable value it doesn't cause problems.
        return new Future.sync(() {
          return transformer.apply(
              new ForeignAggregateTransform(message['transform']));
        }).then((_) => null);
      }
    });
  });

  var type;
  if (transformer is LazyAggregateTransformer) {
    type = 'LazyAggregateTransformer';
  } else if (transformer is DeclaringAggregateTransformer) {
    type = 'DeclaringAggregateTransformer';
  } else {
    type = 'AggregateTransformer';
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
      return phase.map(serializeTransformerLike).toList();
    }).toList()
  };
}

/// Converts [transformerLike] into a serializable map.
///
/// [transformerLike] can be a [Transformer], an [AggregateTransformer], or a
/// [TransformerGroup].
Map serializeTransformerLike(transformerLike) {
  if (transformerLike is Transformer) {
    return _serializeTransformer(transformerLike);
  } else if (transformerLike is TransformerGroup) {
    return _serializeTransformerGroup(transformerLike);
  } else {
    // This has to be last, since "transformerLike is AggregateTransformer" will
    // throw on older versions of barback.
    assert(transformerLike is AggregateTransformer);
    return _serializeAggregateTransformer(transformerLike);
  }
}

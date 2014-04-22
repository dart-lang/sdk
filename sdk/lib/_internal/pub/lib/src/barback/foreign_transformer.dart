// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.foreign_transformer;

import 'dart:async';
import 'dart:isolate';

import 'package:barback/barback.dart';

import '../../../asset/dart/serialize.dart';
import '../barback.dart';
import 'excluding_transformer.dart';

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

  Future<bool> isPrimary(AssetId id) {
    return call(_port, {
      'type': 'isPrimary',
      'id': serializeId(id)
    });
  }

  Future apply(Transform transform) {
    return call(_port, {
      'type': 'apply',
      'transform': serializeTransform(transform)
    });
  }

  String toString() => _toString;
}

class _ForeignDeclaringTransformer extends _ForeignTransformer
    implements DeclaringTransformer {
  _ForeignDeclaringTransformer(Map map)
      : super(map);

  Future declareOutputs(DeclaringTransform transform) {
    return call(_port, {
      'type': 'declareOutputs',
      'transform': serializeDeclaringTransform(transform)
    });
  }
}

class _ForeignLazyTransformer extends _ForeignDeclaringTransformer
    implements LazyTransformer {
  _ForeignLazyTransformer(Map map)
      : super(map);
}

/// A wrapper for a transformer group that's in a different isolate.
class _ForeignGroup implements TransformerGroup {
  final Iterable<Iterable> phases;

  /// The result of calling [toString] on the transformer group in the isolate.
  final String _toString;

  _ForeignGroup(TransformerId id, Map map)
      : phases = map['phases'].map((phase) {
          return phase.map((transformer) => deserializeTransformerOrGroup(
              transformer, id)).toList();
        }).toList(),
        _toString = map['toString'];

  String toString() => _toString;
}

/// Converts a serializable map into a [Transformer] or a [TransformerGroup].
deserializeTransformerOrGroup(Map map, TransformerId id) {
  var transformer;
  switch(map['type']) {
    case 'TransformerGroup': return new _ForeignGroup(id, map);
    case 'Transformer':
      transformer = new _ForeignTransformer(map);
      break;
    case 'DeclaringTransformer':
      transformer = new _ForeignDeclaringTransformer(map);
      break;
    case 'LazyTransformer':
      transformer = new _ForeignLazyTransformer(map);
      break;
    default: assert(false);
  }

  return ExcludingTransformer.wrap(transformer, id.includes, id.excludes);
}

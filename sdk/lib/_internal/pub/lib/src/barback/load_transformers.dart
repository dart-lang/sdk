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

import '../../../asset/dart/serialize.dart';
import '../barback.dart';
import '../dart.dart' as dart;
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
    var uri = baseUrl.resolve('packages/${id.package}/$path');
    var code = """
        import 'dart:isolate';

        import '$uri';

        import r'$baseUrl/packages/\$pub/transformer_isolate.dart';

        void main(_, SendPort replyTo) => loadTransformers(replyTo);
        """;
    log.fine("Loading transformers from $assetId");

    var port = new ReceivePort();
    return dart.runInIsolate(code, port.sendPort)
        .then((_) => port.first)
        .then((sendPort) {
      return call(sendPort, {
        'library': uri.toString(),
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
      if (error is! CrossIsolateException) throw error;
      if (error.type != 'IsolateSpawnException') throw error;
      // TODO(nweiz): don't parse this as a string once issues 12617 and 12689
      // are fixed.
      if (!error.message.split('\n')[1].endsWith("import '$uri';")) {
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
    return call(_port, {
      'type': 'isPrimary',
      'asset': serializeAsset(asset)
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

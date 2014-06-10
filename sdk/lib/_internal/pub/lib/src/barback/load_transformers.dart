// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.load_transformers;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import '../../../asset/dart/serialize.dart';
import '../barback.dart';
import '../dart.dart' as dart;
import '../log.dart' as log;
import '../utils.dart';
import 'asset_environment.dart';
import 'foreign_transformer.dart';
import 'barback_server.dart';

/// Load and return all transformers and groups from the library identified by
/// [id].
Future<Set> loadTransformers(AssetEnvironment environment,
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
            (transformer) => deserializeTransformerLike(transformer, id))
            .toSet();
        log.fine("Transformers from $assetId: $transformers");
        return transformers;
      });
    }).catchError((error, stackTrace) {
      if (error is! CrossIsolateException) throw error;
      if (error.type != 'IsolateSpawnException') throw error;
      // TODO(nweiz): don't parse this as a string once issues 12617 and 12689
      // are fixed.
      if (!error.message.split('\n')[1].startsWith("Failure getting $uri:")) {
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

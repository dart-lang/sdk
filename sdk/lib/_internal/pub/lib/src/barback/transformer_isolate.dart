// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.transformer_isolate;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:barback/barback.dart';

import '../../../asset/dart/serialize.dart';
import '../barback.dart';
import '../dart.dart' as dart;
import '../log.dart' as log;
import '../utils.dart';
import 'asset_environment.dart';
import 'barback_server.dart';
import 'foreign_transformer.dart';
import 'transformer_config.dart';
import 'transformer_id.dart';

/// A wrapper for an isolate from which transformer plugins can be instantiated.
class TransformerIsolate {
  /// The port used to communicate with the wrapped isolate.
  final SendPort _port;

  /// A map indicating the barback server URLs for each [TransformerId] that's
  /// loaded in the wrapped isolate.
  ///
  /// A barback server URL is the URL for the library that the given id
  /// identifies. For example, the URL for "polymer/src/mirrors_remover" might
  /// be "http://localhost:56234/packages/polymer/src/mirrors_remover.dart".
  final Map<TransformerId, Uri> _idsToUrls;

  /// The barback mode for this run of pub.
  final BarbackMode _mode;

  /// Spawns an isolate that loads all transformer libraries defined by [ids].
  ///
  /// This doesn't actually instantiate any transformers, since a
  /// [TransformerId] doesn't define the transformers' configuration. The
  /// transformers can be constructed using [create].
  static Future<TransformerIsolate> spawn(AssetEnvironment environment,
      BarbackServer transformerServer, List<TransformerId> ids) {
    return mapFromIterableAsync(ids, value: (id) {
      return id.getAssetId(environment.barback);
    }).then((idsToAssetIds) {
      var baseUrl = transformerServer.url;
      var idsToUrls = mapMap(idsToAssetIds, value: (id, assetId) {
        var path = assetId.path.replaceFirst('lib/', '');
        // TODO(nweiz): load from a "package:" URI when issue 12474 is fixed.
        return baseUrl.resolve('packages/${id.package}/$path');
      });

      var code = new StringBuffer();
      code.writeln("import 'dart:isolate';");

      for (var url in idsToUrls.values) {
        code.writeln("import '$url';");
      }

      code.writeln("import "
          "r'$baseUrl/packages/\$pub/transformer_isolate.dart';");
      code.writeln(
          "void main(_, SendPort replyTo) => loadTransformers(replyTo);");

      log.fine("Loading transformers from $ids");

      var port = new ReceivePort();
      return dart.runInIsolate(code.toString(), port.sendPort)
          .then((_) => port.first)
          .then((sendPort) {
        return new TransformerIsolate._(sendPort, environment.mode, idsToUrls);
      }).catchError((error, stackTrace) {
        if (error is! CrossIsolateException) throw error;
        if (error.type != 'IsolateSpawnException') throw error;

        // TODO(nweiz): don't parse this as a string once issues 12617 and 12689
        // are fixed.
        var firstErrorLine = error.message.split('\n')[1];
        var missingTransformer = idsToUrls.keys.firstWhere((id) =>
                firstErrorLine.startsWith("Failure getting ${idsToUrls[id]}:"),
            orElse: () => throw error);
        var packageUri = idToPackageUri(idsToAssetIds[missingTransformer]);

        // If there was an IsolateSpawnException and the import that actually
        // failed was the one we were loading transformers from, throw an
        // application exception with a more user-friendly message.
        fail('Transformer library "$packageUri" not found.',
            error, stackTrace);
      });
    });
  }

  TransformerIsolate._(this._port, this._mode, this._idsToUrls);

  /// Instantiate the transformers in the [config.id] with
  /// [config.configuration].
  ///
  /// If there are no transformers defined in the given library, this will
  /// return an empty set.
  Future<Set<Transformer>> create(TransformerConfig config) {
    return call(_port, {
      'library': _idsToUrls[config.id].toString(),
      'mode': _mode.name,
      'configuration': JSON.encode(config.configuration)
    }).then((transformers) {
      transformers = transformers.map(
          (transformer) => deserializeTransformerLike(transformer, config))
          .toSet();
      log.fine("Transformers from $config: $transformers");
      return transformers;
    });
  }
}

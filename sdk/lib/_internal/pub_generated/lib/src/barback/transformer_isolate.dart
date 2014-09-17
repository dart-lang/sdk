library pub.transformer_isolate;
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:barback/barback.dart';
import 'package:source_span/source_span.dart';
import 'package:stack_trace/stack_trace.dart';
import '../../../asset/dart/serialize.dart';
import '../barback.dart';
import '../exceptions.dart';
import '../dart.dart' as dart;
import '../log.dart' as log;
import '../utils.dart';
import 'asset_environment.dart';
import 'barback_server.dart';
import 'foreign_transformer.dart';
import 'transformer_config.dart';
import 'transformer_id.dart';
class TransformerIsolate {
  final SendPort _port;
  final Map<TransformerId, Uri> _idsToUrls;
  final BarbackMode _mode;
  static Future<TransformerIsolate> spawn(AssetEnvironment environment,
      BarbackServer transformerServer, List<TransformerId> ids, {String snapshot}) {
    return mapFromIterableAsync(ids, value: (id) {
      return id.getAssetId(environment.barback);
    }).then((idsToAssetIds) {
      var baseUrl = transformerServer.url;
      var idsToUrls = mapMap(idsToAssetIds, value: (id, assetId) {
        var path = assetId.path.replaceFirst('lib/', '');
        return baseUrl.resolve('packages/${id.package}/$path');
      });
      var code = new StringBuffer();
      code.writeln("import 'dart:isolate';");
      for (var url in idsToUrls.values) {
        code.writeln("import '$url';");
      }
      code.writeln(
          "import " "r'$baseUrl/packages/\$pub/transformer_isolate.dart';");
      code.writeln(
          "void main(_, SendPort replyTo) => loadTransformers(replyTo);");
      log.fine("Loading transformers from $ids");
      var port = new ReceivePort();
      return dart.runInIsolate(
          code.toString(),
          port.sendPort,
          snapshot: snapshot).then((_) => port.first).then((sendPort) {
        return new TransformerIsolate._(sendPort, environment.mode, idsToUrls);
      }).catchError((error, stackTrace) {
        if (error is! CrossIsolateException) throw error;
        if (error.type != 'IsolateSpawnException') throw error;
        var firstErrorLine = error.message.split('\n')[1];
        var missingTransformer = idsToUrls.keys.firstWhere(
            (id) =>
                firstErrorLine.startsWith("Uncaught Error: Failure getting ${idsToUrls[id]}:"),
            orElse: () => throw error);
        var packageUri = idToPackageUri(idsToAssetIds[missingTransformer]);
        fail('Transformer library "$packageUri" not found.', error, stackTrace);
      });
    });
  }
  TransformerIsolate._(this._port, this._mode, this._idsToUrls);
  Future<Set<Transformer>> create(TransformerConfig config) {
    return call(_port, {
      'library': _idsToUrls[config.id].path.toString(),
      'mode': _mode.name,
      'configuration': JSON.encode(config.configuration)
    }).then((transformers) {
      transformers = transformers.map(
          (transformer) => deserializeTransformerLike(transformer, config)).toSet();
      log.fine("Transformers from $config: $transformers");
      return transformers;
    }).catchError((error, stackTrace) {
      throw new TransformerLoadError(error, config.span);
    });
  }
}
class TransformerLoadError extends SourceSpanException implements
    WrappedException {
  final CrossIsolateException innerError;
  Chain get innerChain => innerError.stackTrace;
  TransformerLoadError(CrossIsolateException error, SourceSpan span)
      : innerError = error,
        super("Error loading transformer: ${error.message}", span);
}

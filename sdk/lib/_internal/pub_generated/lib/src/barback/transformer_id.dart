library pub.barback.transformer_id;
import 'dart:async';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart';
import '../io.dart';
import '../utils.dart';
const _BUILT_IN_TRANSFORMERS = const ['\$dart2js'];
class TransformerId {
  final String package;
  final String path;
  final SourceSpan span;
  bool get isBuiltInTransformer => package.startsWith('\$');
  factory TransformerId.parse(String identifier, SourceSpan span) {
    if (identifier.isEmpty) {
      throw new FormatException('Invalid library identifier: "".');
    }
    var parts = split1(identifier, "/");
    if (parts.length == 1) {
      return new TransformerId(parts.single, null, span);
    }
    return new TransformerId(parts.first, parts.last, span);
  }
  TransformerId(this.package, this.path, this.span) {
    if (!package.startsWith('\$')) return;
    if (_BUILT_IN_TRANSFORMERS.contains(package)) return;
    throw new SourceSpanFormatException(
        'Unsupported built-in transformer $package.',
        span);
  }
  bool operator ==(other) =>
      other is TransformerId && other.package == package && other.path == path;
  int get hashCode => package.hashCode ^ path.hashCode;
  String toString() => path == null ? package : '$package/$path';
  Future<AssetId> getAssetId(Barback barback) {
    if (path != null) {
      return new Future.value(new AssetId(package, 'lib/$path.dart'));
    }
    var transformerAsset = new AssetId(package, 'lib/transformer.dart');
    return barback.getAssetById(
        transformerAsset).then(
            (_) =>
                transformerAsset).catchError(
                    (e) => new AssetId(package, 'lib/$package.dart'),
                    test: (e) => e is AssetNotFoundException);
  }
  String getFullPath(String packageDir) {
    if (path != null) return p.join(packageDir, 'lib', p.fromUri('$path.dart'));
    var transformerPath = p.join(packageDir, 'lib', 'transformer.dart');
    if (fileExists(transformerPath)) return transformerPath;
    return p.join(packageDir, 'lib', '$package.dart');
  }
}

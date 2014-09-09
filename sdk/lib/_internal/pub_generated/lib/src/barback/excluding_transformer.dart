library pub.excluding_transformer;
import 'dart:async';
import 'package:barback/barback.dart';
import 'transformer_config.dart';
class ExcludingTransformer extends Transformer {
  static Transformer wrap(Transformer inner, TransformerConfig config) {
    if (!config.hasExclusions) return inner;
    if (inner is LazyTransformer) {
      return new _LazyExcludingTransformer(inner as LazyTransformer, config);
    } else if (inner is DeclaringTransformer) {
      return new _DeclaringExcludingTransformer(
          inner as DeclaringTransformer,
          config);
    } else {
      return new ExcludingTransformer._(inner, config);
    }
  }
  final Transformer _inner;
  final TransformerConfig _config;
  ExcludingTransformer._(this._inner, this._config);
  isPrimary(AssetId id) {
    if (!_config.canTransform(id.path)) return false;
    return _inner.isPrimary(id);
  }
  Future apply(Transform transform) => _inner.apply(transform);
  String toString() => _inner.toString();
}
class _DeclaringExcludingTransformer extends ExcludingTransformer implements
    DeclaringTransformer {
  _DeclaringExcludingTransformer(DeclaringTransformer inner,
      TransformerConfig config)
      : super._(inner as Transformer, config);
  Future declareOutputs(DeclaringTransform transform) =>
      (_inner as DeclaringTransformer).declareOutputs(transform);
}
class _LazyExcludingTransformer extends _DeclaringExcludingTransformer
    implements LazyTransformer {
  _LazyExcludingTransformer(DeclaringTransformer inner,
      TransformerConfig config)
      : super(inner, config);
}

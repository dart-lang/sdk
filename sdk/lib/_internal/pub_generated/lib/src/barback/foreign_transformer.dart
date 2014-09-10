library pub.foreign_transformer;
import 'dart:async';
import 'dart:isolate';
import 'package:barback/barback.dart';
import '../../../asset/dart/serialize.dart';
import 'excluding_transformer.dart';
import 'excluding_aggregate_transformer.dart';
import 'transformer_config.dart';
class _ForeignTransformer extends Transformer {
  final SendPort _port;
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
class _ForeignDeclaringTransformer extends _ForeignTransformer implements
    DeclaringTransformer {
  _ForeignDeclaringTransformer(Map map) : super(map);
  Future declareOutputs(DeclaringTransform transform) {
    return call(_port, {
      'type': 'declareOutputs',
      'transform': serializeDeclaringTransform(transform)
    });
  }
}
class _ForeignLazyTransformer extends _ForeignDeclaringTransformer implements
    LazyTransformer {
  _ForeignLazyTransformer(Map map) : super(map);
}
class _ForeignAggregateTransformer extends AggregateTransformer {
  final SendPort _port;
  final String _toString;
  _ForeignAggregateTransformer(Map map)
      : _port = map['port'],
        _toString = map['toString'];
  Future<String> classifyPrimary(AssetId id) {
    return call(_port, {
      'type': 'classifyPrimary',
      'id': serializeId(id)
    });
  }
  Future apply(AggregateTransform transform) {
    return call(_port, {
      'type': 'apply',
      'transform': serializeAggregateTransform(transform)
    });
  }
  String toString() => _toString;
}
class _ForeignDeclaringAggregateTransformer extends _ForeignAggregateTransformer
    implements DeclaringAggregateTransformer {
  _ForeignDeclaringAggregateTransformer(Map map) : super(map);
  Future declareOutputs(DeclaringAggregateTransform transform) {
    return call(_port, {
      'type': 'declareOutputs',
      'transform': serializeDeclaringAggregateTransform(transform)
    });
  }
}
class _ForeignLazyAggregateTransformer extends
    _ForeignDeclaringAggregateTransformer implements LazyAggregateTransformer {
  _ForeignLazyAggregateTransformer(Map map) : super(map);
}
class _ForeignGroup implements TransformerGroup {
  final Iterable<Iterable> phases;
  final String _toString;
  _ForeignGroup(TransformerConfig config, Map map)
      : phases = map['phases'].map((phase) {
        return phase.map(
            (transformer) => deserializeTransformerLike(transformer, config)).toList();
      }).toList(),
        _toString = map['toString'];
  String toString() => _toString;
}
deserializeTransformerLike(Map map, TransformerConfig config) {
  var transformer;
  switch (map['type']) {
    case 'TransformerGroup':
      return new _ForeignGroup(config, map);
    case 'Transformer':
      transformer = new _ForeignTransformer(map);
      break;
    case 'DeclaringTransformer':
      transformer = new _ForeignDeclaringTransformer(map);
      break;
    case 'LazyTransformer':
      transformer = new _ForeignLazyTransformer(map);
      break;
    case 'AggregateTransformer':
      transformer = new _ForeignAggregateTransformer(map);
      break;
    case 'DeclaringAggregateTransformer':
      transformer = new _ForeignDeclaringAggregateTransformer(map);
      break;
    case 'LazyAggregateTransformer':
      transformer = new _ForeignLazyAggregateTransformer(map);
      break;
    default:
      assert(false);
  }
  if (transformer is Transformer) {
    return ExcludingTransformer.wrap(transformer, config);
  } else {
    assert(transformer is AggregateTransformer);
    return ExcludingAggregateTransformer.wrap(transformer, config);
  }
}

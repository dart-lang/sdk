// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../inferrer/types.dart';
import '../serialization/serialization.dart';
import 'abstract_value_domain.dart';

class KernelGlobalTypeInferenceElementData
    implements GlobalTypeInferenceElementData {
  /// Tag used for identifying serialized [GlobalTypeInferenceElementData]
  /// objects in a debugging data stream.
  static const String tag = 'global-type-inference-element-data';

  Map<ir.TreeNode, AbstractValue>? _receiverMap;

  Map<ir.ForInStatement, AbstractValue>? _iteratorMap;
  Map<ir.ForInStatement, AbstractValue>? _currentMap;
  Map<ir.ForInStatement, AbstractValue>? _moveNextMap;
  KernelGlobalTypeInferenceElementData();

  KernelGlobalTypeInferenceElementData.internal(this._receiverMap,
      this._iteratorMap, this._currentMap, this._moveNextMap);

  /// Deserializes a [GlobalTypeInferenceElementData] object from [source].
  factory KernelGlobalTypeInferenceElementData.readFromDataSource(
      DataSourceReader source,
      ir.Member? context,
      AbstractValueDomain abstractValueDomain) {
    return source.inMemberContext(context, () {
      source.begin(tag);
      Map<ir.TreeNode, AbstractValue>? sendMap =
          source.readTreeNodeMapInContextOrNull(() =>
              abstractValueDomain.readAbstractValueFromDataSource(source));
      Map<ir.ForInStatement, AbstractValue>? iteratorMap =
          source.readTreeNodeMapInContextOrNull(() =>
              abstractValueDomain.readAbstractValueFromDataSource(source));
      Map<ir.ForInStatement, AbstractValue>? currentMap =
          source.readTreeNodeMapInContextOrNull(() =>
              abstractValueDomain.readAbstractValueFromDataSource(source));
      Map<ir.ForInStatement, AbstractValue>? moveNextMap =
          source.readTreeNodeMapInContextOrNull(() =>
              abstractValueDomain.readAbstractValueFromDataSource(source));
      source.end(tag);
      return KernelGlobalTypeInferenceElementData.internal(
          sendMap, iteratorMap, currentMap, moveNextMap);
    });
  }

  @override
  void writeToDataSink(DataSinkWriter sink, ir.Member? context,
      AbstractValueDomain abstractValueDomain) {
    sink.inMemberContext(context, () {
      sink.begin(tag);
      sink.writeTreeNodeMapInContext(
          _receiverMap,
          (AbstractValue value) =>
              abstractValueDomain.writeAbstractValueToDataSink(sink, value),
          allowNull: true);
      sink.writeTreeNodeMapInContext(
          _iteratorMap,
          (AbstractValue value) =>
              abstractValueDomain.writeAbstractValueToDataSink(sink, value),
          allowNull: true);
      sink.writeTreeNodeMapInContext(
          _currentMap,
          (AbstractValue value) =>
              abstractValueDomain.writeAbstractValueToDataSink(sink, value),
          allowNull: true);
      sink.writeTreeNodeMapInContext(
          _moveNextMap,
          (AbstractValue value) =>
              abstractValueDomain.writeAbstractValueToDataSink(sink, value),
          allowNull: true);
      sink.end(tag);
    });
  }

  @override
  GlobalTypeInferenceElementData? compress() {
    final receiverMap = _receiverMap;
    if (receiverMap != null) {
      receiverMap.removeWhere(_mapsToNull);
      if (receiverMap.isEmpty) {
        _receiverMap = null;
      }
    }
    final iteratorMap = _iteratorMap;
    if (iteratorMap != null) {
      iteratorMap.removeWhere(_mapsToNull);
      if (iteratorMap.isEmpty) {
        _iteratorMap = null;
      }
    }
    final currentMap = _currentMap;
    if (currentMap != null) {
      currentMap.removeWhere(_mapsToNull);
      if (currentMap.isEmpty) {
        _currentMap = null;
      }
    }
    final moveNextMap = _moveNextMap;
    if (moveNextMap != null) {
      moveNextMap.removeWhere(_mapsToNull);
      if (moveNextMap.isEmpty) {
        _moveNextMap = null;
      }
    }
    if (_receiverMap == null &&
        _iteratorMap == null &&
        _currentMap == null &&
        _moveNextMap == null) {
      return null;
    }
    return this;
  }

  @override
  AbstractValue? typeOfReceiver(ir.TreeNode node) {
    if (_receiverMap == null) return null;
    return _receiverMap![node];
  }

  void setCurrentTypeMask(ir.ForInStatement node, AbstractValue mask) {
    _currentMap ??= <ir.ForInStatement, AbstractValue>{};
    _currentMap![node] = mask;
  }

  void setMoveNextTypeMask(ir.ForInStatement node, AbstractValue mask) {
    _moveNextMap ??= <ir.ForInStatement, AbstractValue>{};
    _moveNextMap![node] = mask;
  }

  void setIteratorTypeMask(ir.ForInStatement node, AbstractValue mask) {
    _iteratorMap ??= <ir.ForInStatement, AbstractValue>{};
    _iteratorMap![node] = mask;
  }

  @override
  AbstractValue? typeOfIteratorCurrent(covariant ir.ForInStatement node) {
    if (_currentMap == null) return null;
    return _currentMap![node];
  }

  @override
  AbstractValue? typeOfIteratorMoveNext(covariant ir.ForInStatement node) {
    if (_moveNextMap == null) return null;
    return _moveNextMap![node];
  }

  @override
  AbstractValue? typeOfIterator(covariant ir.ForInStatement node) {
    if (_iteratorMap == null) return null;
    return _iteratorMap![node];
  }

  void setReceiverTypeMask(ir.TreeNode node, AbstractValue mask) {
    _receiverMap ??= <ir.TreeNode, AbstractValue>{};
    _receiverMap![node] = mask;
  }
}

bool _mapsToNull(ir.TreeNode node, AbstractValue? value) => value == null;

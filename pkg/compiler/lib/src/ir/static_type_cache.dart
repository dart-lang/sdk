// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../serialization/serialization.dart';

class StaticTypeCache {
  static const String tag = 'static-type-cache';

  final Map<ir.Expression, ir.DartType> _expressionTypes;
  final Map<ir.ForInStatement, ir.DartType> _forInIteratorTypes;

  const StaticTypeCache(
      [this._expressionTypes = const {}, this._forInIteratorTypes]);

  factory StaticTypeCache.readFromDataSource(
      DataSource source, ir.Member context) {
    return source.inMemberContext(context, () {
      source.begin(tag);
      Map<ir.Expression, ir.DartType> expressionTypes =
          source.readTreeNodeMapInContext(source.readDartTypeNode);
      Map<ir.ForInStatement, ir.DartType> forInIteratorTypes = source
          .readTreeNodeMapInContext(source.readDartTypeNode, emptyAsNull: true);
      source.end(tag);
      return new StaticTypeCache(expressionTypes, forInIteratorTypes);
    });
  }

  void writeToDataSink(DataSink sink, ir.Member context) {
    sink.inMemberContext(context, () {
      sink.begin(tag);
      sink.writeTreeNodeMapInContext(_expressionTypes, sink.writeDartTypeNode);
      sink.writeTreeNodeMapInContext(
          _forInIteratorTypes, sink.writeDartTypeNode,
          allowNull: true);
      sink.end(tag);
    });
  }

  ir.DartType operator [](ir.Expression node) => _expressionTypes[node];

  ir.DartType getForInIteratorType(ir.ForInStatement node) {
    return _forInIteratorTypes != null ? _forInIteratorTypes[node] : null;
  }
}

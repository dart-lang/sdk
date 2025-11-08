// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../ir/ir.dart' as ir;
import 'builder.dart';

/// Builder for the elements section of a wasm module.
class ElementsBuilder with Builder<ir.Elements> {
  final ModuleBuilder _moduleBuilder;
  final _functionTableBuilders = <ir.Table, ActiveFunctionSegmentBuilder>{};

  late final declarativeSegmentBuilder =
      DeclarativeSegmentBuilder(_moduleBuilder);

  ElementsBuilder(this._moduleBuilder);

  ActiveFunctionSegmentBuilder activeFunctionSegmentBuilderFor(ir.Table table) {
    assert(table.type.isSubtypeOf(ir.RefType.func(nullable: true)));
    assert(table.enclosingModule == _moduleBuilder.module);
    return _functionTableBuilders.putIfAbsent(
        table, () => ActiveFunctionSegmentBuilder(table));
  }

  @override
  ir.Elements forceBuild() {
    final segments = <ir.ElementSegment>[];
    for (final b in _functionTableBuilders.values) {
      segments.addAll(b.build());
    }
    if (declarativeSegmentBuilder._declaredFunctions.isNotEmpty) {
      segments.add(declarativeSegmentBuilder.build());
    }
    return ir.Elements(segments);
  }
}

class DeclarativeSegmentBuilder with Builder<ir.DeclarativeElementSegment> {
  final ModuleBuilder _moduleBuilder;
  final _declaredFunctions = <ir.BaseFunction>{};

  DeclarativeSegmentBuilder(this._moduleBuilder);

  /// Pre-declare [function] in a declared segment which allows using that
  /// function in `ref.func` constant instructions.
  void declare(ir.BaseFunction function) {
    assert(function.enclosingModule == _moduleBuilder.module);
    _declaredFunctions.add(function);
  }

  @override
  ir.DeclarativeElementSegment forceBuild() =>
      ir.DeclarativeElementSegment(_declaredFunctions.toList());
}

class ActiveFunctionSegmentBuilder with Builder<List<ir.ActiveElementSegment>> {
  final ir.Table table;
  final Map<int, ir.BaseFunction> _functions = {};

  ActiveFunctionSegmentBuilder(this.table);

  void setFunctionAt(int index, ir.BaseFunction function) {
    assert(function.enclosingModule == table.enclosingModule);
    assert(table.maxSize == null || index < table.maxSize!,
        'Index $index greater than max table size ${table.maxSize}');
    _functions[index] = function;
    table.minSize = math.max(table.minSize, index + 1);
  }

  @override
  List<ir.ActiveElementSegment> forceBuild() {
    final entries = _functions.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final segments = <ir.ActiveElementSegment>[];
    if (const ir.RefType.func(nullable: false).isSubtypeOf(table.type)) {
      ir.ActiveFunctionElementSegment? current;
      int lastIndex = -2;
      for (final entry in entries) {
        final index = entry.key;
        final function = entry.value;
        if (index != lastIndex + 1) {
          current = ir.ActiveFunctionElementSegment(table, index);
          segments.add(current);
        }
        current!.entries.add(function);
        lastIndex = index;
      }
    } else {
      ir.ActiveExpressionElementSegment? current;
      int lastIndex = -2;
      for (final entry in entries) {
        final index = entry.key;
        final function = entry.value;
        if (index != lastIndex + 1) {
          current = ir.ActiveExpressionElementSegment(table, table.type, index);
          segments.add(current);
        }
        current!.expressions.add([ir.RefFunc(function), ir.End()]);
        lastIndex = index;
      }
    }
    return segments;
  }
}
